-- ============================================
-- SCRIPT 14: FORCE APPLY OLS POLICY V2
-- Chạy với SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

-- Allow LBACSYS to inherit SYS privs to execute definer rights procedures
GRANT INHERIT PRIVILEGES ON USER SYS TO LBACSYS;

BEGIN
    -- Remove old attachment
    SA_POLICY_ADMIN.REMOVE_TABLE_POLICY('LIBRARY_POLICY','LIBRARY','BOOKS');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    -- Apply Policy again (Should create OLS_LABEL column)
    SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
        policy_name    => 'LIBRARY_POLICY',
        schema_name    => 'LIBRARY',
        table_name     => 'BOOKS',
        table_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL',
        label_function => NULL,
        predicate      => NULL
    );
    
    -- Enable just in case
    SA_POLICY_ADMIN.ENABLE_TABLE_POLICY('LIBRARY_POLICY','LIBRARY','BOOKS');
END;
/

-- Check and Update
SET SERVEROUTPUT ON;
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM DBA_TAB_COLS 
    WHERE OWNER='LIBRARY' AND TABLE_NAME='BOOKS' AND COLUMN_NAME='OLS_LABEL';
    
    IF v_cnt > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Column OLS_LABEL exists. Updating data...');
        EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''PUB'') WHERE sensitivity_level = ''PUBLIC''';
        EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''INT:LIB'') WHERE sensitivity_level = ''INTERNAL''';
        EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''CONF:LIB'') WHERE sensitivity_level = ''CONFIDENTIAL''';
        EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''TS:LIB,HR,FIN:HQ'') WHERE sensitivity_level = ''TOP_SECRET''';
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Data updated.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAILED: Column OLS_LABEL still missing!');
    END IF;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

EXIT;
