-- ============================================
-- SCRIPT 19: DATABASE VAULT REALMS & RULES
-- Chạy với SEC_ADMIN sau khi restart database
-- ============================================
-- Realm bảo vệ schema LIBRARY khỏi DBA
-- ============================================
-- NOTE: SEC_ADMIN cannot use ALTER SESSION SET CONTAINER
-- This script must be run while connected directly to PDB (FREEPDB1)
-- Connection: sec_admin/SecAdmin123@FREEPDB1

SET SERVEROUTPUT ON;

-- ============================================
-- 1. TẠO REALM BẢO VỆ SCHEMA LIBRARY
-- ============================================
PROMPT Creating Library Realm...

BEGIN
    -- Tạo Realm bảo vệ toàn bộ schema LIBRARY
    DVSYS.DBMS_MACADM.CREATE_REALM(
        realm_name        => 'LIBRARY_REALM',
        description       => 'Bảo vệ dữ liệu thư viện khỏi truy cập trái phép',
        enabled           => DVSYS.DBMS_MACUTL.G_YES,
        audit_options     => NULL, -- Unified Auditing is used
        realm_type        => 0  -- Regular realm
    );
    DBMS_OUTPUT.PUT_LINE('LIBRARY_REALM created successfully.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Realm Error: ' || SQLERRM);
END;
/

-- ============================================
-- 2. THÊM CÁC ĐỐI TƯỢNG VÀO REALM
-- ============================================
PROMPT Adding objects to realm...

BEGIN
    -- Check if LIBRARY schema exists
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM all_users WHERE username = 'LIBRARY';
        IF v_exists > 0 THEN
            -- Bảo vệ toàn bộ schema LIBRARY
            DVSYS.DBMS_MACADM.ADD_OBJECT_TO_REALM(
                realm_name   => 'LIBRARY_REALM',
                object_owner => 'LIBRARY',
                object_name  => '%',           -- Tất cả objects
                object_type  => '%'            -- Tất cả types
            );
            DBMS_OUTPUT.PUT_LINE('All LIBRARY objects added to realm.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('LIBRARY schema does not exist yet. Skipping object addition.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Add Object Check Error: ' || SQLERRM);
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Add Object Error: ' || SQLERRM);
END;
/

-- ============================================
-- 3. CẤP QUYỀN TRUY CẬP REALM CHO APPLICATION USERS
-- ============================================
PROMPT Authorizing users for realm access...

BEGIN
    -- Check and authorize users one by one
    DECLARE
        v_user_exists NUMBER;
    BEGIN
        -- LIBRARY user (schema owner) - Full access
        BEGIN
            SELECT COUNT(*) INTO v_user_exists FROM all_users WHERE username = 'LIBRARY';
            IF v_user_exists > 0 THEN
                DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                    realm_name   => 'LIBRARY_REALM',
                    grantee      => 'LIBRARY',
                    rule_set_name => NULL,
                    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_OWNER
                );
                DBMS_OUTPUT.PUT_LINE('LIBRARY authorized as owner.');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('LIBRARY auth error: ' || SQLERRM);
        END;
        
        -- ADMIN_USER - Participant
        BEGIN
            SELECT COUNT(*) INTO v_user_exists FROM all_users WHERE username = 'ADMIN_USER';
            IF v_user_exists > 0 THEN
                DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                    realm_name   => 'LIBRARY_REALM',
                    grantee      => 'ADMIN_USER',
                    rule_set_name => NULL,
                    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
                );
                DBMS_OUTPUT.PUT_LINE('ADMIN_USER authorized as participant.');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ADMIN_USER auth error: ' || SQLERRM);
        END;
        
        -- LIBRARIAN_USER - Participant
        BEGIN
            SELECT COUNT(*) INTO v_user_exists FROM all_users WHERE username = 'LIBRARIAN_USER';
            IF v_user_exists > 0 THEN
                DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                    realm_name   => 'LIBRARY_REALM',
                    grantee      => 'LIBRARIAN_USER',
                    rule_set_name => NULL,
                    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
                );
                DBMS_OUTPUT.PUT_LINE('LIBRARIAN_USER authorized as participant.');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('LIBRARIAN_USER auth error: ' || SQLERRM);
        END;
        
        -- STAFF_USER - Participant
        BEGIN
            SELECT COUNT(*) INTO v_user_exists FROM all_users WHERE username = 'STAFF_USER';
            IF v_user_exists > 0 THEN
                DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                    realm_name   => 'LIBRARY_REALM',
                    grantee      => 'STAFF_USER',
                    rule_set_name => NULL,
                    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
                );
                DBMS_OUTPUT.PUT_LINE('STAFF_USER authorized as participant.');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('STAFF_USER auth error: ' || SQLERRM);
        END;
        
        -- READER_USER - Participant
        BEGIN
            SELECT COUNT(*) INTO v_user_exists FROM all_users WHERE username = 'READER_USER';
            IF v_user_exists > 0 THEN
                DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                    realm_name   => 'LIBRARY_REALM',
                    grantee      => 'READER_USER',
                    rule_set_name => NULL,
                    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
                );
                DBMS_OUTPUT.PUT_LINE('READER_USER authorized as participant.');
            END IF;
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('READER_USER auth error: ' || SQLERRM);
        END;
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Auth Outer Error: ' || SQLERRM);
END;
/

