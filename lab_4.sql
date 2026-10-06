CREATE TABLE employees ( employee_id SERIAL PRIMARY KEY,
                         first_name VARCHAR(50),
                         last_name VARCHAR(50),
                         department VARCHAR(50),
                         salary NUMERIC(10,2),
                         hire_date DATE,
                         manager_id INTEGER,
                         email VARCHAR(100)
);

create table projects (
    project_id serial primary key ,
    project_name varchar(100) ,
    budget numeric(12 ,2 ) ,
    start_date date ,
    end_date date ,
    status varchar(100)

);

create table assignments (
    assignment_id serial primary key ,
    employee_id integer references employees(employee_id) ,
    project_id integer references projects(project_id) ,
    hours_worked numeric(5,1) ,
    assignment_date date

);

insert into employees (first_name, last_name, department, salary, hire_date, manager_id, email) values
            ('John' , 'Smith' , 'IT' , '75000' , '2020-01-15' , NULL , 'john.smith@company.com') ,
            ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
            ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL, 'mbrown@company.com'),
            ('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL, 'emily.davis@company.com'),
            ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
            ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

insert into projects (project_name, budget, start_date, end_date, status) values
            ('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
            ('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
            ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
            ('Database Migration', 120000, '2024-01-10', NULL, 'Active');

insert into assignments (employee_id, project_id, hours_worked, assignment_date) values
             (1, 1, 120.5, '2024-01-15'),
             (2, 1, 95.0, '2024-01-20'),
             (1, 4, 80.0, '2024-02-01'),
             (3, 3, 60.0, '2024-03-05'),
             (5, 2, 110.0, '2024-02-20'),
             (6, 3, 75.5, '2024-03-10');

--Task 1.1
select
    first_name || ' ' || last_name as full_name ,
    department,
    salary
    from employees;

--Task 1.2
select distinct department
from employees;

-- Task 1.3
select project_name ,budget ,
    case
when budget > 150000 then 'Large'
when budget between 100000 and 150000 then 'Medium'
else 'Small'
end as budget_category
from projects;

-- Task 1.4
select
    first_name,
    coalesce(email , 'no email provided' ) as email
from employees;

--Task 2.1
select *  from employees where hire_date > '2020-01-01' ;

--Task 2.2
select * from employees where salary between 60000 and 70000 ;

--Task 2.3
select * from employees where last_name like 'S%' or last_name like 'J%';

--Task 2.4
select * from employees where manager_id is not null and department = 'IT' ;

--Task 3.1
select upper(first_name), -- i think there is no reason to create new table
        length(last_name) ,
        substring(email from  1 for 3)

from employees;

--Task 3.2
select salary*12  as annual_salary,
       round(salary , 2) as monthly_salary,
       salary * 0.1 as raise_amount
from employees;

-- Task 3.3
SELECT
    FORMAT('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_info
FROM projects;

-- Task 3.4
select
    first_name ,
    hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) as years_with_company
from employees;

-- Task 4.1
select
    department ,
    round(avg(salary ), 2) as avg_salary
from employees
group by department ;

-- Task 4.2
select
    p.project_name,
    sum(a.hours_worked) as total_hours
from projects p
join assignments a on p.project_id = a.project_id
group by p.project_id, p.project_name;

-- Task 4.3
select
    department ,
    count(*) as employee_count
from employees
group by department
having count(*) > 1;

--Task 4.4
select
    max(salary) as max_salary,
    min(salary) as min_salary ,
    sum(salary) as total_payroll
from employees ;

--Task 5.1
select
    employee_id ,
    first_name || ' ' || last_name as full_name,
    salary
from employees
where salary > 65000

union
select
    employee_id ,
    first_name || ' ' || last_name as full_name,
    salary
from employees
where hire_date > '2020-01-01' ;

--Task 5.2 
select employee_id , first_name , last_name
from employees
where department = 'IT'
intersect
select employee_id , first_name , last_name
from employees
where salary > 65000 ;

--Task 5.3
select employees.employee_id , employees.first_name , employees.last_name
from employees
where employee_id in(
    select employee_id from employees
    except
    select employee_id from assignments
    );

--Task 6.1
SELECT
    employee_id,
    first_name,
    last_name
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM assignments a
    WHERE a.employee_id = e.employee_id
);

-- Task 6.2
SELECT
    employee_id,
    first_name,
    last_name
FROM employees
WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);

-- Task 6.3
SELECT
    employee_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

-- Task 7.1
SELECT
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    ROUND(AVG(a.hours_worked), 2) AS avg_hours_worked,
    DENSE_RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary;

-- Task 7.2
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS assigned_employees
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;

-- Task 7.3
SELECT
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(first_name || ' ' || last_name) FILTER (
        WHERE salary = (
            SELECT MAX(e2.salary)
            FROM employees e2
            WHERE e2.department = e.department
        )
    ) AS highest_paid_employee,

    GREATEST(MAX(salary), 50000) AS max_salary_capped_min,
    LEAST(MIN(salary), 100000) AS min_salary_capped_max
FROM employees e
GROUP BY department;