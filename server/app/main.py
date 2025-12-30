"""
Library User Management System
Main FastAPI Application
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .config import settings
from .database import Database
from .routers import (
    auth_router,
    users_router,
    profiles_router,
    roles_router,
    privileges_router,
    books_router,
    borrow_router,
    audit_router
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - startup and shutdown events"""
    # Startup
    Database.init_pool()
    print(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} started")
    
    yield
    
    # Shutdown
    Database.close_pool()
    print("👋 Application shutdown complete")


# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
## Library User Management API

API for managing library users with Oracle Database security features:

- **VPD (Virtual Private Database)**: Row-level security
- **OLS (Oracle Label Security)**: Mandatory Access Control (MAC)
- **Audit**: Activity monitoring and logging
- **ODV (Oracle Database Vault)**: Protection from privileged users

### Authentication
All endpoints (except health check) require Basic Authentication with Oracle Database credentials.

### User Types
- **ADMIN**: Full access to all features
- **LIBRARIAN**: Manage books and borrowing
- **STAFF**: View access to branch data
- **READER**: View own data only
    """,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api")
app.include_router(users_router, prefix="/api")
app.include_router(profiles_router, prefix="/api")
app.include_router(roles_router, prefix="/api")
app.include_router(privileges_router, prefix="/api")
app.include_router(books_router, prefix="/api")
app.include_router(borrow_router, prefix="/api")
app.include_router(audit_router, prefix="/api")


# ============================================
# Root endpoints
# ============================================

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint - API info"""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "redoc": "/redoc",
        "health": "/api/health"
    }


@app.get("/api/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    try:
        conn = Database.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM DUAL")
        cursor.close()
        Database.release_connection(conn)
        return {
            "status": "healthy",
            "database": "connected",
            "dsn": settings.DB_DSN
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }
