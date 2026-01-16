USE Parks_and_Recreation;

/* Q1: How many employees are in each department? */
SELECT COUNT(sal.employee_id) AS employee_count, COALESCE(dept.department_name, 'Unassigned') AS department_name
FROM employee_salary AS sal
LEFT JOIN parks_departments AS dept
    ON sal.dept_id = dept.department_id
GROUP BY COALESCE(dept.department_name, 'Unassigned');

/* Q2: What is total payroll cost per department (including Unassigned)? */
SELECT SUM(sal.salary) AS total_payroll_cost, COALESCE(dept.department_name, 'Unassigned') AS department_name
FROM employee_salary AS sal
LEFT JOIN parks_departments AS dept
    ON sal.dept_id = dept.department_id
GROUP BY COALESCE(dept.department_name, 'Unassigned')
ORDER BY total_payroll_cost DESC;

/* Q3: What is avg payroll cost per department (including Unassigned)? */
SELECT ROUND(AVG(sal.salary), 2) AS avg_payroll_per_employee, COALESCE(dept.department_name, 'Unassigned') AS department_name
FROM employee_salary AS sal
LEFT JOIN parks_departments AS dept
    ON sal.dept_id = dept.department_id
GROUP BY COALESCE(dept.department_name, 'Unassigned')
ORDER BY avg_payroll_per_employee DESC;

/* Q4: Which department do the employees belong to in the demographics table? */
SELECT 
    dem.first_name,
    dem.last_name,
    COALESCE(dep.department_id, 0) AS department_id,
    COALESCE(dep.department_name, 'Unassigned') AS department_name
FROM employee_demographics AS dem
LEFT JOIN employee_salary AS sal
    ON dem.employee_id = sal.employee_id
LEFT JOIN parks_departments AS dep
    ON sal.dept_id = dep.department_id
ORDER BY department_name, last_name, first_name;

/* Q5: Which employees have salary records but no demographics record? */
SELECT sal.first_name, sal.last_name, sal.employee_id
FROM employee_salary AS sal
LEFT JOIN employee_demographics AS dem
    ON sal.employee_id = dem.employee_id
WHERE dem.employee_id IS NULL;

/* Q6: Which employees are missing a department assignment? */
SELECT employee_id, CONCAT(last_name, ", ", first_name) AS full_name, dept_id
FROM employee_salary
WHERE dept_id IS NULL;