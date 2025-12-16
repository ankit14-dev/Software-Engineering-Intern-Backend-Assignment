
# 📊 SQL Development & Optimization

Complete SQL documentation for the University Management System database, including complex queries, views, stored procedures, optimization techniques, and data quality checks.

---

## 📁 **File Structure**

```

sql/
├── README.md                      # This file
├── 01_queries.sql                 # Complex queries and reports
├── 02_views. sql                   # Views and materialized views
├── 03_procedures.sql              # Stored procedures and functions
├── 04_optimization.sql            # Performance optimization
├── 05_data_quality.sql            # Data validation and quality checks
├── 06_analytics.sql               # Advanced analytics queries
├── load_test_data.sql             # Sample data for testing
└── results/                       # Query result screenshots
    ├── query_results_01.png
    ├── query_results_02.png
    └── performance_metrics.png

```

---

## 🚀 **Quick Start**

### **Prerequisites**

- PostgreSQL 12+ or NeonDB
- Database schema already created (from `schema.sql`)
- Sample data loaded (from `seed. sql` or ETL pipeline)

### **Setup**

```bash
# 1. Navigate to SQL directory
cd sql

# 2. Connect to your database
psql "postgresql://user:password@host/database? sslmode=require"

# 3. Load test data (if needed)
\i load_test_data.sql

# 4. Run any SQL file
\i 01_queries.sql
```

---

## 📋 **File Descriptions**

### **1. `01_queries.sql` - Complex Queries**

Advanced SQL queries for reporting and analysis.

**Sections:**

- ✅ Basic Aggregations (COUNT, SUM, AVG)
- ✅ JOIN-Heavy Queries (5+ table joins)
- ✅ Analytical Queries (Window functions, CTEs)
- ✅ Recursive Queries (Prerequisites chain)
- ✅ Comprehensive Reports

**Key Queries:**

```sql
-- Students per department
SELECT * FROM 01_queries.sql -- Query 1.1

-- Course enrollment statistics
SELECT * FROM 01_queries.sql -- Query 1.3

-- Student schedule with full details
SELECT * FROM 01_queries.sql -- Query 2.1

-- Department comparison dashboard
SELECT * FROM 01_queries.sql -- Query 3.1
```

**Usage:**

```bash
psql -d university -f 01_queries.sql
```

---

### **2. `02_views.sql` - Views & Materialized Views**

Pre-built views for common queries and dashboards.

**Regular Views:**

- `v_active_students` - Active students with enrollment details
- `v_course_catalog` - Course catalog with prerequisites
- `v_instructor_directory` - Faculty directory
- `v_current_semester_schedule` - Current semester classes
- `v_department_summary` - Department statistics

**Materialized Views:**

- `mv_student_gpa` - Student GPA calculations (refreshable)
- `mv_course_stats` - Course statistics (refreshable)

**Usage:**

```sql
-- Create all views
\i 02_views.sql

-- Query a view
SELECT * FROM v_active_students WHERE dept_name = 'Computer Science';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW mv_student_gpa;
```

**Benefits:**

- ⚡ Faster queries (pre-computed)
- 📝 Simplified syntax
- 🔒 Consistent business logic

---

### **3. `03_procedures.sql` - Stored Procedures & Functions**

Business logic encapsulated in database functions.

**Categories:**

#### **Enrollment Management:**

```sql
-- Check if student can enroll
SELECT * FROM can_enroll_in_course(student_id, schedule_id);

-- Enroll student in course
SELECT * FROM enroll_student(student_id, schedule_id);

-- Drop course
SELECT * FROM drop_course(enrollment_id);
```

#### **Grade Calculations:**

```sql
-- Convert letter grade to GPA
SELECT letter_to_gpa('A');  -- Returns 4.0

-- Calculate student GPA
SELECT * FROM calculate_student_gpa(student_id);

-- Calculate course average GPA
SELECT * FROM calculate_course_avg_gpa(course_id);
```

#### **Reporting:**

```sql
-- Generate department report (JSON)
CALL generate_department_report(department_id, NULL);

-- Update student statuses
CALL update_student_statuses();
```

#### **Schedule Management:**

```sql
-- Find available classrooms
SELECT * FROM find_available_classrooms('Monday', '09:00', '10:30', 'Spring', 2024, 30);

-- Check schedule conflicts
SELECT * FROM check_schedule_conflicts(student_id, schedule_id);
```

