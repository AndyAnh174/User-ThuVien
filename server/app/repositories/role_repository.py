"""
Role Repository - Database operations for Oracle roles
"""

import oracledb
from typing import List, Dict, Any, Optional


class RoleRepository:
    """Repository for Oracle role management"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all roles"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT role, password_required, authentication_type
            FROM dba_roles
            ORDER BY role
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_role_privileges(connection: oracledb.Connection, role_name: str) -> Dict[str, Any]:
        """Get all privileges granted to a role"""
        cursor = connection.cursor()
        
        # System privileges
        cursor.execute("""
            SELECT privilege, admin_option
            FROM dba_sys_privs
            WHERE grantee = UPPER(:role_name)
        """, {"role_name": role_name})
        sys_privs = [{"privilege": row[0], "admin_option": row[1]} for row in cursor.fetchall()]
        
        # Object privileges
        cursor.execute("""
            SELECT owner, table_name, privilege, grantable
            FROM dba_tab_privs
            WHERE grantee = UPPER(:role_name)
        """, {"role_name": role_name})
        obj_privs = [{"owner": row[0], "object": row[1], "privilege": row[2], "grantable": row[3]} 
                     for row in cursor.fetchall()]
        
        # Roles granted to this role
        cursor.execute("""
            SELECT granted_role, admin_option
            FROM dba_role_privs
            WHERE grantee = UPPER(:role_name)
        """, {"role_name": role_name})
        roles = [{"role": row[0], "admin_option": row[1]} for row in cursor.fetchall()]
        
        cursor.close()
        return {
            "role_name": role_name,
            "system_privileges": sys_privs,
            "object_privileges": obj_privs,
            "roles": roles
        }
    
    @staticmethod
    def get_role_users(connection: oracledb.Connection, role_name: str) -> List[str]:
        """Get users who have been granted this role"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT grantee
            FROM dba_role_privs
            WHERE granted_role = UPPER(:role_name)
            ORDER BY grantee
        """, {"role_name": role_name})
        users = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return users
    
    @staticmethod
    def create(connection: oracledb.Connection, 
               role_name: str, 
               password: Optional[str] = None) -> None:
        """Create new role"""
        cursor = connection.cursor()
        
        if password:
            cursor.execute(f'CREATE ROLE {role_name} IDENTIFIED BY "{password}"')
        else:
            cursor.execute(f"CREATE ROLE {role_name} NOT IDENTIFIED")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def alter_password(connection: oracledb.Connection,
                       role_name: str,
                       password: Optional[str] = None) -> None:
        """Change role password"""
        cursor = connection.cursor()
        
        if password:
            cursor.execute(f'ALTER ROLE {role_name} IDENTIFIED BY "{password}"')
        else:
            cursor.execute(f"ALTER ROLE {role_name} NOT IDENTIFIED")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def drop(connection: oracledb.Connection, role_name: str) -> None:
        """Drop role"""
        cursor = connection.cursor()
        cursor.execute(f"DROP ROLE {role_name}")
        connection.commit()
        cursor.close()
    
    @staticmethod
    def grant_privilege_to_role(connection: oracledb.Connection,
                                role_name: str,
                                privilege: str,
                                object_name: Optional[str] = None,
                                with_admin: bool = False) -> None:
        """Grant privilege to role"""
        cursor = connection.cursor()
        
        if object_name:
            # Object privilege
            cursor.execute(f"GRANT {privilege} ON {object_name} TO {role_name}")
        else:
            # System privilege
            admin_clause = "WITH ADMIN OPTION" if with_admin else ""
            cursor.execute(f"GRANT {privilege} TO {role_name} {admin_clause}")
        
        connection.commit()
        cursor.close()
    
    @staticmethod
    def revoke_privilege_from_role(connection: oracledb.Connection,
                                   role_name: str,
                                   privilege: str,
                                   object_name: Optional[str] = None) -> None:
        """Revoke privilege from role"""
        cursor = connection.cursor()
        
        if object_name:
            cursor.execute(f"REVOKE {privilege} ON {object_name} FROM {role_name}")
        else:
            cursor.execute(f"REVOKE {privilege} FROM {role_name}")
        
        connection.commit()
        cursor.close()
