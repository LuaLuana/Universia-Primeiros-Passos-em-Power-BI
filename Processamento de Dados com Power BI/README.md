# Desafio de Projeto — Integrando Dados com MySQL (Aiven) e Transformando com Power BI

Versão do desafio usando **MySQL no Aiven** no lugar do MySQL na Azure. O banco `company` é pequeno, mas tem problemas de qualidade propositais para praticar as transformações.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `01_schema_e_dados.sql` | Cria o banco `company`, as tabelas e os dados de exemplo |
| `02_diagnostico_e_consultas.sql` | Diagnóstico dos problemas, correções e as consultas SQL do desafio |
| `README.md` | Passo a passo, código do Power Query e respostas às diretrizes |

## 1. Criando o banco no Aiven

Execute o `01_schema_e_dados.sql` no Workbench (ou no cliente `mysql`) conectado ao serviço do Aiven.

- O Aiven exige **chave primária em todas as tabelas**, por isso todas as tabelas do script têm PK.
- A conexão exige **SSL**. Use o certificado CA (`ca.pem`) que o Aiven disponibiliza no painel do serviço.

**Modelo:** `employee` (Super_ssn → employee, Dno → department) · `department` (Mgr_ssn → employee) · `dept_locations` · `project` · `works_on`

## 2. Conectando o Power BI

1. **Obter dados → Banco de dados MySQL**.
2. Servidor: `host-do-aiven:porta` (o Aiven usa uma porta diferente da 3306, veja no painel). Banco: `company`.
3. É necessário ter o **MySQL Connector/NET** instalado. Se houver erro de certificado, pode ser preciso instalar o CA do Aiven no repositório de certificados do Windows.
4. Selecione as 5 tabelas e clique em **Transformar dados**.

## 3. Diagnóstico (SQL)

Rode o bloco de diagnóstico do `02_diagnostico_e_consultas.sql`. O que ele revela:

| Diretriz | Achado |
|---|---|
| 3. Nulos | `Minit` e `Super_ssn` têm nulos |
| 4. Colaborador sem gerente | James Borg (diretor, nulo legítimo) e **Maria Souza** (nulo que precisa ser corrigido) |
| 5. Departamento sem gerente | **Marketing (6)** |
| 6. Preencher lacunas | Supondo que Maria gerencia Marketing e responde ao Borg (`UPDATE` no script) |
| 7. Horas dos projetos | Borg e Maria têm horas nulas; o projeto **Campaign (40)** não tem nenhuma hora |

## 4. Transformações no Power Query

Crie as consultas abaixo no **Editor Avançado** (Página Inicial → Editor Avançado). Troque `HOST:PORTA` pelo seu servidor. As consultas `stg_*` são de preparação: desmarque **Habilitar carga** nelas.

### `stg_department` (diretrizes 1 e 2)

```m
let
    Fonte = MySQL.Database("HOST:PORTA", "company", [ReturnSingleDatabase = true]),
    Dept  = Fonte{[Schema = "company", Item = "department"]}[Data],
    Tipos = Table.TransformColumnTypes(Dept, {{"Dnumber", Int64.Type}, {"Mgr_start_date", type date}})
in
    Tipos
```

### `stg_employee` (diretrizes 1, 2, 8 e 12)

```m
let
    Fonte = MySQL.Database("HOST:PORTA", "company", [ReturnSingleDatabase = true]),
    Emp   = Fonte{[Schema = "company", Item = "employee"]}[Data],

    // 1 e 2: tipos. "type number" = número decimal (double) no Power BI
    Tipos = Table.TransformColumnTypes(Emp, {{"Salary", type number}, {"Bdate", type date}}),

    // 8: separa a coluna complexa Address em Rua, Cidade e Estado
    Endereco = Table.SplitColumn(
        Tipos, "Address",
        Splitter.SplitTextByDelimiter(", ", QuoteStyle.Csv),
        {"Rua", "Cidade", "Estado"}),

    // 12: junta Nome e Sobrenome em uma coluna só
    Nome = Table.CombineColumns(
        Endereco, {"Fname", "Lname"},
        Combiner.CombineTextByDelimiter(" ", QuoteStyle.None), "Nome")
in
    Nome
```

### `Employee` — tabela final (diretrizes 9, 10, 11 e 16)

```m
let
    // 9: mescla com department. Base é employee, então a junção é Left Outer
    // (mantém todo colaborador, mesmo sem departamento)
    MescladoDepto = Table.NestedJoin(stg_employee, {"Dno"}, stg_department, {"Dnumber"}, "Dept", JoinKind.LeftOuter),
    ExpDepto      = Table.ExpandTableColumn(MescladoDepto, "Dept", {"Dname"}, {"Departamento"}),

    // 11: auto-mescla para trazer o nome do gerente (Super_ssn -> Ssn)
    MescladoGer   = Table.NestedJoin(ExpDepto, {"Super_ssn"}, ExpDepto, {"Ssn"}, "Ger", JoinKind.LeftOuter),
    ExpGer        = Table.ExpandTableColumn(MescladoGer, "Ger", {"Nome"}, {"Gerente"}),

    // 10 e 16: mantém só o que o relatório usa
    Final = Table.SelectColumns(ExpGer,
        {"Ssn", "Nome", "Sex", "Salary", "Cidade", "Estado", "Departamento", "Gerente"})
in
    Final
```

