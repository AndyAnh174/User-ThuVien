"""
Library User Management System - Pydantic Models
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import date, datetime
from enum import Enum


# ============================================
# Enums
# ============================================

class UserType(str, Enum):
    ADMIN = "ADMIN"
    LIBRARIAN = "LIBRARIAN"
    STAFF = "STAFF"
    READER = "READER"


class SensitivityLevel(str, Enum):
    PUBLIC = "PUBLIC"
    INTERNAL = "INTERNAL"
    CONFIDENTIAL = "CONFIDENTIAL"
    TOP_SECRET = "TOP_SECRET"


class BorrowStatus(str, Enum):
    BORROWING = "BORROWING"
    RETURNED = "RETURNED"
    OVERDUE = "OVERDUE"
    LOST = "LOST"


# ============================================
# Auth Models
# ============================================

class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    success: bool
    message: Optional[str] = None
    user: Optional[dict] = None


class CurrentUser(BaseModel):
    user_id: Optional[int] = None
    username: str
    full_name: Optional[str] = None
    user_type: UserType = UserType.READER
    sensitivity_level: SensitivityLevel = SensitivityLevel.PUBLIC
    branch_id: Optional[int] = None


# ============================================
# User Models
# ============================================

class UserBase(BaseModel):
    oracle_username: str
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    department: Optional[str] = None
    branch_id: Optional[int] = None
    user_type: UserType = UserType.READER
    sensitivity_level: SensitivityLevel = SensitivityLevel.PUBLIC


class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=30)
    password: str = Field(..., min_length=6)
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    department: Optional[str] = None
    branch_id: Optional[int] = None
    user_type: UserType = UserType.READER
    default_tablespace: str = "LIBRARY_DATA"
    temporary_tablespace: str = "LIBRARY_TEMP"
    quota: str = "10M"
    profile: str = "DEFAULT"


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    department: Optional[str] = None
    branch_id: Optional[int] = None
    profile: Optional[str] = None


class UserResponse(UserBase):
    user_id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    users: List[UserResponse]
    total: int


# ============================================
# Oracle User Management Models
# ============================================

class OracleUserCreate(BaseModel):
    username: str
    password: str
    default_tablespace: str = "LIBRARY_DATA"
    temporary_tablespace: str = "LIBRARY_TEMP"
    quota: str = "UNLIMITED"
    profile: str = "DEFAULT"
    account_status: str = "UNLOCK"


class OracleUserUpdate(BaseModel):
    password: Optional[str] = None
    default_tablespace: Optional[str] = None
    temporary_tablespace: Optional[str] = None
    quota: Optional[str] = None
    profile: Optional[str] = None
    account_status: Optional[str] = None  # LOCK or UNLOCK


# ============================================
# Profile Models
# ============================================

class ProfileCreate(BaseModel):
    profile_name: str
    sessions_per_user: str = "UNLIMITED"
    connect_time: str = "UNLIMITED"
    idle_time: str = "UNLIMITED"


class ProfileUpdate(BaseModel):
    sessions_per_user: Optional[str] = None
    connect_time: Optional[str] = None
    idle_time: Optional[str] = None


class ProfileResponse(BaseModel):
    profile_name: str
    resource_name: str
    limit: str


# ============================================
# Role Models
# ============================================

class RoleCreate(BaseModel):
    role_name: str
    password: Optional[str] = None


class RoleResponse(BaseModel):
    role_name: str
    password_required: str


class RolePrivileges(BaseModel):
    role_name: str
    privileges: List[str]
    users: List[str]


# ============================================
# Privilege Models
# ============================================

class PrivilegeGrant(BaseModel):
    grantee: str  # User or Role receiving the privilege
    privilege: str
    object_name: Optional[str] = None  # For object privileges
    column_name: Optional[str] = None  # For column privileges
    with_grant_option: bool = False
    with_admin_option: bool = False


class PrivilegeRevoke(BaseModel):
    grantee: str
    privilege: str
    object_name: Optional[str] = None


class UserPrivileges(BaseModel):
    username: str
    system_privileges: List[dict]
    object_privileges: List[dict]
    roles: List[dict]


# ============================================
# Book Models
# ============================================

class BookBase(BaseModel):
    isbn: Optional[str] = None
    title: str
    author: Optional[str] = None
    publisher: Optional[str] = None
    publish_year: Optional[int] = None
    category_id: Optional[int] = None
    branch_id: Optional[int] = None
    quantity: int = 1
    available_qty: int = 1
    sensitivity_level: SensitivityLevel = SensitivityLevel.PUBLIC


class BookCreate(BookBase):
    pass


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    publisher: Optional[str] = None
    publish_year: Optional[int] = None
    category_id: Optional[int] = None
    quantity: Optional[int] = None
    sensitivity_level: Optional[SensitivityLevel] = None


class BookResponse(BookBase):
    book_id: int
    category_name: Optional[str] = None
    branch_name: Optional[str] = None
    created_at: Optional[datetime] = None


# ============================================
# Borrow Models
# ============================================

class BorrowCreate(BaseModel):
    user_id: int
    book_id: int
    due_date: Optional[date] = None


class BorrowReturn(BaseModel):
    borrow_id: int
    fine_amount: Optional[float] = 0


class BorrowResponse(BaseModel):
    borrow_id: int
    user_id: int
    borrower_name: Optional[str] = None
    book_id: int
    book_title: Optional[str] = None
    borrow_date: date
    due_date: Optional[date] = None
    return_date: Optional[date] = None
    status: BorrowStatus
    fine_amount: float = 0


# ============================================
# Audit Models
# ============================================

class AuditEntry(BaseModel):
    username: str
    action: str
    object_name: Optional[str] = None
    timestamp: str
    return_code: int
    privilege_used: Optional[str] = None
    terminal: Optional[str] = None


class AuditFilter(BaseModel):
    username: Optional[str] = None
    action: Optional[str] = None
    object_name: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    limit: int = 100


# ============================================
# Common Response Models
# ============================================

class SuccessResponse(BaseModel):
    success: bool = True
    message: str


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    detail: Optional[str] = None
