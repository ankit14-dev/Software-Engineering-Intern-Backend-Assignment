-- Active: 1765792167237@@ep-young-mouse-a1oq2npn-pooler.ap-southeast-1.aws.neon.tech@5432@employees

SET search_path TO employees;



-- Get all tables with row counts
SELECT schemaname, tablename, pg_size_pretty(
        pg_total_relation_size(
            schemaname || '.' || tablename
        )
    ) AS size
FROM pg_tables
WHERE
    schemaname = 'employees'
ORDER BY tablename;



SELECT 'employee' as table_name, COUNT(*) as row_count
FROM employees.employee
UNION ALL
SELECT 'department', COUNT(*)
FROM employees.department
UNION ALL
SELECT 'department_employee', COUNT(*)
FROM employees.department_employee
UNION ALL
SELECT 'department_manager', COUNT(*)
FROM employees.department_manager
UNION ALL
SELECT 'salary', COUNT(*)
FROM employees.salary
UNION ALL
SELECT 'title', COUNT(*)
FROM employees.title
ORDER BY table_name;




-- Count rows in each table
SELECT 'employee' as table_name, COUNT(*) as row_count
FROM employee
UNION ALL
SELECT 'department', COUNT(*)
FROM department
UNION ALL
SELECT 'department_employee', COUNT(*)
FROM department_employee
UNION ALL
SELECT 'department_manager', COUNT(*)
FROM department_manager
UNION ALL
SELECT 'salary', COUNT(*)
FROM salary
UNION ALL
SELECT 'title', COUNT(*)
FROM title;