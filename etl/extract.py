import gspread
from google.oauth2.service_account import Credentials
import pandas as pd
import json
from utils.logger import setup_logger

logger = setup_logger('Extract')


class DataExtractor:
    """Extract data from various sources"""

    def __init__(self, source_type, source_path=None, spreadsheet_id=None, credentials_file=None):
        self.source_type = source_type
        self.source_path = source_path
        self.spreadsheet_id = spreadsheet_id
        self.credentials_file = credentials_file

    def extract(self, sheet_name=None):
        """Extract data based on source type"""
        logger.info(f"Extracting data from {self.source_type}")

        if self. source_type == 'google_sheets':
            return self._extract_from_google_sheets(sheet_name)
        elif self.source_type == 'csv':
            return self._extract_from_csv()
        elif self.source_type == 'json':
            return self._extract_from_json()
        elif self.source_type == 'excel':
            return self._extract_from_excel(sheet_name)
        else:
            raise ValueError(f"Unsupported source type: {self.source_type}")

    def _extract_from_google_sheets(self, sheet_name):
        """Extract from Google Sheets"""
        try:
            # Setup credentials
            scopes = [
                'https://www.googleapis.com/auth/spreadsheets. readonly',
                'https://www.googleapis.com/auth/drive.readonly'
            ]
            creds = Credentials.from_service_account_file(
                self.credentials_file, scopes=scopes
            )
            client = gspread.authorize(creds)

            # Open spreadsheet
            spreadsheet = client.open_by_key(self.spreadsheet_id)

            if sheet_name:
                worksheet = spreadsheet.worksheet(sheet_name)
                data = pd.DataFrame(worksheet.get_all_records())
                logger.info(
                    f"Extracted {len(data)} rows from sheet:  {sheet_name}")
                return {sheet_name: data}
            else:
                # Extract all sheets
                all_data = {}
                for worksheet in spreadsheet.worksheets():
                    sheet_data = pd.DataFrame(worksheet.get_all_records())
                    all_data[worksheet.title] = sheet_data
                    logger.info(
                        f"Extracted {len(sheet_data)} rows from sheet: {worksheet.title}")
                return all_data

        except Exception as e:
            logger.error(f"Error extracting from Google Sheets: {str(e)}")
            raise

    def _extract_from_csv(self):
        """Extract from CSV file"""
        try:
            data = pd.read_csv(self.source_path)
            logger.info(
                f"Extracted {len(data)} rows from CSV: {self.source_path}")
            return {'data': data}
        except Exception as e:
            logger.error(f"Error extracting from CSV:  {str(e)}")
            raise

    def _extract_from_json(self):
        """Extract from JSON file"""
        try:
            with open(self.source_path, 'r') as f:
                data = json.load(f)

            if isinstance(data, list):
                df = pd.DataFrame(data)
            elif isinstance(data, dict):
                # If dict with multiple tables
                return {k: pd.DataFrame(v) for k, v in data.items()}
            else:
                raise ValueError("Unsupported JSON structure")

            logger. info(
                f"Extracted {len(df)} rows from JSON: {self.source_path}")
            return {'data': df}
        except Exception as e:
            logger.error(f"Error extracting from JSON: {str(e)}")
            raise

    def _extract_from_excel(self, sheet_name):
        """Extract from Excel file"""
        try:
            if sheet_name:
                data = pd.read_excel(self.source_path, sheet_name=sheet_name)
                logger.info(
                    f"Extracted {len(data)} rows from Excel sheet: {sheet_name}")
                return {sheet_name: data}
            else:
                # Read all sheets
                all_sheets = pd.read_excel(self.source_path, sheet_name=None)
                for name, df in all_sheets.items():
                    logger.info(f"Extracted {len(df)} rows from sheet: {name}")
                return all_sheets
        except Exception as e:
            logger.error(f"Error extracting from Excel: {str(e)}")
            raise
