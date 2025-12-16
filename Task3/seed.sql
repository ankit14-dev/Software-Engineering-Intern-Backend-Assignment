-- ================================================
-- University Management System - Seed Data
-- Author: Ankit
-- Date: 2025-12-16
-- ================================================

-- ================================================
-- INSERT:  Departments
-- ================================================
INSERT INTO
    department (
        dept_name,
        dept_code,
        building,
        established_year
    )
VALUES (
        'Computer Science',
        'CS',
        'Tech Building',
        1985
    ),
    (
        'Electrical Engineering',
        'EE',
        'Engineering Hall',
        1980
    ),
    (
        'Mathematics',
        'MATH',
        'Science Center',
        1975
    ),
    (
        'Physics',
        'PHYS',
        'Science Center',
        1975
    ),
    (
        'Business Administration',
        'BUS',
        'Business School',
        1990
    ),
    (
        'English Literature',
        'ENG',
        'Arts Building',
        1970
    ),
    (
        'Mechanical Engineering',
        'ME',
        'Engineering Hall',
        1982
    ),
    (
        'Biology',
        'BIO',
        'Life Sciences',
        1978
    ),
    (
        'Chemistry',
        'CHEM',
        'Science Center',
        1976
    );

-- ================================================
-- INSERT:  Instructors
-- ================================================
INSERT INTO
    instructor (
        first_name,
        last_name,
        email,
        phone,
        department_id,
        hire_date,
        rank
    )
VALUES
    -- Computer Science
    (
        'Alice',
        'Johnson',
        'alice.johnson@university.edu',
        '555-0101',
        1,
        '2010-08-15',
        'Professor'
    ),
    (
        'Bob',
        'Smith',
        'bob.smith@university.edu',
        '555-0102',
        1,
        '2015-01-10',
        'Associate Professor'
    ),
    (
        'Carol',
        'Williams',
        'carol.williams@university.edu',
        '555-0103',
        1,
        '2018-08-20',
        'Assistant Professor'
    ),

-- Electrical Engineering
(
    'David',
    'Brown',
    'david. brown@university.edu',
    '555-0201',
    2,
    '2008-09-01',
    'Professor'
),
(
    'Emma',
    'Davis',
    'emma.davis@university.edu',
    '555-0202',
    2,
    '2016-01-15',
    'Associate Professor'
),

-- Mathematics
(
    'Frank',
    'Miller',
    'frank.miller@university.edu',
    '555-0301',
    3,
    '2005-08-25',
    'Professor'
),
(
    'Grace',
    'Wilson',
    'grace.wilson@university.edu',
    '555-0302',
    3,
    '2014-09-01',
    'Associate Professor'
),

-- Physics
(
    'Henry',
    'Moore',
    'henry.moore@university.edu',
    '555-0401',
    4,
    '2007-08-15',
    'Professor'
),
(
    'Iris',
    'Taylor',
    'iris.taylor@university.edu',
    '555-0402',
    4,
    '2017-01-10',
    'Assistant Professor'
),

-- Business
(
    'Jack',
    'Anderson',
    'jack.anderson@university.edu',
    '555-0501',
    5,
    '2012-08-20',
    'Professor'
),
(
    'Karen',
    'Thomas',
    'karen.thomas@university.edu',
    '555-0502',
    5,
    '2019-09-01',
    'Assistant Professor'
),

-- English
(
    'Leo',
    'Jackson',
    'leo.jackson@university.edu',
    '555-0601',
    6,
    '2006-08-15',
    'Professor'
),
(
    'Maria',
    'White',
    'maria.white@university.edu',
    '555-0602',
    6,
    '2015-09-01',
    'Associate Professor'
),

-- Mechanical Engineering
(
    'Nathan',
    'Harris',
    'nathan.harris@university.edu',
    '555-0701',
    7,
    '2009-08-20',
    'Professor'
),
(
    'Olivia',
    'Martin',
    'olivia.martin@university.edu',
    '555-0702',
    7,
    '2018-01-15',
    'Assistant Professor'
),

