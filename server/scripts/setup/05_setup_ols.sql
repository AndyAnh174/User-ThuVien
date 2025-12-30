-- ============================================
-- SCRIPT 05: ORACLE LABEL SECURITY (OLS)
-- Chạy với SYS AS SYSDBA SAU khi đã enable OLS
-- (scripts 15 & 16 phải chạy trước và restart database)
-- ============================================

-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON;

-- ============================================
-- 1. GRANT INHERIT PRIVILEGES (bắt buộc!)
-- ============================================
PROMPT Granting INHERIT PRIVILEGES...

GRANT INHERIT PRIVILEGES ON USER SYS TO LBACSYS;
GRANT INHERIT PRIVILEGES ON USER LBACSYS TO SYS;

-- ============================================
-- 2. TẠO POLICY OLS
-- ============================================
PROMPT Creating OLS Policy...

BEGIN
    SA_SYSDBA.CREATE_POLICY(
        policy_name      => 'LIBRARY_POLICY',
        column_name      => 'OLS_LABEL',
        default_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL'
    );
    DBMS_OUTPUT.PUT_LINE('Policy LIBRARY_POLICY created.');
EXCEPTION 
    WHEN OTHERS THEN
        IF SQLCODE = -12416 THEN
            DBMS_OUTPUT.PUT_LINE('Policy already exists, continuing...');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Create Policy Error: ' || SQLERRM);
        END IF;
END;
/

-- ============================================
-- 3. TẠO CÁC LEVELS (Mức độ nhạy cảm)
-- ============================================
PROMPT Creating OLS Levels...

BEGIN
    -- PUBLIC (1000)
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 1000,
        short_name   => 'PUB',
        long_name    => 'PUBLIC'
    );
    DBMS_OUTPUT.PUT_LINE('Level PUB created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Level PUB: ' || SQLERRM);
END;
/

BEGIN
    -- INTERNAL (2000)
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 2000,
        short_name   => 'INT',
        long_name    => 'INTERNAL'
    );
    DBMS_OUTPUT.PUT_LINE('Level INT created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Level INT: ' || SQLERRM);
END;
/

BEGIN
    -- CONFIDENTIAL (3000)
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 3000,
        short_name   => 'CONF',
        long_name    => 'CONFIDENTIAL'
    );
    DBMS_OUTPUT.PUT_LINE('Level CONF created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Level CONF: ' || SQLERRM);
END;
/

BEGIN
    -- TOP_SECRET (4000)
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 4000,
        short_name   => 'TS',
        long_name    => 'TOP_SECRET'
    );
    DBMS_OUTPUT.PUT_LINE('Level TS created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Level TS: ' || SQLERRM);
END;
/

-- ============================================
-- 4. TẠO COMPARTMENTS
-- ============================================
PROMPT Creating OLS Compartments...

BEGIN
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 100,
        short_name   => 'LIB',
        long_name    => 'LIBRARY'
    );
    DBMS_OUTPUT.PUT_LINE('Compartment LIB created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Compartment LIB: ' || SQLERRM);
END;
/

BEGIN
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 200,
        short_name   => 'HR',
        long_name    => 'HUMAN_RESOURCES'
    );
    DBMS_OUTPUT.PUT_LINE('Compartment HR created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Compartment HR: ' || SQLERRM);
END;
/

BEGIN
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 300,
        short_name   => 'FIN',
        long_name    => 'FINANCE'
    );
    DBMS_OUTPUT.PUT_LINE('Compartment FIN created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Compartment FIN: ' || SQLERRM);
END;
/

-- ============================================
-- 5. TẠO GROUPS
-- ============================================
PROMPT Creating OLS Groups...

BEGIN
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 10,
        short_name   => 'HQ',
        long_name    => 'HEADQUARTERS'
    );
    DBMS_OUTPUT.PUT_LINE('Group HQ created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Group HQ: ' || SQLERRM);
END;
/

BEGIN
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 20,
        short_name   => 'BR_A',
        long_name    => 'BRANCH_A',
        parent_name  => 'HQ'
    );
    DBMS_OUTPUT.PUT_LINE('Group BR_A created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Group BR_A: ' || SQLERRM);
END;
/

BEGIN
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 30,
        short_name   => 'BR_B',
        long_name    => 'BRANCH_B',
        parent_name  => 'HQ'
    );
    DBMS_OUTPUT.PUT_LINE('Group BR_B created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Group BR_B: ' || SQLERRM);
