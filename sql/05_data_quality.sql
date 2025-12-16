-- ============================================================================
-- DATA QUALITY CHECKS AND VALIDATION
-- Author:   Ankit
-- Date:  2025-12-17
-- ============================================================================

-- ============================================================================
-- SECTION 1: DUPLICATE DETECTION
-- ============================================================================

-- Query 1.1: Find duplicate students by email
SELECT
    email,
    COUNT(*) as duplicate_count,
    STRING_AGG(student_id::TEXT, ', ') as student_ids,
    STRING_AGG(
        first_name || ' ' || last_name,
        ', '
    ) as names
FROM student
GROUP BY
    email
HAVING
    COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Query 1.2: Find duplicate instructors by email
SELECT
    email,
    COUNT(*) as duplicate_count,
    STRING_AGG(instructor_id::TEXT, ', ') as instructor_ids,
    STRING_AGG(
        first_name || ' ' || last_name,
        ', '
    ) as names
FROM instructor
GROUP BY
    email
HAVING
    COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Query 1.3: Find duplicate department codes
SELECT
    dept_code,
    COUNT(*) as duplicate_count,
    STRING_AGG(department_id::TEXT, ', ') as department_ids,
    STRING_AGG(dept_name, ', ') as names
FROM department
GROUP BY
    dept_code
HAVING
    COUNT(*) > 1;

-- Query 1.4: Find duplicate course codes
SELECT
    course_code,
    COUNT(*) as duplicate_count,
    STRING_AGG(course_id::TEXT, ', ') as course_ids,
    STRING_AGG(course_name, ', ') as names
FROM course
GROUP BY
    course_code
HAVING
    COUNT(*) > 1;

-- Query 1.5: Find duplicate enrollments (same student, same schedule)
SELECT
    student_id,
    schedule_id,
    COUNT(*) as duplicate_count,
    STRING_AGG(enrollment_id::TEXT, ', ') as enrollment_ids,
    STRING_AGG(status, ', ') as statuses
FROM enrollment
GROUP BY
    student_id,
    schedule_id
HAVING
    COUNT(*) > 1;

-- Query 1.6: Find duplicate classrooms (same building and room)
SELECT
    building,
    room_number,
    COUNT(*) as duplicate_count,
    STRING_AGG(classroom_id::TEXT, ', ') as classroom_ids
FROM classroom
GROUP BY
    building,
    room_number
HAVING
    COUNT(*) > 1;

-- Query 1.7: Find duplicate schedules (overlapping times in same classroom)
SELECT
    sch1.schedule_id as schedule1_id,
    sch2.schedule_id as schedule2_id,
    c1.course_code as course1,
    c2.course_code as course2,
    cl.building || ' ' || cl.room_number as classroom,
    sch1.day_of_week,
    sch1.start_time,
    sch1.end_time,
    sch1.semester,
    sch1.year
FROM
    schedule sch1
    JOIN schedule sch2 ON sch1.classroom_id = sch2.classroom_id
    AND sch1.day_of_week = sch2.day_of_week
    AND sch1.semester = sch2.semester
    AND sch1.year = sch2.year
    AND sch1.schedule_id < sch2.schedule_id
    AND (
        sch1.start_time,
        sch1.end_time
    ) OVERLAPS (
        sch2.start_time,
        sch2.end_time
    )
    JOIN course c1 ON sch1.course_id = c1.course_id
    JOIN course c2 ON sch2.course_id = c2.course_id
    JOIN classroom cl ON sch1.classroom_id = cl.classroom_id
ORDER BY sch1.schedule_id;

-- ============================================================================
-- SECTION 2: INVALID DATA DETECTION
-- ============================================================================

-- Query 2.1: Students with invalid email format
SELECT 
    student_id,
    first_name,
    last_name,
    email,
    'Invalid email format' as issue
FROM student
WHERE email ! ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
ORDER BY student_id;

-- Query 2.2: Students with future birth dates
SELECT
    student_id,
    first_name,
    last_name,
    date_of_birth,
    'Birth date in future' as issue