-- Biology
(
    'Paul',
    'Thompson',
    'paul.thompson@university.edu',
    '555-0801',
    8,
    '2011-08-25',
    'Professor'
),
(
    'Quinn',
    'Garcia',
    'quinn.garcia@university.edu',
    '555-0802',
    8,
    '2020-09-01',
    'Assistant Professor'
),

-- Chemistry
(
    'Rachel',
    'Martinez',
    'rachel.martinez@university.edu',
    '555-0901',
    9,
    '2010-08-15',
    'Professor'
),
(
    'Steve',
    'Robinson',
    'steve.robinson@university.edu',
    '555-0902',
    9,
    '2016-01-10',
    'Associate Professor'
);

-- ================================================
-- UPDATE: Department Heads
-- ================================================
UPDATE department SET head_instructor_id = 1 WHERE dept_code = 'CS';

UPDATE department SET head_instructor_id = 4 WHERE dept_code = 'EE';

UPDATE department
SET
    head_instructor_id = 6
WHERE
    dept_code = 'MATH';

UPDATE department
SET
    head_instructor_id = 8
WHERE
    dept_code = 'PHYS';

UPDATE department
SET
    head_instructor_id = 10
WHERE
    dept_code = 'BUS';

UPDATE department
SET
    head_instructor_id = 12
WHERE
    dept_code = 'ENG';

UPDATE department SET head_instructor_id = 14 WHERE dept_code = 'ME';

UPDATE department
SET
    head_instructor_id = 16
WHERE
    dept_code = 'BIO';

UPDATE department
SET
    head_instructor_id = 18
WHERE
    dept_code = 'CHEM';

-- ================================================
-- INSERT: Students
-- ================================================
INSERT INTO
    student (
        first_name,
        last_name,
        email,
        phone,
        date_of_birth,
        enrollment_year,
        department_id,
        status
    )
VALUES
    -- CS Students
    (
        'John',
        'Doe',
        'john.doe@student.edu',
        '555-1001',
        '2003-05-15',
        2022,
        1,
        'Active'
    ),
    (
        'Jane',
        'Smith',
        'jane.smith@student. edu',
        '555-1002',
        '2002-08-22',
        2021,
        1,
        'Active'
    ),
    (
        'Mike',
        'Johnson',
        'mike.johnson@student.edu',
        '555-1003',
        '2003-11-10',
        2022,
        1,
        'Active'
    ),
    (
        'Sarah',
        'Williams',
        'sarah.williams@student. edu',
        '555-1004',
        '2004-02-28',
        2023,
        1,
        'Active'
    ),
    (
        'Tom',
        'Brown',
        'tom.brown@student.edu',
        '555-1005',
        '2001-07-14',
        2020,
        1,
        'Active'
    ),

-- EE Students
(
    'Emily',
    'Davis',
    'emily.davis@student.edu',
    '555-2001',
    '2003-03-18',
    2022,
    2,
    'Active'
),
(
    'Chris',
    'Miller',
    'chris.miller@student.edu',
    '555-2002',
    '2002-09-25',
    2021,
    2,
    'Active'
),
(
    'Anna',
    'Wilson',
    'anna.wilson@student.edu',
    '555-2003',
    '2004-01-12',
    2023,
    2,
    'Active'
),

-- Math Students
(
    'David',
    'Moore',
    'david.moore@student.edu',
    '555-3001',
    '2003-06-20',
    2022,
    3,
    'Active'
),
(
    'Lisa',
    'Taylor',
    'lisa.taylor@student.edu',
    '555-3002',
    '2002-12-05',
    2021,
    3,
    'Active'
),
(
    'Kevin',
    'Anderson',
    'kevin.anderson@student.edu',
    '555-3003',
    '2004-04-16',
    2023,
    3,
    'Active'
),