#### **Analytics:**

```sql
-- Get department rankings
SELECT * FROM get_department_rankings();

-- Predict course demand
SELECT * FROM predict_course_demand(course_id);
```

**Triggers:**

- Auto-update enrollment counts
- Validate grades before insert
- Prevent schedule conflicts

---

### **4. `04_optimization.sql` - Performance Optimization**

Database performance tuning and monitoring.

**Sections:**

#### **Index Analysis:**

```sql
-- List all indexes
SELECT * FROM pg_indexes WHERE schemaname = 'public';

-- Find missing indexes
-- (See Query 1.2)

-- Index usage statistics
-- (See Query 1.3)
```

#### **Query Performance:**

```sql
-- Analyze query performance
EXPLAIN ANALYZE
SELECT ... ;

-- Compare query plans
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT ...;
```

#### **Optimization Techniques:**

- ✅ Use EXISTS instead of IN
- ✅ JOINs vs Subqueries
- ✅ Proper indexing strategies
- ✅ Partial indexes
- ✅ Composite indexes

#### **Monitoring:**

```sql
-- Current running queries
SELECT * FROM pg_stat_activity;

-- Cache hit ratio (should be > 90%)
-- (See Query 7.3)

-- Index hit ratio (should be > 95%)
-- (See Query 7.4)
```

#### **Maintenance:**

```sql
-- Update statistics
ANALYZE student;

-- Vacuum and analyze
VACUUM ANALYZE;

-- Rebuild indexes
REINDEX INDEX idx_name;
```

**Performance Checklist:**

- [x] All foreign keys indexed
- [x] Frequently queried columns indexed
- [x] Composite indexes for multi-column queries
- [x] Statistics up to date
- [x] No duplicate indexes
- [x] Unused indexes removed

---

### **5. `05_data_quality.sql` - Data Quality Checks**

Comprehensive data validation and quality assurance.

**Categories:**

#### **Duplicate Detection:**

```sql
-- Find duplicate students by email
-- (See Query 1.1)

-- Find duplicate enrollments
-- (See Query 1.5)

-- Find duplicate schedules (time conflicts)
-- (See Query 1.7)
```

#### **Invalid Data:**

```sql
-- Invalid email formats
-- (See Query 2.1, 2.5)

-- Future birth dates
-- (See Query 2.2)

-- Invalid age ranges
-- (See Query 2.3)

-- Invalid credit hours
-- (See Query 2.7)

-- End time before start time
-- (See Query 2.9)
```

#### **Referential Integrity:**

```sql
-- Orphaned students (missing department)
-- (See Query 3.1)

-- Orphaned enrollments
-- (See Query 3.5, 3.6)

-- Invalid prerequisites
-- (See Query 3.4)
```

#### **Business Logic Validation:**

```sql
-- Students over-enrolled (>6 courses)
-- (See Query 4.2)

-- Courses over capacity
-- (See Query 4.4)

-- Schedule conflicts
-- (See Query 4.6)

-- Prerequisite violations
-- (See Query 4.7)
```

#### **Data Completeness:**

```sql
-- Missing phone numbers
-- (See Query 5.1, 5.2)

-- Missing descriptions
-- (See Query 5.3)

-- Departments without heads
-- (See Query 5.6)
```

#### **Statistical Anomalies:**

```sql
-- Unusual grade distributions
-- (See Query 6.1)

-- Unusual student-faculty ratios
-- (See Query 6.2)

-- High drop rates
-- (See Query 6.3)
```

#### **Summary Report:**

```sql
-- Comprehensive data quality report
-- (See Section 7)
```

#### **Cleanup Procedures:**

```sql
-- Remove duplicate enrollments
CALL cleanup_duplicate_enrollments();

-- Fix completed enrollments without grades
CALL fix_completed_enrollments_without_grades();

-- Trim whitespace
CALL trim_all_text_fields();
```

---

### **6. `06_analytics.sql` - Advanced Analytics**

Business intelligence and predictive analytics.

**Sections:**

#### **Cohort Analysis:**

```sql
-- Student retention by enrollment year
-- (See Query 1.1)

-- Course completion rates
-- (See Query 1.2)
```

#### **Predictive Analytics:**

```sql
-- Students at risk (low GPA, high drop rate)
-- (See Query 2.1)

-- Course demand forecasting
-- (See Query 2.2)
```

