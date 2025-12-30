from fastapi import APIRouter, HTTPException, Depends, Query, status
from typing import Optional

from ..database import get_db
from ..repositories import AuditRepository
from .auth import get_current_user_info

import oracledb

router = APIRouter(prefix="/audit", tags=["Audit"])


def require_admin(user_info: dict = Depends(get_current_user_info)):
    if user_info.get("user_type") != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access denied. Admin privileges required."
        )
    return user_info


@router.get("")
async def get_audit_trail(
    limit: int = Query(default=100, le=1000),
    username: Optional[str] = None,
    action: Optional[str] = None,
    object_name: Optional[str] = None,
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Get audit trail entries.
    Optional filters: username, action, object_name.
    """
    try:
        return AuditRepository.get_audit_trail(conn, limit, username, action, object_name)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/summary")
async def get_audit_summary(
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get audit summary statistics"""
    try:
        return AuditRepository.get_audit_summary(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/failed-logins")
async def get_failed_logins(
    limit: int = Query(default=50, le=500),
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get failed login attempts"""
    try:
        return AuditRepository.get_failed_logins(conn, limit)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/user/{username}")
async def get_user_activity(
    username: str,
    limit: int = Query(default=100, le=500),
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get activity for a specific user"""
    try:
        return AuditRepository.get_user_activity(conn, username, limit)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/object/{object_name}")
async def get_object_audit(
    object_name: str,
    limit: int = Query(default=100, le=500),
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get audit for a specific object"""
    try:
        return AuditRepository.get_object_audit(conn, object_name, limit)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/fga")
async def get_fga_audit(
    limit: int = Query(default=100, le=500),
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get Fine-Grained Audit entries"""
    try:
        return AuditRepository.get_fga_audit(conn, limit)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/options")
async def get_audit_options(
    user_info: dict = Depends(require_admin),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get current audit configuration"""
    try:
        return AuditRepository.get_audit_options(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
