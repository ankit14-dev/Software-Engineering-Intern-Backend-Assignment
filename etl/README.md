# 📦 ETL Pipeline:  Google Sheets → NeonDB

Production-ready ETL pipeline for migrating data from Google Sheets/CSV/JSON to NeonDB (PostgreSQL).

## Features

✅ Multiple data sources (Google Sheets, CSV, JSON, Excel)
✅ Data validation & cleansing
✅ Duplicate detection & removal
✅ Comprehensive error handling
✅ Detailed logging & reporting
✅ Batch processing
✅ Incremental loading support
✅ Foreign key dependency handling

## Prerequisites

- Python 3.8+
- PostgreSQL/NeonDB database
- Google Cloud credentials (for Google Sheets)

## Installation

```bash
# Clone repository
cd etl

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup environment variables
cp .env.example . env
# Edit .env with your credentials
```

# Configuration
Edit .env file:

```env
# Database (NeonDB)
DB_HOST=your-neon-host. neon.tech
DB_NAME=university
DB_USER=your-username
DB_PASSWORD=your-password

# Google Sheets (optional)
GOOGLE_CREDENTIALS_FILE=credentials.json
SPREADSHEET_ID=your-spreadsheet-id
```

# Usage
## Google Sheets
```bash
python etl.py --source google_sheets --spreadsheet-id YOUR_SPREADSHEET_ID
```
## CSV File
```bash
python etl.py --source csv --path data/students.csv --table student
```
## JSON File
```bash
python etl.py --source json --path data/university.json
```
## Excel File
```bash
python etl.py --source excel --path data/university.xlsx
```
## Process Specific Tables
```bash
python etl.py --source csv --path data. csv --tables student course
```
# Project Structure
```Code
etl/
├── etl.py              # Main ETL orchestrator
├── config.py           # Configuration
├── extract.py          # Data extraction
├── transform.py        # Data transformation
├── load. py             # Database loading
├── utils/
│   ├── logger.py      # Logging utilities
│   └── validators.py  # Data validators
├── logs/              # Log files
└── reports/           # Validation reports
```
# Output
## Logs
- Console output with colors
- Detailed log files in logs/

## Reports
- Validation report: reports/validation_report_TIMESTAMP.json
- Load report: reports/load_report_TIMESTAMP.json
# Error Handling
- Invalid data logged in validation report
- Failed inserts logged separately
- Duplicate records removed automatically
- Foreign key violations handled gracefully



---

## **Step 10: Sample Data Files**

Create sample CSV for testing:

### **File: `sample_data/students.csv`**

```csv
first_name,last_name,email,phone,date_of_birth,enrollment_year,department_id,status
John,Doe,john.doe@student.edu,555-1001,2003-05-15,2022,1,Active
Jane,Smith,jane.smith@student.edu,555-1002,2002-08-22,2021,1,Active
Mike,Johnson,mike.johnson@student.edu,555-1003,2003-11-10,2022,1,Active
```

# Quick Start Commands
```bash
# Setup
cd etl
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Copy and edit environment file
cp .env.example .env
nano .env

# Run ETL
python etl.py --source csv --path sample_data/students.csv
```