-- =====================================================================
-- Laboratory Work #3 - DML Operations
-- =====================================================================

-- =====================================================================
-- PART A: Database and Table Setup
-- =====================================================================

-- Task 1.
-- Выполни ЭТУ строку отдельно, находясь в базе postgres (не в advanced_lab).
-- После этого переключи контекст консоли на advanced_lab и запускай остальное.
CREATE DATABASE advanced_lab;

-- ---- дальше всё выполняется в advanced_lab ----

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(50),
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50),
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- =====================================================================
-- PART B: Advanced INSERT Operations
-- =====================================================================

-- Task 2. INSERT with column specification (только emp_id, first_name, last_name, department)
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Aibek', 'Sarsen', 'IT'),
       (2, 'Dana', 'Nurlan', 'Sales');

-- Так как emp_id мы задали вручную, сдвигаем счётчик SERIAL,
-- иначе следующая вставка получит emp_id = 1 и упадёт с ошибкой дубликата
SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- Task 3. INSERT with DEFAULT values
-- salary не имеет DEFAULT (будет NULL), status по умолчанию 'Active'
INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Timur', 'Bekov', 'HR', DEFAULT, DEFAULT);

-- Task 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT', 120000, 1),
       ('Sales', 90000, 2),
       ('HR', 60000, 3);

-- Task 5. INSERT with expressions
-- hire_date = текущая дата, salary = 50000 * 1.1 = 55000
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Aliya', 'Kenes', 'IT', 50000 * 1.1, CURRENT_DATE);

-- Task 6. INSERT from SELECT (subquery)
-- Временная таблица живёт только в текущей сессии
CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

-- Проверка
SELECT * FROM temp_employees;

-- Дополнительные тестовые данные для следующих заданий
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Marat', 'Omarov',   'IT',    85000, '2018-03-15', 'Active'),
       ('Saule', 'Ospanova', 'IT',    62000, '2019-07-01', 'Active'),
       ('Nurlan', 'Abenov',  'HR',    45000, '2021-02-10', 'Inactive'),
       ('Aigul', 'Tasova',   'Sales', 70000, '2017-11-20', 'Active'),
       ('Bauyrzhan', 'Ergaliev', 'Sales', 38000, '2022-05-05', 'Terminated'),
       ('Madina', 'Sultan',  'HR',    52000, '2020-09-09', 'Inactive');

-- Проекты для тестов (нужны для заданий 16 и 27)
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Old Website',    1, '2021-01-01', '2022-06-30', 30000),
       ('Legacy CRM',     2, '2020-05-01', '2022-12-31', 45000),
       ('Mobile App',     1, '2024-01-01', '2026-12-31', 80000),
       ('HR Portal',      3, '2025-03-01', '2026-10-01', 20000);

-- =====================================================================
-- PART C: Complex UPDATE Operations
-- =====================================================================

-- Task 7. UPDATE with arithmetic expressions (+10% ко всем зарплатам)
UPDATE employees
SET salary = salary * 1.10;

-- Task 8. UPDATE with WHERE and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- Task 9. UPDATE using CASE expression
-- NULL salary попадёт в ELSE -> 'Junior'
UPDATE employees
SET department = CASE
                     WHEN salary > 80000 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- Task 10. UPDATE with DEFAULT
-- У department нет заданного DEFAULT, поэтому станет NULL
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- Тестовые данные: отделы, которые появились после задания 9
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Management', 200000, NULL),
       ('Senior', 100000, NULL),
       ('Junior', 50000, NULL);

-- Task 11. UPDATE with subquery
-- Бюджет = средняя зарплата отдела * 1.2. Если в отделе нет сотрудников,
-- COALESCE оставляет старый бюджет
UPDATE departments d
SET budget = COALESCE(
        (SELECT AVG(e.salary) * 1.2
         FROM employees e
         WHERE e.department = d.dept_name),
        d.budget);

-- Тестовые данные для задания 12
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Ainur', 'Zhaksylyk', 'Sales', 48000, '2021-04-12'),
       ('Erlan', 'Mukhtar',   'Sales', 51000, '2022-08-30');

