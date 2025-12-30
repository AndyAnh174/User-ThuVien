"""
Shared dependencies for RBAC
"""
from fastapi import Depends, HTTPException, status
from .routers.auth import get_current_user_info

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
