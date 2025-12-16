#!/usr/bin/env python3
"""
ETL Pipeline:  Google Sheets/CSV/JSON → NeonDB (PostgreSQL)
Author:  Ankit
Date: 2025-12-16
"""

import sys
import argparse
import json
from datetime import datetime
from config import Config

# Validate config and create required directories
Config.validate()

from extract import DataExtractor
from transform import DataTransformer
from load import DataLoader
from utils.logger import setup_logger

logger = setup_logger('ETL-Main')


class ETLPipeline:
    """Main ETL Pipeline Orchestrator"""

    def __init__(self, source_type, source_path=None, spreadsheet_id=None, credentials_file=None, explicit_table=None):
        self.source_type = source_type
        self.source_path = source_path
        self.spreadsheet_id = spreadsheet_id or Config.SPREADSHEET_ID
        self.credentials_file = credentials_file or Config.GOOGLE_CREDENTIALS_FILE
        self.explicit_table = explicit_table  # NEW

        self.extractor = None
        self.transformer = DataTransformer()
        self.loader = DataLoader(Config.DB_CONFIG)

        self.start_time = None
        self.end_time = None

    def run(self, tables=None):
        """Run the complete ETL pipeline"""
        try:
            self.start_time = datetime.now()
            logger.info("=" * 80)
            logger. info(
                f"ETL Pipeline Started at {self.start_time. strftime('%Y-%m-%d %H:%M:%S')}")
            logger.info("=" * 80)

            # Validate configuration
            Config.validate()

            # EXTRACT
            logger.info("\n[STEP 1/3] EXTRACTING DATA")
            logger.info("-" * 80)
            extracted_data = self.extract_data()

            # TRANSFORM
            logger.info("\n[STEP 2/3] TRANSFORMING DATA")
            logger.info("-" * 80)
            transformed_data = self.transform_data(extracted_data, tables)

            # LOAD
            logger.info("\n[STEP 3/3] LOADING DATA")
            logger. info("-" * 80)
            self.load_data(transformed_data)

            # Generate Reports
            self.generate_reports()

            self.end_time = datetime.now()
            duration = (self.end_time - self.start_time).total_seconds()

            logger.info("\n" + "=" * 80)
            logger.info(f"ETL Pipeline Completed Successfully!")
            logger.info(f"Duration: {duration:.2f} seconds")
            logger.info("=" * 80)

            return True

        except Exception as e:
            logger.error(f"\nETL Pipeline Failed: {str(e)}")
            return False
        finally:
            if self.loader. conn:
                self.loader. disconnect()

    def extract_data(self):
        """Extract data from source"""
        self.extractor = DataExtractor(
            source_type=self.source_type,
            source_path=self.source_path,
            spreadsheet_id=self.spreadsheet_id,
            credentials_file=self.credentials_file
        )

        extracted_data = self.extractor. extract()
        logger.info(f"Extraction completed: {len(extracted_data)} datasets")
        return extracted_data

    def transform_data(self, extracted_data, tables=None):
        """Transform and validate data"""
        transformed = {}

        for sheet_name, df in extracted_data.items():
            # Try to infer table name from file path or sheet name
            table_name = self._infer_table_name(sheet_name, df)

            # Skip if specific tables requested and this isn't one
            if tables and table_name not in tables:
                continue

            logger.info(f"\nTransforming:  {sheet_name} to {table_name}")

            if table_name == 'department':
                transformed[table_name] = self.transformer.transform_departments(
                    df)
            elif table_name == 'student':
                transformed[table_name] = self.transformer.transform_students(
                    df)
            elif table_name == 'course':
                transformed[table_name] = self.transformer.transform_courses(
                    df)
            elif table_name == 'instructor':
                transformed[table_name] = self.transformer.transform_instructors(
                    df)
            else:
                logger.warning(f"No transformer defined for:  {table_name}")

        logger.info(f"\nTransformation completed: {len(transformed)} tables")
        return transformed

    def _infer_table_name(self, sheet_name, df):
        """Infer table name from sheet name or column names"""
        
        # Use explicit table if provided
        if self.explicit_table:
            return self.explicit_table
        # Check columns to detect table type
        columns = set(df.columns. str.lower())

        # Department detection
        if 'dept_code' in columns or 'dept_name' in columns:
            return 'department'

        # Student detection
        if 'enrollment_year' in columns or ('email' in columns and 'date_of_birth' in columns):
            return 'student'

        # Course detection
        if 'course_code' in columns or 'course_name' in columns:
            return 'course'

        # Instructor detection
        if 'hire_date' in columns and 'rank' in columns:
            return 'instructor'

        # Classroom detection
        if 'room_number' in columns or ('building' in columns and 'capacity' in columns):
            return 'classroom'

        # Schedule detection
        if 'day_of_week' in columns and 'start_time' in columns:
            return 'schedule'

        # Enrollment detection
        if 'grade' in columns and 'schedule_id' in columns:
            return 'enrollment'

        # Fallback to sheet name mapping
        table_mappings = {
            'departments': 'department',
            'students': 'student',
            'courses': 'course',
            'instructors': 'instructor',
            'classrooms': 'classroom',
            'schedules':  'schedule',
            'enrollments': 'enrollment',
        }

        return table_mappings.get(sheet_name.lower(), sheet_name. lower())

    def load_data(self, transformed_data):
        """Load data into database"""
        self.loader.connect()

        # Load in correct order (respecting foreign keys)
        load_order = ['department', 'instructor', 'student', 'course',
                      'classroom', 'schedule', 'enrollment']

        for table_name in load_order:
            if table_name in transformed_data:
                df = transformed_data[table_name]
                logger.info(f"\nLoading {table_name}:  {len(df)} records")

                if table_name == 'department':
                    self.loader.load_departments(df)
                elif table_name == 'student':
                    self.loader. load_students(df)
                elif table_name == 'course':
                    self.loader. load_courses(df)
                # Add more loaders as needed

        logger.info("\nLoading completed")

    def generate_reports(self):
        """Generate validation and loading reports"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # Validation Report
        validation_report = self. transformer.get_validation_report()
        validation_file = f"{Config.REPORT_DIR}/validation_report_{timestamp}.json"

        with open(validation_file, 'w') as f:
            json.dump(validation_report, f, indent=2)

        logger.info(f"\nValidation report saved:  {validation_file}")
        logger.info(
            f"Total Records: {validation_report['statistics']['total_records']}")
        logger.info(
            f"Valid Records: {validation_report['statistics']['valid_records']}")
        logger.info(
            f"Invalid Records: {validation_report['statistics']['invalid_records']}")
        logger.info(
            f"Duplicates Removed: {validation_report['statistics']['duplicates_removed']}")

        # Load Report
        load_stats = self.loader.get_load_stats()
        load_file = f"{Config.REPORT_DIR}/load_report_{timestamp}. json"

        with open(load_file, 'w') as f:
            json. dump(load_stats, f, indent=2)

        logger.info(f"\nLoad report saved: {load_file}")
        logger.info(f"Inserted: {load_stats['inserted']}")
        logger.info(f"Failed: {load_stats['failed']}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='ETL Pipeline for University Database')

    parser.add_argument('--source', required=True,
                        choices=['google_sheets', 'csv', 'json', 'excel'],
                        help='Data source type')
    parser.add_argument('--path', help='Path to CSV/JSON/Excel file')
    parser.add_argument('--spreadsheet-id', help='Google Sheets ID')
    parser.add_argument('--credentials', help='Google credentials JSON file')
    parser.add_argument('--tables', nargs='+',
                        help='Specific tables to process')
    parser.add_argument(
        '--table', help='Explicit table name (department, student, course, etc.)')  # NEW

    args = parser.parse_args()

    # Validate arguments
    if args.source in ['csv', 'json', 'excel'] and not args.path:
        parser.error(f"--path is required for {args.source} source")

    if args.source == 'google_sheets' and not (args.spreadsheet_id or Config.SPREADSHEET_ID):
        parser.error("--spreadsheet-id is required for google_sheets source")

    # Run ETL
    pipeline = ETLPipeline(
        source_type=args.source,
        source_path=args.path,
        spreadsheet_id=args. spreadsheet_id,
        credentials_file=args.credentials,
        explicit_table=args.table  # NEW
    )

    success = pipeline.run(tables=args.tables)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
