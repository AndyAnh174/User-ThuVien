"""
Profiles Router - Profile management
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import List

from ..database import get_db
from ..models import ProfileCreate, ProfileUpdate, SuccessResponse
from ..repositories import ProfileRepository
from .auth import get_current_user

import oracledb

router = APIRouter(prefix="/profiles", tags=["Profiles"])


@router.get("")
async def get_profiles(
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get all Oracle profiles"""
    try:
        return ProfileRepository.get_all(conn)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{profile_name}")
async def get_profile(
    profile_name: str,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Get profile details with all resource limits"""
    try:
        resources = ProfileRepository.get_by_name(conn, profile_name)
        users = ProfileRepository.get_users_with_profile(conn, profile_name)
        return {
            "profile_name": profile_name,
            "resources": resources,
            "users": users
        }
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("", response_model=SuccessResponse)
async def create_profile(
    profile: ProfileCreate,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Create new Oracle profile.
    Resource values can be: UNLIMITED, DEFAULT, or a specific number.
    """
    try:
        ProfileRepository.create(
            conn,
            profile_name=profile.profile_name,
            sessions_per_user=profile.sessions_per_user,
            connect_time=profile.connect_time,
            idle_time=profile.idle_time
        )
        return SuccessResponse(message=f"Profile {profile.profile_name} created successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{profile_name}", response_model=SuccessResponse)
async def update_profile(
    profile_name: str,
    profile: ProfileUpdate,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """Update profile resource limits"""
    try:
        resources = {k: v for k, v in profile.model_dump().items() if v is not None}
        if not resources:
            raise HTTPException(status_code=400, detail="No resources to update")
        
        ProfileRepository.alter(conn, profile_name, resources)
        return SuccessResponse(message=f"Profile {profile_name} updated successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{profile_name}", response_model=SuccessResponse)
async def delete_profile(
    profile_name: str,
    cascade: bool = False,
    current_user: str = Depends(get_current_user),
    conn: oracledb.Connection = Depends(get_db)
):
    """
    Delete Oracle profile.
    Set cascade=true to reassign users to DEFAULT profile.
    """
    try:
        ProfileRepository.drop(conn, profile_name, cascade=cascade)
        return SuccessResponse(message=f"Profile {profile_name} deleted successfully")
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=400, detail=str(e))