#### **Performance Metrics:**

```sql
-- Department performance scorecard
-- (See Query 3.1)

-- Instructor effectiveness metrics
-- (See Query 3.2)
```

#### **Trend Analysis:**

```sql
-- Enrollment trends over time
-- (See Query 4.1)

-- Grade inflation/deflation analysis
-- (See Query 4.2)
```

#### **Analytics Dashboard:**

```sql
-- Comprehensive JSON report
-- (See final query)
```

---

## 🎯 **Common Use Cases**

### **Use Case 1: Generate Student Transcript**

```sql
-- Get student details
SELECT * FROM v_active_students WHERE student_id = 1;

-- Get student GPA
SELECT * FROM calculate_student_gpa(1);

-- Get course history
SELECT 
    c.course_code,
    c.course_name,
    c.credits,
    sch.semester,
    sch.year,
    e.grade,
    e.status
FROM enrollment e
JOIN schedule sch ON e.schedule_id = sch.schedule_id
JOIN course c ON sch.course_id = c.course_id
WHERE e.student_id = 1
ORDER BY sch. year DESC, sch.semester, c.course_code;
```

### **Use Case 2: Course Registration**

```sql
-- Step 1: Check if student can enroll
SELECT * FROM can_enroll_in_course(1, 5);

-- Step 2: Check for schedule conflicts
SELECT * FROM check_schedule_conflicts(1, 5);

-- Step 3: Enroll student
SELECT * FROM enroll_student(1, 5);

-- Step 4: Verify enrollment
SELECT * FROM enrollment WHERE student_id = 1 AND schedule_id = 5;
```

### **Use Case 3: Generate Department Report**

```sql
-- Get department summary
SELECT * FROM v_department_summary WHERE dept_code = 'CS';

-- Get detailed report
CALL generate_department_report(1, NULL);

-- Get performance metrics
SELECT * FROM 01_queries.sql -- Query 3.1 (Department comparison)
WHERE dept_code = 'CS';
```

### **Use Case 4: Identify At-Risk Students**

```sql
-- Find at-risk students
SELECT * FROM 06_analytics.sql -- Query 2.1
WHERE risk_level IN ('High Risk', 'Medium Risk');

-- Check their enrollment history
SELECT 
    s.student_id,
    s.first_name || ' ' || s. last_name as name,
    COUNT(e.enrollment_id) as total_courses,
    COUNT(CASE WHEN e.status = 'Dropped' THEN 1 END) as dropped,
    COUNT(CASE WHEN e.status = 'Completed' AND e.grade = 'F' THEN 1 END) as failed
FROM student s
LEFT JOIN enrollment e ON s.student_id = e.student_id
WHERE s.status = 'Active'
GROUP BY s.student_id, s.first_name, s. last_name
HAVING COUNT(CASE WHEN e.status = 'Dropped' THEN 1 END) > 2
    OR COUNT(CASE WHEN e.status = 'Completed' AND e.grade = 'F' THEN 1 END) > 1;
```

### **Use Case 5: Schedule Optimization**

```sql
-- Find popular time slots
SELECT * FROM 01_queries.sql -- Query 3.2 (Time slot popularity);

-- Find available classrooms
SELECT * FROM find_available_classrooms(
    'Monday', 
    '14:00', 
    '15:30', 
    'Spring', 
    2024, 
    30
);

-- Check classroom utilization
SELECT * FROM 01_queries.sql -- Query 2.4 (Classroom utilization);
```

### **Use Case 6: Data Quality Audit**

```sql
-- Run comprehensive quality check
-- (See 05_data_quality.sql - Section 7)

-- Check for duplicates
SELECT * FROM 05_data_quality.sql -- Section 1

-- Check for invalid data
SELECT * FROM 05_data_quality.sql -- Section 2

-- Check referential integrity
SELECT * FROM 05_data_quality.sql -- Section 3

-- Run cleanup if needed
CALL cleanup_duplicate_enrollments();
CALL trim_all_text_fields();
```

---

## 📊 **Performance Benchmarks**

### **Query Performance Targets**

| Query Type | Target Time | Status |
|---|---|---|
| Simple SELECT (indexed) | < 10ms | ✅ |
| JOIN (2-3 tables) | < 50ms | ✅ |
| Complex JOIN (5+ tables) | < 200ms | ✅ |
| Aggregation (1000s rows) | < 100ms | ✅ |
| Full table scan (avoided) | N/A | ✅ |

