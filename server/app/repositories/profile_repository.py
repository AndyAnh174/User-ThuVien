"""
Profile Repository - Database operations for Oracle profiles
"""

import oracledb
from typing import List, Dict, Any


class ProfileRepository:
    """Repository for Oracle profile management"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all profiles with their resource limits"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT DISTINCT profile
            FROM dba_profiles
            ORDER BY profile
        """)
        profiles = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return [{"profile_name": p} for p in profiles]
    
    @staticmethod
    def get_by_name(connection: oracledb.Connection, profile_name: str) -> List[Dict[str, Any]]:
        """Get profile details (all resource limits)"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT resource_name, resource_type, limit
            FROM dba_profiles
            WHERE profile = UPPER(:profile_name)
            ORDER BY resource_name
        """, {"profile_name": profile_name})
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_users_with_profile(connection: oracledb.Connection, profile_name: str) -> List[str]:
        """Get list of users assigned to a profile"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT username
            FROM dba_users
            WHERE profile = UPPER(:profile_name)
            ORDER BY username
        """, {"profile_name": profile_name})
        users = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return users
    
    @staticmethod
    def create(connection: oracledb.Connection, 
               profile_name: str,
               sessions_per_user: str = "UNLIMITED",
               connect_time: str = "UNLIMITED",
               idle_time: str = "UNLIMITED") -> None:
        """Create new profile"""
        cursor = connection.cursor()
        cursor.execute(f"""
            CREATE PROFILE {profile_name} LIMIT
            SESSIONS_PER_USER {sessions_per_user}
            CONNECT_TIME {connect_time}
            IDLE_TIME {idle_time}
        """)
        connection.commit()
        cursor.close()
    
    @staticmethod
    def alter(connection: oracledb.Connection,
              profile_name: str,
              resources: Dict[str, str]) -> None:
        """Alter profile resource limits"""
        cursor = connection.cursor()
        
        for resource_name, limit_value in resources.items():
            if limit_value:
                cursor.execute(f"""
                    ALTER PROFILE {profile_name} LIMIT
                    {resource_name.upper()} {limit_value}
                """)
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def drop(connection: oracledb.Connection, profile_name: str, cascade: bool = False) -> None:
        """Drop profile"""
        cursor = connection.cursor()
        cascade_clause = "CASCADE" if cascade else ""
        cursor.execute(f"DROP PROFILE {profile_name} {cascade_clause}")
        connection.commit()
        cursor.close()