FROM student
WHERE
    date_of_birth > CURRENT_DATE
ORDER BY date_of_birth DESC;

-- Query 2.3: Students younger than 15 or older than 80
SELECT
    student_id,
    first_name,
    last_name,
    date_of_birth,
    EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, date_of_birth)
    ) as age,
    CASE
        WHEN EXTRACT(
            YEAR
            FROM AGE (CURRENT_DATE, date_of_birth)
        ) < 15 THEN 'Too young'
        WHEN EXTRACT(
            YEAR
            FROM AGE (CURRENT_DATE, date_of_birth)
        ) > 80 THEN 'Too old'
    END as issue
FROM student
WHERE
    EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, date_of_birth)
    ) < 15
    OR EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, date_of_birth)
    ) > 80
ORDER BY age;

-- Query 2.4: Students with enrollment year before birth year
SELECT
    student_id,
    first_name,
    last_name,
    date_of_birth,
    enrollment_year,
    'Enrolled before birth' as issue
FROM student
WHERE
    enrollment_year < EXTRACT(
        YEAR
        FROM date_of_birth
    )
ORDER BY student_id;

-- Query 2.5: Instructors with invalid email format
SELECT
    instructor_id,
    first_name,
    last_name,
    email,
    'Invalid email format' as issue
FROM instructor
WHERE
    email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
ORDER BY instructor_id;

-- Query 2.6: Instructors hired in the future
SELECT
    instructor_id,
    first_name,
    last_name,
    hire_date,
    'Hire date in future' as issue
FROM instructor
WHERE
    hire_date > CURRENT_DATE
ORDER BY hire_date DESC;

-- Query 2.7: Courses with invalid credit hours
SELECT
    course_id,
    course_code,
    course_name,
    credits,
    CASE
        WHEN credits <= 0 THEN 'Zero or negative credits'
        WHEN credits > 6 THEN 'Too many credits'
    END as issue
FROM course
WHERE
    credits <= 0
    OR credits > 6
ORDER BY credits DESC;

-- Query 2.8: Courses with invalid capacity
SELECT
    course_id,
    course_code,
    course_name,
    max_capacity,
    'Invalid capacity' as issue
FROM course
WHERE
    max_capacity IS NOT NULL
    AND max_capacity <= 0
ORDER BY course_id;

-- Query 2.9: Schedules with end time before start time
SELECT
    schedule_id,
    c.course_code,
    c.course_name,
    day_of_week,
    start_time,
    end_time,
    'End time before start time' as issue
FROM schedule sch
    JOIN course c ON sch.course_id = c.course_id
WHERE
    end_time <= start_time
ORDER BY schedule_id;

-- Query 2.10: Classrooms with invalid capacity
SELECT
    classroom_id,
    building,
    room_number,
    capacity,
    'Invalid capacity' as issue
FROM classroom
WHERE
    capacity <= 0
ORDER BY classroom_id;

-- Query 2.11: Enrollments with grade but not completed
SELECT
    enrollment_id,
    student_id,
    schedule_id,
    grade,
    status,
    'Grade assigned but not completed' as issue
FROM enrollment
WHERE
    grade IS NOT NULL
    AND status != 'Completed'
ORDER BY enrollment_id;

-- Query 2.12: Completed enrollments without grade
SELECT
    enrollment_id,
    student_id,
    schedule_id,
    status,
    'Completed but no grade' as issue
FROM enrollment
WHERE
    status = 'Completed'
    AND grade IS NULL
ORDER BY enrollment_id;

-- ============================================================================
-- SECTION 3: REFERENTIAL INTEGRITY CHECKS
-- ============================================================================

