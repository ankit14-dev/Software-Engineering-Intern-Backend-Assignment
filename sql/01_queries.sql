-- Active: 1765792167237@@ep-young-mouse-a1oq2npn-pooler.ap-southeast-1.aws.neon.tech@5432@employees
-- ============================================================================
-- SQL Development & Optimization
-- Author:  Ankit
-- Date: 2025-12-17
-- Description: Complex queries for university database
-- ============================================================================

-- ============================================================================
-- SECTION 1: BASIC AGGREGATIONS
-- ============================================================================

-- Query 1.1: Count students per department



SELECT
    d.dept_name,
    d.dept_code,
    COUNT(s.student_id) as total_students,
    COUNT(
        CASE
            WHEN s.status = 'Active' THEN 1
        END
    ) as active_students,
    COUNT(
        CASE
            WHEN s.status = 'Graduated' THEN 1
        END
    ) as graduated_students
FROM department d
    LEFT JOIN student s ON d.department_id = s.department_id
GROUP BY
    d.department_id,
    d.dept_name,
    d.dept_code
ORDER BY total_students DESC;

-- Query 1.2: Average enrollment year per department
SELECT
    d.dept_name,
    ROUND(AVG(s.enrollment_year), 2) as avg_enrollment_year,
    MIN(s.enrollment_year) as earliest_year,
    MAX(s.enrollment_year) as latest_year,
    COUNT(s.student_id) as student_count
FROM department d
    LEFT JOIN student s ON d.department_id = s.department_id
GROUP BY
    d.dept_name
ORDER BY avg_enrollment_year DESC;

-- Query 1.3: Course statistics
SELECT
    c.course_code,
    c.course_name,
    c.credits,
    c.max_capacity,
    COUNT(DISTINCT sch.schedule_id) as sections_offered,
    COUNT(DISTINCT e.student_id) as total_enrollments,
    ROUND(
        COUNT(DISTINCT e.student_id)::numeric / NULLIF(
            COUNT(DISTINCT sch.schedule_id),
            0
        ),
        2
    ) as avg_students_per_section
FROM
    course c
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    c.credits,
    c.max_capacity
ORDER BY total_enrollments DESC;

-- Query 1.4: Instructor teaching load
SELECT
    i.first_name || ' ' || i.last_name as instructor_name,
    i.rank,
    d.dept_name,
    COUNT(DISTINCT sch.course_id) as courses_teaching,
    COUNT(DISTINCT sch.schedule_id) as total_sections,
    COUNT(DISTINCT e.student_id) as total_students,
    STRING_AGG(
        DISTINCT c.course_code,
        ', '
        ORDER BY c.course_code
    ) as courses
FROM
    instructor i
    JOIN department d ON i.department_id = d.department_id
    LEFT JOIN schedule sch ON i.instructor_id = sch.instructor_id
    LEFT JOIN course c ON sch.course_id = c.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    i.instructor_id,
    i.first_name,
    i.last_name,
    i.rank,
    d.dept_name
ORDER BY total_students DESC;

-- ============================================================================
-- SECTION 2: JOIN-HEAVY QUERIES
-- ============================================================================

-- Query 2.1: Complete student schedule view
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    s.email,
    d.dept_name,
    c.course_code,
    c.course_name,
    c.credits,
    i.first_name || ' ' || i.last_name as instructor_name,
    cl.building || ' ' || cl.room_number as classroom,
    sch.day_of_week,
    sch.start_time,
    sch.end_time,
    sch.semester,
    sch.year,
    e.grade,
    e.status as enrollment_status
FROM
    student s
    JOIN department d ON s.department_id = d.department_id
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
    JOIN course c ON sch.course_id = c.course_id
    JOIN instructor i ON sch.instructor_id = i.instructor_id
    JOIN classroom cl ON sch.classroom_id = cl.classroom_id
ORDER BY s.student_id, sch.day_of_week, sch.start_time;

-- Query 2.2: Course prerequisites chain

