-- =====================================================================
-- Desafio: MySQL (Aiven) + Power BI
-- Banco de exemplo "company" (baseado no modelo clássico Elmasri/Navathe)
-- Contém problemas de qualidade PROPOSITAIS para a etapa de transformação:
--   * Super_ssn nulo (o diretor James Borg é legítimo; a Maria não)
--   * Departamento 6 (Marketing) sem gerente
--   * Horas nulas em works_on
--   * Projeto 40 sem nenhuma hora registrada
--   * Coluna Address "complexa" (rua, cidade, estado juntos)
-- Obs.: o Aiven exige chave primária em toda tabela (sql_require_primary_key).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS company;
USE company;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS works_on, project, dept_locations, department, employee;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Tabelas (as FKs circulares employee <-> department entram no final)
-- ---------------------------------------------------------------------
CREATE TABLE employee (
    Fname      VARCHAR(15)   NOT NULL,
    Minit      CHAR(1),
    Lname      VARCHAR(15)   NOT NULL,
    Ssn        CHAR(9)       NOT NULL,
    Bdate      DATE,
    Address    VARCHAR(60),
    Sex        CHAR(1),
    Salary     DECIMAL(10,2),
    Super_ssn  CHAR(9),
    Dno        INT,
    PRIMARY KEY (Ssn)
);

CREATE TABLE department (
    Dname           VARCHAR(25) NOT NULL,
    Dnumber         INT         NOT NULL,
    Mgr_ssn         CHAR(9),
    Mgr_start_date  DATE,
    PRIMARY KEY (Dnumber),
    UNIQUE (Dname)
);

CREATE TABLE dept_locations (
    Dnumber    INT         NOT NULL,
    Dlocation  VARCHAR(15) NOT NULL,
    PRIMARY KEY (Dnumber, Dlocation)
);

CREATE TABLE project (
    Pname      VARCHAR(25) NOT NULL,
    Pnumber    INT         NOT NULL,
    Plocation  VARCHAR(15),
    Dnum       INT         NOT NULL,
    PRIMARY KEY (Pnumber),
    UNIQUE (Pname)
);

CREATE TABLE works_on (
    Essn   CHAR(9)      NOT NULL,
    Pno    INT          NOT NULL,
    Hours  DECIMAL(4,1),
    PRIMARY KEY (Essn, Pno)
);

-- ---------------------------------------------------------------------
-- Dados
-- ---------------------------------------------------------------------
INSERT INTO employee VALUES
('John',     'B', 'Smith',   '123456789', '1965-01-09', '731 Fondren, Houston, TX',   'M', 30000.00, '333445555', 5),
('Franklin', 'T', 'Wong',    '333445555', '1955-12-08', '638 Voss, Houston, TX',      'M', 40000.00, '888665555', 5),
('Alicia',   'J', 'Zelaya',  '999887777', '1968-01-19', '3321 Castle, Spring, TX',    'F', 25000.00, '987654321', 4),
('Jennifer', 'S', 'Wallace', '987654321', '1941-06-20', '291 Berry, Bellaire, TX',    'F', 43000.00, '888665555', 4),
('Ramesh',   'K', 'Narayan', '666884444', '1962-09-15', '975 Fire Oak, Humble, TX',   'M', 38000.00, '333445555', 5),
('Joyce',    'A', 'English', '453453453', '1972-07-31', '5631 Rice, Houston, TX',     'F', 25000.00, '333445555', 5),
('Ahmad',    'V', 'Jabbar',  '987987987', '1969-03-29', '980 Dallas, Houston, TX',    'M', 25000.00, '987654321', 4),
('James',    'E', 'Borg',    '888665555', '1937-11-10', '450 Stone, Houston, TX',     'M', 55000.00, NULL,        1),
('Maria',    'L', 'Souza',   '111222333', '1990-04-12', '120 Elm, Dallas, TX',        'F', 35000.00, NULL,        6);

INSERT INTO department VALUES
('Research',       5, '333445555', '1988-05-22'),
('Administration', 4, '987654321', '1995-01-01'),
('Headquarters',   1, '888665555', '1981-06-19'),
('Marketing',      6, NULL,        NULL);

INSERT INTO dept_locations VALUES
(1, 'Houston'),
(4, 'Stafford'),
(5, 'Bellaire'),
(5, 'Sugarland'),
(5, 'Houston'),
(6, 'Dallas');

INSERT INTO project VALUES
('ProductX',        1,  'Bellaire',  5),
('ProductY',        2,  'Sugarland', 5),
('ProductZ',        3,  'Houston',   5),
('Computerization', 10, 'Stafford',  4),
('Reorganization',  20, 'Houston',   1),
('Newbenefits',     30, 'Stafford',  4),
('Campaign',        40, 'Dallas',    6);

INSERT INTO works_on VALUES
('123456789', 1,  32.5),
('123456789', 2,  7.5),
('666884444', 3,  40.0),
('453453453', 1,  20.0),
('453453453', 2,  20.0),
('333445555', 2,  10.0),
('333445555', 3,  10.0),
('333445555', 10, 10.0),
('333445555', 20, 10.0),
('999887777', 30, 30.0),
('999887777', 10, 10.0),
('987987987', 10, 35.0),
('987987987', 30, 5.0),
('987654321', 30, 20.0),
('987654321', 20, 15.0),
('888665555', 20, NULL),
('111222333', 40, NULL);

-- ---------------------------------------------------------------------
-- Chaves estrangeiras (depois dos INSERTs, por causa da referência circular)
-- ---------------------------------------------------------------------
ALTER TABLE employee
    ADD CONSTRAINT fk_emp_super FOREIGN KEY (Super_ssn) REFERENCES employee (Ssn),
    ADD CONSTRAINT fk_emp_dept  FOREIGN KEY (Dno)       REFERENCES department (Dnumber);

ALTER TABLE department
    ADD CONSTRAINT fk_dept_mgr  FOREIGN KEY (Mgr_ssn)   REFERENCES employee (Ssn);

ALTER TABLE dept_locations
    ADD CONSTRAINT fk_loc_dept  FOREIGN KEY (Dnumber)   REFERENCES department (Dnumber);

ALTER TABLE project
    ADD CONSTRAINT fk_proj_dept FOREIGN KEY (Dnum)      REFERENCES department (Dnumber);

ALTER TABLE works_on
    ADD CONSTRAINT fk_wo_emp    FOREIGN KEY (Essn)      REFERENCES employee (Ssn),
    ADD CONSTRAINT fk_wo_proj   FOREIGN KEY (Pno)       REFERENCES project (Pnumber);