-- Query 3.1: Orphaned students (department doesn't exist)
SELECT s.student_id, s.first_name, s.last_name, s.department_id, 'Orphaned student - department missing' as issue
FROM student s
    LEFT JOIN department d ON s.department_id = d.department_id
WHERE
    d.department_id IS NULL;

-- Query 3.2: Orphaned instructors (department doesn't exist)
SELECT i.instructor_id, i.first_name, i.last_name, i.department_id, 'Orphaned instructor - department missing' as issue
FROM instructor i
    LEFT JOIN department d ON i.department_id = d.department_id
WHERE
    d.department_id IS NULL;

-- Query 3.3: Orphaned courses (department doesn't exist)
SELECT c.course_id, c.course_code, c.course_name, c.department_id, 'Orphaned course - department missing' as issue
FROM course c
    LEFT JOIN department d ON c.department_id = d.department_id
WHERE
    d.department_id IS NULL;

-- Query 3.4: Courses with invalid prerequisites (prerequisite doesn't exist)
SELECT c.course_id, c.course_code, c.course_name, c.prerequisite_course_id, 'Invalid prerequisite' as issue
FROM course c
    LEFT JOIN course prereq ON c.prerequisite_course_id = prereq.course_id
WHERE
    c.prerequisite_course_id IS NOT NULL
    AND prereq.course_id IS NULL;

-- Query 3.5: Orphaned enrollments (student doesn't exist)
SELECT e.enrollment_id, e.student_id, e.schedule_id, 'Orphaned enrollment - student missing' as issue
FROM enrollment e
    LEFT JOIN student s ON e.student_id = s.student_id
WHERE
    s.student_id IS NULL;

-- Query 3.6: Orphaned enrollments (schedule doesn't exist)
SELECT e.enrollment_id, e.student_id, e.schedule_id, 'Orphaned enrollment - schedule missing' as issue
FROM enrollment e
    LEFT JOIN schedule sch ON e.schedule_id = sch.schedule_id
WHERE
    sch.schedule_id IS NULL;

-- Query 3.7: Orphaned schedules (course doesn't exist)
SELECT sch.schedule_id, sch.course_id, 'Orphaned schedule - course missing' as issue
FROM schedule sch
    LEFT JOIN course c ON sch.course_id = c.course_id
WHERE
    c.course_id IS NULL;

-- Query 3.8: Orphaned schedules (instructor doesn't exist)
SELECT sch.schedule_id, sch.instructor_id, 'Orphaned schedule - instructor missing' as issue
FROM schedule sch
    LEFT JOIN instructor i ON sch.instructor_id = i.instructor_id
WHERE
    i.instructor_id IS NULL;

-- Query 3.9: Orphaned schedules (classroom doesn't exist)
SELECT sch.schedule_id, sch.classroom_id, 'Orphaned schedule - classroom missing' as issue
FROM schedule sch
    LEFT JOIN classroom cl ON sch.classroom_id = cl.classroom_id
WHERE
    cl.classroom_id IS NULL;

-- Query 3.10: Department heads that don't exist as instructors
SELECT d.department_id, d.dept_name, d.head_instructor_id, 'Department head not found in instructors' as issue
FROM department d
    LEFT JOIN instructor i ON d.head_instructor_id = i.instructor_id
WHERE
    d.head_instructor_id IS NOT NULL
    AND i.instructor_id IS NULL;

-- ============================================================================
-- SECTION 4: BUSINESS LOGIC VALIDATION
-- ============================================================================

-- Query 4.1: Students enrolled in courses from different departments
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    sd.dept_name as student_dept,
    cd.dept_name as course_dept,
    c.course_code,
    c.course_name,
    'Cross-department enrollment' as note
FROM
    student s
    JOIN department sd ON s.department_id = sd.department_id
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
    JOIN course c ON sch.course_id = c.course_id
    JOIN department cd ON c.department_id = cd.department_id
WHERE
    s.department_id != c.department_id
    AND e.status = 'Enrolled'
ORDER BY s.student_id, c.course_code;

-- Query 4.2: Students over-enrolled (more than 6 courses per semester)
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    sch.semester,
    sch.year,
    COUNT(DISTINCT e.enrollment_id) as course_count,
    'Over-enrolled' as issue
FROM
    student s
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
WHERE
    e.status = 'Enrolled'
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name,
    sch.semester,
    sch.year
HAVING
    COUNT(DISTINCT e.enrollment_id) > 6
ORDER BY course_count DESC;

-- Query 4.3: Students under-enrolled (less than 3 courses per semester)
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    sch.semester,
    sch.year,
    COUNT(DISTINCT e.enrollment_id) as course_count,
    'Under-enrolled' as issue
FROM
    student s
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
WHERE
    e.status = 'Enrolled'
    AND s.status = 'Active'
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name,
    sch.semester,
    sch.year
HAVING
    COUNT(DISTINCT e.enrollment_id) < 3
ORDER BY course_count;

-- Query 4.4: Courses over capacity
SELECT
    c.course_code,
    c.course_name,
    c.max_capacity,
    sch.semester,
    sch.year,
    COUNT(e.enrollment_id) as enrolled_count,
    COUNT(e.enrollment_id) - c.max_capacity as over_by,
    'Over capacity' as issue
FROM
    course c
    JOIN schedule sch ON c.course_id = sch.course_id
    JOIN enrollment e ON sch.schedule_id = e.schedule_id
WHERE
    e.status = 'Enrolled'
    AND c.max_capacity IS NOT NULL
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    c.max_capacity,
    sch.semester,
    sch.year
HAVING
    COUNT(e.enrollment_id) > c.max_capacity
ORDER BY over_by DESC;

-- Query 4.5: Instructors teaching too many courses (more than 4)
SELECT
    i.instructor_id,
    i.first_name || ' ' || i.last_name as instructor_name,
    i.rank,
    sch.semester,
    sch.year,
    COUNT(DISTINCT sch.course_id) as courses_teaching,
    'Heavy teaching load' as issue
FROM instructor i
    JOIN schedule sch ON i.instructor_id = sch.instructor_id
GROUP BY
    i.instructor_id,
    i.first_name,
    i.last_name,
    i.rank,
    sch.semester,
    sch.year
HAVING
    COUNT(DISTINCT sch.course_id) > 4
ORDER BY courses_teaching DESC;

-- Query 4.6: Students with schedule conflicts (overlapping times)
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    c1.course_code as course1,
    c2.course_code as course2,
    sch1.day_of_week,
    sch1.start_time,
    sch1.end_time,
    'Schedule conflict' as issue
FROM
    student s
    JOIN enrollment e1 ON s.student_id = e1.student_id
    JOIN schedule sch1 ON e1.schedule_id = sch1.schedule_id
    JOIN course c1 ON sch1.course_id = c1.course_id
    JOIN enrollment e2 ON s.student_id = e2.student_id
    JOIN schedule sch2 ON e2.schedule_id = sch2.schedule_id
    JOIN course c2 ON sch2.course_id = c2.course_id
WHERE
    e1.status = 'Enrolled'
    AND e2.status = 'Enrolled'
    AND e1.enrollment_id < e2.enrollment_id
    AND sch1.day_of_week = sch2.day_of_week
    AND sch1.semester = sch2.semester
    AND sch1.year = sch2.year
    AND (
        sch1.start_time,
        sch1.end_time
    ) OVERLAPS (
        sch2.start_time,
        sch2.end_time
    )
ORDER BY s.student_id, sch1.day_of_week, sch1.start_time;

-- Query 4.7: Students enrolled without completing prerequisites
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    c.course_code,
    c.course_name,
    prereq.course_code as prerequisite_code,
    prereq.course_name as prerequisite_name,
    'Prerequisite not completed' as issue
FROM
    student s
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
    JOIN course c ON sch.course_id = c.course_id
    JOIN course prereq ON c.prerequisite_course_id = prereq.course_id
WHERE
    e.status = 'Enrolled'
    AND NOT EXISTS (
        SELECT 1
        FROM enrollment e2
            JOIN schedule sch2 ON e2.schedule_id = sch2.schedule_id
        WHERE
            e2.student_id = s.student_id
            AND sch2.course_id = c.prerequisite_course_id
            AND e2.status = 'Completed'
            AND e2.grade NOT IN ('F', 'D')
    )
ORDER BY s.student_id, c.course_code;

-- Query 4.8: Instructors teaching outside their department
SELECT
    i.instructor_id,
    i.first_name || ' ' || i.last_name as instructor_name,
    id.dept_name as instructor_dept,
    cd.dept_name as course_dept,
    c.course_code,
    c.course_name,
    'Teaching outside department' as note
FROM
    instructor i
    JOIN department id ON i.department_id = id.department_id
    JOIN schedule sch ON i.instructor_id = sch.instructor_id
    JOIN course c ON sch.course_id = c.course_id
    JOIN department cd ON c.department_id = cd.department_id
WHERE
    i.department_id != c.department_id
ORDER BY i.instructor_id, c.course_code;

-- ============================================================================
-- SECTION 5: DATA COMPLETENESS CHECKS
-- ============================================================================

-- Query 5.1: Students with missing phone numbers
SELECT
    student_id,
    first_name,
    last_name,
    email,
    'Missing phone number' as issue
FROM student
WHERE
    phone IS NULL
    OR TRIM(phone) = ''
ORDER BY student_id;

-- Query 5.2: Instructors with missing phone numbers
SELECT
    instructor_id,
    first_name,
    last_name,
    email,
    'Missing phone number' as issue
FROM instructor
WHERE
    phone IS NULL
    OR TRIM(phone) = ''
ORDER BY instructor_id;

-- Query 5.3: Courses without descriptions
SELECT
    course_id,
    course_code,
    course_name,
    'Missing description' as issue
FROM course
WHERE
    description IS NULL
    OR TRIM(description) = ''
ORDER BY course_code;

-- Query 5.4: Courses without max capacity
SELECT
    course_id,
    course_code,
    course_name,
    'Missing max capacity' as issue
FROM course
WHERE
    max_capacity IS NULL
ORDER BY course_code;

-- Query 5.5: Departments without buildings
SELECT
    department_id,
    dept_name,
    dept_code,
    'Missing building' as issue
FROM department
WHERE
    building IS NULL
    OR TRIM(building) = ''
ORDER BY dept_code;

-- Query 5.6: Departments without heads
SELECT
    department_id,
    dept_name,
    dept_code,
    'Missing department head' as issue
FROM department
WHERE
    head_instructor_id IS NULL
ORDER BY dept_code;

-- Query 5.7: Classrooms without equipment info
SELECT
    classroom_id,
    building,
    room_number,
    'Missing equipment info' as issue
FROM classroom
WHERE
    equipment IS NULL
    OR TRIM(equipment) = ''
ORDER BY building, room_number;

-- ============================================================================
-- SECTION 6: STATISTICAL ANOMALIES
-- ============================================================================

-- Query 6.1: Courses with unusual grade distributions (too many A's or F's)
SELECT
    c.course_code,
    c.course_name,
    COUNT(e.enrollment_id) as total_graded,
    COUNT(
        CASE
            WHEN e.grade IN ('A', 'A-') THEN 1
        END
    ) as grade_a,
    COUNT(
        CASE
            WHEN e.grade = 'F' THEN 1
        END
    ) as grade_f,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) * 100,
        2
    ) as percent_a,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade = 'F' THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) * 100,
        2
    ) as percent_f,
    CASE
        WHEN COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) > 0.7 THEN 'Too many A grades'
        WHEN COUNT(
            CASE
                WHEN e.grade = 'F' THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) > 0.3 THEN 'High failure rate'
        ELSE 'Normal distribution'
    END as note
FROM
    course c
    JOIN schedule sch ON c.course_id = sch.course_id
    JOIN enrollment e ON sch.schedule_id = e.schedule_id
WHERE
    e.status = 'Completed'
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name
HAVING
    COUNT(e.enrollment_id) >= 5 -- Only courses with enough data
ORDER BY percent_a DESC;

-- Query 6.2: Departments with unusual student-faculty ratios
SELECT
    d.dept_name,
    COUNT(DISTINCT s.student_id) as students,
    COUNT(DISTINCT i.instructor_id) as instructors,
    ROUND(
        COUNT(DISTINCT s.student_id)::NUMERIC / NULLIF(
            COUNT(DISTINCT i.instructor_id),
            0
        ),
        2
    ) as ratio,
    CASE
        WHEN COUNT(DISTINCT s.student_id)::NUMERIC / NULLIF(
            COUNT(DISTINCT i.instructor_id),
            0
        ) > 50 THEN 'Very high ratio'
        WHEN COUNT(DISTINCT s.student_id)::NUMERIC / NULLIF(
            COUNT(DISTINCT i.instructor_id),
            0
        ) < 10 THEN 'Very low ratio'
        ELSE 'Normal ratio'
    END as note
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    AND s.status = 'Active'
    LEFT JOIN instructor i ON d.department_id = i.department_id
GROUP BY
    d.department_id,
    d.dept_name
ORDER BY ratio DESC NULLS LAST;

-- Query 6.3: Courses with unusual drop rates
SELECT
    c.course_code,
    c.course_name,
    COUNT(e.enrollment_id) as total_enrollments,
    COUNT(
        CASE
            WHEN e.status = 'Dropped' THEN 1
        END
    ) as dropped,
    ROUND(
        COUNT(
            CASE
                WHEN e.status = 'Dropped' THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) * 100,
        2
    ) as drop_rate_percent,
    CASE
        WHEN COUNT(
            CASE
                WHEN e.status = 'Dropped' THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) > 0.25 THEN 'High drop rate'
        ELSE 'Normal drop rate'
    END as note
FROM
    course c
    JOIN schedule sch ON c.course_id = sch.course_id
    JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name
HAVING
    COUNT(e.enrollment_id) >= 5
ORDER BY drop_rate_percent DESC;

-- ============================================================================
-- SECTION 7: DATA QUALITY SUMMARY REPORT
-- ============================================================================

-- Comprehensive data quality report

WITH quality_metrics AS (
    SELECT 'Duplicate Students' as metric, COUNT(*) as issue_count
    FROM (SELECT email FROM student GROUP BY email HAVING COUNT(*) > 1) dup
    
    UNION ALL
    
    SELECT 'Invalid Student Emails', COUNT(*)
    FROM student
    WHERE email ! ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    
    UNION ALL
    
    SELECT 'Students with Future Birth Dates', COUNT(*)
    FROM student
    WHERE date_of_birth > CURRENT_DATE
    
    UNION ALL
    
    SELECT 'Orphaned Students', COUNT(*)
    FROM student s
    LEFT JOIN department d ON s.department_id = d.department_id
    WHERE d.department_id IS NULL
    
    UNION ALL
    
    SELECT 'Duplicate Enrollments', COUNT(*)
    FROM (SELECT student_id, schedule_id FROM enrollment GROUP BY student_id, schedule_id HAVING COUNT(*) > 1) dup
    
    UNION ALL
    
    SELECT 'Completed Enrollments Without Grades', COUNT(*)
    FROM enrollment
    WHERE status = 'Completed' AND grade IS NULL
    
    UNION ALL
    
    SELECT 'Schedule Conflicts', COUNT(*)
    FROM (
        SELECT DISTINCT e1.student_id
        FROM enrollment e1
        JOIN schedule sch1 ON e1.schedule_id = sch1.schedule_id
        JOIN enrollment e2 ON e1.student_id = e2.student_id
        JOIN schedule sch2 ON e2.schedule_id = sch2.schedule_id
        WHERE e1.enrollment_id < e2.enrollment_id
        AND e1.status = 'Enrolled' AND e2.status = 'Enrolled'
        AND sch1.day_of_week = sch2.day_of_week
        AND sch1.semester = sch2.semester
        AND sch1.year = sch2.year
        AND (sch1.start_time, sch1.end_time) OVERLAPS (sch2.start_time, sch2.end_time)
    ) conflicts
    
    UNION ALL
    
    SELECT 'Over-Capacity Courses', COUNT(*)
    FROM (
        SELECT sch.schedule_id
        FROM schedule sch
        JOIN course c ON sch.course_id = c.course_id
        JOIN enrollment e ON sch. schedule_id = e.schedule_id
        WHERE e.status = 'Enrolled'
        AND c.max_capacity IS NOT NULL
        GROUP BY sch.schedule_id, c.max_capacity
        HAVING COUNT(e.enrollment_id) > c.max_capacity
    ) overcap
    
    UNION ALL
    
    SELECT 'Prerequisite Violations', COUNT(*)
    FROM (
        SELECT DISTINCT e.enrollment_id
        FROM enrollment e
        JOIN schedule sch ON e. schedule_id = sch.schedule_id
        JOIN course c ON sch.course_id = c.course_id
        WHERE e.status = 'Enrolled'
        AND c.prerequisite_course_id IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 
            FROM enrollment e2
            JOIN schedule sch2 ON e2.schedule_id = sch2.schedule_id
            WHERE e2.student_id = e. student_id
            AND sch2.course_id = c. prerequisite_course_id
            AND e2.status = 'Completed'
            AND e2.grade NOT IN ('F', 'D')
        )
    ) prereq
)
SELECT 
    metric,
    issue_count,
    CASE 
        WHEN issue_count = 0 THEN '✓ PASS'
        WHEN issue_count <= 5 THEN '⚠️  WARNING'
        ELSE '❌ CRITICAL'
    END as status
FROM quality_metrics
ORDER BY issue_count DESC;

-- ============================================================================
-- SECTION 8: DATA CLEANUP PROCEDURES
-- ============================================================================

-- Procedure 8.1: Remove duplicate enrollments (keeps the first one)
CREATE OR REPLACE PROCEDURE cleanup_duplicate_enrollments()
AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM enrollment
    WHERE enrollment_id IN (
        SELECT enrollment_id
        FROM (
            SELECT 
                enrollment_id,
                ROW_NUMBER() OVER (
                    PARTITION BY student_id, schedule_id 
                    ORDER BY enrollment_date, enrollment_id
                ) as rn
            FROM enrollment
        ) duplicates
        WHERE rn > 1
    );
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % duplicate enrollments', v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Procedure 8.2: Fix completed enrollments without grades
CREATE OR REPLACE PROCEDURE fix_completed_enrollments_without_grades()
AS $$
BEGIN
    UPDATE enrollment
    SET status = 'Enrolled'
    WHERE status = 'Completed' AND grade IS NULL;
    
    RAISE NOTICE 'Fixed completed enrollments without grades';
END;
$$ LANGUAGE plpgsql;

-- Procedure 8.3: Trim whitespace from all text fields
CREATE OR REPLACE PROCEDURE trim_all_text_fields()
AS $$
BEGIN
    UPDATE student SET 
        first_name = TRIM(first_name),
        last_name = TRIM(last_name),
        email = TRIM(LOWER(email));
    
    UPDATE instructor SET 
        first_name = TRIM(first_name),
        last_name = TRIM(last_name),
        email = TRIM(LOWER(email));
    
    UPDATE department SET 
        dept_name = TRIM(dept_name),
        dept_code = TRIM(UPPER(dept_code));
    
    UPDATE course SET 
        course_code = TRIM(UPPER(course_code)),
        course_name = TRIM(course_name);
    
    RAISE NOTICE 'Trimmed whitespace from all text fields';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

/*
-- Run data quality checks
SELECT * FROM student WHERE email ! ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- Run cleanup procedures
CALL cleanup_duplicate_enrollments();
CALL fix_completed_enrollments_without_grades();
CALL trim_all_text_fields();

-- Generate summary report
-- (Copy and run the quality_metrics CTE query above)
*/