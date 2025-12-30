"""
Borrow Router - Borrow/Return book management
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import Optional
from datetime import date

from ..database import get_db
from ..models import BorrowCreate, SuccessResponse
from ..repositories import BorrowRepository, BookRepository
from ..dependencies import require_staff_privilege
from .auth import get_current_user_info

import oracledb

router = APIRouter(prefix="/borrow", tags=["Borrow"])


@router.get("")
async def get_borrow_history(
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Get borrow history.
    Results are filtered manually to emulate VPD for readers.
    """
    try:
        return BorrowRepository.get_all(conn, user_info.get('oracle_username'), user_info.get('user_type'))
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/active")
async def get_active_borrows(
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all active (not returned) borrows"""
    try:
        return BorrowRepository.get_active_borrows(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/user/{user_id}")
async def get_user_borrow_history(
    user_id: int,
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get borrow history for a specific user"""
    try:
        return BorrowRepository.get_by_user(conn, user_id)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{borrow_id}")
async def get_borrow_record(
    borrow_id: int,
    user_info: dict = Depends(get_current_user_info),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get specific borrow record"""
    record = BorrowRepository.get_by_id(conn, borrow_id)
    if not record:
        raise HTTPException(status_code=404, detail="Borrow record not found")
    return record


@router.post("", response_model=SuccessResponse)
async def borrow_book(
    borrow: BorrowCreate,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Borrow a book.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        # Check book availability
        book = BookRepository.get_by_id(conn, borrow.book_id)
        if not book:
            raise HTTPException(status_code=404, detail="Book not found")
        if book.get("available_qty", 0) <= 0:
            raise HTTPException(status_code=400, detail="Book not available")
        
        # Create borrow record
        borrow_id = BorrowRepository.create(
            conn, borrow.user_id, borrow.book_id, borrow.due_date, user_info.get('oracle_username')
        )
        
        # Update book availability
        BookRepository.update_availability(conn, borrow.book_id, -1)
        
        return SuccessResponse(message=f"Book borrowed successfully. Borrow ID: {borrow_id}")
        
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{borrow_id}/return", response_model=SuccessResponse)
async def return_book(
    borrow_id: int,
    fine_amount: float = 0,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Return a borrowed book.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        # Get borrow record
        record = BorrowRepository.get_by_id(conn, borrow_id)
        if not record:
            raise HTTPException(status_code=404, detail="Borrow record not found")
        if record.get("status") == "RETURNED":
            raise HTTPException(status_code=400, detail="Book already returned")
        
        # Mark as returned
        success = BorrowRepository.return_book(conn, borrow_id, fine_amount)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to return book")
        
        # Update book availability
        BookRepository.update_availability(conn, record["book_id"], 1)
        
        return SuccessResponse(message="Book returned successfully")
        
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{borrow_id}/lost", response_model=SuccessResponse)
async def mark_lost(
    borrow_id: int,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Mark book as lost.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        success = BorrowRepository.mark_lost(conn, borrow_id)
        if not success:
            raise HTTPException(status_code=404, detail="Borrow record not found")
        return SuccessResponse(message="Book marked as lost")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/update-overdue", response_model=SuccessResponse)
async def update_overdue_books(
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Mark all overdue books.
    Restricted to STAFF, LIBRARIAN, ADMIN.
    """
    try:
        count = BorrowRepository.mark_overdue(conn)
        return SuccessResponse(message=f"Marked {count} books as overdue")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
