"""
Roles Router - Role management
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional

from ..database import get_db
from ..models import RoleCreate, SuccessResponse
from ..repositories import RoleRepository
from .auth import get_current_user

import oracledb

router = APIRouter(prefix="/roles", tags=["Roles"])


@router.get("")
async def get_roles(
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all Oracle roles"""
    try:
        return RoleRepository.get_all(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{role_name}")
async def get_role(
    role_name: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get role details with privileges and users"""
    try:
        privileges = RoleRepository.get_role_privileges(conn, role_name)
        users = RoleRepository.get_role_users(conn, role_name)
        return {
            **privileges,
            "users": users
        }
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("", response_model=SuccessResponse)
async def create_role(
    role: RoleCreate,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Create new Oracle role.
    If password is provided, role will be password-protected.
    """
    try:
        RoleRepository.create(conn, role.role_name, role.password)
        return SuccessResponse(message=f"Role {role.role_name} created successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{role_name}/password", response_model=SuccessResponse)
async def change_role_password(
    role_name: str,
    password: Optional[str] = None,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Change role password.
    If password is None, role will be NOT IDENTIFIED.
    """
    try:
        RoleRepository.alter_password(conn, role_name, password)
        msg = f"Password set for role {role_name}" if password else f"Password removed from role {role_name}"
        return SuccessResponse(message=msg)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{role_name}", response_model=SuccessResponse)
async def delete_role(
    role_name: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Delete Oracle role"""
    try:
        RoleRepository.drop(conn, role_name)
        return SuccessResponse(message=f"Role {role_name} deleted successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{role_name}/grant", response_model=SuccessResponse)
async def grant_to_role(
    role_name: str,
    privilege: str,
    object_name: Optional[str] = None,
    with_admin: bool = False,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Grant privilege to role"""
    try:
        RoleRepository.grant_privilege_to_role(conn, role_name, privilege, object_name, with_admin)
        return SuccessResponse(message=f"Granted {privilege} to {role_name}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{role_name}/revoke", response_model=SuccessResponse)
async def revoke_from_role(
    role_name: str,
    privilege: str,
    object_name: Optional[str] = None,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Revoke privilege from role"""
    try:
        RoleRepository.revoke_privilege_from_role(conn, role_name, privilege, object_name)
        return SuccessResponse(message=f"Revoked {privilege} from {role_name}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
