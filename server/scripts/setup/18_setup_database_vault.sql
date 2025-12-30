-- ============================================
-- SCRIPT 18: ORACLE DATABASE VAULT (ODV)
-- Chạy với SYS AS SYSDBA
-- ============================================
-- Database Vault ngăn chặn privileged users (DBA) 
-- truy cập dữ liệu nhạy cảm của ứng dụng
-- ============================================

-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON;

-- ============================================
-- 1. KIỂM TRA DATABASE VAULT ĐÃ CÀI ĐẶT CHƯA
-- ============================================
PROMPT Checking Database Vault installation...

SELECT * FROM DBA_DV_STATUS;

-- ============================================
-- 2. TẠO DATABASE VAULT OWNER VÀ ACCOUNT MANAGER
-- ============================================
PROMPT Creating Database Vault users...

-- DV Owner - quản lý realms và rules
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER dv_owner IDENTIFIED BY "DVOwner#123" 
        DEFAULT TABLESPACE library_data 
        TEMPORARY TABLESPACE library_temp 
        QUOTA 50M ON library_data';
    DBMS_OUTPUT.PUT_LINE('User dv_owner created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User dv_owner already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

-- DV Account Manager - quản lý users
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER dv_acctmgr IDENTIFIED BY "DVAcctMgr#123" 
        DEFAULT TABLESPACE library_data 
        TEMPORARY TABLESPACE library_temp 
        QUOTA 10M ON library_data';
    DBMS_OUTPUT.PUT_LINE('User dv_acctmgr created.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User dv_acctmgr already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

GRANT CREATE SESSION TO dv_owner;
GRANT CREATE SESSION TO dv_acctmgr;

-- ============================================
-- 3. CẤU HÌNH DATABASE VAULT
-- ============================================
PROMPT Configuring Database Vault...

BEGIN
    -- Configure Database Vault (chạy 1 lần)
    DVSYS.CONFIGURE_DV(
        dvowner_uname         => 'DV_OWNER',
        dvacctmgr_uname       => 'DV_ACCTMGR'
    );
    DBMS_OUTPUT.PUT_LINE('Database Vault configured successfully.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('DV Config Error (may already be configured): ' || SQLERRM);
END;
/

-- ============================================
-- 4. ENABLE DATABASE VAULT
-- ============================================
PROMPT Enabling Database Vault...

BEGIN
    DVSYS.DBMS_MACADM.ENABLE_DV;
    DBMS_OUTPUT.PUT_LINE('Database Vault enabled. RESTART DATABASE REQUIRED!');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('DV Enable Error: ' || SQLERRM);
END;
/

-- ============================================
-- NOTE: RESTART DATABASE SAU BƯỚC NÀY
-- docker restart oracle23ai
-- ============================================

PROMPT ============================================
PROMPT IMPORTANT: Restart database now!
PROMPT docker restart oracle23ai
PROMPT Then run script 19_setup_dv_realms.sql
PROMPT ============================================

COMMIT;
