"""Testing environment configuration."""
from .base import BaseConfig

class TestingConfig(BaseConfig):
    """Testing configuration."""
    DEBUG = False
    TESTING = True
    
    # Use test database
    DATABASE_NAME = 'ReputationGuardian_Test'
    
    # Disable external services in tests
    LOG_LEVEL = 'ERROR'
