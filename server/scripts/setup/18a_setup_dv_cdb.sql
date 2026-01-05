-- ============================================
-- SCRIPT 18a: SETUP DV IN CDB ROOT
-- Run with SYS AS SYSDBA in CDB
-- ============================================

SET SERVEROUTPUT ON;

-- Create Common DV Owner
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER c##sec_admin IDENTIFIED BY "SecAdmin123" CONTAINER=ALL';
    DBMS_OUTPUT.PUT_LINE('User c##sec_admin created.');
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, SET CONTAINER TO c##sec_admin CONTAINER=ALL';
    EXECUTE IMMEDIATE 'GRANT DV_OWNER TO c##sec_admin WITH ADMIN OPTION CONTAINER=ALL';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User c##sec_admin already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

-- Create Common DV AcctMgr
BEGIN
    EXECUTE IMMEDIATE 'CREATE USER c##dv_acctmgr IDENTIFIED BY "DVAcctMgr#123" CONTAINER=ALL';
    DBMS_OUTPUT.PUT_LINE('User c##dv_acctmgr created.');
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, SET CONTAINER TO c##dv_acctmgr CONTAINER=ALL';
    EXECUTE IMMEDIATE 'GRANT DV_ACCTMGR TO c##dv_acctmgr WITH ADMIN OPTION CONTAINER=ALL';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1920 THEN
            DBMS_OUTPUT.PUT_LINE('User c##dv_acctmgr already exists. Skipping...');
        ELSE
            RAISE;
        END IF;
END;
/

-- Configure DV in CDB
BEGIN
    -- Check if DV is already configured
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM DBA_DV_STATUS WHERE STATUS = 'ENABLED';
        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('CDB Database Vault already configured.');
        ELSE
            DVSYS.CONFIGURE_DV(
                dvowner_uname         => 'C##SEC_ADMIN',
                dvacctmgr_uname       => 'C##DV_ACCTMGR'
            );
            DBMS_OUTPUT.PUT_LINE('CDB Database Vault configured.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('CDB DV Config Warning: ' || SQLERRM);
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CDB DV Config Error: ' || SQLERRM);
END;
/

-- Enable DV in CDB
-- NOTE: This must be run AFTER restart by C##SEC_ADMIN user
-- SYS cannot enable DV directly, it requires DV_OWNER role
-- So we'll configure it here, but enable will be done after restart by C##SEC_ADMIN
BEGIN
    -- Check if already enabled
    DECLARE
        v_enabled VARCHAR2(10);
    BEGIN
        BEGIN
            SELECT STATUS INTO v_enabled FROM DBA_DV_STATUS WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_enabled := 'FALSE';
            WHEN OTHERS THEN
                v_enabled := 'UNKNOWN';
        END;
        
        IF v_enabled = 'ENABLED' THEN
            DBMS_OUTPUT.PUT_LINE('CDB Database Vault already enabled.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CDB Database Vault configured. Enable will be done after restart by C##SEC_ADMIN.');
            DBMS_OUTPUT.PUT_LINE('After restart, run as C##SEC_ADMIN: DVSYS.DBMS_MACADM.ENABLE_DV;');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('CDB DV Status Check: ' || SQLERRM);
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CDB DV Check Outer Error: ' || SQLERRM);
END;
/

EXIT;
