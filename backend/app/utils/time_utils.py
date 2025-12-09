import datetime
import pytz

SYRIA_TIMEZONE = pytz.timezone('Asia/Damascus')

def get_syria_time():
    """
    Get current time in Syria timezone
    """
    return datetime.datetime.now(SYRIA_TIMEZONE)
