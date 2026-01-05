"""
Audit Repository - Database operations for audit trail
"""

import oracledb
from typing import List, Dict, Any, Optional
from datetime import datetime

from ..database import Database


class AuditRepository:
    """Repository for audit trail operations"""
    
    @staticmethod
    def get_audit_trail(connection: oracledb.Connection,
                        limit: int = 100,
                        username: Optional[str] = None,
                        action: Optional[str] = None,
                        object_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Get audit trail entries from application audit log.
        
        Uses library.app_audit_log instead of unified_audit_trail
        to avoid ORA-00942/ORA-01031 in Oracle Free/DV environments.
        """
        cursor = connection.cursor()
        
        query = """
            SELECT performed_by as username, action_type as action, table_name as object_name,
                   TO_CHAR(performed_at, 'YYYY-MM-DD"T"HH24:MI:SS') as timestamp,
                   NULL as return_code, NULL as privilege_used, ip_address as terminal, user_agent as os_user
            FROM library.app_audit_log
            WHERE 1=1
        """
        params = {"limit": limit}
        
        if username:
            query += " AND UPPER(performed_by) = UPPER(:username)"
            params["username"] = username
        
        if action:
            query += " AND UPPER(action_type) LIKE UPPER(:action)"
            params["action"] = f"%{action}%"
        
        if object_name:
            query += " AND UPPER(table_name) LIKE UPPER(:object_name)"
            params["object_name"] = f"%{object_name}%"
        
        query += " ORDER BY performed_at DESC FETCH FIRST :limit ROWS ONLY"
        
        cursor.execute(query, params)
        columns = ["username", "action", "object_name", "timestamp", 
                   "return_code", "privilege_used", "terminal", "os_user"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_failed_logins(connection: oracledb.Connection, 
                          limit: int = 50) -> List[Dict[str, Any]]:
        """Get failed login attempts from app audit log"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT performed_by as username, ip_address as terminal, user_agent as os_user,
                   TO_CHAR(performed_at, 'YYYY-MM-DD"T"HH24:MI:SS') as timestamp,
                   NULL as error_code
            FROM library.app_audit_log
            WHERE action_type = 'LOGIN_FAILED'
            ORDER BY performed_at DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"limit": limit})
        columns = ["username", "terminal", "os_user", "timestamp", "error_code"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_user_activity(connection: oracledb.Connection,
                          username: str,
                          limit: int = 100) -> List[Dict[str, Any]]:
        """Get activity for a specific user from app audit log"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT action_type as action, table_name as object_name, NULL as privilege,
                   TO_CHAR(performed_at, 'YYYY-MM-DD"T"HH24:MI:SS') as timestamp,
                   'SUCCESS' as result
            FROM library.app_audit_log
            WHERE UPPER(performed_by) = UPPER(:username)
            ORDER BY performed_at DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"username": username, "limit": limit})
        columns = ["action", "object_name", "privilege", "timestamp", "result"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_object_audit(connection: oracledb.Connection,
                         object_name: str,
                         limit: int = 100) -> List[Dict[str, Any]]:
        """Get audit for a specific object from app audit log"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT performed_by as username, action_type as action, NULL as privilege,
                   TO_CHAR(performed_at, 'YYYY-MM-DD"T"HH24:MI:SS') as timestamp,
                   'SUCCESS' as result
            FROM library.app_audit_log
            WHERE UPPER(table_name) LIKE UPPER(:object_name)
            ORDER BY performed_at DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"object_name": f"%{object_name}%", "limit": limit})
        columns = ["username", "action", "privilege", "timestamp", "result"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_audit_summary(connection: oracledb.Connection) -> Dict[str, Any]:
        """Get audit summary statistics from app audit log"""
        cursor = connection.cursor()
        
        # Total entries
        cursor.execute("SELECT COUNT(*) FROM library.app_audit_log")
        total = cursor.fetchone()[0]
        
        # Failed logins today
        cursor.execute("""
            SELECT COUNT(*) FROM library.app_audit_log
            WHERE action_type = 'LOGIN_FAILED'
            AND TRUNC(performed_at) = TRUNC(SYSDATE)
        """)
        failed_logins_today = cursor.fetchone()[0]
        
        # Top actions
        cursor.execute("""
            SELECT action_type, COUNT(*) as cnt
            FROM library.app_audit_log
            GROUP BY action_type
            ORDER BY cnt DESC
            FETCH FIRST 10 ROWS ONLY
        """)
        top_actions = [{"action": row[0], "count": row[1]} for row in cursor.fetchall()]
        
        # Top users
        cursor.execute("""
            SELECT performed_by, COUNT(*) as cnt
            FROM library.app_audit_log
            WHERE performed_by IS NOT NULL
            GROUP BY performed_by
            ORDER BY cnt DESC
            FETCH FIRST 10 ROWS ONLY
        """)
        top_users = [{"user": row[0], "count": row[1]} for row in cursor.fetchall()]
        
        cursor.close()
        return {
            "total_entries": total,
            "failed_logins_today": failed_logins_today,
            "top_actions": top_actions,
            "top_users": top_users
        }
    
    @staticmethod
    def get_fga_audit(connection: oracledb.Connection,
                      limit: int = 100) -> List[Dict[str, Any]]:
        """Get Fine-Grained Audit entries from app audit log"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT performed_by as user, 'LIBRARY' as schema, table_name as object, action_type as policy,
                   NULL as sql, TO_CHAR(performed_at, 'YYYY-MM-DD"T"HH24:MI:SS') as timestamp
            FROM library.app_audit_log
            WHERE action_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
            ORDER BY performed_at DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"limit": limit})
        columns = ["user", "schema", "object", "policy", "sql", "timestamp"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_audit_options(connection: oracledb.Connection) -> Dict[str, List[Dict[str, Any]]]:
        """Get current audit configuration - simplified for app audit log"""
        # App audit log doesn't use Oracle unified audit policies
        # Return empty list for UI compatibility
        return {
            "statement_options": [],
            "object_options": []
        }
