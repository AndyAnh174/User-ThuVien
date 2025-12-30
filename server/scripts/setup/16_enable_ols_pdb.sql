-- ============================================
-- SCRIPT 16: ENABLE OLS IN PDB
-- Chạy với SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Checking OLS Status in PDB...');
    
    -- Attempt to enable in PDB
    BEGIN
        LBACSYS.CONFIGURE_OLS;
        LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;
        DBMS_OUTPUT.PUT_LINE('OLS Configured/Enabled in PDB.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Configure OLS Error: ' || SQLERRM);
    END;
END;
/

-- Close and Open PDB to take effect
-- ALTER PLUGGABLE DATABASE FREEPDB1 CLOSE IMMEDIATE;
-- ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
-- Note: SQLPlus script might lose connection if we close PDB.
-- Better to restart form outside or reconnect.

PROMPT PDB OLS Configuration Attempted.