-- Physics Students
(
    'Rachel',
    'Thomas',
    'rachel.thomas@student.edu',
    '555-4001',
    '2003-08-30',
    2022,
    4,
    'Active'
),
(
    'James',
    'Jackson',
    'james.jackson@student.edu',
    '555-4002',
    '2002-10-22',
    2021,
    4,
    'Active'
),

-- Business Students
(
    'Michelle',
    'White',
    'michelle.white@student.edu',
    '555-5001',
    '2003-07-08',
    2022,
    5,
    'Active'
),
(
    'Robert',
    'Harris',
    'robert.harris@student.edu',
    '555-5002',
    '2004-03-14',
    2023,
    5,
    'Active'
),
(
    'Laura',
    'Martin',
    'laura.martin@student.edu',
    '555-5003',
    '2002-11-27',
    2021,
    5,
    'Active'
),

-- English Students
(
    'Daniel',
    'Thompson',
    'daniel.thompson@student.edu',
    '555-6001',
    '2003-09-19',
    2022,
    6,
    'Active'
),
(
    'Sophie',
    'Garcia',
    'sophie.garcia@student.edu',
    '555-6002',
    '2004-05-03',
    2023,
    6,
    'Active'
),

-- ME Students
(
    'Alex',
    'Martinez',
    'alex.martinez@student.edu',
    '555-7001',
    '2003-04-25',
    2022,
    7,
    'Active'
),
(
    'Jessica',
    'Robinson',
    'jessica.robinson@student.edu',
    '555-7002',
    '2002-08-11',
    2021,
    7,
    'Active'
),

-- Biology Students
(
    'Brian',
    'Clark',
    'brian.clark@student.edu',
    '555-8001',
    '2003-12-01',
    2022,
    8,
    'Active'
),
(
    'Amanda',
    'Rodriguez',
    'amanda.rodriguez@student.edu',
    '555-8002',
    '2004-06-17',
    2023,
    8,
    'Active'
),

-- Chemistry Students
(
    'Steven',
    'Lewis',
    'steven.lewis@student.edu',
    '555-9001',
    '2003-10-09',
    2022,
    9,
    'Active'
),
(
    'Nicole',
    'Lee',
    'nicole.lee@student.edu',
    '555-9002',
    '2002-07-23',
    2021,
    9,
    'Active'
);

-- ================================================
-- INSERT: Courses
-- ================================================
INSERT INTO
    course (
        course_code,
        course_name,
        description,
        credits,
        department_id,
        prerequisite_course_id,
        max_capacity
    )
VALUES
    -- Computer Science Courses
    (
        'CS101',
        'Introduction to Programming',
        'Fundamentals of programming using Python',
        3,
        1,
        NULL,
        50
    ),
    (
        'CS102',
        'Data Structures',
        'Study of fundamental data structures and algorithms',
        4,
        1,
        NULL,
        45
    ),
    (
        'CS201',
        'Object-Oriented Programming',
        'Advanced programming with OOP concepts',
        3,
        1,
        1,
        40
    ),
    (
        'CS301',
        'Database Systems',
        'Design and implementation of database systems',
        4,
        1,
        2,
        35
    ),
    (
        'CS401',
        'Advanced Algorithms',
        'Advanced algorithm design and analysis',
        4,
        1,
        2,
        30
    ),

-- Electrical Engineering Courses
(
    'EE101',
    'Circuit Analysis',
    'Fundamentals of electrical circuits',
    4,
    2,
    NULL,
    40
),
(
    'EE201',
    'Digital Logic Design',
    'Design of digital circuits and systems',
    4,
    2,
    6,
    35
),
(
    'EE301',
    'Microprocessors',
    'Architecture and programming of microprocessors',
    4,
    2,
    7,
    30
),

-- Mathematics Courses
(
    'MATH101',
    'Calculus I',
    'Differential calculus and applications',
    4,
    3,
    NULL,
    60
),
(
    'MATH102',
    'Calculus II',
    'Integral calculus and applications',
    4,
    3,
    9,
    55
),
(
    'MATH201',
    'Linear Algebra',
    'Matrices, vector spaces, and linear transformations',
    3,
    3,
    9,
    50
),
(
    'MATH301',
    'Differential Equations',
    'Ordinary and partial differential equations',
    4,
    3,
    10,
    40
),