### `Departamento_Local` (diretriz 13)

```m
let
    Fonte = MySQL.Database("HOST:PORTA", "company", [ReturnSingleDatabase = true]),
    Loc   = Fonte{[Schema = "company", Item = "dept_locations"]}[Data],

    Mescla = Table.NestedJoin(stg_department, {"Dnumber"}, Loc, {"Dnumber"}, "Loc", JoinKind.LeftOuter),
    Exp    = Table.ExpandTableColumn(Mescla, "Loc", {"Dlocation"}),

    // Ex.: "Research - Houston" (cada combinação departamento-local fica única)
    Unico  = Table.CombineColumns(
        Exp, {"Dname", "Dlocation"},
        Combiner.CombineTextByDelimiter(" - ", QuoteStyle.None), "Departamento_Local"),

    Final  = Table.SelectColumns(Unico, {"Dnumber", "Departamento_Local", "Mgr_ssn"})
in
    Final
```

### `Horas_Projeto` (diretriz 7)

```m
let
    Fonte = MySQL.Database("HOST:PORTA", "company", [ReturnSingleDatabase = true]),
    WO    = Fonte{[Schema = "company", Item = "works_on"]}[Data],
    Proj  = Fonte{[Schema = "company", Item = "project"]}[Data],

    Tipos = Table.TransformColumnTypes(WO, {{"Hours", type number}}),

    // Decisão: nulo significa "horas não informadas", não zero.
    // Se no seu contexto significar "não trabalhou", troque por 0:
    // Table.ReplaceValue(Tipos, null, 0, Replacer.ReplaceValue, {"Hours"})
    Mescla = Table.NestedJoin(Proj, {"Pnumber"}, Tipos, {"Pno"}, "WO", JoinKind.LeftOuter),
    Exp    = Table.ExpandTableColumn(Mescla, "WO", {"Essn", "Hours"}),
    Final  = Table.SelectColumns(Exp, {"Pnumber", "Pname", "Essn", "Hours"})
in
    Final
```

### `Colaboradores_por_Gerente` (diretriz 15)

```m
let
    ComGerente = Table.SelectRows(Employee, each [Gerente] <> null),
    Agrupado   = Table.Group(ComGerente, {"Gerente"},
        {{"Qtd_Colaboradores", each Table.RowCount(_), Int64.Type}})
in
    Agrupado
```

## 5. Query SQL usada para juntar colaboradores e gerentes (diretriz 11)

```sql
SELECT e.Ssn,
       CONCAT(e.Fname, ' ', e.Lname) AS colaborador,
       CONCAT(g.Fname, ' ', g.Lname) AS gerente
FROM employee e
LEFT JOIN employee g ON g.Ssn = e.Super_ssn
ORDER BY gerente, colaborador;
```

`LEFT JOIN` porque o James Borg não tem supervisor e não pode sumir do resultado. É uma auto-junção: a tabela `employee` aparece duas vezes, uma como colaborador (`e`) e outra como gerente (`g`).

## 6. Por que usar Mesclar e não Acrescentar? (diretriz 14)

Estou supondo que o "atribuir" do enunciado seja **Acrescentar** (Append), a outra forma de combinar consultas no Power BI.

- **Mesclar (Merge)** combina tabelas **na horizontal**: traz colunas de outra tabela casando linhas por uma chave. Aqui a chave é `employee.Dno = department.Dnumber`, e o resultado é cada colaborador com o nome do seu departamento. O mesmo vale para o nome do gerente (`Super_ssn = Ssn`) e para departamento + local.
- **Acrescentar (Append)** empilha linhas de tabelas com a **mesma estrutura de colunas**. `employee` e `department` têm colunas completamente diferentes. Empilhar geraria uma tabela com colunas quase todas nulas e sem ligar nenhum colaborador ao seu departamento.

## 7. Checklist das diretrizes

| # | Diretriz | Onde |
|---|---|---|
| 1 | Cabeçalhos e tipos | `Table.TransformColumnTypes` nas consultas `stg_*` |
| 2 | Valores monetários como double | `Salary` → `type number` |
| 3 | Nulos | Seção 3 (SQL) |
| 4 | Colaboradores sem gerente | Seção 3 (SQL) |
| 5 | Departamentos sem gerente | Seção 3 (SQL) |
| 6 | Preencher lacunas | `UPDATE` no `02_diagnostico_e_consultas.sql` |
| 7 | Horas dos projetos | Seção 3 e `Horas_Projeto` |
| 8 | Separar colunas complexas | `Address` → Rua, Cidade, Estado |
| 9 | Mesclar employee e department | `Employee` (Left Outer) |
| 10 | Eliminar colunas desnecessárias | `Table.SelectColumns` |
| 11 | Colaborador + gerente | Seção 5 (SQL) e `Employee` (M) |
| 12 | Nome + Sobrenome | `stg_employee` |
| 13 | Departamento + local | `Departamento_Local` |
| 14 | Mesclar vs. Acrescentar | Seção 6 |
| 15 | Colaboradores por gerente | `Colaboradores_por_Gerente` |
| 16 | Eliminar colunas de cada tabela | `Table.SelectColumns` em cada consulta final |