-- ============================================
-- 4. TẠO COMMAND RULE NGĂN DBA DROP TABLE
-- ============================================
PROMPT Creating command rules...

BEGIN
    -- Check if LIBRARY schema exists before creating command rules
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM all_users WHERE username = 'LIBRARY';
        IF v_exists > 0 THEN
            -- Ngăn DROP TABLE trong schema LIBRARY
            DVSYS.DBMS_MACADM.CREATE_COMMAND_RULE(
                command         => 'DROP TABLE',
                rule_set_name   => 'Disabled',
                object_owner    => 'LIBRARY',
                object_name     => '%',
                enabled         => DVSYS.DBMS_MACUTL.G_YES
            );
            DBMS_OUTPUT.PUT_LINE('DROP TABLE rule created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('LIBRARY schema does not exist. Skipping DROP TABLE rule.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('DROP TABLE Rule Check Error: ' || SQLERRM);
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Command Rule Error: ' || SQLERRM);
END;
/

BEGIN
    -- Check if LIBRARY schema exists before creating command rules
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM all_users WHERE username = 'LIBRARY';
        IF v_exists > 0 THEN
            -- Ngăn TRUNCATE TABLE trong schema LIBRARY
            DVSYS.DBMS_MACADM.CREATE_COMMAND_RULE(
                command         => 'TRUNCATE TABLE',
                rule_set_name   => 'Disabled',
                object_owner    => 'LIBRARY',
                object_name     => '%',
                enabled         => DVSYS.DBMS_MACUTL.G_YES
            );
            DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE rule created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('LIBRARY schema does not exist. Skipping TRUNCATE TABLE rule.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE Rule Check Error: ' || SQLERRM);
    END;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Command Rule Error: ' || SQLERRM);
END;
/

-- ============================================
-- 5. KIỂM TRA CẤU HÌNH
-- ============================================
PROMPT Checking Database Vault configuration...

SELECT NAME, ENABLED FROM DVSYS.DBA_DV_REALM WHERE NAME = 'LIBRARY_REALM';
SELECT GRANTEE, AUTH_OPTIONS FROM DVSYS.DBA_DV_REALM_AUTH WHERE REALM_NAME = 'LIBRARY_REALM';

COMMIT;

PROMPT ============================================
PROMPT Database Vault setup completed!
PROMPT DBA (SYS) now CANNOT access LIBRARY data
PROMPT Only authorized users can access the realm
PROMPT ============================================
