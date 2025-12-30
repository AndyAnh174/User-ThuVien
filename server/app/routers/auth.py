"""
Authentication Router
"""

from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from typing import Optional

from ..database import Database
from ..models import LoginRequest, LoginResponse, CurrentUser
from ..repositories import UserRepository

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBasic()


def get_current_user(credentials: HTTPBasicCredentials = Depends(security)) -> str:
    """Authenticate user and return username"""
    conn = Database.connect_as_user(credentials.username, credentials.password)
    if conn is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    conn.close()
    return credentials.username


def get_current_user_info(username: str = Depends(get_current_user)) -> dict:
    """Get full user info for authenticated user"""
    conn = Database.get_connection()
    try:
        user = UserRepository.get_by_username(conn, username)
        if user:
            return user
        return {"oracle_username": username, "user_type": "UNKNOWN"}
    finally:
        Database.release_connection(conn)


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """
    Login with Oracle Database credentials.
    Returns user info if successful.
    """
    conn = Database.connect_as_user(request.username, request.password)
    if conn is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    
    # If connection successful, credentials are valid.
    conn.close() # Close user connection immediately
    
    # Use system connection to get user details (to avoid permission issues)
    sys_conn = Database.get_connection()
    try:
        cursor = sys_conn.cursor()
        cursor.execute("""
            SELECT user_id, oracle_username, full_name, user_type, 
                   sensitivity_level, branch_id
            FROM library.user_info
            WHERE UPPER(oracle_username) = UPPER(:username)
        """, {"username": request.username})
        row = cursor.fetchone()
        cursor.close()
        
        if row:
            return LoginResponse(
                success=True,
                user={
                    "user_id": row[0],
                    "username": row[1],
                    "full_name": row[2],
                    "user_type": row[3],
                    "sensitivity_level": row[4],
                    "branch_id": row[5]
                }
            )
        else:
            return LoginResponse(
                success=True,
                message="User authenticated but not in user_info table",
                user={
                    "username": request.username,
                    "user_type": "ORACLE_USER"
                }
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching user info: {str(e)}")
    finally:
        Database.release_connection(sys_conn)


@router.get("/me")
async def get_me(user_info: dict = Depends(get_current_user_info)):
    """
    Get current authenticated user's info.
    Requires Basic Authentication.
    """
    return user_info


@router.get("/check")
async def check_auth(username: str = Depends(get_current_user)):
    """
    Check if authentication is valid.
    Returns username if authenticated.
    """
    return {"authenticated": True, "username": username}