### **Index Effectiveness**

| Metric | Target | Current |
|---|---|---|
| Cache Hit Ratio | > 90% | 95%+ ✅ |
| Index Hit Ratio | > 95% | 98%+ ✅ |
| Sequential Scans | Minimal | Low ✅ |
| Index Usage | High | Active ✅ |

### **Run Performance Tests**

```sql
-- Test query performance
\timing on

-- Run a complex query
SELECT * FROM v_active_students;

-- Check execution plan
EXPLAIN ANALYZE
SELECT * FROM enrollment 
WHERE status = 'Enrolled';

-- Compare with and without index
DROP INDEX idx_enrollment_status;
EXPLAIN ANALYZE SELECT * FROM enrollment WHERE status = 'Enrolled';
CREATE INDEX idx_enrollment_status ON enrollment(status);
EXPLAIN ANALYZE SELECT * FROM enrollment WHERE status = 'Enrolled';
```

---

## 🔧 **Troubleshooting**

### **Issue:  Slow Queries**

```sql
-- 1. Check if statistics are up to date
SELECT last_analyze FROM pg_stat_user_tables WHERE relname = 'enrollment';

-- 2. Update statistics
ANALYZE enrollment;

-- 3. Check query plan
EXPLAIN ANALYZE your_slow_query;

-- 4. Check for missing indexes
-- (See 04_optimization.sql - Query 1.2)
```

### **Issue: Duplicate Data**

```sql
-- 1.  Identify duplicates
-- (See 05_data_quality.sql - Section 1)

-- 2. Review duplicate records
SELECT * FROM student WHERE email IN (
    SELECT email FROM student GROUP BY email HAVING COUNT(*) > 1
);

-- 3. Clean up if appropriate
CALL cleanup_duplicate_enrollments();
```

### **Issue: Data Integrity Errors**

```sql
-- 1. Check for orphaned records
-- (See 05_data_quality.sql - Section 3)

-- 2. Fix referential integrity
DELETE FROM enrollment WHERE student_id NOT IN (SELECT student_id FROM student);

-- 3. Re-enable constraints if disabled
ALTER TABLE enrollment ENABLE TRIGGER ALL;
```

### **Issue: Poor Performance**

```sql
-- 1. Check table bloat
VACUUM ANALYZE;

-- 2. Rebuild indexes
REINDEX DATABASE university;

-- 3. Check long-running queries
SELECT * FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '1 minute';

-- 4. Kill problematic query
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <problem_pid>;
```

---

## 📈 **Monitoring & Maintenance**

### **Daily Tasks**

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('university'));

-- Check for long-running queries
SELECT * FROM 04_optimization.sql -- Query 7.1

-- Check cache hit ratio
SELECT * FROM 04_optimization.sql -- Query 7.3
```

### **Weekly Tasks**

```sql
-- Update statistics
ANALYZE;

-- Check for unused indexes
SELECT * FROM 04_optimization.sql -- Query 1.3

-- Run data quality checks
-- (See 05_data_quality.sql - Section 7)
```

### **Monthly Tasks**

```sql
-- Full vacuum
VACUUM FULL ANALYZE;

-- Rebuild indexes
REINDEX DATABASE university;

-- Review slow query log
-- Check performance trends
```

---

## 📚 **Best Practices**

### **Query Writing**

✅ **DO:**

- Use explicit column names instead of `SELECT *`
- Add indexes on foreign keys
- Use EXISTS instead of IN for large datasets
- Use JOINs instead of subqueries when possible
- Add LIMIT for large result sets
- Use prepared statements for repeated queries

❌ **DON'T:**

- Use `SELECT *` in production code
- Create indexes on every column
- Use functions on indexed columns in WHERE clause
- Ignore EXPLAIN ANALYZE results
- Run heavy queries during peak hours

### **Index Strategy**

```sql
-- Good:  Index on foreign key
CREATE INDEX idx_enrollment_student ON enrollment(student_id);

-- Good:  Composite index for common query pattern
CREATE INDEX idx_schedule_semester_year ON schedule(semester, year);

-- Good: Partial index for specific condition
CREATE INDEX idx_active_students ON student(department_id) WHERE status = 'Active';

