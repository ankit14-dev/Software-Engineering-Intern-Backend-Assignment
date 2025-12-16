import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class Config:
    """ETL Pipeline Configuration"""

    # Database Configuration
    DB_CONFIG = {
        'host': os.getenv('DB_HOST'),
        'port': int(os.getenv('DB_PORT', 5432)),
        'database':  os.getenv('DB_NAME'),
        'user': os. getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'sslmode': os.getenv('DB_SSLMODE', 'require')
    }

    # Google Sheets Configuration
    GOOGLE_CREDENTIALS_FILE = os.getenv(
        'GOOGLE_CREDENTIALS_FILE', 'credentials.json')
    SPREADSHEET_ID = os. getenv('SPREADSHEET_ID')

    # ETL Configuration
    BATCH_SIZE = int(os.getenv('BATCH_SIZE', 1000))
    LOG_LEVEL = os. getenv('LOG_LEVEL', 'INFO')
    ENABLE_INCREMENTAL = os.getenv(
        'ENABLE_INCREMENTAL', 'false').lower() == 'true'

    # Directories
    LOG_DIR = 'logs'
    REPORT_DIR = 'reports'

    # Data Source Types
    SOURCE_TYPES = ['google_sheets', 'csv', 'json', 'excel']

    @classmethod
    def validate(cls):
        """Validate required configuration"""
        required = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD']
        missing = [key for key in required if not os. getenv(key)]

        if missing:
            raise ValueError(
                f"Missing required environment variables: {', '.join(missing)}")

        # Create directories
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        os.makedirs(cls.REPORT_DIR, exist_ok=True)

        return True
