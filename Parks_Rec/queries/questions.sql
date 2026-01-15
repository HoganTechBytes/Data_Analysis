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
GROUP BY COALESCE(dept.department_name, 'Unassigned');

/* Q3: What is avg payroll cost per department (including Unassigned)? */
SELECT ROUND(AVG(sal.salary), 2) AS avg_payroll_per_employee, COALESCE(dept.department_name, 'Unassigned') AS department_name
FROM employee_salary AS sal
LEFT JOIN parks_departments AS dept
    ON sal.dept_id = dept.department_id
GROUP BY COALESCE(dept.department_name, 'Unassigned')
ORDER BY avg_payroll_per_employee DESC;