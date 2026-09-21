USE company;

-- =====================================================================
-- DIAGNÓSTICO (itens 3, 4, 5 e 7 das diretrizes)
-- =====================================================================

-- 3) Nulos por coluna em employee
SELECT COUNT(*)                     AS total,
       SUM(Minit     IS NULL)       AS minit_nulo,
       SUM(Address   IS NULL)       AS address_nulo,
       SUM(Salary    IS NULL)       AS salary_nulo,
       SUM(Super_ssn IS NULL)       AS super_ssn_nulo,
       SUM(Dno       IS NULL)       AS dno_nulo
FROM employee;

-- 4) Colaboradores sem gerente: quem é gerente de departamento e quem não é?
SELECT e.Ssn,
       CONCAT(e.Fname, ' ', e.Lname)  AS colaborador,
       d.Dname                        AS gerencia_o_depto
FROM employee e
LEFT JOIN department d ON d.Mgr_ssn = e.Ssn
WHERE e.Super_ssn IS NULL;
-- James Borg gerencia Headquarters (topo da hierarquia: nulo é legítimo).
-- Maria Souza não gerencia nada e não tem supervisor: precisa de correção.

-- 5) Departamentos sem gerente
SELECT Dnumber, Dname
FROM department
WHERE Mgr_ssn IS NULL;

-- 7) Horas por projeto (LEFT JOIN para não perder projetos sem registros)
SELECT p.Pnumber,
       p.Pname,
       COUNT(w.Essn)         AS qtd_registros,
       SUM(w.Hours)          AS total_horas,
       SUM(w.Hours IS NULL)  AS registros_sem_horas
FROM project p
LEFT JOIN works_on w ON w.Pno = p.Pnumber
GROUP BY p.Pnumber, p.Pname
ORDER BY p.Pnumber;

-- =====================================================================
-- CORREÇÃO (item 6: "suponha que você possui os dados e preencha as lacunas")
-- =====================================================================

-- Supondo que a Maria (111222333) é a gerente de Marketing desde 01/01/2024
UPDATE department
SET Mgr_ssn = '111222333', Mgr_start_date = '2024-01-01'
WHERE Dnumber = 6 AND Mgr_ssn IS NULL;

-- Supondo que ela responde ao diretor James Borg (888665555)
UPDATE employee
SET Super_ssn = '888665555'
WHERE Ssn = '111222333' AND Super_ssn IS NULL;

-- =====================================================================
-- CONSULTAS DO DESAFIO
-- =====================================================================

-- 9) Colaborador + nome do departamento (LEFT JOIN: base é employee)
SELECT e.Ssn,
       CONCAT(e.Fname, ' ', e.Lname) AS colaborador,
       d.Dname                       AS departamento
FROM employee e
LEFT JOIN department d ON d.Dnumber = e.Dno;

-- 11) Colaborador + nome do gerente (auto-junção na tabela employee)
SELECT e.Ssn,
       CONCAT(e.Fname, ' ', e.Lname) AS colaborador,
       CONCAT(g.Fname, ' ', g.Lname) AS gerente
FROM employee e
LEFT JOIN employee g ON g.Ssn = e.Super_ssn
ORDER BY gerente, colaborador;

-- 15) Quantidade de colaboradores por gerente
SELECT g.Ssn,
       CONCAT(g.Fname, ' ', g.Lname) AS gerente,
       COUNT(e.Ssn)                  AS qtd_colaboradores
FROM employee e
JOIN employee g ON g.Ssn = e.Super_ssn
GROUP BY g.Ssn, g.Fname, g.Lname
ORDER BY qtd_colaboradores DESC;
