"""
Privileges Router - Privilege management
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import Optional

from ..database import get_db
from ..models import PrivilegeGrant, PrivilegeRevoke, SuccessResponse
from ..repositories import PrivilegeRepository
from .auth import get_current_user

import oracledb

router = APIRouter(prefix="/privileges", tags=["Privileges"])


@router.get("/system")
async def get_system_privileges(
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get list of available system privileges"""
    return {"privileges": PrivilegeRepository.SYSTEM_PRIVILEGES}


@router.get("/user/{username}")
async def get_user_privileges(
    username: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all privileges for a specific user"""
    try:
        return PrivilegeRepository.get_all_privileges_for_user(conn, username)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/check/{username}/{privilege}")
async def check_privilege(
    username: str,
    privilege: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Check if user has a specific privilege"""
    has_priv = PrivilegeRepository.check_privilege(conn, username, privilege)
    return {"user": username, "privilege": privilege, "has_privilege": has_priv}


@router.post("/grant/system", response_model=SuccessResponse)
async def grant_system_privilege(
    grant: PrivilegeGrant,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Grant system privilege to user or role.
    Set with_admin_option=true to allow grantee to grant privilege to others.
    """
    try:
        PrivilegeRepository.grant_system_privilege(
            conn, grant.grantee, grant.privilege, grant.with_admin_option
        )
        return SuccessResponse(message=f"Granted {grant.privilege} to {grant.grantee}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/revoke/system", response_model=SuccessResponse)
async def revoke_system_privilege(
    revoke: PrivilegeRevoke,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Revoke system privilege from user or role"""
    try:
        PrivilegeRepository.revoke_system_privilege(conn, revoke.grantee, revoke.privilege)
        return SuccessResponse(message=f"Revoked {revoke.privilege} from {revoke.grantee}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/grant/object", response_model=SuccessResponse)
async def grant_object_privilege(
    grant: PrivilegeGrant,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Grant object privilege (on table or column) to user or role.
    Set with_grant_option=true to allow grantee to grant privilege to others.
    """
    if not grant.object_name:
        raise HTTPException(status_code=400, detail="object_name is required for object privileges")
    
    try:
        PrivilegeRepository.grant_object_privilege(
            conn, grant.grantee, grant.privilege, grant.object_name,
            grant.column_name, grant.with_grant_option
        )
        msg = f"Granted {grant.privilege} ON {grant.object_name}"
        if grant.column_name:
            msg += f"({grant.column_name})"
        msg += f" to {grant.grantee}"
        return SuccessResponse(message=msg)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/revoke/object", response_model=SuccessResponse)
async def revoke_object_privilege(
    revoke: PrivilegeRevoke,
    column_name: Optional[str] = None,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Revoke object privilege from user or role"""
    if not revoke.object_name:
        raise HTTPException(status_code=400, detail="object_name is required for object privileges")
    
    try:
        PrivilegeRepository.revoke_object_privilege(
            conn, revoke.grantee, revoke.privilege, revoke.object_name, column_name
        )
        return SuccessResponse(message=f"Revoked {revoke.privilege} ON {revoke.object_name} from {revoke.grantee}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/grant/role", response_model=SuccessResponse)
async def grant_role_to_user(
    grantee: str,
    role: str,
    with_admin: bool = False,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Grant role to user or another role"""
    try:
        PrivilegeRepository.grant_role(conn, grantee, role, with_admin)
        return SuccessResponse(message=f"Granted role {role} to {grantee}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/revoke/role", response_model=SuccessResponse)
async def revoke_role_from_user(
    grantee: str,
    role: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Revoke role from user or another role"""
    try:
        PrivilegeRepository.revoke_role(conn, grantee, role)
        return SuccessResponse(message=f"Revoked role {role} from {grantee}")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
