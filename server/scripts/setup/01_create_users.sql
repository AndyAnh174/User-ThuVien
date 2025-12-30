-- ============================================
-- SCRIPT 01: TẠO TABLESPACES VÀ USERS
-- Chạy với SYS AS SYSDBA
-- ============================================

-- Kết nối vào PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- ============================================
-- 1. TẠO TABLESPACES (Oracle tự chọn đường dẫn)
-- ============================================

CREATE TABLESPACE library_data
    DATAFILE 'library_data01.dbf'
    SIZE 100M
    AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE library_temp
    TEMPFILE 'library_temp01.dbf'
    SIZE 50M
    AUTOEXTEND ON NEXT 25M MAXSIZE UNLIMITED;

-- ============================================
-- 2. TẠO 3 USERS QUẢN TRỊ BẢO MẬT
-- ============================================

CREATE USER lib_project IDENTIFIED BY "LibProject123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA UNLIMITED ON library_data;

GRANT CONNECT, RESOURCE TO lib_project;
GRANT CREATE SESSION TO lib_project;
GRANT CREATE PROCEDURE TO lib_project;
GRANT EXECUTE ON DBMS_RLS TO lib_project;
GRANT EXECUTE ON DBMS_FGA TO lib_project;
GRANT SELECT ANY DICTIONARY TO lib_project;

CREATE USER lib_admin IDENTIFIED BY "LibAdmin123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA UNLIMITED ON library_data;

GRANT CONNECT, RESOURCE TO lib_admin;
GRANT CREATE SESSION TO lib_admin;
GRANT SELECT ANY DICTIONARY TO lib_admin;

CREATE USER system_orcl_free IDENTIFIED BY "SysOrcl123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA UNLIMITED ON library_data;

GRANT CONNECT, RESOURCE TO system_orcl_free;
GRANT CREATE SESSION TO system_orcl_free;
GRANT SELECT ANY DICTIONARY TO system_orcl_free;

-- ============================================
-- 3. TẠO SCHEMA LIBRARY
-- ============================================

CREATE USER library IDENTIFIED BY "Library123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA UNLIMITED ON library_data;

GRANT CONNECT, RESOURCE TO library;
GRANT CREATE SESSION TO library;
GRANT CREATE TABLE TO library;
GRANT CREATE VIEW TO library;
GRANT CREATE PROCEDURE TO library;
GRANT CREATE SEQUENCE TO library;
GRANT CREATE TRIGGER TO library;

-- ============================================
-- 4. TẠO CÁC ROLES (RBAC)
-- ============================================

CREATE ROLE admin_role;
CREATE ROLE librarian_role;
CREATE ROLE staff_role;
CREATE ROLE reader_role;

-- ============================================
-- 5. TẠO CÁC USERS ỨNG DỤNG
-- ============================================

CREATE USER admin_user IDENTIFIED BY "Admin123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 50M ON library_data;
GRANT CREATE SESSION TO admin_user;
GRANT admin_role TO admin_user;

CREATE USER librarian_user IDENTIFIED BY "Librarian123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 20M ON library_data;
GRANT CREATE SESSION TO librarian_user;
GRANT librarian_role TO librarian_user;

CREATE USER staff_user IDENTIFIED BY "Staff123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 10M ON library_data;
GRANT CREATE SESSION TO staff_user;
GRANT staff_role TO staff_user;

CREATE USER reader_user IDENTIFIED BY "Reader123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 5M ON library_data;
GRANT CREATE SESSION TO reader_user;
GRANT reader_role TO reader_user;

COMMIT;

SELECT 'Script 01 completed!' FROM DUAL;