WITH RECURSIVE course_prerequisites AS (
    -- Base case: courses without prerequisites
    SELECT 
        course_id,
        course_code,
        course_name,
        prerequisite_course_id,
        0 as level,
        ARRAY[course_id] as path
    FROM course
    WHERE prerequisite_course_id IS NULL
    
    UNION ALL

-- Recursive case: courses with prerequisites
SELECT 
        c.course_id,
        c.course_code,
        c.course_name,
        c.prerequisite_course_id,
        cp.level + 1,
        cp.path || c. course_id
    FROM course c
    JOIN course_prerequisites cp ON c.prerequisite_course_id = cp. course_id
    WHERE NOT c.course_id = ANY(cp.path)  -- Prevent cycles
)
SELECT 
    level,
    course_code,
    course_name,
    prerequisite_course_id,
    (SELECT course_code FROM course WHERE course_id = cp.prerequisite_course_id) as prerequisite_code
FROM course_prerequisites cp
ORDER BY level, course_code;

-- Query 2.3: Student course history with grades
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    d.dept_name,
    COUNT(DISTINCT e.enrollment_id) as total_enrollments,
    COUNT(
        CASE
            WHEN e.status = 'Completed' THEN 1
        END
    ) as completed_courses,
    COUNT(
        CASE
            WHEN e.status = 'Enrolled' THEN 1
        END
    ) as current_courses,
    COUNT(
        CASE
            WHEN e.status = 'Dropped' THEN 1
        END
    ) as dropped_courses,
    SUM(
        CASE
            WHEN e.status = 'Completed' THEN c.credits
            ELSE 0
        END
    ) as total_credits,
    STRING_AGG(
        DISTINCT CASE
            WHEN e.status = 'Completed' THEN e.grade
        END,
        ', '
        ORDER BY e.grade
    ) as grades_earned
FROM
    student s
    JOIN department d ON s.department_id = d.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
    LEFT JOIN schedule sch ON e.schedule_id = sch.schedule_id
    LEFT JOIN course c ON sch.course_id = c.course_id
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name,
    d.dept_name
ORDER BY s.student_id;

-- Query 2.4: Classroom utilization analysis
SELECT
    cl.building,
    cl.room_number,
    cl.capacity,
    COUNT(DISTINCT sch.schedule_id) as total_classes,
    COUNT(DISTINCT sch.day_of_week) as days_used,
    STRING_AGG(
        DISTINCT sch.day_of_week,
        ', '
        ORDER BY sch.day_of_week
    ) as days,
    COUNT(DISTINCT e.student_id) as total_students,
    ROUND(
        COUNT(DISTINCT e.student_id)::numeric / NULLIF(cl.capacity, 0) * 100,
        2
    ) as utilization_percent
FROM
    classroom cl
    LEFT JOIN schedule sch ON cl.classroom_id = sch.classroom_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    cl.classroom_id,
    cl.building,
    cl.room_number,
    cl.capacity
ORDER BY utilization_percent DESC NULLS LAST;

-- ============================================================================
-- SECTION 3: ANALYTICAL QUERIES
-- ============================================================================

-- Query 3.1: Department comparison dashboard
SELECT
    d.dept_name,
    d.dept_code,
    COUNT(DISTINCT s.student_id) as total_students,
    COUNT(DISTINCT i.instructor_id) as total_instructors,
    COUNT(DISTINCT c.course_id) as total_courses,
    COUNT(DISTINCT e.enrollment_id) as total_enrollments,
    ROUND(
        COUNT(DISTINCT e.enrollment_id)::numeric / NULLIF(
            COUNT(DISTINCT s.student_id),
            0
        ),
        2
    ) as avg_courses_per_student,
    ROUND(
        COUNT(DISTINCT s.student_id)::numeric / NULLIF(
            COUNT(DISTINCT i.instructor_id),
            0
        ),
        2
    ) as student_instructor_ratio
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    LEFT JOIN instructor i ON d.department_id = i.department_id
    LEFT JOIN course c ON d.department_id = c.department_id
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    d.department_id,
    d.dept_name,
    d.dept_code
ORDER BY total_students DESC;

