"""
Library User Management System - Configuration
"""

import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings"""
    
    # App info
    APP_NAME: str = "Library User Management API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Database
    DB_USER: str = "library"
    DB_PASSWORD: str = "Library123"
    DB_HOST: str = "localhost"
    DB_PORT: int = 1521
    DB_SERVICE: str = "FREEPDB1"
    
    # Pool settings
    DB_POOL_MIN: int = 2
    DB_POOL_MAX: int = 10
    DB_POOL_INCREMENT: int = 1
    
    @property
    def DB_DSN(self) -> str:
        return f"{self.DB_HOST}:{self.DB_PORT}/{self.DB_SERVICE}"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()
