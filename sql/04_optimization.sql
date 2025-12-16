-- ============================================================================
-- DATABASE OPTIMIZATION AND PERFORMANCE TUNING
-- Author:  Ankit
-- Date: 2025-12-17
-- ============================================================================

-- ============================================================================
-- SECTION 1: INDEX ANALYSIS
-- ============================================================================

-- Query 1.1: List all existing indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_indexes
WHERE
    schemaname = 'public'
ORDER BY tablename, indexname;

-- Query 1.2: Find missing indexes (tables without indexes on foreign keys)
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    CASE
        WHEN i.indexname IS NULL THEN '❌ MISSING INDEX'
        ELSE '✓ Indexed'
    END as index_status
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
    LEFT JOIN pg_indexes i ON i.tablename = tc.table_name
    AND i.indexdef LIKE '%' || kcu.column_name || '%'
WHERE
    tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- Query 1.3: Index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as number_of_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    CASE
        WHEN idx_scan = 0 THEN '⚠️  UNUSED INDEX'
        WHEN idx_scan < 10 THEN '⚠️  RARELY USED'
        ELSE '✓ Active'
    END as usage_status
FROM pg_stat_user_indexes
WHERE
    schemaname = 'public'
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;

-- Query 1.4: Table sizes and bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(
        pg_total_relation_size(
            schemaname || '.' || tablename
        )
    ) AS total_size,
    pg_size_pretty(
        pg_relation_size(
            schemaname || '.' || tablename
        )
    ) AS table_size,
    pg_size_pretty(
        pg_total_relation_size(
            schemaname || '.' || tablename
        ) - pg_relation_size(
            schemaname || '.' || tablename
        )
    ) AS indexes_size,
    (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE
            table_schema = schemaname
            AND table_name = tablename
    ) as column_count
FROM pg_tables
WHERE
    schemaname = 'public'
ORDER BY pg_total_relation_size(
        schemaname || '.' || tablename
    ) DESC;

-- ============================================================================
-- SECTION 2: CREATE OPTIMIZED INDEXES
-- ============================================================================

-- Foreign Key Indexes (if not already created)
CREATE INDEX IF NOT EXISTS idx_student_department ON student (department_id);

CREATE INDEX IF NOT EXISTS idx_course_department ON course (department_id);

CREATE INDEX IF NOT EXISTS idx_course_prerequisite ON course (prerequisite_course_id);

CREATE INDEX IF NOT EXISTS idx_instructor_department ON instructor (department_id);

CREATE INDEX IF NOT EXISTS idx_schedule_course ON schedule (course_id);

CREATE INDEX IF NOT EXISTS idx_schedule_instructor ON schedule (instructor_id);

CREATE INDEX IF NOT EXISTS idx_schedule_classroom ON schedule (classroom_id);

CREATE INDEX IF NOT EXISTS idx_enrollment_student ON enrollment (student_id);

CREATE INDEX IF NOT EXISTS idx_enrollment_schedule ON enrollment (schedule_id);

-- Composite Indexes for Common Query Patterns
CREATE INDEX IF NOT EXISTS idx_schedule_semester_year ON schedule (semester, year);

CREATE INDEX IF NOT EXISTS idx_schedule_day_time ON schedule (day_of_week, start_time);

CREATE INDEX IF NOT EXISTS idx_enrollment_status ON enrollment (status);

CREATE INDEX IF NOT EXISTS idx_student_status ON student (status);

CREATE INDEX IF NOT EXISTS idx_student_enrollment_year ON student (enrollment_year);

-- Partial Indexes (for specific conditions)
CREATE INDEX IF NOT EXISTS idx_active_students ON student (
    department_id,
    enrollment_year
)
WHERE
    status = 'Active';

CREATE INDEX IF NOT EXISTS idx_enrolled_courses ON enrollment (student_id, schedule_id)
WHERE
    status = 'Enrolled';

CREATE INDEX IF NOT EXISTS idx_completed_enrollments ON enrollment (student_id, grade)
WHERE
    status = 'Completed';