-- Query 3.2: Time slot popularity
SELECT
    sch.day_of_week,
    sch.start_time,
    sch.end_time,
    COUNT(DISTINCT sch.schedule_id) as classes_scheduled,
    COUNT(DISTINCT e.student_id) as total_students,
    ROUND(
        AVG(COUNT(DISTINCT e.student_id)) OVER (
            PARTITION BY
                sch.day_of_week
        ),
        2
    ) as avg_students_for_day
FROM schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    sch.day_of_week,
    sch.start_time,
    sch.end_time
ORDER BY sch.day_of_week, sch.start_time;

-- Query 3.3: Student retention by enrollment year
SELECT
    enrollment_year,
    COUNT(*) as total_students,
    COUNT(
        CASE
            WHEN status = 'Active' THEN 1
        END
    ) as active,
    COUNT(
        CASE
            WHEN status = 'Graduated' THEN 1
        END
    ) as graduated,
    COUNT(
        CASE
            WHEN status = 'Inactive' THEN 1
        END
    ) as inactive,
    ROUND(
        COUNT(
            CASE
                WHEN status = 'Active' THEN 1
            END
        )::numeric / COUNT(*) * 100,
        2
    ) as active_percent,
    ROUND(
        COUNT(
            CASE
                WHEN status = 'Graduated' THEN 1
            END
        )::numeric / COUNT(*) * 100,
        2
    ) as graduated_percent
FROM student
GROUP BY
    enrollment_year
ORDER BY enrollment_year DESC;

-- Query 3.4: Course difficulty analysis (based on grade distribution)
SELECT
    c.course_code,
    c.course_name,
    c.credits,
    COUNT(e.enrollment_id) as total_enrollments,
    COUNT(
        CASE
            WHEN e.grade IN ('A', 'A-') THEN 1
        END
    ) as grade_a,
    COUNT(
        CASE
            WHEN e.grade IN ('B+', 'B', 'B-') THEN 1
        END
    ) as grade_b,
    COUNT(
        CASE
            WHEN e.grade IN ('C+', 'C', 'C-') THEN 1
        END
    ) as grade_c,
    COUNT(
        CASE
            WHEN e.grade IN ('D', 'F') THEN 1
        END
    ) as grade_d_f,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::numeric / NULLIF(COUNT(e.enrollment_id), 0) * 100,
        2
    ) as percent_a,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('D', 'F') THEN 1
            END
        )::numeric / NULLIF(COUNT(e.enrollment_id), 0) * 100,
        2
    ) as percent_failing
FROM
    course c
    JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    AND e.status = 'Completed'
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    c.credits
HAVING
    COUNT(e.enrollment_id) > 0
ORDER BY percent_failing DESC NULLS LAST;

-- ============================================================================
-- SECTION 4: WINDOW FUNCTIONS
-- ============================================================================

-- Query 4.1: Student ranking by credits earned
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    d.dept_name,
    SUM(c.credits) as total_credits,
    RANK() OVER (
        ORDER BY SUM(c.credits) DESC
    ) as overall_rank,
    RANK() OVER (
        PARTITION BY
            d.department_id
        ORDER BY SUM(c.credits) DESC
    ) as dept_rank
FROM
    student s
    JOIN department d ON s.department_id = d.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
    AND e.status = 'Completed'
    LEFT JOIN schedule sch ON e.schedule_id = sch.schedule_id
    LEFT JOIN course c ON sch.course_id = c.course_id
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name,
    d.dept_name,
    d.department_id
ORDER BY total_credits DESC NULLS LAST;

-- Query 4.2: Running total of enrollments by semester
SELECT
    sch.year,
    sch.semester,
    COUNT(e.enrollment_id) as enrollments_this_semester,
    SUM(COUNT(e.enrollment_id)) OVER (
        ORDER BY sch.year, sch.semester
    ) as running_total_enrollments,
    AVG(COUNT(e.enrollment_id)) OVER (
        ORDER BY sch.year, sch.semester ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
    ) as moving_avg_3_semesters
FROM schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    sch.year,
    sch.semester
ORDER BY sch.year DESC, sch.semester;

-- ============================================================================
-- SECTION 5: REPORTS
-- ============================================================================

