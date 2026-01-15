USE Parks_and_Recreation;

-- CASE statement example --

-- SELECT first_name, 
--         last_name,
-- CASE
--     WHEN age <= 30 THEN "Young"
--     WHEN age BETWEEN 31 AND 50 THEN "OLD"
--     WHEN age >= 50 THEN "Very Old"
-- END AS Age_Bracket
-- FROM employee_demographics;

/* Pay increase and Bonus Case statement example 

    < 50000 = 5%
    >= 50000 = 7%
    Finance = 10% bonus
*/

SELECT first_name, last_name, salary,
CASE 
    WHEN salary < 50000 THEN ROUND((salary * 1.05), 2)
    WHEN salary > 50000 THEN ROUND((salary * 1.07), 2)
    ELSE salary
END AS 'New Salary',
CASE 
    WHEN dept_id = 6 THEN ROUND((salary * .10), 2)
    ELSE 0.00
END AS Bonus
FROM employee_salary