-- Physics Courses
(
    'PHYS101',
    'Physics I',
    'Mechanics and thermodynamics',
    4,
    4,
    NULL,
    50
),
(
    'PHYS102',
    'Physics II',
    'Electricity and magnetism',
    4,
    4,
    13,
    45
),
(
    'PHYS201',
    'Modern Physics',
    'Quantum mechanics and relativity',
    4,
    4,
    14,
    35
),

-- Business Courses
(
    'BUS101',
    'Introduction to Business',
    'Overview of business principles',
    3,
    5,
    NULL,
    70
),
(
    'BUS201',
    'Financial Accounting',
    'Principles of financial accounting',
    3,
    5,
    NULL,
    60
),
(
    'BUS301',
    'Marketing Management',
    'Marketing strategies and management',
    3,
    5,
    16,
    50
),

-- English Courses
(
    'ENG101',
    'English Composition',
    'Academic writing and composition',
    3,
    6,
    NULL,
    30
),
(
    'ENG201',
    'World Literature',
    'Survey of world literature',
    3,
    6,
    19,
    28
),

-- Mechanical Engineering Courses
(
    'ME101',
    'Engineering Mechanics',
    'Statics and dynamics',
    4,
    7,
    NULL,
    40
),
(
    'ME201',
    'Thermodynamics',
    'Principles of thermodynamics',
    4,
    7,
    21,
    35
),

-- Biology Courses
(
    'BIO101',
    'General Biology',
    'Introduction to biological sciences',
    4,
    8,
    NULL,
    45
),
(
    'BIO201',
    'Cell Biology',
    'Structure and function of cells',
    4,
    8,
    23,
    35
),

-- Chemistry Courses
(
    'CHEM101',
    'General Chemistry',
    'Fundamentals of chemistry',
    4,
    9,
    NULL,
    50
),
(
    'CHEM201',
    'Organic Chemistry',
    'Study of organic compounds',
    4,
    9,
    25,
    40
);

-- ================================================
-- INSERT:  Classrooms
-- ================================================
INSERT INTO
    classroom (
        building,
        room_number,
        capacity,
        equipment
    )
VALUES (
        'Tech Building',
        '101',
        50,
        'Projector, Whiteboard, Computers'
    ),
    (
        'Tech Building',
        '102',
        45,
        'Projector, Whiteboard, Computers'
    ),
    (
        'Tech Building',
        '201',
        40,
        'Projector, Smartboard, Computers'
    ),
    (
        'Tech Building',
        '202',
        35,
        'Projector, Whiteboard'
    ),
    (
        'Engineering Hall',
        '101',
        50,
        'Projector, Lab Equipment'
    ),
    (
        'Engineering Hall',
        '102',
        40,
        'Projector, Lab Equipment'
    ),
    (
        'Engineering Hall',
        '201',
        35,
        'Projector, Whiteboard'
    ),
    (
        'Science Center',
        '101',
        60,
        'Projector, Whiteboard'
    ),
    (
        'Science Center',
        '102',
        55,
        'Projector, Whiteboard'
    ),
    (
        'Science Center',
        '201',
        50,
        'Projector, Lab Equipment'
    ),
    (
        'Science Center',
        '202',
        40,
        'Projector, Lab Equipment'
    ),
    (
        'Business School',
        '101',
        70,
        'Projector, Smartboard'
    ),
    (
        'Business School',
        '201',
        60,
        'Projector, Whiteboard'
    ),
    (
        'Arts Building',
        '101',
        30,
        'Projector, Whiteboard'
    ),
    (
        'Arts Building',
        '201',
        28,
        'Projector, Smartboard'
    ),
    (
        'Life Sciences',
        '101',
        45,
        'Projector, Lab Equipment'
    ),
    (
        'Life Sciences',
        '201',
        35,
        'Projector, Lab Equipment'
    );

