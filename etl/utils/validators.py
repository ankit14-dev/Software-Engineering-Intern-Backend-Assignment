from datetime import datetime
import re


class DataValidator:
    """Data validation utilities"""

    @staticmethod
    def validate_email(email):
        """Validate email format"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, str(email).strip()))

    @staticmethod
    def validate_phone(phone):
        """Validate phone format (flexible)"""
        if not phone or str(phone).strip() == '':
            return True  # Phone is optional
        pattern = r'^[\d\s\-\+\(\)]{7,20}$'
        return bool(re.match(pattern, str(phone).strip()))

    @staticmethod
    def validate_date(date_str, date_format='%Y-%m-%d'):
        """Validate date format"""
        try:
            datetime.strptime(str(date_str), date_format)
            return True
        except (ValueError, TypeError):
            return False

    @staticmethod
    def validate_year(year):
        """Validate year (1900-current year + 1)"""
        try:
            year_int = int(year)
            current_year = datetime.now().year
            return 1900 <= year_int <= current_year + 1
        except (ValueError, TypeError):
            return False

    @staticmethod
    def validate_status(status, allowed_values):
        """Validate status against allowed values"""
        return str(status).strip() in allowed_values

    @staticmethod
    def validate_integer(value, min_val=None, max_val=None):
        """Validate integer with optional range"""
        try:
            val = int(value)
            if min_val is not None and val < min_val:
                return False
            if max_val is not None and val > max_val:
                return False
            return True
        except (ValueError, TypeError):
            return False

    @staticmethod
    def clean_string(value, max_length=None):
        """Clean and validate string"""
        if value is None:
            return None
        cleaned = str(value).strip()
        if max_length and len(cleaned) > max_length:
            return cleaned[:max_length]
        return cleaned if cleaned else None
