# Modelagem em Estrela com Power BI - Financial Sample

Desafio de projeto: transformar a tabela única **Financial Sample** em um modelo dimensional (**star schema**) no Power BI, com tabelas dimensão e uma tabela fato.

## Esquema em estrela

![Esquema em estrela](imagens/star_schema.svg)

## Tabelas do modelo

| Tabela | Tipo | Descrição |
|---|---|---|
| `financials_origem` | Origem (oculta) | Cópia da tabela original, mantida como backup e sem relacionamentos |
| `f_vendas` | Fato | Vendas, com `Sk_ID`, `ID_produto`, `Product`, `Segment`, `Country`, `Discount Band`, `Date`, `Sales`, `Sale Price`, `Units Sold` e `Profit` |
| `d_Produtos` | Dimensão | Produto com métricas agregadas: média, mediana, máximo e mínimo do valor de vendas e média da manufatura |
| `d_Produtos_detalhes` | Dimensão (oculta) | `ID_Produto`, `Discount Band`, `Sale Price`, `Units Sold`, `Manufacturing Price` |
| `d_descontos` | Dimensão | `ID_Produto`, `Discounts`, `Discount Band` e a chave `Sk_ID` |
| `d_Detalhes` | Dimensão | Informações de vendas que não foram contempladas nas demais dimensões |
| `D_Calendario` | Dimensão | Tabela de datas criada por DAX |

## Relacionamentos

Todos os relacionamentos seguem o padrão do star schema: **muitos para um (\*:1)**, com filtro cruzado **único**, saindo da dimensão para a `f_vendas`.

- `D_Calendario[Date]` -> `f_vendas[Date]`
- `d_descontos[Sk_ID]` -> `f_vendas[Sk_ID]`
- `d_Produtos`, `d_Detalhes` e `d_Produtos_detalhes` -> `f_vendas` *(complete com as colunas usadas como chave)*

## Processo de construção

1. **Importação** do arquivo `Financial Sample.xlsx` para o Power BI.
2. **Backup:** a tabela original foi mantida como `financials_origem` e ocultada.
3. **Criação das tabelas** no Power Query, a partir de cópias da tabela original, selecionando as colunas de cada visão *(descreva aqui o que você fez: duplicar consulta, remover colunas, agrupar)*.
4. **Chave substituta (`Sk_ID`):** como `ID_Produto` se repete na `d_descontos`, foi criada uma coluna de índice (`Sk_ID`) para servir de chave única no relacionamento com a fato.
5. **Agrupamento:** a `d_Produtos` foi criada por agrupamento, calculando média, mediana, máximo e mínimo.
6. **Coluna condicional:** foi criada a coluna `Índice` de produtos a partir de uma condição *(descreva a regra utilizada)*.
7. **Calendário:** criada por DAX (veja abaixo).
8. **Relacionamentos** criados na Exibição de Modelo, conforme o esquema acima.
9. **Reorganização das colunas** em cada tabela.

## Funções DAX utilizadas

### Tabela de calendário

```dax
D_Calendario =
CALENDAR (
    DATE ( YEAR ( MIN ( Financials_origem[Date] ) ), 1, 1 ),
    DATE ( YEAR ( MAX ( Financials_origem[Date] ) ), 12, 31 )
)
```

### Colunas do calendário

```dax
Ano = YEAR ( D_Calendario[Date] )
Mes_Numero = MONTH ( D_Calendario[Date] )
Mes = FORMAT ( D_Calendario[Date], "MMMM" )
Trimestre = "T" & QUARTER ( D_Calendario[Date] )
Dia_Semana = FORMAT ( D_Calendario[Date], "dddd" )
```

A coluna `Mes` está classificada por `Mes_Numero` para ordenar os meses corretamente.

| Função | Uso |
|---|---|
| `CALENDAR` | Gera a tabela de datas |
| `MIN` / `MAX` | Define o início e o fim do calendário a partir dos dados |
| `DATE` | Monta o primeiro e o último dia do período |
| `YEAR` / `MONTH` / `QUARTER` | Extraem ano, mês e trimestre |
| `FORMAT` | Gera o nome do mês e do dia da semana |

*(Acrescente aqui outras funções DAX usadas no projeto.)*

## Arquivos

- `relatorio gerencial de vendas.pbix`: projeto do Power BI
- `Financial Sample.xlsx`: base de dados original
- `imagens/star_schema.svg`: diagrama do esquema em estrela

## Ferramentas

- Power BI Desktop (Power Query e DAX)
- GitHub
