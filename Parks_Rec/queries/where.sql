-- WHERE CLAUSE EXAMPLES --
USE Parks_and_Recreation;

/* SELECT *
   FROM employee_salary
   WHERE first_name = 'Leslie'; */

/* SELECT *
   FROM employee_salary
   WHERE salary > 50000; */

/* SELECT *
   FROM employee_demographics
   WHERE first_name LIKE "Jer%"; */

SELECT *
FROM employee_demographics
WHERE first_name LIKE "%a%";