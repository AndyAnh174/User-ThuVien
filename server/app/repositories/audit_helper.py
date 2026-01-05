"""
Audit Helper - Utility functions for logging audit events
"""
import oracledb
from typing import Optional, Dict, Any
from datetime import datetime


class AuditHelper:
    """Helper class for logging audit events"""
    
    @staticmethod
    def log_action(connection: oracledb.Connection,
                   action_type: str,
                   table_name: str,
                   record_id: Optional[int] = None,
                   old_values: Optional[Dict[str, Any]] = None,
                   new_values: Optional[Dict[str, Any]] = None,
                   performed_by: Optional[str] = None) -> None:
        """
        Log an audit event to app_audit_log.
        
        This is called automatically by repositories when data changes.
        """
        try:
            cursor = connection.cursor()
            
            # Convert dict to JSON string if provided
            old_json = None
            if old_values:
                import json
                old_json = json.dumps(old_values, ensure_ascii=False)
            
            new_json = None
            if new_values:
                import json
                new_json = json.dumps(new_values, ensure_ascii=False)
            
            # Get current user if not provided
            if not performed_by:
                cursor.execute("SELECT USER FROM DUAL")
                performed_by = cursor.fetchone()[0]
            
            cursor.execute("""
                INSERT INTO library.app_audit_log (
                    action_type, table_name, record_id, 
                    old_values, new_values, performed_by, performed_at
                ) VALUES (
                    :action_type, :table_name, :record_id,
                    :old_values, :new_values, :performed_by, SYSTIMESTAMP
                )
            """, {
                "action_type": action_type,
                "table_name": table_name,
                "record_id": record_id,
                "old_values": old_json,
                "new_values": new_json,
                "performed_by": performed_by
            })
            
            connection.commit()
            cursor.close()
        except Exception as e:
            # Don't fail the main operation if audit logging fails
            print(f"[AUDIT ERROR] Failed to log {action_type} on {table_name}: {e}")
            connection.rollback()