-- ================================================
-- INSERT:  Schedules (Spring 2024)
-- ================================================
INSERT INTO
    schedule (
        course_id,
        instructor_id,
        classroom_id,
        semester,
        year,
        day_of_week,
        start_time,
        end_time
    )
VALUES
    -- CS Courses
    (
        1,
        1,
        1,
        'Spring',
        2024,
        'Monday',
        '09:00:00',
        '10:30:00'
    ),
    (
        1,
        1,
        1,
        'Spring',
        2024,
        'Wednesday',
        '09:00:00',
        '10:30:00'
    ),
    (
        2,
        2,
        2,
        'Spring',
        2024,
        'Tuesday',
        '10:00:00',
        '11:30:00'
    ),
    (
        2,
        2,
        2,
        'Spring',
        2024,
        'Thursday',
        '10:00:00',
        '11:30:00'
    ),
    (
        3,
        3,
        3,
        'Spring',
        2024,
        'Monday',
        '14:00:00',
        '15:30:00'
    ),
    (
        3,
        3,
        3,
        'Spring',
        2024,
        'Wednesday',
        '14:00:00',
        '15:30:00'
    ),

-- EE Courses
(
    6,
    4,
    5,
    'Spring',
    2024,
    'Tuesday',
    '09:00:00',
    '11:00:00'
),
(
    6,
    4,
    5,
    'Spring',
    2024,
    'Thursday',
    '09:00:00',
    '11:00:00'
),
(
    7,
    5,
    6,
    'Spring',
    2024,
    'Monday',
    '13:00:00',
    '15:00:00'
),

-- Math Courses
(
    9,
    6,
    8,
    'Spring',
    2024,
    'Monday',
    '08:00:00',
    '09:30:00'
),
(
    9,
    6,
    8,
    'Spring',
    2024,
    'Wednesday',
    '08:00:00',
    '09:30:00'
),
(
    9,
    6,
    8,
    'Spring',
    2024,
    'Friday',
    '08:00:00',
    '09:30:00'
),
(
    10,
    7,
    9,
    'Spring',
    2024,
    'Tuesday',
    '11:00:00',
    '12:30:00'
),
(
    10,
    7,
    9,
    'Spring',
    2024,
    'Thursday',
    '11:00:00',
    '12:30:00'
),

-- Physics Courses
(
    13,
    8,
    10,
    'Spring',
    2024,
    'Monday',
    '10:00:00',
    '12:00:00'
),
(
    13,
    8,
    10,
    'Spring',
    2024,
    'Wednesday',
    '10:00:00',
    '12:00:00'
),
(
    14,
    9,
    11,
    'Spring',
    2024,
    'Tuesday',
    '14:00:00',
    '16:00:00'
),

-- Business Courses
(
    16,
    10,
    12,
    'Spring',
    2024,
    'Monday',
    '16:00:00',
    '17:30:00'
),
(
    17,
    11,
    13,
    'Spring',
    2024,
    'Tuesday',
    '13:00:00',
    '14:30:00'
),

-- English Courses
(
    19,
    12,
    14,
    'Spring',
    2024,
    'Monday',
    '11:00:00',
    '12:30:00'
),
(
    19,
    12,
    14,
    'Spring',
    2024,
    'Wednesday',
    '11:00:00',
    '12:30:00'
),

-- ME Courses
( 21, 14, 7, 'Spring', 2024, 'Tuesday', '08:00:00', '10:00:00' ),

-- Biology Courses
(
    23,
    16,
    16,
    'Spring',
    2024,
    'Monday',
    '13:00:00',
    '15:00:00'
),
(
    23,
    16,
    16,
    'Spring',
    2024,
    'Wednesday',
    '13:00:00',
    '15:00:00'
),

-- Chemistry Courses
(
    25,
    18,
    11,
    'Spring',
    2024,
    'Thursday',
    '09:00:00',
    '11:00:00'
),
(
    25,
    18,
    11,
    'Spring',
    2024,
    'Friday',
    '09:00:00',
    '11:00:00'
);

