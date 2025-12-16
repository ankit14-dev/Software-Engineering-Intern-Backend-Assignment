-- ============================================================================
-- STORED PROCEDURES AND FUNCTIONS
-- Author:  Ankit
-- Date: 2025-12-17
-- ============================================================================

-- ============================================================================
-- SECTION 1: ENROLLMENT MANAGEMENT FUNCTIONS
-- ============================================================================

-- Function 1.1: Check if student can enroll in a course
CREATE OR REPLACE FUNCTION can_enroll_in_course(
    p_student_id INTEGER,
    p_schedule_id INTEGER
) RETURNS TABLE(
    can_enroll BOOLEAN,
    reason TEXT
) AS $$
DECLARE
    v_course_id INTEGER;
    v_prerequisite_id INTEGER;
    v_current_enrollment INTEGER;
    v_max_capacity INTEGER;
    v_already_enrolled BOOLEAN;
    v_prerequisite_completed BOOLEAN;
BEGIN
    -- Get course details
    SELECT sch.course_id, c.prerequisite_course_id, c. max_capacity
    INTO v_course_id, v_prerequisite_id, v_max_capacity
    FROM schedule sch
    JOIN course c ON sch.course_id = c.course_id
    WHERE sch.schedule_id = p_schedule_id;
    
    -- Check if already enrolled
    SELECT EXISTS(
        SELECT 1 FROM enrollment 
        WHERE student_id = p_student_id 
        AND schedule_id = p_schedule_id
    ) INTO v_already_enrolled;
    
    IF v_already_enrolled THEN
        RETURN QUERY SELECT FALSE, 'Already enrolled in this course';
        RETURN;
    END IF;
    
    -- Check capacity
    SELECT COUNT(*) INTO v_current_enrollment
    FROM enrollment
    WHERE schedule_id = p_schedule_id AND status = 'Enrolled';
    
    IF v_current_enrollment >= v_max_capacity THEN
        RETURN QUERY SELECT FALSE, 'Course is full';
        RETURN;
    END IF;
    
    -- Check prerequisites
    IF v_prerequisite_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 
            FROM enrollment e
            JOIN schedule sch ON e.schedule_id = sch.schedule_id
            WHERE e.student_id = p_student_id
            AND sch.course_id = v_prerequisite_id
            AND e.status = 'Completed'
            AND e.grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-')
        ) INTO v_prerequisite_completed;
        
        IF NOT v_prerequisite_completed THEN
            RETURN QUERY SELECT FALSE, 'Prerequisite not completed';
            RETURN;
        END IF;
    END IF;
    
    RETURN QUERY SELECT TRUE, 'Eligible to enroll';
END;
$$ LANGUAGE plpgsql;

-- Function 1.2: Enroll student in course
CREATE OR REPLACE FUNCTION enroll_student(
    p_student_id INTEGER,
    p_schedule_id INTEGER
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    enrollment_id INTEGER
) AS $$
DECLARE
    v_can_enroll BOOLEAN;
    v_reason TEXT;
    v_new_enrollment_id INTEGER;
BEGIN
    -- Check eligibility
    SELECT ce.can_enroll, ce.reason 
    INTO v_can_enroll, v_reason
    FROM can_enroll_in_course(p_student_id, p_schedule_id) ce;
    
    IF NOT v_can_enroll THEN
        RETURN QUERY SELECT FALSE, v_reason, NULL:: INTEGER;
        RETURN;
    END IF;
    
    -- Enroll student
    INSERT INTO enrollment (student_id, schedule_id, enrollment_date, status)
    VALUES (p_student_id, p_schedule_id, CURRENT_DATE, 'Enrolled')
    RETURNING enrollment. enrollment_id INTO v_new_enrollment_id;
    
    RETURN QUERY SELECT TRUE, 'Successfully enrolled', v_new_enrollment_id;
END;
$$ LANGUAGE plpgsql;

