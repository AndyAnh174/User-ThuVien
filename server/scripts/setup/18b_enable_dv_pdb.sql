-- ============================================
-- SCRIPT 18b: ENABLE DV IN PDB
-- Run with SEC_ADMIN (Local DV Owner)
-- ============================================
-- NOTE: Connect directly to PDB: sec_admin/SecAdmin123@FREEPDB1
-- SEC_ADMIN cannot use ALTER SESSION SET CONTAINER

SET SERVEROUTPUT ON;

BEGIN
    -- Configure Database Vault in PDB using Local Users
    -- This binds the DV Owner role to this user for the PDB
    DVSYS.CONFIGURE_DV(
        dvowner_uname         => 'SEC_ADMIN',
        dvacctmgr_uname       => 'DV_ACCTMGR_USER'
    );
    DBMS_OUTPUT.PUT_LINE('PDB Database Vault configured.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Config Warning: ' || SQLERRM);
END;
/

BEGIN
    DVSYS.DBMS_MACADM.ENABLE_DV;
    DBMS_OUTPUT.PUT_LINE('PDB Database Vault enabled. RESTART REQUIRED.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Enable Error: ' || SQLERRM);
END;
/

EXIT;
