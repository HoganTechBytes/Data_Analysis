USE Parks_and_Recreation;

-- Inner join example. By default JOIN is an INNER JOIN. 
-- JOIN == INNER JOIN

/* This is messy because you end up with a lot of duplicate columns in this case.
Both tables have employee_id, first_name, last_name, etc. */

/* SELECT *
   FROM employee_demographics
   JOIN employee_salary
     ON employee_demographics.employee_id = employee_salary.employee_id; */

-- Same query with explicit INNER JOIN and table aliases for readability --

-- SELECT *
-- FROM employee_demographics AS dem
-- INNER JOIN employee_salary AS sal
--     ON dem.employee_id = sal.employee_id;

/*
-- Rewriting to select specific columns to avoid duplicates --
SELECT dem.employee_id, dem.first_name, dem.last_name, age, occupation, salary
FROM employee_demographics AS dem
INNER JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id;

-- LEFT and RIGHT JOIN examples, and rewriting a RIGHT JOIN as a LEFT JOIN --

-- LEFT JOIN example --
SELECT dem.employee_id, dem.first_name, dem.last_name, age, occupation, salary
FROM employee_demographics AS dem
LEFT JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id;

-- RIGHT JOIN example --
SELECT dem.employee_id, dem.first_name, dem.last_name, age, occupation, salary
FROM employee_demographics AS dem
RIGHT JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id;

-- Rewriting the RIGHT JOIN as a LEFT JOIN by switching table order --
SELECT dem.employee_id, dem.first_name, dem.last_name, age, occupation, salary
FROM employee_salary AS sal
LEFT JOIN employee_demographics AS dem
    ON dem.employee_id = sal.employee_id;
*/

-- SELF JOIN example --
-- SELECT emp1.employee_id AS 'employee ID', emp1.first_name AS firstName, emp1.last_name AS lastName,
--        emp2.employee_id AS 'Assigned ID', emp2.first_name AS 'Assigned First Name', emp2.last_name AS 'Assigned Last Name'
-- FROM employee_salary AS emp1
-- JOIN employee_salary AS emp2
--     ON emp1.employee_id + 1 = emp2.employee_id;

-- Joining multiple tables --
-- SELECT *
-- FROM employee_demographics AS dem
-- JOIN employee_salary AS sal
--     ON dem.employee_id = sal.employee_id
-- JOIN parks_departments AS dep
--     ON sal.dept_id = dep.department_id;

-- Using multple joins to answer a question --
-- Which department do the employees belong to in the demographics table--

SELECT dem.first_name, dem.last_name, dep.department_id, dep.department_name
FROM employee_demographics AS dem
JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id
JOIN parks_departments AS dep
    ON sal.dept_id = dep.department_id;