/* GROUP BY and ORDER BY EXAMPLES
   This is practice, and some common mistakes are included for learning purposes.
   
   When using ORDER BY, you can use DESC to sort in descending order. By default, ORDER BY sorts in ascending order.
   
   When using GROUP BY, all selected columns must either be included in the GROUP BY clause or be used in an aggregate function (like COUNT, AVG, SUM, etc.).
*/

USE Parks_and_Recreation;

/* Example 1: Grouping by a single column and ordering the results, this query will cause and error because
   first_name is not included in the GROUP BY clause or an aggregate function. 

    SELECT first_name
    FROM employee_demographics
    GROUP BY gender; */

-- Corrected Query 1: Include first_name in the ORDER BY clause

/* SELECT first_name
   FROM employee_demographics
   ORDER BY gender; */

-- Example 2: Grouping with an aggregate function --

/* SELECT gender, AVG(age)
   FROM employee_demographics
   GROUP BY gender; */

-- A little change to make the column name more descriptive --

/*SELECT gender, AVG(age) AS 'average_age'
   FROM employee_demographics
   GROUP BY gender; */

-- Clean up the average age to show only two decimal places --

/* SELECT gender, ROUND(AVG(age), 2) AS 'average_age'
   FROM employee_demographics
   GROUP BY gender; */

/* Example 3: Grouping by multiple columns

   SELECT occupation, salary
   FROM employee_salary
   GROUP BY occupation, salary; */

-- ORDER BY with multiple columns --
/* SELECT *
   FROM employee_demographics
   ORDER BY first_name, age, gender; */