-- Text Search Indexes
CREATE INDEX IF NOT EXISTS idx_student_name_search ON student USING gin (
    to_tsvector(
        'english',
        first_name || ' ' || last_name
    )
);

CREATE INDEX IF NOT EXISTS idx_course_name_search ON course USING gin (
    to_tsvector(
        'english',
        course_name || ' ' || description
    )
);

-- Email Search (for login/lookup)
CREATE INDEX IF NOT EXISTS idx_student_email_lower ON student (LOWER(email));

CREATE INDEX IF NOT EXISTS idx_instructor_email_lower ON instructor (LOWER(email));

-- ============================================================================
-- SECTION 3: QUERY PERFORMANCE ANALYSIS
-- ============================================================================

-- Query 3.1: Slow query to optimize - Student enrollments with full details
-- BEFORE optimization
EXPLAIN
ANALYZE
SELECT
    s.first_name || ' ' || s.last_name as student_name,
    c.course_code,
    c.course_name,
    i.first_name || ' ' || i.last_name as instructor_name,
    sch.day_of_week,
    sch.start_time,
    e.status
FROM
    student s
    JOIN enrollment e ON s.student_id = e.student_id
    JOIN schedule sch ON e.schedule_id = sch.schedule_id
    JOIN course c ON sch.course_id = c.course_id
    JOIN instructor i ON sch.instructor_id = i.instructor_id
WHERE
    s.status = 'Active'
    AND e.status = 'Enrolled';