-- ================================================
-- INSERT:  Enrollments
-- ================================================
INSERT INTO
    enrollment (
        student_id,
        schedule_id,
        enrollment_date,
        grade,
        status
    )
VALUES
    -- Student 1 (John Doe - CS) enrollments
    (
        1,
        1,
        '2024-01-10',
        NULL,
        'Enrolled'
    ),
    (
        1,
        3,
        '2024-01-10',
        NULL,
        'Enrolled'
    ),
    (
        1,
        10,
        '2024-01-10',
        NULL,
        'Enrolled'
    ),
    (
        1,
        13,
        '2024-01-10',
        NULL,
        'Enrolled'
    ),

-- Student 2 (Jane Smith - CS) enrollments
(
    2,
    3,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    2,
    5,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    2,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 3 (Mike Johnson - CS) enrollments
(
    3,
    1,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    3,
    3,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    3,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 4 (Sarah Williams - CS) enrollments
(
    4,
    1,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    4,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    4,
    17,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 5 (Tom Brown - CS) enrollments
(
    5,
    5,
    '2024-01-10',
    'A',
    'Completed'
),
(
    5,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 6 (Emily Davis - EE) enrollments
(
    6,
    7,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    6,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    6,
    13,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 7 (Chris Miller - EE) enrollments
(
    7,
    7,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    7,
    9,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    7,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 8 (Anna Wilson - EE) enrollments
(
    8,
    7,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    8,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 9 (David Moore - Math) enrollments
(
    9,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    9,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    9,
    13,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 10 (Lisa Taylor - Math) enrollments
(
    10,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    10,
    15,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    10,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 11 (Kevin Anderson - Math) enrollments
(
    11,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    11,
    13,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 12 (Rachel Thomas - Physics) enrollments
(
    12,
    13,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    12,
    15,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    12,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 13 (James Jackson - Physics) enrollments
(
    13,
    15,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    13,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 14 (Michelle White - Business) enrollments
(
    14,
    17,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    14,
    18,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    14,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 15 (Robert Harris - Business) enrollments
(
    15,
    17,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    15,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 16 (Laura Martin - Business) enrollments
(
    16,
    17,
    '2024-01-10',
    'B+',
    'Completed'
),
(
    16,
    18,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 17 (Daniel Thompson - English) enrollments
(
    17,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    17,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 18 (Sophie Garcia - English) enrollments
(
    18,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    18,
    17,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 19 (Alex Martinez - ME) enrollments
(
    19,
    21,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    19,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    19,
    13,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 20 (Jessica Robinson - ME) enrollments
(
    20,
    21,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    20,
    12,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 21 (Brian Clark - Biology) enrollments
(
    21,
    23,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    21,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 22 (Amanda Rodriguez - Biology) enrollments
(
    22,
    23,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    22,
    25,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 23 (Steven Lewis - Chemistry) enrollments
(
    23,
    25,
    '2024-01-10',
    NULL,
    'Enrolled'
),
(
    23,
    10,
    '2024-01-10',
    NULL,
    'Enrolled'
),

-- Student 24 (Nicole Lee - Chemistry) enrollments
(
    24,
    25,
    '2024-01-10',
    'A-',
    'Completed'
),
(
    24,
    19,
    '2024-01-10',
    NULL,
    'Enrolled'
);

-- ================================================
-- Seed data insertion complete
-- ================================================

-- Display summary
SELECT 'Database seeded successfully!' AS message;

SELECT 'Departments: ' || COUNT(*) FROM department;

SELECT 'Instructors: ' || COUNT(*) FROM instructor;

SELECT 'Students: ' || COUNT(*) FROM student;

SELECT 'Courses: ' || COUNT(*) FROM course;

SELECT 'Classrooms: ' || COUNT(*) FROM classroom;

SELECT 'Schedules: ' || COUNT(*) FROM schedule;

SELECT 'Enrollments: ' || COUNT(*) FROM enrollment;