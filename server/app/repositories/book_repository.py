"""
Book Repository - Database operations for books
"""

import oracledb
from typing import List, Dict, Any, Optional


class BookRepository:
    """Repository for book-related database operations"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection, user_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get all books (filtered by VPD/Role based on sensitivity level)"""
        cursor = connection.cursor()
        
        query = """
            SELECT b.book_id, b.isbn, b.title, b.author, b.publisher, b.publish_year,
                   b.category_id, c.category_name, b.branch_id, br.branch_name,
                   b.quantity, b.available_qty, b.sensitivity_level, b.created_at
            FROM library.books b
            LEFT JOIN library.categories c ON b.category_id = c.category_id
            LEFT JOIN library.branches br ON b.branch_id = br.branch_id
            WHERE 1=1
        """
        params = {}
        
        # Manual VPD/OLS simulation for READER
        if user_type == 'READER':
            query += " AND b.sensitivity_level = 'PUBLIC'"
            
        query += " ORDER BY b.book_id"
        
        cursor.execute(query, params)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def get_by_id(connection: oracledb.Connection, book_id: int) -> Optional[Dict[str, Any]]:
        """Get book by ID"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT b.book_id, b.isbn, b.title, b.author, b.publisher, b.publish_year,
                   b.category_id, c.category_name, b.branch_id, br.branch_name,
                   b.quantity, b.available_qty, b.sensitivity_level, b.created_at
            FROM library.books b
            LEFT JOIN library.categories c ON b.category_id = c.category_id
            LEFT JOIN library.branches br ON b.branch_id = br.branch_id
            WHERE b.book_id = :book_id
        """, {"book_id": book_id})
        columns = [col[0].lower() for col in cursor.description]
        row = cursor.fetchone()
        cursor.close()
        return dict(zip(columns, row)) if row else None
    
    @staticmethod
    def search(connection: oracledb.Connection, 
               keyword: Optional[str] = None,
               category_id: Optional[int] = None,
               branch_id: Optional[int] = None,
               user_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Search books by keyword, category, or branch"""
        cursor = connection.cursor()
        
        query = """
            SELECT b.book_id, b.isbn, b.title, b.author, b.publisher, b.publish_year,
                   c.category_name, br.branch_name, b.quantity, b.available_qty, b.sensitivity_level
            FROM library.books b
            LEFT JOIN library.categories c ON b.category_id = c.category_id
            LEFT JOIN library.branches br ON b.branch_id = br.branch_id
            WHERE 1=1
        """
        params = {}
        
        # Manual VPD/OLS simulation for READER
        if user_type == 'READER':
            query += " AND b.sensitivity_level = 'PUBLIC'"
        
        if keyword:
            query += " AND (UPPER(b.title) LIKE UPPER(:keyword) OR UPPER(b.author) LIKE UPPER(:keyword))"
            params["keyword"] = f"%{keyword}%"
        
        if category_id:
            query += " AND b.category_id = :category_id"
            params["category_id"] = category_id
        
        if branch_id:
            query += " AND b.branch_id = :branch_id"
            params["branch_id"] = branch_id
        
        query += " ORDER BY b.title"
        
        cursor.execute(query, params)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
    
    @staticmethod
    def create(connection: oracledb.Connection, book_data: Dict[str, Any]) -> int:
        """Create new book"""
        cursor = connection.cursor()
        cursor.execute("""
            INSERT INTO library.books 
            (isbn, title, author, publisher, publish_year, category_id, 
             branch_id, quantity, available_qty, sensitivity_level)
            VALUES (:isbn, :title, :author, :publisher, :publish_year, :category_id,
                    :branch_id, :quantity, :available_qty, :sensitivity_level)
            RETURNING book_id INTO :book_id
        """, {
            **book_data,
            "book_id": cursor.var(oracledb.NUMBER)
        })
        book_id = cursor.bindvars["book_id"].getvalue()[0]
        connection.commit()
        cursor.close()
        return int(book_id)
    
    @staticmethod
    def update(connection: oracledb.Connection, book_id: int, book_data: Dict[str, Any]) -> bool:
        """Update book"""
        set_clause = ", ".join([f"{k} = :{k}" for k in book_data.keys()])
        cursor = connection.cursor()
        cursor.execute(f"""
            UPDATE library.books
            SET {set_clause}, updated_at = CURRENT_TIMESTAMP
            WHERE book_id = :book_id
        """, {**book_data, "book_id": book_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0
    
    @staticmethod
    def delete(connection: oracledb.Connection, book_id: int) -> bool:
        """Delete book"""
        cursor = connection.cursor()
        cursor.execute("DELETE FROM library.books WHERE book_id = :book_id", {"book_id": book_id})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0
    
    @staticmethod
    def update_availability(connection: oracledb.Connection, book_id: int, change: int) -> bool:
        """Update book availability (+ for return, - for borrow)"""
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE library.books
            SET available_qty = available_qty + :change
            WHERE book_id = :book_id AND available_qty + :change >= 0
        """, {"book_id": book_id, "change": change})
        affected = cursor.rowcount
        connection.commit()
        cursor.close()
        return affected > 0


class CategoryRepository:
    """Repository for book categories"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all categories"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT category_id, category_code, category_name, description
            FROM library.categories
            ORDER BY category_name
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]


class BranchRepository:
    """Repository for library branches"""
    
    @staticmethod
    def get_all(connection: oracledb.Connection) -> List[Dict[str, Any]]:
        """Get all branches"""
        cursor = connection.cursor()
        cursor.execute("""
            SELECT branch_id, branch_code, branch_name, address, phone
            FROM library.branches
            ORDER BY branch_name
        """)
        columns = [col[0].lower() for col in cursor.description]
        rows = cursor.fetchall()
        cursor.close()
        return [dict(zip(columns, row)) for row in rows]
