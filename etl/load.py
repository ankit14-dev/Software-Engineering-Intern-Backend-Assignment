import psycopg2
from psycopg2.extras import execute_batch
from utils.logger import setup_logger
from config import Config

logger = setup_logger('Load')


class DataLoader:
    """Load data into PostgreSQL database"""

    def __init__(self, db_config):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.stats = {
            'inserted': 0,
            'failed': 0,
            'skipped': 0
        }

    def connect(self):
        """Connect to database"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn. cursor()
            logger.info("Connected to database successfully")
        except Exception as e:
            logger.error(f"Database connection failed: {str(e)}")
            raise

    def disconnect(self):
        """Disconnect from database"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Disconnected from database")

    def load_departments(self, df):
        """Load department data"""
        logger.info(f"Loading {len(df)} departments")

        query = """
        INSERT INTO department (dept_name, dept_code, building, established_year)
        VALUES (%(dept_name)s, %(dept_code)s, %(building)s, %(established_year)s)
        ON CONFLICT (dept_code) DO UPDATE SET
            dept_name = EXCLUDED.dept_name,
            building = EXCLUDED.building,
            established_year = EXCLUDED.established_year
        RETURNING department_id;
        """

        return self._execute_batch_insert(query, df. to_dict('records'))

    def load_students(self, df):
        """Load student data"""
        logger.info(f"Loading {len(df)} students")

        query = """
        INSERT INTO student (first_name, last_name, email, phone, date_of_birth, 
                            enrollment_year, department_id, status)
        VALUES (%(first_name)s, %(last_name)s, %(email)s, %(phone)s, %(date_of_birth)s,
                %(enrollment_year)s, %(department_id)s, %(status)s)
        ON CONFLICT (email) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            phone = EXCLUDED.phone,
            date_of_birth = EXCLUDED.date_of_birth,
            enrollment_year = EXCLUDED. enrollment_year,
            department_id = EXCLUDED.department_id,
            status = EXCLUDED. status
        RETURNING student_id;
        """

        return self._execute_batch_insert(query, df.to_dict('records'))

    def load_courses(self, df):
        """Load course data"""
        logger.info(f"Loading {len(df)} courses")

        query = """
        INSERT INTO course (course_code, course_name, description, credits, 
                           department_id, prerequisite_course_id, max_capacity)
        VALUES (%(course_code)s, %(course_name)s, %(description)s, %(credits)s,
                %(department_id)s, %(prerequisite_course_id)s, %(max_capacity)s)
        ON CONFLICT (course_code) DO UPDATE SET
            course_name = EXCLUDED.course_name,
            description = EXCLUDED.description,
            credits = EXCLUDED.credits,
            department_id = EXCLUDED.department_id,
            prerequisite_course_id = EXCLUDED.prerequisite_course_id,
            max_capacity = EXCLUDED.max_capacity
        RETURNING course_id;
        """

        return self._execute_batch_insert(query, df.to_dict('records'))

    def _execute_batch_insert(self, query, data):
        """Execute batch insert with error handling"""
        inserted = 0
        failed = 0

        try:
            for record in data:
                try:
                    self.cursor. execute(query, record)
                    inserted += 1
                except psycopg2.Error as e:
                    logger.warning(f"Failed to insert record: {str(e)}")
                    failed += 1
                    self.conn.rollback()
                    continue

            self.conn.commit()
            self.stats['inserted'] += inserted
            self.stats['failed'] += failed

            logger.info(f"Inserted:  {inserted}, Failed: {failed}")
            return inserted

        except Exception as e:
            self.conn.rollback()
            logger.error(f"Batch insert failed: {str(e)}")
            raise

    def get_load_stats(self):
        """Get loading statistics"""
        return self.stats
