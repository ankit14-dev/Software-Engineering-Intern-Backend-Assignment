-- ================================================
-- University Management System Database Schema
-- Author:  Ankit
-- Date: 2025-12-16
-- Description: Normalized schema (3NF) for university management
-- ================================================

-- Drop tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS enrollment CASCADE;

DROP TABLE IF EXISTS schedule CASCADE;

DROP TABLE IF EXISTS classroom CASCADE;

DROP TABLE IF EXISTS course CASCADE;

DROP TABLE IF EXISTS student CASCADE;

DROP TABLE IF EXISTS instructor CASCADE;

DROP TABLE IF EXISTS department CASCADE;

-- ================================================
-- TABLE: department
-- ================================================
CREATE TABLE department (
    department_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    building VARCHAR(50),
    head_instructor_id INTEGER,
    established_year INTEGER CHECK (
        established_year >= 1800
        AND established_year <= EXTRACT(
            YEAR
            FROM CURRENT_DATE
        )
    ),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ================================================
-- TABLE: instructor
-- ================================================
CREATE TABLE instructor (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    department_id INTEGER NOT NULL,
    hire_date DATE NOT NULL,
    rank VARCHAR(30) CHECK (
        rank IN (
            'Professor',
            'Associate Professor',
            'Assistant Professor',
            'Lecturer',
            'Adjunct'
        )
    ),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT
);

-- ================================================
-- TABLE: student
-- ================================================
CREATE TABLE student (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    date_of_birth DATE NOT NULL CHECK (date_of_birth < CURRENT_DATE),
    enrollment_year INTEGER NOT NULL CHECK (
        enrollment_year >= 1900
        AND enrollment_year <= EXTRACT(
            YEAR
            FROM CURRENT_DATE
        ) + 1
    ),
    department_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' CHECK (
        status IN (
            'Active',
            'Inactive',
            'Graduated',
            'Suspended'
        )
    ),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT
);

-- ================================================
-- TABLE: course
-- ================================================
CREATE TABLE course (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    description TEXT,
    credits INTEGER NOT NULL CHECK (
        credits > 0
        AND credits <= 6
    ),
    department_id INTEGER NOT NULL,
    prerequisite_course_id INTEGER,
    max_capacity INTEGER CHECK (max_capacity > 0),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (department_id) REFERENCES department (department_id) ON DELETE RESTRICT,
    FOREIGN KEY (prerequisite_course_id) REFERENCES course (course_id) ON DELETE SET NULL
);

-- ================================================
-- TABLE: classroom
-- ================================================
CREATE TABLE classroom (
    classroom_id SERIAL PRIMARY KEY,
    building VARCHAR(50) NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    equipment TEXT,
    UNIQUE (building, room_number)
);

-- ================================================
-- TABLE: schedule
-- ================================================
CREATE TABLE schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    classroom_id INTEGER NOT NULL,
    semester VARCHAR(20) NOT NULL CHECK (
        semester IN ('Fall', 'Spring', 'Summer')
    ),
    year INTEGER NOT NULL CHECK (
        year >= 2000
        AND year <= 2100
    ),
    day_of_week VARCHAR(10) NOT NULL CHECK (
        day_of_week IN (
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
        )
    ),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time),
    FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    FOREIGN KEY (instructor_id) REFERENCES instructor (instructor_id) ON DELETE RESTRICT,
    FOREIGN KEY (classroom_id) REFERENCES classroom (classroom_id) ON DELETE RESTRICT,
    UNIQUE (
        classroom_id,
        day_of_week,
        start_time,
        semester,
        year
    )
);

-- ================================================
-- TABLE: enrollment
-- ================================================
CREATE TABLE enrollment (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    schedule_id INTEGER NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade VARCHAR(2) CHECK (
        grade IN (
            'A',
            'A-',
            'B+',
            'B',
            'B-',
            'C+',
            'C',
            'C-',
            'D',
            'F'
        )
        OR grade IS NULL
    ),
    status VARCHAR(20) DEFAULT 'Enrolled' CHECK (
        status IN (
            'Enrolled',
            'Dropped',
            'Completed'
        )
    ),
    FOREIGN KEY (student_id) REFERENCES student (student_id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES schedule (schedule_id) ON DELETE CASCADE,
    UNIQUE (student_id, schedule_id)
);

-- ================================================
-- Add FK for department head (circular dependency)
-- ================================================
ALTER TABLE department
ADD CONSTRAINT fk_department_head FOREIGN KEY (head_instructor_id) REFERENCES instructor (instructor_id) ON DELETE SET NULL;

-- ================================================
-- INDEXES for Performance Optimization
-- ================================================

-- Foreign Key Indexes
CREATE INDEX idx_student_department ON student (department_id);

CREATE INDEX idx_course_department ON course (department_id);

CREATE INDEX idx_course_prerequisite ON course (prerequisite_course_id);

CREATE INDEX idx_instructor_department ON instructor (department_id);

CREATE INDEX idx_schedule_course ON schedule (course_id);

CREATE INDEX idx_schedule_instructor ON schedule (instructor_id);

CREATE INDEX idx_schedule_classroom ON schedule (classroom_id);

CREATE INDEX idx_enrollment_student ON enrollment (student_id);

CREATE INDEX idx_enrollment_schedule ON enrollment (schedule_id);

-- Composite Indexes for Common Queries
CREATE INDEX idx_schedule_semester_year ON schedule (semester, year);

CREATE INDEX idx_enrollment_status ON enrollment (status);

CREATE INDEX idx_student_status ON student (status);

CREATE INDEX idx_schedule_day_time ON schedule (day_of_week, start_time);

-- Name Search Indexes
CREATE INDEX idx_student_name ON student (last_name, first_name);

CREATE INDEX idx_instructor_name ON instructor (last_name, first_name);

CREATE INDEX idx_course_name ON course (course_name);

-- ================================================
-- Comments for Documentation
-- ================================================
COMMENT ON TABLE department IS 'Academic departments within the university';

COMMENT ON TABLE instructor IS 'Faculty members teaching courses';

COMMENT ON TABLE student IS 'Students enrolled in the university';

COMMENT ON TABLE course IS 'Courses offered by departments';

COMMENT ON TABLE classroom IS 'Physical classrooms for conducting classes';

COMMENT ON TABLE schedule IS 'Course schedules with time, location, and instructor';

COMMENT ON TABLE enrollment IS 'Student enrollments in scheduled courses';

-- ================================================
-- Schema creation complete
-- ================================================