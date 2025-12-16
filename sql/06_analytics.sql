-- ============================================================================
-- ADVANCED ANALYTICS QUERIES
-- Author:  Ankit
-- Date: 2025-12-17
-- ============================================================================

-- ============================================================================
-- SECTION 1: COHORT ANALYSIS
-- ============================================================================

-- Query 1.1: Student retention by enrollment year
SELECT
    enrollment_year,
    COUNT(*) as total_students,
    COUNT(
        CASE
            WHEN status = 'Active' THEN 1
        END
    ) as still_active,
    COUNT(
        CASE
            WHEN status = 'Graduated' THEN 1
        END
    ) as graduated,
    COUNT(
        CASE
            WHEN status IN ('Inactive', 'Suspended') THEN 1
        END
    ) as dropped_out,
    ROUND(
        COUNT(
            CASE
                WHEN status = 'Active' THEN 1
            END
        )::NUMERIC / COUNT(*) * 100,
        2
    ) as retention_rate,
    ROUND(
        COUNT(
            CASE
                WHEN status = 'Graduated' THEN 1
            END
        )::NUMERIC / COUNT(*) * 100,
        2
    ) as graduation_rate
FROM student
GROUP BY
    enrollment_year
ORDER BY enrollment_year DESC;

-- Query 1.2: Course completion rates by semester
SELECT
    sch.year,
    sch.semester,
    c.course_code,
    c.course_name,
    COUNT(e.enrollment_id) as total_enrolled,
    COUNT(
        CASE
            WHEN e.status = 'Completed' THEN 1
        END
    ) as completed,
    COUNT(
        CASE
            WHEN e.status = 'Dropped' THEN 1
        END
    ) as dropped,
    ROUND(
        COUNT(
            CASE
                WHEN e.status = 'Completed' THEN 1
            END
        )::NUMERIC / COUNT(e.enrollment_id) * 100,
        2
    ) as completion_rate
FROM
    schedule sch
    JOIN course c ON sch.course_id = c.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    sch.year,
    sch.semester,
    c.course_id,
    c.course_code,
    c.course_name
HAVING
    COUNT(e.enrollment_id) > 0
ORDER BY sch.year DESC, sch.semester, completion_rate;

-- ============================================================================
-- SECTION 2: PREDICTIVE ANALYTICS
-- ============================================================================

-- Query 2.1: Students at risk (low GPA or many dropped courses)
WITH
    student_performance AS (
        SELECT
            s.student_id,
            s.first_name || ' ' || s.last_name as student_name,
            d.dept_name,
            COUNT(e.enrollment_id) as total_enrollments,
            COUNT(
                CASE
                    WHEN e.status = 'Dropped' THEN 1
                END
            ) as dropped_count,
            COUNT(
                CASE
                    WHEN e.status = 'Completed' THEN 1
                END
            ) as completed_count,
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
            ROUND(
                COUNT(
                    CASE
                        WHEN e.status = 'Dropped' THEN 1
                    END
                )::NUMERIC / NULLIF(COUNT(e.enrollment_id), 0) * 100,
                2
            ) as drop_rate
        FROM
            student s
            JOIN department d ON s.department_id = d.department_id
            LEFT JOIN enrollment e ON s.student_id = e.student_id
        WHERE
            s.status = 'Active'
        GROUP BY
            s.student_id,
            s.first_name,
            s.last_name,
            d.dept_name
    )
SELECT
    *,
    CASE
        WHEN gpa < 2.0
        OR drop_rate > 30 THEN 'High Risk'
        WHEN gpa < 2.5
        OR drop_rate > 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_level
FROM student_performance
WHERE
    completed_count > 0 -- Only students with some history
ORDER BY
    CASE
        WHEN gpa < 2.0
        OR drop_rate > 30 THEN 1
        WHEN gpa < 2.5
        OR drop_rate > 20 THEN 2
        ELSE 3
    END,
    gpa NULLS LAST;