-- Function 1.3: Drop course
CREATE OR REPLACE FUNCTION drop_course(
    p_enrollment_id INTEGER
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_status TEXT;
BEGIN
    -- Check enrollment status
    SELECT status INTO v_status
    FROM enrollment
    WHERE enrollment_id = p_enrollment_id;
    
    IF v_status IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Enrollment not found';
        RETURN;
    END IF;
    
    IF v_status = 'Completed' THEN
        RETURN QUERY SELECT FALSE, 'Cannot drop completed course';
        RETURN;
    END IF;
    
    IF v_status = 'Dropped' THEN
        RETURN QUERY SELECT FALSE, 'Course already dropped';
        RETURN;
    END IF;
    
    -- Update status
    UPDATE enrollment
    SET status = 'Dropped'
    WHERE enrollment_id = p_enrollment_id;
    
    RETURN QUERY SELECT TRUE, 'Course dropped successfully';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 2: GRADE CALCULATION FUNCTIONS
-- ============================================================================

-- Function 2.1: Convert letter grade to GPA
CREATE OR REPLACE FUNCTION letter_to_gpa(p_grade VARCHAR(2))
RETURNS NUMERIC AS $$
BEGIN
    RETURN CASE 
        WHEN p_grade = 'A' THEN 4.0
        WHEN p_grade = 'A-' THEN 3.7
        WHEN p_grade = 'B+' THEN 3.3
        WHEN p_grade = 'B' THEN 3.0
        WHEN p_grade = 'B-' THEN 2.7
        WHEN p_grade = 'C+' THEN 2.3
        WHEN p_grade = 'C' THEN 2.0
        WHEN p_grade = 'C-' THEN 1.7
        WHEN p_grade = 'D' THEN 1.0
        WHEN p_grade = 'F' THEN 0.0
        ELSE NULL
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function 2.2: Calculate student GPA
CREATE OR REPLACE FUNCTION calculate_student_gpa(p_student_id INTEGER)
RETURNS TABLE(
    student_id INTEGER,
    student_name TEXT,
    total_credits NUMERIC,
    gpa NUMERIC,
    completed_courses INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name,
        COALESCE(SUM(c.credits), 0):: NUMERIC,
        ROUND(
            COALESCE(
                SUM(letter_to_gpa(e.grade) * c.credits) / NULLIF(SUM(c.credits), 0),
                0
            ), 3
        ),
        COUNT(e.enrollment_id)::INTEGER
    FROM student s
    LEFT JOIN enrollment e ON s.student_id = e.student_id AND e.status = 'Completed'
    LEFT JOIN schedule sch ON e.schedule_id = sch.schedule_id
    LEFT JOIN course c ON sch.course_id = c.course_id
    WHERE s.student_id = p_student_id
    GROUP BY s.student_id, s.first_name, s.last_name;
END;
$$ LANGUAGE plpgsql;

-- Function 2.3: Calculate course average GPA
CREATE OR REPLACE FUNCTION calculate_course_avg_gpa(p_course_id INTEGER)
RETURNS TABLE(
    course_code VARCHAR(20),
    course_name VARCHAR(100),
    total_enrollments BIGINT,
    completed_enrollments BIGINT,
    average_gpa NUMERIC,
    grade_distribution JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.course_code,
        c.course_name,
        COUNT(e.enrollment_id),
        COUNT(e.enrollment_id) FILTER (WHERE e.status = 'Completed'),
        ROUND(AVG(letter_to_gpa(e. grade)), 3),
        jsonb_build_object(
            'A', COUNT(*) FILTER (WHERE e.grade IN ('A', 'A-')),
            'B', COUNT(*) FILTER (WHERE e.grade IN ('B+', 'B', 'B-')),
            'C', COUNT(*) FILTER (WHERE e.grade IN ('C+', 'C', 'C-')),
            'D_F', COUNT(*) FILTER (WHERE e.grade IN ('D', 'F'))
        )
    FROM course c
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id AND e.status = 'Completed'
    WHERE c.course_id = p_course_id
    GROUP BY c.course_id, c.course_code, c.course_name;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 3: REPORTING PROCEDURES
-- ============================================================================

-- Procedure 3.1: Generate department report
CREATE OR REPLACE PROCEDURE generate_department_report(
    p_department_id INTEGER,
    OUT report JSONB
)
AS $$
BEGIN
    SELECT jsonb_build_object(
        'department', jsonb_build_object(
            'dept_name', d.dept_name,
            'dept_code', d.dept_code,
            'building', d.building,
            'established_year', d.established_year
        ),
        'statistics', jsonb_build_object(
            'total_students', COUNT(DISTINCT s.student_id),
            'active_students', COUNT(DISTINCT s.student_id) FILTER (WHERE s.status = 'Active'),
            'total_instructors', COUNT(DISTINCT i. instructor_id),
            'total_courses', COUNT(DISTINCT c.course_id),
            'total_enrollments', COUNT(DISTINCT e. enrollment_id)
        ),
        'students_by_year', (
            SELECT jsonb_object_agg(enrollment_year, count)
            FROM (
                SELECT enrollment_year, COUNT(*) as count
                FROM student
                WHERE department_id = p_department_id
                GROUP BY enrollment_year
            ) year_counts
        )
    ) INTO report
    FROM department d
    LEFT JOIN student s ON d.department_id = s.department_id
    LEFT JOIN instructor i ON d.department_id = i.department_id
    LEFT JOIN course c ON d.department_id = c.department_id
    LEFT JOIN schedule sch ON c.course_id = sch.course_id
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    WHERE d.department_id = p_department_id
    GROUP BY d.department_id, d.dept_name, d. dept_code, d.building, d.established_year;
END;
$$ LANGUAGE plpgsql;

-- Procedure 3.2: Update student status based on credits
CREATE OR REPLACE PROCEDURE update_student_statuses()
AS $$
DECLARE
    v_updated_count INTEGER := 0;
BEGIN
    -- Mark students as graduated if they have 120+ credits with passing grades
    UPDATE student s
    SET status = 'Graduated'
    WHERE status = 'Active'
    AND (
        SELECT COALESCE(SUM(c.credits), 0)
        FROM enrollment e
        JOIN schedule sch ON e.schedule_id = sch.schedule_id
        JOIN course c ON sch.course_id = c.course_id
        WHERE e.student_id = s.student_id
        AND e.status = 'Completed'
        AND e.grade NOT IN ('F', 'D')
    ) >= 120;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RAISE NOTICE 'Updated % students to Graduated status', v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 4: SCHEDULE MANAGEMENT FUNCTIONS
-- ============================================================================

-- Function 4.1: Find available classrooms
CREATE OR REPLACE FUNCTION find_available_classrooms(
    p_day_of_week VARCHAR(10),
    p_start_time TIME,
    p_end_time TIME,
    p_semester VARCHAR(20),
    p_year INTEGER,
    p_min_capacity INTEGER DEFAULT 20
) RETURNS TABLE(
    classroom_id INTEGER,
    building VARCHAR(50),
    room_number VARCHAR(10),
    capacity INTEGER,
    equipment TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cl.classroom_id,
        cl.building,
        cl.room_number,
        cl.capacity,
        cl.equipment
    FROM classroom cl
    WHERE cl.capacity >= p_min_capacity
    AND NOT EXISTS (
        SELECT 1 
        FROM schedule sch
        WHERE sch.classroom_id = cl.classroom_id
        AND sch.day_of_week = p_day_of_week
        AND sch.semester = p_semester
        AND sch.year = p_year
        AND (
            (sch.start_time, sch.end_time) OVERLAPS (p_start_time, p_end_time)
        )
    )
    ORDER BY cl.capacity, cl.building, cl.room_number;
END;
$$ LANGUAGE plpgsql;

-- Function 4.2: Get student schedule conflicts
CREATE OR REPLACE FUNCTION check_schedule_conflicts(
    p_student_id INTEGER,
    p_schedule_id INTEGER
) RETURNS TABLE(
    has_conflict BOOLEAN,
    conflicting_course TEXT,
    conflict_time TEXT
) AS $$
DECLARE
    v_day VARCHAR(10);
    v_start_time TIME;
    v_end_time TIME;
    v_semester VARCHAR(20);
    v_year INTEGER;
BEGIN
    -- Get the schedule details
    SELECT day_of_week, start_time, end_time, semester, year
    INTO v_day, v_start_time, v_end_time, v_semester, v_year
    FROM schedule
    WHERE schedule_id = p_schedule_id;
    
    RETURN QUERY
    SELECT 
        TRUE,
        c.course_code || ' - ' || c.course_name,
        sch.start_time:: TEXT || ' - ' || sch.end_time::TEXT
    FROM enrollment e
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
    JOIN course c ON sch.course_id = c.course_id
    WHERE e.student_id = p_student_id
    AND e.status = 'Enrolled'
    AND sch.day_of_week = v_day
    AND sch.semester = v_semester
    AND sch.year = v_year
    AND (sch.start_time, sch.end_time) OVERLAPS (v_start_time, v_end_time);
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL:: TEXT, NULL::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 5: ANALYTICS FUNCTIONS
-- ============================================================================

-- Function 5.1: Get department rankings
CREATE OR REPLACE FUNCTION get_department_rankings()
RETURNS TABLE(
    rank INTEGER,
    dept_name VARCHAR(100),
    total_students BIGINT,
    total_instructors BIGINT,
    student_faculty_ratio NUMERIC,
    avg_gpa NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.student_id) DESC)::INTEGER,
        d.dept_name,
        COUNT(DISTINCT s.student_id),
        COUNT(DISTINCT i.instructor_id),
        ROUND(
            COUNT(DISTINCT s.student_id)::NUMERIC / 
            NULLIF(COUNT(DISTINCT i.instructor_id), 0), 
            2
        ),
        ROUND(AVG(letter_to_gpa(e.grade)), 3)
    FROM department d
    LEFT JOIN student s ON d.department_id = s.department_id AND s.status = 'Active'
    LEFT JOIN instructor i ON d.department_id = i.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id AND e.status = 'Completed'
    GROUP BY d.department_id, d.dept_name
    ORDER BY total_students DESC;
END;
$$ LANGUAGE plpgsql;

-- Function 5.2:  Predict course demand
CREATE OR REPLACE FUNCTION predict_course_demand(p_course_id INTEGER)
RETURNS TABLE(
    course_code VARCHAR(20),
    historical_avg_enrollment NUMERIC,
    last_semester_enrollment BIGINT,
    trend TEXT,
    recommended_sections INTEGER
) AS $$
DECLARE
    v_avg NUMERIC;
    v_last BIGINT;
    v_trend TEXT;
BEGIN
    -- Calculate historical average
    SELECT AVG(enrollment_count)
    INTO v_avg
    FROM (
        SELECT COUNT(e.enrollment_id) as enrollment_count
        FROM schedule sch
        LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
        WHERE sch.course_id = p_course_id
        GROUP BY sch.semester, sch.year
    ) historical;
    
    -- Get last semester enrollment
    SELECT COUNT(e.enrollment_id)
    INTO v_last
    FROM schedule sch
    LEFT JOIN enrollment e ON sch.schedule_id = e.schedule_id
    WHERE sch.course_id = p_course_id
    AND (sch.year, sch.semester) = (
        SELECT year, semester 
        FROM schedule 
        WHERE course_id = p_course_id
        ORDER BY year DESC, semester DESC 
        LIMIT 1
    );
    
    -- Determine trend
    IF v_last > v_avg * 1.1 THEN
        v_trend := 'Increasing';
    ELSIF v_last < v_avg * 0.9 THEN
        v_trend := 'Decreasing';
    ELSE
        v_trend := 'Stable';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.course_code,
        ROUND(COALESCE(v_avg, 0), 2),
        COALESCE(v_last, 0),
        v_trend,
        CASE 
            WHEN v_trend = 'Increasing' THEN CEIL(v_avg / 30. 0) + 1
            WHEN v_trend = 'Decreasing' THEN GREATEST(CEIL(v_avg / 30.0) - 1, 1)
            ELSE CEIL(v_avg / 30.0)
        END::INTEGER
    FROM course c
    WHERE c.course_id = p_course_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 6: TRIGGERS
-- ============================================================================

-- Trigger 1: Auto-update enrollment count
CREATE OR REPLACE FUNCTION update_enrollment_count()
RETURNS TRIGGER AS $$
BEGIN
    -- This could update a summary table or send notifications
    RAISE NOTICE 'Enrollment changed:  Student %, Schedule %, Status %', 
        NEW.student_id, NEW. schedule_id, NEW.status;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enrollment_change
AFTER INSERT OR UPDATE ON enrollment
FOR EACH ROW
EXECUTE FUNCTION update_enrollment_count();

-- Trigger 2: Validate grade before insert
CREATE OR REPLACE FUNCTION validate_grade()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.grade IS NOT NULL AND NEW.status != 'Completed' THEN
        RAISE EXCEPTION 'Cannot assign grade to non-completed enrollment';
    END IF;
    
    IF NEW.status = 'Completed' AND NEW.grade IS NULL THEN
        RAISE EXCEPTION 'Completed enrollment must have a grade';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_grade
BEFORE INSERT OR UPDATE ON enrollment
FOR EACH ROW
EXECUTE FUNCTION validate_grade();

-- Trigger 3: Prevent schedule conflicts
CREATE OR REPLACE FUNCTION prevent_schedule_conflicts()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM schedule
    WHERE classroom_id = NEW.classroom_id
    AND day_of_week = NEW.day_of_week
    AND semester = NEW.semester
    AND year = NEW.year
    AND schedule_id != COALESCE(NEW.schedule_id, -1)
    AND (start_time, end_time) OVERLAPS (NEW.start_time, NEW.end_time);
    
    IF v_conflict_count > 0 THEN
        RAISE EXCEPTION 'Schedule conflict:  Classroom already booked for this time slot';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_schedule_conflicts
BEFORE INSERT OR UPDATE ON schedule
FOR EACH ROW
EXECUTE FUNCTION prevent_schedule_conflicts();

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

/*
-- Example 1: Check if student can enroll
SELECT * FROM can_enroll_in_course(1, 1);

-- Example 2: Enroll student
SELECT * FROM enroll_student(1, 1);

-- Example 3: Calculate student GPA
SELECT * FROM calculate_student_gpa(1);

-- Example 4: Get course average GPA
SELECT * FROM calculate_course_avg_gpa(1);

-- Example 5: Generate department report
CALL generate_department_report(1, NULL);

-- Example 6: Find available classrooms
SELECT * FROM find_available_classrooms('Monday', '09:00', '10:30', 'Spring', 2024, 30);

-- Example 7: Check schedule conflicts
SELECT * FROM check_schedule_conflicts(1, 2);

-- Example 8: Get department rankings
SELECT * FROM get_department_rankings();

-- Example 9: Update student statuses
CALL update_student_statuses();

-- Example 10: Predict course demand
SELECT * FROM predict_course_demand(1);
*/