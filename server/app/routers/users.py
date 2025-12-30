
"""
Users Router - User management
"""

from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import List, Optional

from ..database import Database, get_db
from ..models import UserCreate, UserUpdate, UserResponse, SuccessResponse
from ..repositories import UserRepository, OracleUserRepository
from .auth import get_current_user_info
from ..dependencies import get_user_db

import oracledb

router = APIRouter(prefix="/users", tags=["Users"])


def require_staff_privilege(user_info: dict = Depends(get_current_user_info)):
    allowed_roles = ["ADMIN", "LIBRARIAN", "STAFF"]
    if user_info.get("user_type") not in allowed_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access denied. Staff privileges required."
        )
    return user_info


def require_admin_privilege(user_info: dict = Depends(get_current_user_info)):
    if user_info.get("user_type") != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access denied. Admin privileges required."
        )
    return user_info


@router.get("", response_model=List[dict])
async def get_users(
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_user_db)
):
    """
    Get all users.
    Results are filtered by VPD based on current user's role.
    Restricted to ADMIN, LIBRARIAN, STAFF.
    """
    try:
        users = UserRepository.get_all(conn)
        return users
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{user_id}")
async def get_user(
    user_id: int,
    user_info: dict = Depends(require_staff_privilege),
    conn: oracledb.Connection = Depends(get_user_db)
):
    """
    Get specific user by ID
    Restricted to ADMIN, LIBRARIAN, STAFF.
    """
    user = UserRepository.get_by_id(conn, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def require_librarian_or_admin(user_info: dict = Depends(get_current_user_info)):
    allowed = ["ADMIN", "LIBRARIAN"]
    if user_info.get("user_type") not in allowed:
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access denied. Librarian or Admin privileges required."
        )
    return user_info


