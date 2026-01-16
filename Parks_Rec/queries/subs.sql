USE Parks_and_Recreation;

SELECT *
FROM employee_demographics
WHERE employee_id IN (
    SELECT employee_id
    FROM employee_salary
    WHERE dept_id = 1
);

SELECT first_name, last_name, salary, AVG(salary)
FROM employee_salary
GROUP BY first_name, salary;

SELECT first_name, last_name, salary, (
    SELECT ROUND(AVG(salary), 2)
    FROM employee_salary
) AS average_salary
FROM employee_salary;