-- Task 12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- =====================================================================
-- PART D: Advanced DELETE Operations
-- =====================================================================

-- Task 13. DELETE with simple WHERE
DELETE FROM employees
WHERE status = 'Terminated';

-- Тестовые данные для задания 14
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Test', 'Newbie', NULL, 30000, '2023-06-01');

-- Task 14. DELETE with complex WHERE
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- Task 15. DELETE with subquery
-- В задании сравнивается dept_id (число) с employees.department (строка),
-- в Postgres это даст ошибку типов. Поэтому сравниваем по названию отдела:
-- удаляем отделы, в которых нет ни одного сотрудника
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

-- Task 16. DELETE with RETURNING
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- =====================================================================
-- PART E: Operations with NULL Values
-- =====================================================================

-- Task 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Nulla', 'Person', NULL, NULL);

-- Task 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- Task 19. DELETE with NULL conditions
-- Строка из задания 17 удалится, т.к. salary IS NULL
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- =====================================================================
-- PART F: RETURNING Clause Operations
-- =====================================================================

-- Task 20. INSERT with RETURNING (emp_id и полное имя)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Kairat', 'Zhunis', 'IT', 60000, '2022-01-15')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- Task 21. UPDATE with RETURNING (старая и новая зарплата)
-- В RETURNING обращение к столбцу даёт НОВОЕ значение,
-- старое получаем как new - 5000
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
          salary - 5000 AS old_salary,
          salary        AS new_salary;

-- Task 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- =====================================================================
-- PART G: Advanced DML Patterns
-- =====================================================================

-- Task 23. Conditional INSERT (только если такого сотрудника ещё нет)
-- Второй запуск этого запроса ничего не вставит
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Kairat', 'Zhunis', 'IT', 60000, '2022-01-15'
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Kairat'
                    AND last_name = 'Zhunis');

-- Тестовые данные для заданий 24 и 27: заново добавляем отделы IT и Sales
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT', 150000, NULL),
       ('Sales', 80000, NULL);

-- Task 24. UPDATE with JOIN logic using subqueries
-- Бюджет отдела > 100000 -> +10%, иначе +5%
UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget
                                FROM departments d
                                WHERE d.dept_name = e.department
                                LIMIT 1) > 100000 THEN 1.10
                          ELSE 1.05
                      END;

-- Task 25. Bulk operations
-- Сначала вставляем 5 сотрудников одним запросом
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bulk1', 'Test', 'IT', 40000, '2024-01-01'),
       ('Bulk2', 'Test', 'IT', 41000, '2024-01-02'),
       ('Bulk3', 'Test', 'IT', 42000, '2024-01-03'),
       ('Bulk4', 'Test', 'IT', 43000, '2024-01-04'),
       ('Bulk5', 'Test', 'IT', 44000, '2024-01-05');

-- Затем одним UPDATE поднимаем им зарплаты на 10%
UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Test'
  AND first_name LIKE 'Bulk%';

-- Task 26. Data migration simulation
-- Тестовые данные: Inactive сотрудники
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Old', 'Timer1', 'HR', 40000, '2021-01-01', 'Inactive'),
       ('Old', 'Timer2', 'IT', 45000, '2021-02-01', 'Inactive');

-- Шаг 1: создаём архивную таблицу с той же структурой
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

-- Шаг 2: копируем Inactive сотрудников в архив
INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

-- Шаг 3: удаляем их из основной таблицы
DELETE FROM employees
WHERE status = 'Inactive';

-- Проверка
SELECT * FROM employee_archive;

-- Task 27. Complex business logic
-- Тестовые данные: проект в отделе IT (в нём больше 3 сотрудников после задания 25)
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Cloud Migration',
        (SELECT dept_id FROM departments WHERE dept_name = 'IT' LIMIT 1),
        '2025-01-01', '2026-06-30', 90000);

-- Продлеваем на 30 дней проекты с бюджетом > 50000,
-- если в отделе-владельце больше 3 сотрудников
UPDATE projects p
SET end_date = end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;

-- Финальная проверка
SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
