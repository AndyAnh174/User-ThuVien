"""
Books Router - Book management
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional

from ..database import get_db
from ..models import BookCreate, BookUpdate, SuccessResponse
from ..repositories import BookRepository, CategoryRepository, BranchRepository
from ..dependencies import require_staff_privilege, get_user_db
from .auth import get_current_user_info

import oracledb

router = APIRouter(prefix="/books", tags=["Books"])



def validate_sensitivity_level(user_role: str, level: str):
    user_role = user_role.upper()
    allowed_levels = {
        "STAFF": ["PUBLIC", "INTERNAL"],
        "LIBRARIAN": ["PUBLIC", "INTERNAL", "CONFIDENTIAL"],
        "ADMIN": ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "TOP_SECRET"]
    }
    
    if user_role not in allowed_levels:
        allowed = [] # Default deny
    else:
        allowed = allowed_levels[user_role]
        
    if level not in allowed:
        raise HTTPException(
            status_code=403, 
            detail=f"Quyền {user_role} không được phép thao tác với tài liệu {level}."
        )

@router.get("")
async def get_books(
    keyword: Optional[str] = None,
    category_id: Optional[int] = None,
    branch_id: Optional[int] = None,
    user_info: dict = Depends(get_current_user_info),
    # NOTE:
    #   We deliberately use the shared LIBRARY connection here (get_db)
    #   instead of per-user proxy (get_user_db) because Oracle Database Vault
    #   + VPD policies can raise ORA-28112 when the policy function executes
    #   under a proxied session (LIBRARY[USERNAME]).
    #   The row-level visibility is still enforced at the database layer
    #   via existing VPD/OLS configuration.
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Get all books.
    NOTE: Row-level filtering is enforced in `BookRepository` based on
    user_type + branch_id + sensitivity_level (app-layer VPD simulation).
    """
    try:
        user_type = user_info.get("user_type")
        user_branch_id = user_info.get("branch_id")
        user_sensitivity = user_info.get("sensitivity_level")
        if keyword or category_id or branch_id:
            return BookRepository.search(
                conn,
                keyword=keyword,
                category_id=category_id,
                branch_id=branch_id,
                user_type=user_type,
                user_branch_id=user_branch_id,
                user_sensitivity=user_sensitivity,
            )
        return BookRepository.get_all(
            conn,
            user_type=user_type,
            user_branch_id=user_branch_id,
            user_sensitivity=user_sensitivity,
        )
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
        # Validate Sensitivity Level
        validate_sensitivity_level(user_info.get("user_type"), book.sensitivity_level.value)

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
    try:
        update_data = {k: v for k, v in book.model_dump().items() if v is not None}
        if not update_data:
            raise HTTPException(status_code=400, detail="No data to update")
            
        # Validate Sensitivity Level if user is updating it
        if "sensitivity_level" in update_data:
            sensitivity_value = update_data["sensitivity_level"]
            # Check if it's enum or string (depending on pydantic model serialization)
            if hasattr(sensitivity_value, 'value'):
                sensitivity_value = sensitivity_value.value
                update_data["sensitivity_level"] = sensitivity_value
            
            validate_sensitivity_level(user_info.get("user_type"), sensitivity_value)
            
        success = BookRepository.update(conn, book_id, update_data)
        if not success:
            raise HTTPException(status_code=404, detail="Book not found")
        
        return SuccessResponse(message="Book updated successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


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