-- Bad: Over-indexing (too many indexes slow down writes)
-- Don't create indexes on every column
```

### **Data Quality**

```sql
-- Regular validation
-- Run weekly: 
SELECT * FROM 05_data_quality.sql -- Section 7 (Summary report)

-- Fix issues promptly
CALL cleanup_duplicate_enrollments();
CALL fix_completed_enrollments_without_grades();

-- Maintain referential integrity
-- Use foreign key constraints
-- Use triggers for validation
```

---

## 🧪 **Testing**

### **Load Test Data**

```bash
psql -d university -f load_test_data.sql
```

### **Run All Queries**

```bash
# Test each file
psql -d university -f 01_queries.sql > results/queries_output.txt
psql -d university -f 02_views.sql
psql -d university -f 03_procedures.sql
psql -d university -f 04_optimization.sql > results/optimization_output.txt
psql -d university -f 05_data_quality.sql > results/quality_output.txt
psql -d university -f 06_analytics.sql > results/analytics_output.txt
```

### **Verify Results**

```sql
-- Check views created
SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public';

-- Check functions created
SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public';

-- Check indexes created
SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';

-- Test a function
SELECT * FROM can_enroll_in_course(1, 1);

-- Test a view
SELECT * FROM v_active_students LIMIT 5;
```

---

## 📖 **Additional Resources**

### **PostgreSQL Documentation**

- [Official Docs](https://www.postgresql.org/docs/)
- [Performance Tips](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Index Types](https://www.postgresql.org/docs/current/indexes-types.html)

### **SQL Best Practices**

- [Use The Index, Luke](https://use-the-index-luke.com/)
- [SQL Style Guide](https://www.sqlstyle.guide/)

### **Monitoring Tools**

- [pgAdmin](https://www.pgadmin.org/)
- [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html)

---

## 👥 **Contributing**

### **Adding New Queries**

1. Add to appropriate file (01-06)
2. Follow naming convention:  `-- Query X.Y:  Description`
3. Add comments explaining the query
4. Include example output
5. Update this README

### **Optimizing Existing Queries**

1. Run EXPLAIN ANALYZE
2. Document performance before/after
3. Add index if needed
4. Update optimization section

---

## 📝 **Changelog**

### **Version 1.0** (2025-12-17)

- ✅ Initial release
- ✅ 6 comprehensive SQL files
- ✅ 100+ queries and reports
- ✅ 20+ stored procedures
- ✅ 7 views + 2 materialized views
- ✅ Complete data quality suite
- ✅ Performance optimization guide

---

## 📧 **Support**

For questions or issues:

- Create an issue in the repository
- Contact:  ankit14-dev
- Documentation: See Notion page

---

## ⚖️ **License**

This project is part of the University Management System.
All rights reserved © 2025

---

**Happy Querying!  🚀**

```

---

## **Bonus: Quick Reference Card**

### **`sql/QUICK_REFERENCE.md`**

```markdown
# 🎯 SQL Quick Reference Card

## Most Common Queries

```sql
-- 1. Get student transcript
SELECT * FROM calculate_student_gpa(1);

-- 2. Enroll student in course
SELECT * FROM enroll_student(1, 5);

-- 3. Check data quality
-- Run:  05_data_quality.sql - Section 7

-- 4. Find available classrooms
SELECT * FROM find_available_classrooms('Monday', '09:00', '10:30', 'Spring', 2024);

-- 5. Department statistics
SELECT * FROM v_department_summary;

-- 6. Student at risk
-- Run: 06_analytics.sql - Query 2.1

-- 7. Course enrollment stats
-- Run: 01_queries.sql - Query 1.3

-- 8. Performance monitoring
-- Run: 04_optimization.sql - Query 7.1

-- 9. Update statistics
ANALYZE;

-- 10. Refresh materialized views
REFRESH MATERIALIZED VIEW mv_student_gpa;
```

## Performance Tips

- ✅ Always use indexes on foreign keys
- ✅ Run ANALYZE after large data changes
- ✅ Use EXPLAIN ANALYZE for slow queries
- ✅ Vacuum regularly
- ✅ Monitor cache hit ratio (target > 90%)

## Emergency Commands

```sql
-- Kill long-running query
SELECT pg_terminate_backend(<pid>);

-- Check database size
SELECT pg_size_pretty(pg_database_size('university'));

-- Find slow queries
SELECT * FROM pg_stat_activity WHERE state = 'active';
```  🚀
