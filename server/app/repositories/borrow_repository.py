"""
Borrow Repository - Database operations for borrow history
"""

import oracledb
from typing import List, Dict, Any, Optional
from datetime import date


class BorrowRepository:
    """Repository for borrow history operations"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection, username: Optional[str] = None, user_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Get all borrow history.
        Includes manual filtering logic to emulate VPD if connection pool context isn't set.
        """
        cursor = connection.cursor()
        
        sql = """
            SELECT bh.borrow_id, bh.user_id, u.full_name as borrower_name,
                   bh.book_id, b.title as book_title,
                   bh.borrow_date, bh.due_date, bh.return_date,
                   bh.status, bh.fine_amount, bh.notes, bh.created_by
            FROM library.borrow_history bh
            JOIN library.user_info u ON bh.user_id = u.user_id
            JOIN library.books b ON bh.book_id = b.book_id
        """
        
        params = {}
        
        # Manual filtering for Readers (Web App Logic)
        if user_type == 'READER' and username:
            sql += " WHERE UPPER(u.oracle_username) = UPPER(:username)"
            params["username"] = username
            
        sql += " ORDER BY bh.borrow_date DESC"
        
        cursor.execute(sql, params)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_by_id(connection: oracledb.Connection, borrow_id: int) -> Optional[Dict[str, Any]]:
        """Get borrow record by ID"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT bh.borrow_id, bh.user_id, u.full_name as borrower_name,
                   bh.book_id, b.title as book_title,
                   bh.borrow_date, bh.due_date, bh.return_date,
                   bh.status, bh.fine_amount, bh.notes, bh.created_by
            FROM library.borrow_history bh
            JOIN library.user_info u ON bh.user_id = u.user_id
            JOIN library.books b ON bh.book_id = b.book_id
            WHERE bh.borrow_id = :borrow_id
        """, {"borrow_id": borrow_id})
        columns = [col[0].lower() for col in cursor.description]
        row = cursor.fetchone()
        cursor.close()
        return dict(zip(columns, row)) if row else None
    
    @staticmethod
    def get_by_user(connection: oracledb.Connection, user_id: int) -> List[Dict[str, Any]]:
        """Get borrow history for a specific user"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT bh.borrow_id, bh.book_id, b.title as book_title,
                   bh.borrow_date, bh.due_date, bh.return_date,
                   bh.status, bh.fine_amount
            FROM library.borrow_history bh
            JOIN library.books b ON bh.book_id = b.book_id
            WHERE bh.user_id = :user_id
            ORDER BY bh.borrow_date DESC
        """, {"user_id": user_id})
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_active_borrows(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all active (not returned) borrows"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT bh.borrow_id, bh.user_id, u.full_name as borrower_name,
                   bh.book_id, b.title as book_title,
                   bh.borrow_date, bh.due_date, bh.status
            FROM library.borrow_history bh
            JOIN library.user_info u ON bh.user_id = u.user_id
            JOIN library.books b ON bh.book_id = b.book_id
            WHERE bh.status IN ('BORROWING', 'OVERDUE')
            ORDER BY bh.due_date
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def create(connection: oracledb.Connection, 
               user_id: int, 
               book_id: int,
               due_date: Optional[date] = None,
               created_by: str = "SYSTEM") -> int:
        """Create new borrow record"""
        cursor = connection.cursor()
        
        # Default due date is 14 days from now
        due_sql = ":due_date" if due_date else "SYSDATE + 14"
        
        cursor.execute(f"""
            INSERT INTO library.borrow_history 
            (user_id, book_id, borrow_date, due_date, status, created_by)
            VALUES (:user_id, :book_id, SYSDATE, {due_sql}, 'BORROWING', :created_by)
            RETURNING borrow_id INTO :borrow_id
        """, {
            "user_id": user_id,
            "book_id": book_id,
            "due_date": due_date,
            "created_by": created_by,
            "borrow_id": cursor.var(oracledb.NUMBER)
        })
        borrow_id = cursor.bindvars["borrow_id"].getvalue()[0]
        connection.commit()
        cursor.close()
        return int(borrow_id)
    
    @staticmethod
    def return_book(connection: oracledb.Connection,
                    borrow_id: int,
                    fine_amount: float = 0) -> bool:
        """Mark book as returned"""
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE library.borrow_history
            SET return_date = SYSDATE,
                status = 'RETURNED',
                fine_amount = :fine_amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE borrow_id = :borrow_id AND status = 'BORROWING'
        """, {"borrow_id": borrow_id, "fine_amount": fine_amount})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0
    
    @staticmethod
    def mark_overdue(connection: oracledb.Connection) -> int:
        """Mark all overdue books"""
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE library.borrow_history
            SET status = 'OVERDUE', updated_at = CURRENT_TIMESTAMP
            WHERE status = 'BORROWING' AND due_date < SYSDATE
        """)
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected
    
    @staticmethod
    def mark_lost(connection: oracledb.Connection, borrow_id: int) -> bool:
        """Mark book as lost"""
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE library.borrow_history
            SET status = 'LOST', updated_at = CURRENT_TIMESTAMP
            WHERE borrow_id = :borrow_id
        """, {"borrow_id": borrow_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0
