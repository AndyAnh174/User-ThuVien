"""
User Repository - Database operations for users
"""

import oracledb
from typing import List, Optional, Dict, Any
from ..database import Database


class UserRepository:
    """Repository for user-related database operations"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all users from user_info table (filtered by VPD)"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT user_id, oracle_username, full_name, email, phone, address,
                   department, branch_id, user_type, sensitivity_level,
                   created_at, updated_at
            FROM library.user_info
            ORDER BY user_id
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_by_id(connection: oracledb.Connection, user_id: int) -> Optional[Dict[str, Any]]:
        """Get user by ID"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT user_id, oracle_username, full_name, email, phone, address,
                   department, branch_id, user_type, sensitivity_level,
                   created_at, updated_at
            FROM library.user_info
            WHERE user_id = :user_id
        """, {"user_id": user_id})
        columns = [col[0].lower() for col in cursor.description]
        row = cursor.fetchone()
        cursor.close()
        return dict(zip(columns, row)) if row else None
    
    @staticmethod
    def get_by_username(connection: oracledb.Connection, username: str) -> Optional[Dict[str, Any]]:
        """Get user by Oracle username"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT user_id, oracle_username, full_name, email, phone, address,
                   department, branch_id, user_type, sensitivity_level,
                   created_at, updated_at
            FROM library.user_info
            WHERE UPPER(oracle_username) = UPPER(:username)
        """, {"username": username})
        columns = [col[0].lower() for col in cursor.description]
        row = cursor.fetchone()
        cursor.close()
        return dict(zip(columns, row)) if row else None
    
    @staticmethod
    def create(connection: oracledb.Connection, user_data: Dict[str, Any]) -> int:
        """Create new user in user_info table"""
        cursor = connection.cursor()
        cursor.execute("""
            INSERT INTO library.user_info 
            (oracle_username, full_name, email, phone, address, department, 
             branch_id, user_type, sensitivity_level)
            VALUES (:oracle_username, :full_name, :email, :phone, :address,
                    :department, :branch_id, :user_type, :sensitivity_level)
            RETURNING user_id INTO :user_id
        """, {
            **user_data,
            "user_id": cursor.var(oracledb.NUMBER)
        })
        user_id = cursor.bindvars["user_id"].getvalue()[0]
        connection.commit()
        cursor.close()
        return int(user_id)
    
    @staticmethod
    def update(connection: oracledb.Connection, user_id: int, user_data: Dict[str, Any]) -> bool:
        """Update user in user_info table"""
        set_clause = ", ".join([f"{k} = :{k}" for k in user_data.keys()])
        cursor = connection.cursor()
        cursor.execute(f"""
            UPDATE library.user_info
            SET {set_clause}, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = :user_id
        """, {**user_data, "user_id": user_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0
    
    @staticmethod
    def delete(connection: oracledb.Connection, user_id: int) -> bool:
        """Delete user from user_info table"""
        cursor = connection.cursor()
        cursor.execute("""
            DELETE FROM library.user_info WHERE user_id = :user_id
        """, {"user_id": user_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0


class OracleUserRepository:
    """Repository for Oracle user management (CREATE USER, ALTER USER, etc.)"""
    
    @staticmethod
    def get_all_oracle_users(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all Oracle database users"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT username, account_status, lock_date, created,
                   default_tablespace, temporary_tablespace, profile
            FROM dba_users
            WHERE username NOT IN ('SYS', 'SYSTEM', 'DBSNMP', 'OUTLN', 'ANONYMOUS')
            ORDER BY username
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_user_quota(connection: oracledb.Connection, username: str) -> List[Dict[str, Any]]:
        """Get user tablespace quotas"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT tablespace_name, bytes, max_bytes
            FROM dba_ts_quotas
            WHERE username = UPPER(:username)
        """, {"username": username})
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def create_oracle_user(connection: oracledb.Connection, 
                           username: str, password: str,
                           default_ts: str = "LIBRARY_DATA",
                           temp_ts: str = "LIBRARY_TEMP",
                           quota: str = "10M",
                           profile: str = "DEFAULT") -> None:
        """Create new Oracle database user"""
        cursor = connection.cursor()
        
        # Create user
        cursor.execute(f"""
            CREATE USER {username} IDENTIFIED BY "{password}"
            DEFAULT TABLESPACE {default_ts}
            TEMPORARY TABLESPACE {temp_ts}
            QUOTA {quota} ON {default_ts}
            PROFILE {profile}
        """)
        
        # Grant basic connect
        cursor.execute(f"GRANT CREATE SESSION TO {username}")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def alter_oracle_user(connection: oracledb.Connection, 
                          username: str, 
                          changes: Dict[str, Any]) -> None:
        """Alter Oracle database user"""
        cursor = connection.cursor()
        
        if "password" in changes and changes["password"]:
            cursor.execute(f'ALTER USER {username} IDENTIFIED BY "{changes["password"]}"')
        
        if "default_tablespace" in changes:
            cursor.execute(f"ALTER USER {username} DEFAULT TABLESPACE {changes['default_tablespace']}")
        
        if "temporary_tablespace" in changes:
            cursor.execute(f"ALTER USER {username} TEMPORARY TABLESPACE {changes['temporary_tablespace']}")
        
        if "quota" in changes:
            ts = changes.get("tablespace", "LIBRARY_DATA")
            cursor.execute(f"ALTER USER {username} QUOTA {changes['quota']} ON {ts}")
        
        if "profile" in changes:
            cursor.execute(f"ALTER USER {username} PROFILE {changes['profile']}")
        
        if "account_status" in changes:
            status = "UNLOCK" if changes["account_status"].upper() == "UNLOCK" else "LOCK"
            cursor.execute(f"ALTER USER {username} ACCOUNT {status}")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def drop_oracle_user(connection: oracledb.Connection, username: str, cascade: bool = False) -> None:
        """Drop Oracle database user"""
        cursor = connection.cursor()
        cascade_clause = "CASCADE" if cascade else ""
        cursor.execute(f"DROP USER {username} {cascade_clause}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def grant_role(connection: oracledb.Connection, username: str, role: str) -> None:
        """Grant role to user"""
        cursor = connection.cursor()
        cursor.execute(f"GRANT {role} TO {username}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def revoke_role(connection: oracledb.Connection, username: str, role: str) -> None:
        """Revoke role from user"""
        cursor = connection.cursor()
        cursor.execute(f"REVOKE {role} FROM {username}")
        connection.commit()
        cursor.close()