@router.post("", response_model=SuccessResponse)
async def create_user(
    user: UserCreate,
    user_info: dict = Depends(require_librarian_or_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Create a new user.
    Creates both Oracle database user and user_info record.
    - ADMIN: Can create any user type.
    - LIBRARIAN: Can only create READER and STAFF.
    - RESTRICTED: LIBRARIAN cannot create ADMIN or other LIBRARIAN.
    """
    current_role = user_info.get("user_type")
    target_role = user.user_type.upper()

    # Rule: Librarian cannot create Admin or Librarian
    if current_role == "LIBRARIAN":
        if target_role in ["ADMIN", "LIBRARIAN"]:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Thủ thư không được phép tạo tài khoản Admin hoặc Thủ thư khác."
            )

    try:
        # Create Oracle user
        OracleUserRepository.create_oracle_user(
            conn,
            username=user.username,
            password=user.password,
            default_ts=user.default_tablespace,
            temp_ts=user.temporary_tablespace,
            quota=user.quota,
            profile=user.profile if user_info.get("user_type") == "ADMIN" else "DEFAULT"
        )
        
        # Assign role based on user type
        role_map = {
            "ADMIN": "ADMIN_ROLE",
            "LIBRARIAN": "LIBRARIAN_ROLE",
            "STAFF": "STAFF_ROLE",
            "READER": "READER_ROLE"
        }
        role = role_map.get(user.user_type.upper(), "READER_ROLE")
        OracleUserRepository.grant_role(conn, user.username, role)
        
        # Create user_info record
        user_data = {
            "oracle_username": user.username.upper(),
            "full_name": user.full_name,
            "email": user.email,
            "phone": user.phone,
            "address": user.address,
            "department": user.department,
            "branch_id": user.branch_id,
            "user_type": user.user_type.upper(),
            "sensitivity_level": "PUBLIC"
        }
        UserRepository.create(conn, user_data)
        
        return SuccessResponse(message=f"User {user.username} created successfully")
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        if error_obj.code == 1920:
             raise HTTPException(status_code=400, detail=f"Tên tài khoản '{user.username}' đã tồn tại trong hệ thống.")
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{user_id}", response_model=SuccessResponse)
async def update_user(
    user_id: int,
    user: UserUpdate,
    user_info: dict = Depends(require_librarian_or_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Update user info.
    - ADMIN: Can update any user.
    - LIBRARIAN: Can only update READER and STAFF.
    """
    existing_user = UserRepository.get_by_id(conn, user_id)
    if not existing_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check permission for Librarian
    current_role = user_info.get("user_type")
    
    # 1. Librarian restriction
    target_role = existing_user.get("user_type", "READER").upper()
    if current_role == "LIBRARIAN":
        if target_role in ["ADMIN", "LIBRARIAN"]:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Thủ thư không được phép chỉnh sửa tài khoản Admin hoặc Thủ thư khác."
            )

    update_data = {k: v for k, v in user.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=400, detail="No data to update")

    # 2. Profile restriction: Only Admin can update profile
    if "profile" in update_data and current_role != "ADMIN":
        del update_data["profile"]

    # Handle Oracle specific updates
    if "profile" in update_data:
        try:
            OracleUserRepository.alter_oracle_user(
                conn, 
                existing_user["oracle_username"], 
                {"profile": update_data["profile"]}
            )
        except oracledb.DatabaseError as e:
            raise HTTPException(status_code=400, detail=f"Failed to update Oracle profile: {str(e)}")
        
        # Remove profile from user_info update data as it's not a column there
        del update_data["profile"]

    if update_data:
        success = UserRepository.update(conn, user_id, update_data)
    
    return SuccessResponse(message="User updated successfully")


@router.delete("/{user_id}", response_model=SuccessResponse)
async def delete_user(
    user_id: int,
    cascade: bool = False,
    user_info: dict = Depends(require_librarian_or_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Delete user.
    - ADMIN: Can delete any user.
    - LIBRARIAN: Can only delete READER and STAFF.
    """
    # Get user to find Oracle username
    user = UserRepository.get_by_id(conn, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check permission for Librarian
    current_role = user_info.get("user_type")
    target_role = user.get("user_type", "READER").upper()
    
    if current_role == "LIBRARIAN":
        if target_role in ["ADMIN", "LIBRARIAN"]:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Thủ thư không được phép xóa tài khoản Admin hoặc Thủ thư khác."
            )
    
    try:
        # Delete from user_info
        UserRepository.delete(conn, user_id)
        
        # Optionally drop Oracle user
        if cascade and user.get("oracle_username"):
            try:
                OracleUserRepository.drop_oracle_user(conn, user["oracle_username"], cascade=True)
            except:
                pass  # Oracle user might not exist
        
        return SuccessResponse(message="User deleted successfully")
        
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ============================================
# Oracle User Management Endpoints
# ============================================

@router.get("/oracle/all")
async def get_oracle_users(
    user_info: dict = Depends(require_admin_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all Oracle database users"""
    try:
        return OracleUserRepository.get_all_oracle_users(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/oracle/{username}/lock")
async def lock_user(
    username: str,
    user_info: dict = Depends(require_admin_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """Lock Oracle user account"""
    try:
        OracleUserRepository.alter_oracle_user(conn, username, {"account_status": "LOCK"})
        return SuccessResponse(message=f"User {username} locked")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/oracle/{username}/unlock")
async def unlock_user(
    username: str,
    user_info: dict = Depends(require_admin_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """Unlock Oracle user account"""
    try:
        OracleUserRepository.alter_oracle_user(conn, username, {"account_status": "UNLOCK"})
        return SuccessResponse(message=f"User {username} unlocked")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/oracle/{username}/password")
async def change_password(
    username: str,
    new_password: str,
    user_info: dict = Depends(require_admin_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """Change Oracle user password"""
    try:
        OracleUserRepository.alter_oracle_user(conn, username, {"password": new_password})
        return SuccessResponse(message=f"Password changed for {username}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/oracle/{username}/quota")
async def change_quota(
    username: str,
    quota: str,
    tablespace: str = "LIBRARY_DATA",
    user_info: dict = Depends(require_admin_privilege),
    conn: oracledb.Connection = Depends(get_db)
):
    """Change user quota on tablespace"""
    try:
        OracleUserRepository.alter_oracle_user(conn, username, {
            "quota": quota,
            "tablespace": tablespace
        })
        return SuccessResponse(message=f"Quota changed for {username}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
