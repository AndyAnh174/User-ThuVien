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


def get_user_db(user_info: dict = Depends(get_current_user_info)):
    """
    Get proxy connection for current logged-in user.
    Enables OLS/VPD policies.
    """
    from .database import Database
    
    username = user_info.get("oracle_username")
    print(f"[DEBUG] get_user_db called for oracle_username: {username}")
    
    if not username:
        print(f"[DEBUG] No oracle_username, using default LIBRARY connection")
        conn = Database.get_connection()
    else:
        try:
            conn = Database.get_proxy_connection(username)
            # Verify the session user
            cursor = conn.cursor()
            cursor.execute("SELECT SYS_CONTEXT('USERENV', 'SESSION_USER'), SYS_CONTEXT('USERENV', 'PROXY_USER') FROM DUAL")
            session_user, proxy_user = cursor.fetchone()
            print(f"[DEBUG] Proxy Connection: session_user={session_user}, proxy_user={proxy_user}")
            cursor.close()
        except Exception as e:
            print(f"[ERROR] Proxy connect failed for {username}: {e}")
            raise HTTPException(status_code=500, detail=f"Database Proxy Connection Failed: {e}")

    try:
        yield conn
    finally:
        conn.close()