-- Query 2.2: Course demand forecasting
WITH
    historical_enrollment AS (
        SELECT c.course_id, c.course_code, c.course_name, sch.year, sch.semester, COUNT(e.enrollment_id) as enrollment_count
        FROM
            course c
            JOIN schedule sch ON c.course_id = sch.course_id
            LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
        GROUP BY
            c.course_id,
            c.course_code,
            c.course_name,
            sch.year,
            sch.semester
    )
SELECT
    course_code,
    course_name,
    ROUND(AVG(enrollment_count), 1) as avg_enrollment,
    MIN(enrollment_count) as min_enrollment,
    MAX(enrollment_count) as max_enrollment,
    ROUND(STDDEV(enrollment_count), 1) as std_dev,
    CASE
        WHEN STDDEV(enrollment_count) / NULLIF(AVG(enrollment_count), 0) > 0.3 THEN 'High Variance'
        WHEN STDDEV(enrollment_count) / NULLIF(AVG(enrollment_count), 0) > 0.15 THEN 'Medium Variance'
        ELSE 'Stable'
    END as demand_stability
FROM historical_enrollment
GROUP BY
    course_id,
    course_code,
    course_name
HAVING
    COUNT(*) >= 2 -- At least 2 semesters of data
ORDER BY avg_enrollment DESC;

-- ============================================================================
-- SECTION 3: PERFORMANCE METRICS
-- ============================================================================

-- Query 3.1: Department performance scorecard
SELECT
    d.dept_name,
    COUNT(DISTINCT s.student_id) as total_students,
    COUNT(DISTINCT i.instructor_id) as total_faculty,
    ROUND(
        AVG(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 4.0
                WHEN e.grade IN ('B+', 'B', 'B-') THEN 3.0
                WHEN e.grade IN ('C+', 'C', 'C-') THEN 2.0
                WHEN e.grade = 'D' THEN 1.0
                WHEN e.grade = 'F' THEN 0.0
            END
        ),
        3
    ) as avg_gpa,
    ROUND(
        COUNT(
            CASE
                WHEN e.status = 'Completed' THEN 1
            END
        )::NUMERIC / NULLIF(COUNT(e.enrollment_id), 0) * 100,
        2
    ) as completion_rate,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::NUMERIC / NULLIF(
            COUNT(e.enrollment_id) FILTER (
                WHERE
                    e.status = 'Completed'
            ),
            0
        ) * 100,
        2
    ) as percent_a_grades
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    AND s.status = 'Active'
    LEFT JOIN instructor i ON d.department_id = i.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
GROUP BY
    d.department_id,
    d.dept_name
ORDER BY avg_gpa DESC NULLS LAST;

-- Query 3.2: Instructor effectiveness metrics
SELECT
    i.instructor_id,
    i.first_name || ' ' || i.last_name as instructor_name,
    i.rank,
    d.dept_name,
    COUNT(DISTINCT sch.course_id) as courses_taught,
    COUNT(DISTINCT e.student_id) as students_taught,
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
    ) as avg_student_gpa,
    ROUND(
        COUNT(
            CASE
                WHEN e.status = 'Dropped' THEN 1
            END
        )::NUMERIC / NULLIF(COUNT(e.enrollment_id), 0) * 100,
        2
    ) as drop_rate,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::NUMERIC / NULLIF(
            COUNT(e.enrollment_id) FILTER (
                WHERE
                    e.status = 'Completed'
            ),
            0
        ) * 100,
        2
    ) as percent_a_grades
FROM
    instructor i
    JOIN department d ON i.department_id = d.department_id
    LEFT JOIN schedule sch ON i.instructor_id = sch.instructor_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
GROUP BY
    i.instructor_id,
    i.first_name,
    i.last_name,
    i.rank,
    d.dept_name
HAVING
    COUNT(e.enrollment_id) >= 10 -- Minimum sample size
