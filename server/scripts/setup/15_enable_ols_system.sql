-- ============================================
-- SCRIPT 15: ENABLE OLS SYSTEM WIDE
-- Chạy với SYS AS SYSDBA
-- ============================================

-- Connect to CDB Root
ALTER SESSION SET CONTAINER = CDB$ROOT;

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Configuring OLS...');
    LBACSYS.CONFIGURE_OLS;
    LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;
    DBMS_OUTPUT.PUT_LINE('OLS Enabled. Validating...');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error enabling OLS: ' || SQLERRM);
END;
/

-- Unlock LBACSYS just in case
ALTER USER lbacsys IDENTIFIED BY "Lbacsys#123" ACCOUNT UNLOCK;

PROMPT Please RESTART the database instace now.