-- Query 3.2: Aggregation performance - Department statistics
EXPLAIN
ANALYZE
SELECT
    d.dept_name,
    COUNT(DISTINCT s.student_id) as total_students,
    COUNT(DISTINCT e.enrollment_id) as total_enrollments,
    ROUND(
        AVG(
            CASE
                WHEN e.grade = 'A' THEN 4. 0
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
    ) as avg_gpa
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
    AND e.status = 'Completed'
GROUP BY
    d.department_id,
    d.dept_name
ORDER BY total_students DESC;

-- Query 3.3: Complex JOIN performance - Course prerequisites chain
EXPLAIN
ANALYZE
WITH RECURSIVE
    course_prerequisites AS (
        SELECT
            course_id,
            course_code,
            course_name,
            prerequisite_course_id,
            0 as level
        FROM course
        WHERE
            prerequisite_course_id IS NULL
        UNION ALL
        SELECT c.course_id, c.course_code, c.course_name, c.prerequisite_course_id, cp.level + 1
        FROM
            course c
            JOIN course_prerequisites cp ON c.prerequisite_course_id = cp.course_id
    )
SELECT *
FROM course_prerequisites
ORDER BY level, course_code;

-- ============================================================================
-- SECTION 4: QUERY OPTIMIZATION TECHNIQUES
-- ============================================================================

-- Technique 1: Use EXISTS instead of IN for large datasets
-- BAD: Using IN
EXPLAIN
ANALYZE
SELECT s.*
FROM student s
WHERE
    s.department_id IN (
        SELECT department_id
        FROM department
        WHERE
            dept_code IN ('CS', 'EE', 'MATH')
    );

-- GOOD: Using EXISTS
EXPLAIN
ANALYZE
SELECT s.*
FROM student s
WHERE
    EXISTS (
        SELECT 1
        FROM department d
        WHERE
            d.department_id = s.department_id
            AND d.dept_code IN ('CS', 'EE', 'MATH')
    );

-- Technique 2: Use JOINs instead of subqueries when possible
-- BAD: Subquery in SELECT
EXPLAIN
ANALYZE
SELECT
    s.student_id,
    s.first_name,
    (
        SELECT dept_name
        FROM department
        WHERE
            department_id = s.department_id
    ) as dept_name,
    (
        SELECT COUNT(*)
        FROM enrollment
        WHERE
            student_id = s.student_id
    ) as enrollment_count
FROM student s;

-- GOOD: Using JOINs
EXPLAIN
ANALYZE
SELECT s.student_id, s.first_name, d.dept_name, COUNT(e.enrollment_id) as enrollment_count
FROM
    student s
    LEFT JOIN department d ON s.department_id = d.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
GROUP BY
    s.student_id,
    s.first_name,
    d.dept_name;

-- Technique 3: Use LIMIT for pagination
-- GOOD:  Paginated query with index
EXPLAIN
ANALYZE
SELECT s.student_id, s.first_name, s.last_name, s.email
FROM student s
WHERE
    s.status = 'Active'
ORDER BY s.student_id
LIMIT 20
OFFSET
    0;

-- Technique 4: Avoid SELECT *
-- BAD:  Selecting all columns
EXPLAIN ANALYZE SELECT * FROM enrollment WHERE status = 'Enrolled';

-- GOOD: Select only needed columns
EXPLAIN
ANALYZE
SELECT
    enrollment_id,
    student_id,
    schedule_id,
    status
FROM enrollment
WHERE
    status = 'Enrolled';

-- ============================================================================
-- SECTION 5: STATISTICS AND VACUUM
-- ============================================================================

-- Update table statistics (run periodically)
ANALYZE student;

ANALYZE course;

ANALYZE enrollment;

ANALYZE schedule;

ANALYZE department;

ANALYZE instructor;

ANALYZE classroom;

-- Vacuum and analyze all tables
VACUUM ANALYZE;

-- Check last vacuum and analyze times
SELECT
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples
FROM pg_stat_user_tables
WHERE
    schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- ============================================================================
-- SECTION 6: PERFORMANCE BENCHMARKS
-- ============================================================================

-- Benchmark 1: Student lookup by email (should use index)
EXPLAIN (
    ANALYZE,
    BUFFERS,
    TIMING
)
SELECT *
FROM student
WHERE
    LOWER(email) = 'john. doe@student.edu';

-- Benchmark 2: Course search (should use GIN index)
EXPLAIN (
    ANALYZE,
    BUFFERS,
    TIMING
)
SELECT
    course_id,
    course_code,
    course_name
FROM course
WHERE
    to_tsvector(
        'english',
        course_name || ' ' || description
    ) @@ to_tsquery('english', 'programming');

-- Benchmark 3: Enrollment aggregation
EXPLAIN (
    ANALYZE,
    BUFFERS,
    TIMING
)
SELECT d.dept_name, COUNT(DISTINCT s.student_id) as students, COUNT(e.enrollment_id) as enrollments
FROM
    department d
    LEFT JOIN student s ON d.department_id = s.department_id
    LEFT JOIN enrollment e ON s.student_id = e.student_id
GROUP BY
    d.dept_name;

-- ============================================================================
-- SECTION 7: MONITORING QUERIES
-- ============================================================================

-- Query 7.1: Current running queries
SELECT
    pid,
    now() - query_start as duration,
    state,
    query
FROM pg_stat_activity
WHERE
    state != 'idle'
    AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC;

-- Query 7.2: Table access patterns
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    CASE
        WHEN seq_scan > idx_scan THEN '⚠️  More sequential scans'
        ELSE '✓ Index usage good'
    END as scan_status
FROM pg_stat_user_tables
WHERE
    schemaname = 'public'
ORDER BY seq_scan DESC;

-- Query 7.3: Cache hit ratio (should be > 90%)
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / NULLIF(
        sum(heap_blks_hit) + sum(heap_blks_read),
        0
    ) * 100 as cache_hit_ratio
FROM pg_statio_user_tables;

-- Query 7.4: Index hit ratio (should be > 95%)
SELECT
    sum(idx_blks_read) as idx_read,
    sum(idx_blks_hit) as idx_hit,
    sum(idx_blks_hit) / NULLIF(
        sum(idx_blks_hit) + sum(idx_blks_read),
        0
    ) * 100 as index_hit_ratio
FROM pg_statio_user_indexes;

-- ============================================================================
-- SECTION 8: OPTIMIZATION RECOMMENDATIONS
-- ============================================================================

-- Recommendation 1: Find duplicate indexes
SELECT
    a.indexname as index1,
    b.indexname as index2,
    a.tablename,
    a.indexdef as def1,
    b.indexdef as def2
FROM
    pg_indexes a
    JOIN pg_indexes b ON a.tablename = b.tablename
    AND a.indexname < b.indexname
    AND a.indexdef = b.indexdef
WHERE
    a.schemaname = 'public';

-- Recommendation 2: Identify large tables without primary key
SELECT t.tablename, pg_size_pretty(
        pg_total_relation_size(
            t.schemaname || '.' || t.tablename
        )
    ) as size
FROM pg_tables t
    LEFT JOIN information_schema.table_constraints tc ON t.tablename = tc.table_name
    AND tc.constraint_type = 'PRIMARY KEY'
WHERE
    t.schemaname = 'public'
    AND tc.constraint_name IS NULL
ORDER BY pg_total_relation_size(
        t.schemaname || '.' || t.tablename
    ) DESC;

-- Recommendation 3: Find columns that should be indexed
SELECT
    t.tablename,
    c.column_name,
    c.data_type,
    CASE
        WHEN c.column_name LIKE '%_id' THEN 'Foreign Key - Should be indexed'
        WHEN c.column_name IN ('email', 'code', 'status') THEN 'Common lookup column'
        ELSE 'Review for indexing'
    END as recommendation
FROM
    information_schema.columns c
    JOIN pg_tables t ON c.table_name = t.tablename
    LEFT JOIN pg_indexes i ON t.tablename = i.tablename
    AND i.indexdef LIKE '%' || c.column_name || '%'
WHERE
    t.schemaname = 'public'
    AND i.indexname IS NULL
    AND c.column_name NOT LIKE 'created_%'
ORDER BY t.tablename, c.ordinal_position;

-- ============================================================================
-- SECTION 9: QUERY PERFORMANCE COMPARISON
-- ============================================================================

-- Create a timing function
CREATE OR REPLACE FUNCTION time_query(p_query TEXT, p_iterations INTEGER DEFAULT 10)
RETURNS TABLE(
    iteration INTEGER,
    execution_time NUMERIC
) AS $$
DECLARE
    v_start TIMESTAMP;
    v_end TIMESTAMP;
    v_duration NUMERIC;
    i INTEGER;
BEGIN
    FOR i IN 1..p_iterations LOOP
        v_start := clock_timestamp();
        EXECUTE p_query;
        v_end := clock_timestamp();
        v_duration := EXTRACT(EPOCH FROM (v_end - v_start)) * 1000; -- milliseconds
        
        RETURN QUERY SELECT i, v_duration;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
/*
SELECT 
AVG(execution_time) as avg_ms,
MIN(execution_time) as min_ms,
MAX(execution_time) as max_ms
FROM time_query('SELECT COUNT(*) FROM student', 100);
*/

-- ============================================================================
-- SECTION 10: MAINTENANCE SCRIPTS
-- ============================================================================

-- Script 10.1: Rebuild indexes (run during maintenance window)
DO $$
DECLARE
    idx RECORD;
BEGIN
    FOR idx IN 
        SELECT indexname, tablename 
        FROM pg_indexes 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'REINDEX INDEX ' || idx.indexname;
        RAISE NOTICE 'Reindexed:  %', idx.indexname;
    END LOOP;
END $$;

-- Script 10.2: Update all statistics
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ANALYZE ' || tbl.tablename;
        RAISE NOTICE 'Analyzed: %', tbl.tablename;
    END LOOP;
END $$;

-- ============================================================================
-- PERFORMANCE TUNING CHECKLIST
-- ============================================================================

/*
✓ 1. All foreign keys have indexes
✓ 2. Frequently queried columns are indexed
✓ 3. Composite indexes for multi-column WHERE clauses
✓ 4. Partial indexes for filtered queries
✓ 5. Text search indexes (GIN) for full-text search
✓ 6. Statistics are up to date (ANALYZE)
✓ 7. Dead tuples are removed (VACUUM)
✓ 8. No duplicate indexes
✓ 9. Unused indexes are removed
✓ 10. Query plans reviewed with EXPLAIN ANALYZE
✓ 11. Cache hit ratio > 90%
✓ 12. Index hit ratio > 95%
✓ 13. Slow queries identified and optimized
✓ 14. Connection pooling configured
✓ 15. Monitoring and alerting set up
*/