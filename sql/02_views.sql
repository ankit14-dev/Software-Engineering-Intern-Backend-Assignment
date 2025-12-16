-- ============================================================================
-- VIEWS AND MATERIALIZED VIEWS
-- ============================================================================

-- View 1: Active students with full details
CREATE OR REPLACE VIEW v_active_students AS
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    s.date_of_birth,
    EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, s.date_of_birth)
    ) as age,
    s.enrollment_year,
    EXTRACT(
        YEAR
        FROM CURRENT_DATE
    ) - s.enrollment_year as years_enrolled,
    d.dept_name,
    d.dept_code,
    d.building as dept_building,
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
    SUM(
        CASE
            WHEN e.status = 'Completed' THEN c.credits
            ELSE 0
        END
    ) as total_credits_earned
FROM
    student s
    JOIN department d ON s.department_id = d.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
    LEFT JOIN schedule sch ON e.schedule_id = sch.schedule_id
    LEFT JOIN course c ON sch.course_id = c.course_id
WHERE
    s.status = 'Active'
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    s.date_of_birth,
    s.enrollment_year,
    d.dept_name,
    d.dept_code,
    d.building;

-- View 2: Course catalog with prerequisites
CREATE OR REPLACE VIEW v_course_catalog AS
SELECT
    c.course_id,
    c.course_code,
    c.course_name,
    c.description,
    c.credits,
    c.max_capacity,
    d.dept_name,
    d.dept_code,
    prereq.course_code as prerequisite_code,
    prereq.course_name as prerequisite_name,
    COUNT(DISTINCT sch.schedule_id) as sections_available,
    COUNT(DISTINCT e.student_id) as current_enrollments
FROM
    course c
    JOIN department d ON c.department_id = d.department_id
    LEFT JOIN course prereq ON c.prerequisite_course_id = prereq.course_id
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    AND e.status = 'Enrolled'
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    c.description,
    c.credits,
    c.max_capacity,
    d.dept_name,
    d.dept_code,
    prereq.course_code,
    prereq.course_name;

-- View 3: Instructor directory
CREATE OR REPLACE VIEW v_instructor_directory AS
SELECT
    i.instructor_id,
    i.first_name || ' ' || i.last_name as full_name,
    i.email,
    i.phone,
    i.rank,
    d.dept_name,
    d.dept_code,
    d.building,
    i.hire_date,
    EXTRACT(
        YEAR
        FROM AGE (CURRENT_DATE, i.hire_date)
    ) as years_of_service,
    COUNT(DISTINCT sch.course_id) as courses_teaching,
    COUNT(DISTINCT e.student_id) as total_students,
    STRING_AGG(
        DISTINCT c.course_code,
        ', '
        ORDER BY c.course_code
    ) as course_codes
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
    i.email,
    i.phone,
    i.rank,
    d.dept_name,
    d.dept_code,
    d.building,
    i.hire_date;

-- View 4: Current semester schedule
CREATE OR REPLACE VIEW v_current_semester_schedule AS
SELECT
    sch.schedule_id,
    c.course_code,
    c.course_name,
    c.credits,
    i.first_name || ' ' || i.last_name as instructor_name,
    cl.building || ' ' || cl.room_number as classroom,
    cl.capacity,
    sch.day_of_week,
    sch.start_time,
    sch.end_time,
    sch.semester,
    sch.year,
    COUNT(e.student_id) as enrolled_students,
    c.max_capacity - COUNT(e.student_id) as available_seats,
    ROUND(
        COUNT(e.student_id)::numeric / NULLIF(c.max_capacity, 0) * 100,
        2
    ) as fill_percentage
FROM
    schedule sch
    JOIN course c ON sch.course_id = c.course_id
    JOIN instructor i ON sch.instructor_id = i.instructor_id
    JOIN classroom cl ON sch.classroom_id = cl.classroom_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    AND e.status = 'Enrolled'
WHERE
    sch.year = EXTRACT(
        YEAR
        FROM CURRENT_DATE
    )
GROUP BY
    sch.schedule_id,
    c.course_code,
    c.course_name,
    c.credits,
    i.first_name,
    i.last_name,
    cl.building,
    cl.room_number,
    cl.capacity,
    sch.day_of_week,
    sch.start_time,
    sch.end_time,
    sch.semester,
    sch.year,
    c.max_capacity;

-- View 5: Department summary
CREATE OR REPLACE VIEW v_department_summary AS
SELECT
    d.department_id,
    d.dept_name,
    d.dept_code,
    d.building,
    head.first_name || ' ' || head.last_name as department_head,
    d.established_year,
    COUNT(DISTINCT s.student_id) as total_students,
    COUNT(DISTINCT i.instructor_id) as total_instructors,
    COUNT(DISTINCT c.course_id) as total_courses,
    ROUND(
        COUNT(DISTINCT s.student_id)::numeric / NULLIF(
            COUNT(DISTINCT i.instructor_id),
            0
        ),
        2
    ) as student_faculty_ratio
FROM
    department d
    LEFT JOIN instructor head ON d.head_instructor_id = head.instructor_id
    LEFT JOIN student s ON d.department_id = s.department_id
    AND s.status = 'Active'
    LEFT JOIN instructor i ON d.department_id = i.department_id
    LEFT JOIN course c ON d.department_id = c.department_id
GROUP BY
    d.department_id,
    d.dept_name,
    d.dept_code,
    d.building,
    head.first_name,
    head.last_name,
    d.established_year;

-- ============================================================================
-- MATERIALIZED VIEWS (for performance on large datasets)
-- ============================================================================

-- Materialized View 1: Student GPA summary
CREATE MATERIALIZED VIEW mv_student_gpa AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name as student_name,
    d.dept_name,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Completed'
    ) as completed_courses,
    SUM(c.credits) FILTER (
        WHERE
            e.status = 'Completed'
    ) as total_credits,
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
        3
    ) as gpa,
    STRING_AGG(
        DISTINCT e.grade,
        ', '
        ORDER BY e.grade
    ) FILTER (
        WHERE
            e.status = 'Completed'
    ) as grades_received
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
    d.dept_name;

-- Create index on materialized view
CREATE INDEX idx_mv_student_gpa_dept ON mv_student_gpa (dept_name);

CREATE INDEX idx_mv_student_gpa_gpa ON mv_student_gpa (gpa DESC NULLS LAST);

-- Refresh command (run periodically)
-- REFRESH MATERIALIZED VIEW mv_student_gpa;

-- Materialized View 2: Course enrollment statistics
CREATE MATERIALIZED VIEW mv_course_stats AS
SELECT
    c.course_id,
    c.course_code,
    c.course_name,
    d.dept_name,
    COUNT(DISTINCT sch.schedule_id) as total_sections_offered,
    COUNT(e.enrollment_id) as total_enrollments,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Completed'
    ) as completed,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Dropped'
    ) as dropped,
    ROUND(
        COUNT(e.enrollment_id) FILTER (
            WHERE
                e.status = 'Dropped'
        )::numeric / NULLIF(COUNT(e.enrollment_id), 0) * 100,
        2
    ) as drop_rate_percent,
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
        3
    ) as avg_grade_gpa
FROM
    course c
    JOIN department d ON c.department_id = d.department_id
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    c.course_id,
    c.course_code,
    c.course_name,
    d.dept_name;

CREATE INDEX idx_mv_course_stats_dept ON mv_course_stats (dept_name);

CREATE INDEX idx_mv_course_stats_enrollments ON mv_course_stats (total_enrollments DESC);