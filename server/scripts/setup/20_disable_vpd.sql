-- ============================================
-- SCRIPT: TAT VPD POLICIES
-- Chay voi SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON;

PROMPT Dropping VPD policies...

-- Drop VPD policy tren USER_INFO
BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'VPD_USER_INFO_POLICY'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_USER_INFO_POLICY dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_USER_INFO_POLICY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'VPD_USER_INFO'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_USER_INFO dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_USER_INFO: ' || SQLERRM);
END;
/

-- Drop VPD policy tren BOOKS
BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'BOOKS',
        policy_name   => 'VPD_BOOKS_POLICY'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_BOOKS_POLICY dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_BOOKS_POLICY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'BOOKS',
        policy_name   => 'VPD_BOOKS'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_BOOKS dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_BOOKS: ' || SQLERRM);
END;
/

-- Drop VPD policy tren BORROW_HISTORY
BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'BORROW_HISTORY',
        policy_name   => 'VPD_BORROW_HISTORY_POLICY'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_BORROW_HISTORY_POLICY dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_BORROW_HISTORY_POLICY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'BORROW_HISTORY',
        policy_name   => 'VPD_BORROW_HISTORY'
    );
    DBMS_OUTPUT.PUT_LINE('VPD_BORROW_HISTORY dropped.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('VPD_BORROW_HISTORY: ' || SQLERRM);
END;
/

-- Kiem tra con policy nao khong
PROMPT Checking remaining VPD policies...
SELECT policy_name, object_name FROM dba_policies WHERE object_owner = 'LIBRARY';

COMMIT;

PROMPT ============================================
PROMPT VPD policies dropped successfully!
PROMPT ============================================
