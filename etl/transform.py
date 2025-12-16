import pandas as pd
from datetime import datetime
from utils.logger import setup_logger
from utils.validators import DataValidator

logger = setup_logger('Transform')


class DataTransformer:
    """Transform and validate data"""

    def __init__(self):
        self.validator = DataValidator()
        self.errors = []
        self.stats = {
            'total_records': 0,
            'valid_records': 0,
            'invalid_records': 0,
            'duplicates_removed': 0
        }

    def transform_students(self, df):
        """Transform student data"""
        logger.info("Transforming student data")
        original_count = len(df)
        self.stats['total_records'] += original_count

        # Create a copy
        df = df.copy()

        # Remove duplicates based on email
        df = df.drop_duplicates(subset=['email'], keep='first')
        duplicates = original_count - len(df)
        self.stats['duplicates_removed'] += duplicates
        logger.info(f"Removed {duplicates} duplicate students")

        # Clean and validate
        valid_rows = []
        for idx, row in df.iterrows():
            errors = []

            # Validate email
            if not self.validator. validate_email(row. get('email')):
                errors.append(f"Invalid email: {row. get('email')}")

            # Validate phone (optional)
            if not self.validator.validate_phone(row.get('phone')):
                errors.append(f"Invalid phone: {row.get('phone')}")

            # Validate date_of_birth
            if not self.validator.validate_date(row.get('date_of_birth')):
                errors.append(
                    f"Invalid date_of_birth: {row.get('date_of_birth')}")

            # Validate enrollment_year
            if not self.validator. validate_year(row.get('enrollment_year')):
                errors.append(
                    f"Invalid enrollment_year: {row.get('enrollment_year')}")

            # Validate status
            if not self.validator.validate_status(
                row.get('status', 'Active'),
                ['Active', 'Inactive', 'Graduated', 'Suspended']
            ):
                errors. append(f"Invalid status: {row.get('status')}")

            if errors:
                self.errors. append({
                    'table': 'student',
                    'row': idx,
                    'email': row.get('email'),
                    'errors': errors
                })
                self.stats['invalid_records'] += 1
            else:
                # Clean data
                cleaned_row = {
                    'first_name': self.validator.clean_string(row.get('first_name'), 50),
                    'last_name': self.validator.clean_string(row.get('last_name'), 50),
                    'email': self.validator. clean_string(row.get('email'), 100),
                    'phone': self.validator.clean_string(row.get('phone'), 15),
                    'date_of_birth': row.get('date_of_birth'),
                    'enrollment_year': int(row.get('enrollment_year')),
                    'department_id': int(row.get('department_id')),
                    'status': self.validator.clean_string(row.get('status', 'Active'), 20)
                }
                valid_rows.append(cleaned_row)
                self.stats['valid_records'] += 1

        result_df = pd.DataFrame(valid_rows)
        logger.info(f"Transformed {len(result_df)} valid student records")
        return result_df

    def transform_departments(self, df):
        """Transform department data"""
        logger. info("Transforming department data")
        original_count = len(df)
        self.stats['total_records'] += original_count

        df = df.copy()

        # Remove duplicates based on dept_code
        df = df. drop_duplicates(subset=['dept_code'], keep='first')
        duplicates = original_count - len(df)
        self.stats['duplicates_removed'] += duplicates

        valid_rows = []
        for idx, row in df.iterrows():
            errors = []

            # Validate required fields
            if not row.get('dept_name') or not row.get('dept_code'):
                errors.append(
                    "Missing required fields: dept_name or dept_code")

            if errors:
                self.errors. append({
                    'table':  'department',
                    'row': idx,
                    'dept_code': row.get('dept_code'),
                    'errors': errors
                })
                self.stats['invalid_records'] += 1
            else:
                cleaned_row = {
                    'dept_name': self.validator. clean_string(row.get('dept_name'), 100),
                    'dept_code': self.validator.clean_string(row.get('dept_code'), 10),
                    'building': self.validator.clean_string(row.get('building'), 50),
                    'established_year': int(row.get('established_year')) if row.get('established_year') else None
                }
                valid_rows. append(cleaned_row)
                self.stats['valid_records'] += 1

        result_df = pd.DataFrame(valid_rows)
        logger.info(f"Transformed {len(result_df)} valid department records")
        return result_df

    def transform_courses(self, df):
        """Transform course data"""
        logger. info("Transforming course data")
        original_count = len(df)
        self.stats['total_records'] += original_count

        df = df. copy()
        df = df.drop_duplicates(subset=['course_code'], keep='first')
        duplicates = original_count - len(df)
        self.stats['duplicates_removed'] += duplicates

        valid_rows = []
        for idx, row in df.iterrows():
            errors = []

            # Validate credits
            if not self.validator. validate_integer(row.get('credits'), min_val=1, max_val=6):
                errors.append(f"Invalid credits: {row. get('credits')}")

            if errors:
                self.errors. append({
                    'table':  'course',
                    'row': idx,
                    'course_code': row.get('course_code'),
                    'errors': errors
                })
                self.stats['invalid_records'] += 1
            else:
                cleaned_row = {
                    'course_code': self. validator.clean_string(row. get('course_code'), 20),
                    'course_name': self.validator.clean_string(row.get('course_name'), 100),
                    'description': self.validator.clean_string(row.get('description')),
                    'credits': int(row.get('credits')),
                    'department_id': int(row.get('department_id')),
                    'prerequisite_course_id': int(row.get('prerequisite_course_id')) if row.get('prerequisite_course_id') else None,
                    'max_capacity': int(row.get('max_capacity')) if row.get('max_capacity') else None
                }
                valid_rows. append(cleaned_row)
                self.stats['valid_records'] += 1

        result_df = pd.DataFrame(valid_rows)
        logger.info(f"Transformed {len(result_df)} valid course records")
        return result_df

    def get_validation_report(self):
        """Generate validation report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'statistics': self.stats,
            'errors': self.errors
        }
        return report
