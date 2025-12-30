-- ============================================
-- SCRIPT 13: UPDATE OLS DATA LABELS
-- Connect as SYS
CONN sys/Oracle123@localhost:1521/FREEPDB1 AS SYSDBA

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Granting FULL privilege to SYS for update...');
    BEGIN
        SA_USER_ADMIN.SET_USER_PRIVS(
            policy_name => 'LIBRARY_POLICY',
            user_name   => 'SYS',
            privileges  => 'FULL'
        );
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Grant privs warning: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('Updating OLS Data Labels...');
    
    -- Update Data Labels
    UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB') WHERE sensitivity_level = 'PUBLIC';
    UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB') WHERE sensitivity_level = 'INTERNAL';
    UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB') WHERE sensitivity_level = 'CONFIDENTIAL';
    UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ') WHERE sensitivity_level = 'TOP_SECRET';
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Data labels updated successfully.');
END;
/
/

EXIT;
