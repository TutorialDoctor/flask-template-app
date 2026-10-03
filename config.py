import os

class Config:
    """Base configuration."""
    SECRET_KEY = os.environ.get('SECRET_KEY', 'default_fallback_key')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

class DevelopmentConfig(Config):
    """Development-specific configuration."""
    DEBUG = True
    PEEWEE_DATABASE_URI = 'data.db'
    CACHE_TYPE = "SimpleCache"
    CACHE_DEFAULT_TIMEOUT: 30
    SECRET_KEY = "thisissecret"
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024 # 2. Limit the maximum file upload size (e.g., 16 Megabytes)

class ProductionConfig(Config):
    """Production-specific configuration."""
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    CACHE_TYPE = "RedisCache"  # Choose backend (e.g., SimpleCache, RedisCache, MemcachedCache)
    CACHE_REDIS_URL = "redis://localhost:6379/0"
    CACHE_DEFAULT_TIMEOUT = 300  # Global timeout in seconds