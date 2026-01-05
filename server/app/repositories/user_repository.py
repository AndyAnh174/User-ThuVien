"""
User Repository - Database operations for users
"""

import oracledb
from typing import List, Optional, Dict, Any
from ..database import Database
from .audit_helper import AuditHelper


class UserRepository:
    """Repository for user-related database operations"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all users from user_info table (filtered by VPD)"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT u.user_id, u.oracle_username, u.full_name, u.email, u.phone, u.address,
                   u.department, u.branch_id, b.branch_name, u.user_type, u.sensitivity_level,
                   u.created_at, u.updated_at
            FROM library.user_info u
            LEFT JOIN library.branches b ON u.branch_id = b.branch_id
            ORDER BY u.user_id
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
        
        # Log audit event
        AuditHelper.log_action(
            connection,
            action_type="INSERT",
            table_name="USER_INFO",
            record_id=int(user_id),
            new_values=user_data,
            performed_by=user_data.get("oracle_username")
        )
        
        return int(user_id)
    
    @staticmethod
    def update(connection: oracledb.Connection, user_id: int, user_data: Dict[str, Any]) -> bool:
        """Update user in user_info table"""
        # Get old values before update
        old_user = UserRepository.get_by_id(connection, user_id)
        
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
        
        # Log audit event if update was successful
        if affected > 0:
            AuditHelper.log_action(
                connection,
                action_type="UPDATE",
                table_name="USER_INFO",
                record_id=user_id,
                old_values=old_user,
                new_values=user_data
            )
        
        return affected > 0
    
    @staticmethod
    def delete(connection: oracledb.Connection, user_id: int) -> bool:
        """Delete user from user_info table"""
        # Get old values before delete
        old_user = UserRepository.get_by_id(connection, user_id)
        
        cursor = connection.cursor()
        cursor.execute("""
            DELETE FROM library.user_info WHERE user_id = :user_id
        """, {"user_id": user_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        
        # Log audit event if delete was successful
        if affected > 0 and old_user:
            AuditHelper.log_action(
                connection,
                action_type="DELETE",
                table_name="USER_INFO",
                record_id=user_id,
                old_values=old_user
            )
        
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
        """
        Create new Oracle database user.

        NOTE:
        -----
        Under Oracle Database Vault, only the DV account manager
        (DV_ACCTMGR) is typically allowed to create users. The
        regular application accounts (LIBRARY, ADMIN_USER, ...) will
        hit ORA-01031 even if they have CREATE USER granted.

        To respect this, we open a dedicated connection as the
        DV account manager user (dv_acctmgr_user) solely for the
        CREATE USER command. Role grants and application metadata
        updates still run on the caller's connection.
        """
        dv_conn = None
        try:
            dv_conn = Database.connect_as_user(
                "dv_acctmgr_user",
                "DVAcctMgr#123",
            )
            cursor = dv_conn.cursor()

            # Create user with proper syntax
            create_user_sql = f'CREATE USER {username} IDENTIFIED BY "{password}"'
            create_user_sql += f' DEFAULT TABLESPACE {default_ts}'
            create_user_sql += f' TEMPORARY TABLESPACE {temp_ts}'
            create_user_sql += f' PROFILE {profile}'
            cursor.execute(create_user_sql)
            
            # Grant quota separately to avoid syntax issues
            if quota and quota.upper() != 'UNLIMITED':
                cursor.execute(f'ALTER USER {username} QUOTA {quota} ON {default_ts}')
            else:
                cursor.execute(f'ALTER USER {username} QUOTA UNLIMITED ON {default_ts}')

            # Basic connect privilege
            cursor.execute(f"GRANT CREATE SESSION TO {username}")

            dv_conn.commit()
            cursor.close()
        finally:
            if dv_conn is not None:
                dv_conn.close()
    
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
        """
        Grant role to user.
        
        Handles ORA-01924 gracefully - if role grant fails due to
        Database Vault restrictions, logs warning but doesn't fail.
        """
        cursor = connection.cursor()
        try:
            cursor.execute(f"GRANT {role} TO {username}")
            connection.commit()
        except oracledb.DatabaseError as e:
            error_obj, = e.args
            if error_obj.code == 1924:
                # Role not granted or doesn't exist - log but don't fail
                print(f"[WARN] Could not grant role {role} to {username}: {e}")
                connection.rollback()
            else:
                raise
        finally:
            cursor.close()
    
    @staticmethod
    def revoke_role(connection: oracledb.Connection, username: str, role: str) -> None:
        """Revoke role from user"""
        cursor = connection.cursor()
        cursor.execute(f"REVOKE {role} FROM {username}")
        connection.commit()
        cursor.close()
