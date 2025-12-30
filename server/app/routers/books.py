"""
Books Router - Book management
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_db
from ..models import BookCreate, BookUpdate, SuccessResponse
from ..repositories import BookRepository, CategoryRepository, BranchRepository
from ..dependencies import require_staff_privilege
from .auth import get_current_user_info

import oracledb

router = APIRouter(prefix="/books", tags=["Books"])


@router.get("")
async def get_books(
    keyword: Optional[str] = None,
    category_id: Optional[int] = None,
    branch_id: Optional[int] = None,
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Get all books.
    Results are filtered by VPD based on current user's sensitivity level.
    Optional filters: keyword (title/author), category_id, branch_id.
    """
    try:
        user_type = user_info.get("user_type")
        if keyword or category_id or branch_id:
            return BookRepository.search(conn, keyword, category_id, branch_id, user_type)
        return BookRepository.get_all(conn, user_type)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/categories")
async def get_categories(
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all book categories"""
    return CategoryRepository.get_all(conn)


@router.get("/branches")
async def get_branches(
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all library branches"""
    return BranchRepository.get_all(conn)


@router.get("/{book_id}")
async def get_book(
    book_id: int,
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get specific book by ID"""
    book = BookRepository.get_by_id(conn, book_id)
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
    return book


@router.post("", response_model=SuccessResponse)
async def create_book(
    book: BookCreate,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Create new book.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        book_data = book.model_dump()
        # Force available_qty to match quantity on creation
        book_data["available_qty"] = book_data["quantity"]
        book_data["sensitivity_level"] = book_data["sensitivity_level"].value
        book_id = BookRepository.create(conn, book_data)
        return SuccessResponse(message=f"Book created with ID {book_id}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{book_id}", response_model=SuccessResponse)
async def update_book(
    book_id: int,
    book: BookUpdate,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Update book.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    update_data = {k: v for k, v in book.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No data to update")
    
    # Convert enum to string
    if "sensitivity_level" in update_data:
        update_data["sensitivity_level"] = update_data["sensitivity_level"].value
    
    success = BookRepository.update(conn, book_id, update_data)
    if not success:
        raise HTTPException(status_code=404, detail="Book not found")
    
    return SuccessResponse(message="Book updated successfully")


@router.delete("/{book_id}", response_model=SuccessResponse)
async def delete_book(
    book_id: int,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Delete book.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        success = BookRepository.delete(conn, book_id)
        if not success:
            raise HTTPException(status_code=404, detail="Book not found")
        return SuccessResponse(message="Book deleted successfully")
    except oracledb.DatabaseError as e:
        error_obj = e.args[0]
        if error_obj.code == 2292:
            raise HTTPException(
                status_code=400, 
                detail="Không thể xóa sách này vì đã có dữ liệu mượn trả (Lịch sử giao dịch). Vui lòng xóa lịch sử liên quan trước."
            )
        raise HTTPException(status_code=400, detail=str(e))
