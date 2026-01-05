-- ============================================
-- SCRIPT 18: ORACLE DATABASE VAULT (ODV)
-- Chạy với SYS AS SYSDBA trong PDB context
-- ============================================
-- Database Vault ngăn chặn privileged users (DBA) 
-- truy cập dữ liệu nhạy cảm của ứng dụng
-- ============================================

SET SERVEROUTPUT ON;

-- Chuyển sang PDB (if running from CDB)
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = FREEPDB1';
EXCEPTION
    WHEN OTHERS THEN
        -- Already in PDB or no permission, continue
        NULL;
END;
/

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
    EXECUTE IMMEDIATE 'CREATE USER sec_admin IDENTIFIED BY "SecAdmin123" 
        DEFAULT TABLESPACE USERS 
        QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User sec_admin created.');
    
    -- Grant DV_OWNER role to sec_admin
    EXECUTE IMMEDIATE 'GRANT DV_OWNER TO sec_admin WITH ADMIN OPTION';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User sec_admin already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

-- DV Account Manager - quản lý users
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER dv_acctmgr_user IDENTIFIED BY "DVAcctMgr#123" 
        DEFAULT TABLESPACE USERS 
        QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User dv_acctmgr_user created.');

    -- Grant DV_ACCTMGR role
    EXECUTE IMMEDIATE 'GRANT DV_ACCTMGR TO dv_acctmgr_user WITH ADMIN OPTION';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User dv_acctmgr_user already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

GRANT CREATE SESSION TO sec_admin;
GRANT CREATE SESSION TO dv_acctmgr_user;

-- Grant required privileges for package usage
BEGIN
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.CONFIGURE_DV TO sec_admin';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.DBMS_MACADM TO sec_admin';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.DBMS_MACUTL TO sec_admin';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Grant Warning: ' || SQLERRM);
END;
/

-- ============================================
-- 3. CẤU HÌNH DATABASE VAULT
-- ============================================
-- DV Configuration and Enablement moved to 18b_enable_dv_pdb.sql
-- to be run by C##SEC_ADMIN


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