-- Report 1: Students per department with demographics
SELECT
    d.dept_name,
    d.dept_code,
    COUNT(s.student_id) as total_students,
    COUNT(
        CASE
            WHEN s.status = 'Active' THEN 1
        END
    ) as active,
    COUNT(
        CASE
            WHEN s.status = 'Graduated' THEN 1
        END
    ) as graduated,
    ROUND(
        AVG(
            EXTRACT(
                YEAR
                FROM CURRENT_DATE
            ) - EXTRACT(
                YEAR
                FROM s.date_of_birth
            )
        ),
        1
    ) as avg_age,
    MIN(s.enrollment_year) as earliest_enrollment,
    MAX(s.enrollment_year) as latest_enrollment,
    COUNT(DISTINCT i.instructor_id) as instructors
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    LEFT JOIN instructor i ON d.department_id = i.department_id
GROUP BY
    d.department_id,
    d.dept_name,
    d.dept_code
ORDER BY total_students DESC;

-- Report 2: Average grade per course
SELECT
    c.course_code,
    c.course_name,
    d.dept_name,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Completed'
    ) as completed_enrollments,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Enrolled'
    ) as current_enrollments,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Dropped'
    ) as dropped_enrollments,
    MODE() WITHIN GROUP (
        ORDER BY e.grade
    ) as most_common_grade,
    ROUND(
        AVG(
            CASE
                WHEN e.grade = 'A' THEN 4.0
                WHEN e.grade = 'A-' THEN 3.7
                WHEN e.grade = 'B+' THEN 3.3
                WHEN e.grade = 'B' THEN 3.0
                WHEN e.grade = 'B-' THEN 2.7
                WHEN e.grade = 'C+' THEN 2.3
                WHEN e.grade = 'C' THEN 2.0
                WHEN e.grade = 'C-' THEN 1.7
                WHEN e.grade = 'D' THEN 1.0
                WHEN e.grade = 'F' THEN 0.0
            END
        ),
        2
    ) as avg_gpa
FROM
    course c
    JOIN department d ON c.department_id = d.department_id
    JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    d.dept_name
HAVING
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Completed'
    ) > 0
ORDER BY avg_gpa DESC NULLS LAST;

-- Report 3: Faculty workload report
SELECT
    i.instructor_id,
    i.first_name || ' ' || i.last_name as instructor_name,
    i.rank,
    d.dept_name,
    i.hire_date,
    EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, i.hire_date)
    ) as years_of_service,
    COUNT(DISTINCT sch.course_id) as unique_courses,
    COUNT(sch.schedule_id) as total_sections,
    SUM(c.credits) as total_credit_hours,
    COUNT(DISTINCT e.student_id) as total_students,
    ROUND(
        COUNT(DISTINCT e.student_id)::numeric / NULLIF(COUNT(sch.schedule_id), 0),
        1
    ) as avg_class_size
FROM
    instructor i
    JOIN department d ON i.department_id = d.department_id
    LEFT JOIN schedule sch ON i.instructor_id = sch.instructor_id
    LEFT JOIN course c ON sch.course_id = c.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    i.instructor_id,
    i.first_name,
    i.last_name,
    i.rank,
    d.dept_name,
    i.hire_date
ORDER BY total_students DESC;

-- Report 4: Semester enrollment trends
SELECT
    sch.year,
    sch.semester,
    COUNT(DISTINCT s.student_id) as unique_students,
    COUNT(DISTINCT c.course_id) as courses_offered,
    COUNT(DISTINCT sch.schedule_id) as total_sections,
    COUNT(e.enrollment_id) as total_enrollments,
    ROUND(
        COUNT(e.enrollment_id)::numeric / NULLIF(
            COUNT(DISTINCT s.student_id),
            0
        ),
        2
    ) as avg_courses_per_student,
    ROUND(
        COUNT(e.enrollment_id)::numeric / NULLIF(
            COUNT(DISTINCT sch.schedule_id),
            0
        ),
        2
    ) as avg_students_per_section
FROM
    schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    LEFT JOIN student s ON e.student_id = s.student_id
    LEFT JOIN course c ON sch.course_id = c.course_id
GROUP BY
    sch.year,
    sch.semester
ORDER BY sch.year DESC, sch.semester;