END;
/

-- ============================================
-- 6. TẠO LABELS
-- ============================================
PROMPT Creating OLS Labels...

BEGIN
    SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 1000, 'PUB');
    DBMS_OUTPUT.PUT_LINE('Label PUB created.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 2000, 'INT:LIB');
    DBMS_OUTPUT.PUT_LINE('Label INT:LIB created.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 3000, 'CONF:LIB');
    DBMS_OUTPUT.PUT_LINE('Label CONF:LIB created.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 3500, 'CONF:LIB:HQ');
    DBMS_OUTPUT.PUT_LINE('Label CONF:LIB:HQ created.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 4000, 'TS:LIB,HR,FIN:HQ');
    DBMS_OUTPUT.PUT_LINE('Label TS:LIB,HR,FIN:HQ created.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ============================================
-- 7. GÁN LABELS CHO USERS
-- ============================================
PROMPT Assigning labels to users...

BEGIN
    -- ADMIN - Full access
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'ADMIN_USER',
        max_read_label => 'TS:LIB,HR,FIN:HQ'
    );
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'ADMIN_USER',
        privileges  => 'FULL'
    );
    DBMS_OUTPUT.PUT_LINE('ADMIN_USER: TS:LIB,HR,FIN:HQ with FULL');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ADMIN_USER: ' || SQLERRM);
END;
/

BEGIN
    -- LIBRARIAN - Up to CONFIDENTIAL
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'LIBRARIAN_USER',
        max_read_label => 'CONF:LIB:HQ'
    );
    DBMS_OUTPUT.PUT_LINE('LIBRARIAN_USER: CONF:LIB:HQ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('LIBRARIAN_USER: ' || SQLERRM);
END;
/

BEGIN
    -- STAFF - Up to INTERNAL
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'STAFF_USER',
        max_read_label => 'INT:LIB'
    );
    DBMS_OUTPUT.PUT_LINE('STAFF_USER: INT:LIB');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('STAFF_USER: ' || SQLERRM);
END;
/

BEGIN
    -- READER - PUBLIC only
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'READER_USER',
        max_read_label => 'PUB'
    );
    DBMS_OUTPUT.PUT_LINE('READER_USER: PUB');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('READER_USER: ' || SQLERRM);
END;
/

BEGIN
    -- LIBRARY (schema owner) - Full access
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'LIBRARY',
        max_read_label => 'TS:LIB,HR,FIN:HQ'
    );
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'LIBRARY',
        privileges  => 'FULL'
    );
    DBMS_OUTPUT.PUT_LINE('LIBRARY: TS:LIB,HR,FIN:HQ with FULL');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('LIBRARY: ' || SQLERRM);
END;
/

-- ============================================
-- 8. ÁP DỤNG POLICY LÊN BẢNG BOOKS
-- ============================================
PROMPT Applying policy to BOOKS table...

BEGIN
    SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
        policy_name    => 'LIBRARY_POLICY',
        schema_name    => 'LIBRARY',
        table_name     => 'BOOKS',
        table_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL,LABEL_DEFAULT',
        label_function => NULL,
        predicate      => NULL
    );
    DBMS_OUTPUT.PUT_LINE('Policy applied to LIBRARY.BOOKS');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Apply Policy: ' || SQLERRM);
END;
/

-- ============================================
-- 9. CẬP NHẬT LABELS CHO DỮ LIỆU HIỆN CÓ
-- ============================================
PROMPT Updating labels for existing data...

BEGIN
    -- PUBLIC books
    UPDATE library.books 
    SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
    WHERE sensitivity_level = 'PUBLIC';
    
    -- INTERNAL books
    UPDATE library.books 
    SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB')
    WHERE sensitivity_level = 'INTERNAL';
    
    -- CONFIDENTIAL books
    UPDATE library.books 
    SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB')
    WHERE sensitivity_level = 'CONFIDENTIAL';
    
    -- TOP_SECRET books
    UPDATE library.books 
    SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ')
    WHERE sensitivity_level = 'TOP_SECRET';
    
    DBMS_OUTPUT.PUT_LINE('Data labels updated.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Update Labels: ' || SQLERRM);
END;
/

COMMIT;

PROMPT ============================================
PROMPT OLS Setup completed!
PROMPT ============================================
