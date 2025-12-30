"""
Audit Repository - Database operations for audit trail
"""

import oracledb
from typing import List, Dict, Any, Optional
from datetime import datetime


class AuditRepository:
    """Repository for audit trail operations"""
    
    @staticmethod
    def get_audit_trail(connection: oracledb.Connection,
                        limit: int = 100,
                        username: Optional[str] = None,
                        action: Optional[str] = None,
                        object_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get audit trail entries with optional filters"""
        cursor = connection.cursor()
        
        query = """
            SELECT dbusername, action_name, object_name, 
                   TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time,
                   return_code, system_privilege_used, terminal, os_username
            FROM unified_audit_trail
            WHERE 1=1
        """
        params = {"limit": limit}
        
        if username:
            query += " AND UPPER(dbusername) = UPPER(:username)"
            params["username"] = username
        
        if action:
            query += " AND UPPER(action_name) LIKE UPPER(:action)"
            params["action"] = f"%{action}%"
        
        if object_name:
            query += " AND UPPER(object_name) LIKE UPPER(:object_name)"
            params["object_name"] = f"%{object_name}%"
        
        query += " ORDER BY event_timestamp DESC FETCH FIRST :limit ROWS ONLY"
        
        cursor.execute(query, params)
        columns = ["username", "action", "object_name", "timestamp", 
                   "return_code", "privilege_used", "terminal", "os_user"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_failed_logins(connection: oracledb.Connection, 
                          limit: int = 50) -> List[Dict[str, Any]]:
        """Get failed login attempts"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT dbusername, terminal, os_username,
                   TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time,
                   return_code
            FROM unified_audit_trail
            WHERE action_name = 'LOGON' AND return_code != 0
            ORDER BY event_timestamp DESC
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
        """Get activity for a specific user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT action_name, object_name, system_privilege_used,
                   TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time,
                   CASE return_code WHEN 0 THEN 'SUCCESS' ELSE 'FAILED' END as result
            FROM unified_audit_trail
            WHERE UPPER(dbusername) = UPPER(:username)
            ORDER BY event_timestamp DESC
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
        """Get audit for a specific object"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT dbusername, action_name, system_privilege_used,
                   TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time,
                   CASE return_code WHEN 0 THEN 'SUCCESS' ELSE 'FAILED' END as result
            FROM unified_audit_trail
            WHERE UPPER(object_name) LIKE UPPER(:object_name)
            ORDER BY event_timestamp DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"object_name": f"%{object_name}%", "limit": limit})
        columns = ["username", "action", "privilege", "timestamp", "result"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_audit_summary(connection: oracledb.Connection) -> Dict[str, Any]:
        """Get audit summary statistics"""
        cursor = connection.cursor()
        
        # Total entries
        cursor.execute("SELECT COUNT(*) FROM unified_audit_trail")
        total = cursor.fetchone()[0]
        
        # Failed logins today
        cursor.execute("""
            SELECT COUNT(*) FROM unified_audit_trail
            WHERE action_name = 'LOGON' AND return_code != 0
            AND TRUNC(event_timestamp) = TRUNC(SYSDATE)
        """)
        failed_logins_today = cursor.fetchone()[0]
        
        # Top actions
        cursor.execute("""
            SELECT action_name, COUNT(*) as cnt
            FROM unified_audit_trail
            GROUP BY action_name
            ORDER BY cnt DESC
            FETCH FIRST 10 ROWS ONLY
        """)
        top_actions = [{"action": row[0], "count": row[1]} for row in cursor.fetchall()]
        
        # Top users
        cursor.execute("""
            SELECT dbusername, COUNT(*) as cnt
            FROM unified_audit_trail
            WHERE dbusername IS NOT NULL
            GROUP BY dbusername
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
        """Get Fine-Grained Audit entries - Mapped to unified audit trail"""
        cursor = connection.cursor()
        # In unified audit, FGA is also recorded. Filter by audit_type if needed, or simply return typical columns
        cursor.execute("""
            SELECT dbusername, object_schema, object_name, audit_option,
                   sql_text, TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time
            FROM unified_audit_trail
            WHERE audit_type = 'FineGrainedAudit'
            ORDER BY event_timestamp DESC
            FETCH FIRST :limit ROWS ONLY
        """, {"limit": limit})
        columns = ["user", "schema", "object", "policy", "sql", "timestamp"]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_audit_options(connection: oracledb.Connection) -> Dict[str, List[Dict[str, Any]]]:
        """Get current audit configuration"""
        # Unified audit uses policies, simpler view here
        cursor = connection.cursor()
        
        cursor.execute("""
            SELECT user_name, policy_name, enabled_opt, success, failure
            FROM audit_unified_enabled_policies
            ORDER BY user_name, policy_name
        """)
        policies = [{"user": row[0], "policy": row[1], "option": row[2], 
                     "success": row[3], "failure": row[4]} 
                    for row in cursor.fetchall()]
        
        cursor.close()
        return {
            "statement_options": policies, # Mapped roughly for UI compatibility
            "object_options": [] 
        }
