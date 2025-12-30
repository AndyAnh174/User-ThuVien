-- ============================================
-- SCRIPT 12: FORCE APPLY OLS POLICY
-- Chạy với SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting OLS Policy Re-application...');
    
    -- 1. Try Remove existing policy to clear state
    BEGIN
        SA_POLICY_ADMIN.REMOVE_TABLE_POLICY(
            policy_name => 'LIBRARY_POLICY',
            schema_name => 'LIBRARY',
            table_name  => 'BOOKS'
        );
        DBMS_OUTPUT.PUT_LINE('Removed existing policy.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Remove policy skipped/failed: ' || SQLERRM);
    END;

    -- 2. Apply Policy
    BEGIN
        SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
            policy_name    => 'LIBRARY_POLICY',
            schema_name    => 'LIBRARY',
            table_name     => 'BOOKS',
            table_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL,LABEL_DEFAULT',
            label_function => NULL,
            predicate      => NULL
        );
        DBMS_OUTPUT.PUT_LINE('Applied policy successfully.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Apply policy failed: ' || SQLERRM);
        -- Try Enable if it was just disabled
        BEGIN
            SA_POLICY_ADMIN.ENABLE_TABLE_POLICY(
                policy_name => 'LIBRARY_POLICY',
                schema_name => 'LIBRARY',
                table_name  => 'BOOKS'
            );
             DBMS_OUTPUT.PUT_LINE('Enabled policy successfully.');
        EXCEPTION WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('Enable policy failed: ' || SQLERRM);
        END;
    END;
END;
/

-- 3. Update Data Labels (Quan trọng: Nếu policy chưa apply, cột ols_label không tồn tại -> Update sẽ lỗi)
-- Chúng ta dùng Dynamic SQL để tránh lỗi biên dịch nếu cột chưa có
BEGIN
    EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''PUB'') WHERE sensitivity_level = ''PUBLIC''';
    EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''INT:LIB'') WHERE sensitivity_level = ''INTERNAL''';
    EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''CONF:LIB'') WHERE sensitivity_level = ''CONFIDENTIAL''';
    EXECUTE IMMEDIATE 'UPDATE library.books SET ols_label = CHAR_TO_LABEL(''LIBRARY_POLICY'', ''TS:LIB,HR,FIN:HQ'') WHERE sensitivity_level = ''TOP_SECRET''';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Data labels updated.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Update data failed (Maybe OLS column missing?): ' || SQLERRM);
END;
/

PROMPT Force Apply Completed.
