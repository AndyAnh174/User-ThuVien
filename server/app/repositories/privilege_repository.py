"""
Privilege Repository - Database operations for privileges
"""

import oracledb
from typing import List, Dict, Any, Optional


class PrivilegeRepository:
    """Repository for Oracle privilege management"""
    
    # System privileges relevant to the project
    SYSTEM_PRIVILEGES = [
        "CREATE PROFILE", "ALTER PROFILE", "DROP PROFILE",
        "CREATE ROLE", "ALTER ANY ROLE", "DROP ANY ROLE", "GRANT ANY ROLE",
        "CREATE SESSION",
        "CREATE ANY TABLE", "ALTER ANY TABLE", "DROP ANY TABLE",
        "SELECT ANY TABLE", "DELETE ANY TABLE", "INSERT ANY TABLE", "UPDATE ANY TABLE",
        "CREATE TABLE",
        "CREATE USER", "ALTER USER", "DROP USER"
    ]
    
    @staticmethod
    def get_all_system_privileges(connection: oracledb.Connection) -> List[str]:
        """Get list of all available system privileges"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT DISTINCT privilege
            FROM dba_sys_privs
            ORDER BY privilege
        """)
        privs = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return privs
    
    @staticmethod
    def get_user_system_privileges(connection: oracledb.Connection, 
                                   username: str) -> List[Dict[str, Any]]:
        """Get system privileges granted directly to user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT privilege, admin_option
            FROM dba_sys_privs
            WHERE grantee = UPPER(:username)
            ORDER BY privilege
        """, {"username": username})
        privs = [{"privilege": row[0], "admin_option": row[1], "source": "DIRECT"} 
                 for row in cursor.fetchall()]
        cursor.close()
        return privs
    
    @staticmethod
    def get_user_object_privileges(connection: oracledb.Connection,
                                   username: str) -> List[Dict[str, Any]]:
        """Get object privileges granted to user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT owner, table_name, privilege, grantable, grantor
            FROM dba_tab_privs
            WHERE grantee = UPPER(:username)
            ORDER BY owner, table_name, privilege
        """, {"username": username})
        privs = [{"owner": row[0], "object": row[1], "privilege": row[2], 
                  "grantable": row[3], "grantor": row[4]} 
                 for row in cursor.fetchall()]
        cursor.close()
        return privs
    
    @staticmethod
    def get_user_column_privileges(connection: oracledb.Connection,
                                   username: str) -> List[Dict[str, Any]]:
        """Get column-level privileges granted to user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT owner, table_name, column_name, privilege, grantable
            FROM dba_col_privs
            WHERE grantee = UPPER(:username)
            ORDER BY owner, table_name, column_name
        """, {"username": username})
        privs = [{"owner": row[0], "object": row[1], "column": row[2],
                  "privilege": row[3], "grantable": row[4]} 
                 for row in cursor.fetchall()]
        cursor.close()
        return privs
    
    @staticmethod
    def get_user_roles(connection: oracledb.Connection, 
                       username: str) -> List[Dict[str, Any]]:
        """Get roles granted to user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT granted_role, admin_option, default_role
            FROM dba_role_privs
            WHERE grantee = UPPER(:username)
            ORDER BY granted_role
        """, {"username": username})
        roles = [{"role": row[0], "admin_option": row[1], "default_role": row[2]} 
                 for row in cursor.fetchall()]
        cursor.close()
        return roles
    
    @staticmethod
    def get_all_privileges_for_user(connection: oracledb.Connection,
                                    username: str) -> Dict[str, Any]:
        """Get all privileges (system, object, column, roles) for user"""
        return {
            "username": username,
            "system_privileges": PrivilegeRepository.get_user_system_privileges(connection, username),
            "object_privileges": PrivilegeRepository.get_user_object_privileges(connection, username),
            "column_privileges": PrivilegeRepository.get_user_column_privileges(connection, username),
            "roles": PrivilegeRepository.get_user_roles(connection, username)
        }
    
    @staticmethod
    def grant_system_privilege(connection: oracledb.Connection,
                               grantee: str,
                               privilege: str,
                               with_admin: bool = False) -> None:
        """Grant system privilege to user or role"""
        cursor = connection.cursor()
        admin_clause = "WITH ADMIN OPTION" if with_admin else ""
        cursor.execute(f"GRANT {privilege} TO {grantee} {admin_clause}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def revoke_system_privilege(connection: oracledb.Connection,
                                grantee: str,
                                privilege: str) -> None:
        """Revoke system privilege from user or role"""
        cursor = connection.cursor()
        cursor.execute(f"REVOKE {privilege} FROM {grantee}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def grant_object_privilege(connection: oracledb.Connection,
                               grantee: str,
                               privilege: str,
                               object_name: str,
                               column_name: Optional[str] = None,
                               with_grant: bool = False) -> None:
        """Grant object privilege (on table or column)"""
        cursor = connection.cursor()
        grant_clause = "WITH GRANT OPTION" if with_grant else ""
        
        if column_name:
            # Column-level privilege
            cursor.execute(f"GRANT {privilege} ({column_name}) ON {object_name} TO {grantee} {grant_clause}")
        else:
            # Table-level privilege
            cursor.execute(f"GRANT {privilege} ON {object_name} TO {grantee} {grant_clause}")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def revoke_object_privilege(connection: oracledb.Connection,
                                grantee: str,
                                privilege: str,
                                object_name: str,
                                column_name: Optional[str] = None) -> None:
        """Revoke object privilege"""
        cursor = connection.cursor()
        
        if column_name:
            cursor.execute(f"REVOKE {privilege} ({column_name}) ON {object_name} FROM {grantee}")
        else:
            cursor.execute(f"REVOKE {privilege} ON {object_name} FROM {grantee}")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def grant_role(connection: oracledb.Connection,
                   grantee: str,
                   role: str,
                   with_admin: bool = False) -> None:
        """Grant role to user or role"""
        cursor = connection.cursor()
        admin_clause = "WITH ADMIN OPTION" if with_admin else ""
        cursor.execute(f"GRANT {role} TO {grantee} {admin_clause}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def revoke_role(connection: oracledb.Connection,
                    grantee: str,
                    role: str) -> None:
        """Revoke role from user or role"""
        cursor = connection.cursor()
        cursor.execute(f"REVOKE {role} FROM {grantee}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def check_privilege(connection: oracledb.Connection,
                        username: str,
                        privilege: str) -> bool:
        """Check if user has a specific privilege (directly or via role)"""
        cursor = connection.cursor()
        
        # Check direct privilege
        cursor.execute("""
            SELECT 1 FROM dba_sys_privs
            WHERE grantee = UPPER(:username) AND privilege = UPPER(:privilege)
        """, {"username": username, "privilege": privilege})
        
        if cursor.fetchone():
            cursor.close()
            return True
        
        # Check via roles
        cursor.execute("""
            SELECT 1 FROM dba_sys_privs sp
            JOIN dba_role_privs rp ON sp.grantee = rp.granted_role
            WHERE rp.grantee = UPPER(:username) AND sp.privilege = UPPER(:privilege)
        """, {"username": username, "privilege": privilege})
        
        result = cursor.fetchone() is not None
        cursor.close()
        return result
