"""
Library User Management System - Database Connection
"""

import oracledb
from contextlib import contextmanager
from typing import Generator, Optional
from .config import settings


class Database:
    """Oracle Database connection manager"""
    
    _pool: Optional[oracledb.ConnectionPool] = None
    
    @classmethod
    def init_pool(cls) -> None:
        """Initialize connection pool"""
        if cls._pool is not None:
            return
        
        try:
            # Try thick mode (with Oracle Instant Client)
            oracledb.init_oracle_client()
        except:
            pass  # Use thin mode
        
        cls._pool = oracledb.create_pool(
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            dsn=settings.DB_DSN,
            min=settings.DB_POOL_MIN,
            max=settings.DB_POOL_MAX,
            increment=settings.DB_POOL_INCREMENT,
            homogeneous=False  # Required for proxy authentication (OLS)
        )
        print(f"✅ Database pool created: {settings.DB_DSN}")
    
    @classmethod
    def close_pool(cls) -> None:
        """Close connection pool"""
        if cls._pool:
            cls._pool.close()
            cls._pool = None
            print("✅ Database pool closed")
    
    @classmethod
    def get_connection(cls) -> oracledb.Connection:
        """Get a connection from pool"""
        if cls._pool is None:
            cls.init_pool()
        return cls._pool.acquire()

    @classmethod
    def get_proxy_connection(cls, username: str) -> oracledb.Connection:
        """Get a proxy connection for specific user"""
        # Create direct connection with proxy authentication
        # Pool acquire(user=...) may not work in thin mode
        # Use direct connect with proxy_user parameter
        return oracledb.connect(
            user=f"{settings.DB_USER}[{username.upper()}]",
            password=settings.DB_PASSWORD,
            dsn=settings.DB_DSN
        )
    
    @classmethod
    def release_connection(cls, connection: oracledb.Connection) -> None:
        """Release connection back to pool"""
        if cls._pool:
            cls._pool.release(connection)
    
    @classmethod
    @contextmanager
    def get_cursor(cls) -> Generator[oracledb.Cursor, None, None]:
        """Context manager for database cursor"""
        conn = cls.get_connection()
        try:
            cursor = conn.cursor()
            try:
                yield cursor
                conn.commit()
            except Exception:
                conn.rollback()
                raise
            finally:
                cursor.close()
        finally:
            cls.release_connection(conn)
    
    @classmethod
    def connect_as_user(cls, username: str, password: str) -> Optional[oracledb.Connection]:
        """Connect to database as specific user (for authentication)"""
        try:
            return oracledb.connect(
                user=username,
                password=password,
                dsn=settings.DB_DSN
            )
        except oracledb.DatabaseError:
            return None


def get_db() -> Generator[oracledb.Connection, None, None]:
    """Dependency for FastAPI - yields database connection"""
    conn = Database.get_connection()
    try:
        yield conn
    finally:
        Database.release_connection(conn)
