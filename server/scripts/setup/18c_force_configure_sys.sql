-- Run as SYS in PDB
SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = FREEPDB1';
EXCEPTION
    WHEN OTHERS THEN
        -- Already in PDB or error, continue
        NULL;
END;
/

BEGIN
    DVSYS.CONFIGURE_DV(
        dvowner_uname         => 'SEC_ADMIN',
        dvacctmgr_uname       => 'DV_ACCTMGR_USER'
    );
    DBMS_OUTPUT.PUT_LINE('PDB DV Configured by SYS.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Config Error: ' || SQLERRM);
END;
/

-- Try enabling as SYS (might fail if SYS loses power, but worth trying)
BEGIN
    DVSYS.DBMS_MACADM.ENABLE_DV;
    DBMS_OUTPUT.PUT_LINE('PDB DV Enabled by SYS. RESTART REQUIRED.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Enable Error by SYS: ' || SQLERRM);
END;
/

EXIT;