ORDER BY avg_student_gpa DESC NULLS LAST;

-- ============================================================================
-- SECTION 4: TREND ANALYSIS
-- ============================================================================

-- Query 4.1: Enrollment trends over time
SELECT
    year,
    semester,
    COUNT(DISTINCT s.student_id) as unique_students,
    COUNT(e.enrollment_id) as total_enrollments,
    ROUND(
        COUNT(e.enrollment_id)::NUMERIC / NULLIF(
            COUNT(DISTINCT s.student_id),
            0
        ),
        2
    ) as avg_courses_per_student,
    LAG(COUNT(e.enrollment_id)) OVER (
        ORDER BY year, semester
    ) as previous_semester_enrollments,
    COUNT(e.enrollment_id) - LAG(COUNT(e.enrollment_id)) OVER (
        ORDER BY year, semester
    ) as enrollment_change,
    ROUND(
        (
            COUNT(e.enrollment_id) - LAG(COUNT(e.enrollment_id)) OVER (
                ORDER BY year, semester
            )
        )::NUMERIC / NULLIF(
            LAG(COUNT(e.enrollment_id)) OVER (
                ORDER BY year, semester
            ),
            0
        ) * 100,
        2
    ) as percent_change
FROM
    schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    LEFT JOIN student s ON e.student_id = s.student_id
GROUP BY
    year,
    semester
ORDER BY year DESC, semester;

-- Query 4.2: Grade inflation/deflation analysis
SELECT
    sch.year,
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
    ) as avg_gpa,
    COUNT(e.enrollment_id) FILTER (
        WHERE
            e.status = 'Completed'
    ) as total_graded,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade IN ('A', 'A-') THEN 1
            END
        )::NUMERIC / NULLIF(
            COUNT(e.enrollment_id) FILTER (
                WHERE
                    e.status = 'Completed'
            ),
            0
        ) * 100,
        2
    ) as percent_a,
    ROUND(
        COUNT(
            CASE
                WHEN e.grade = 'F' THEN 1
            END
        )::NUMERIC / NULLIF(
            COUNT(e.enrollment_id) FILTER (
                WHERE
                    e.status = 'Completed'
            ),
            0
        ) * 100,
        2
    ) as percent_f
FROM schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
WHERE
    e.status = 'Completed'
GROUP BY
    sch.year
ORDER BY sch.year;

-- ============================================================================
-- COMPREHENSIVE ANALYTICS DASHBOARD
-- ============================================================================

-- Generate JSON report for dashboard
SELECT jsonb_build_object(
        'timestamp', NOW(), 'summary', jsonb_build_object(
            'total_students', (
                SELECT COUNT(*)
                FROM student
                WHERE
                    status = 'Active'
            ), 'total_instructors', (
                SELECT COUNT(*)
                FROM instructor
            ), 'total_courses', (
                SELECT COUNT(*)
                FROM course
            ), 'total_departments', (
                SELECT COUNT(*)
                FROM department
            ), 'current_enrollments', (
                SELECT COUNT(*)
                FROM enrollment
                WHERE
                    status = 'Enrolled'
            )
        ), 'gpa_stats', (
            SELECT jsonb_build_object(
                    'overall_avg_gpa', ROUND(
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
                        ), 3
                    )
                )
            FROM enrollment e
            WHERE
                e.status = 'Completed'
        ), 'top_departments', (
            SELECT jsonb_agg(dept_info)
            FROM (
                    SELECT jsonb_build_object(
                            'dept_name', d.dept_name, 'student_count', COUNT(DISTINCT s.student_id)
                        ) as dept_info
                    FROM department d
                        LEFT JOIN student s ON d.department_id = s.department_id
                        AND s.status = 'Active'
                    GROUP BY
                        d.dept_name
                    ORDER BY COUNT(DISTINCT s.student_id) DESC
                    LIMIT 5
                ) top_depts
        )
    ) as analytics_dashboard;