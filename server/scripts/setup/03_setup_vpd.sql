-- ============================================
-- SCRIPT 03: THIẾT LẬP VPD (Virtual Private Database)
-- Chạy với SYS hoặc user có quyền DBMS_RLS
-- ============================================

-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- ============================================
-- 1. POLICY FUNCTION: Reader chỉ thấy lịch sử mượn của mình
-- ============================================
CREATE OR REPLACE FUNCTION library.vpd_borrow_history_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
BEGIN
    -- Bỏ qua policy cho các user quản trị
    IF v_user IN ('SYS', 'SYSTEM', 'LIB_PROJECT', 'LIB_ADMIN', 'LIBRARY', 'ADMIN_USER') THEN
        RETURN NULL; -- Không filter = thấy hết
    END IF;
    
    -- Kiểm tra loại user
    BEGIN
        SELECT user_type INTO v_user_type
        FROM library.user_info
        WHERE UPPER(oracle_username) = UPPER(v_user);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '1=0'; -- Không tìm thấy user -> không thấy gì
    END;
    
    -- ADMIN và LIBRARIAN thấy hết
    IF v_user_type IN ('ADMIN', 'LIBRARIAN') THEN
        RETURN NULL;
    END IF;
    
    -- STAFF chỉ thấy của chi nhánh mình
    IF v_user_type = 'STAFF' THEN
        RETURN 'user_id IN (SELECT user_id FROM library.user_info WHERE branch_id = (SELECT branch_id FROM library.user_info WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER''))))';
    END IF;
    
    -- READER chỉ thấy của chính mình
    IF v_user_type = 'READER' THEN
        RETURN 'user_id = (SELECT user_id FROM library.user_info WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER'')))';
    END IF;
    
    -- Mặc định: không thấy gì
    RETURN '1=0';
END;
/

-- ============================================
-- 2. POLICY FUNCTION: Staff chỉ thấy user cùng chi nhánh
-- ============================================
CREATE OR REPLACE FUNCTION library.vpd_user_info_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
BEGIN
    -- Bỏ qua policy cho các user quản trị
    IF v_user IN ('SYS', 'SYSTEM', 'LIB_PROJECT', 'LIB_ADMIN', 'LIBRARY', 'ADMIN_USER') THEN
        RETURN NULL;
    END IF;
    
    -- Kiểm tra loại user
    BEGIN
        SELECT user_type INTO v_user_type
        FROM library.user_info
        WHERE UPPER(oracle_username) = UPPER(v_user);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '1=0';
    END;
    
    -- ADMIN và LIBRARIAN thấy hết
    IF v_user_type IN ('ADMIN', 'LIBRARIAN') THEN
        RETURN NULL;
    END IF;
    
    -- STAFF chỉ thấy user cùng chi nhánh
    IF v_user_type = 'STAFF' THEN
        RETURN 'branch_id = (SELECT branch_id FROM library.user_info WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER'')))';
    END IF;
    
    -- READER chỉ thấy thông tin của chính mình
    IF v_user_type = 'READER' THEN
        RETURN 'UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER''))';
    END IF;
    
    RETURN '1=0';
END;
/

-- ============================================
-- 3. POLICY FUNCTION: Sách theo chi nhánh (VPD)
-- OLS sẽ xử lý phần sensitivity level
-- ============================================
CREATE OR REPLACE FUNCTION library.vpd_books_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
    v_branch_id NUMBER;
BEGIN
    -- Bỏ qua policy cho các user quản trị
    IF v_user IN ('SYS', 'SYSTEM', 'LIB_PROJECT', 'LIB_ADMIN', 'LIBRARY') THEN
        RETURN NULL;
    END IF;
    
    -- Kiểm tra loại user và chi nhánh
    BEGIN
        SELECT user_type, branch_id 
        INTO v_user_type, v_branch_id
        FROM library.user_info
        WHERE UPPER(oracle_username) = UPPER(v_user);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '1=0'; -- Không tìm thấy user -> không thấy gì
    END;
    
    -- ADMIN: Thấy tất cả
    IF v_user_type = 'ADMIN' THEN
        RETURN NULL;
    END IF;
    
    -- LIBRARIAN: Thấy sách của chi nhánh mình + Trụ sở chính (branch_id = 1)
    IF v_user_type = 'LIBRARIAN' THEN
        IF v_branch_id IS NULL THEN
            RETURN 'branch_id = 1'; -- Chỉ thấy HQ
        ELSIF v_branch_id = 1 THEN
            RETURN NULL; -- Nếu ở HQ thì thấy tất cả
        ELSE
            RETURN 'branch_id IN (1, ' || v_branch_id || ')';
        END IF;
    END IF;
    
    -- STAFF: Chỉ thấy sách của chi nhánh mình
    IF v_user_type = 'STAFF' THEN
        IF v_branch_id IS NULL THEN
            RETURN '1=0'; -- Không có chi nhánh -> không thấy gì
        ELSE
            RETURN 'branch_id = ' || v_branch_id;
        END IF;
    END IF;
    
    -- READER: Thấy tất cả sách (OLS sẽ filter theo sensitivity)
    IF v_user_type = 'READER' THEN
        RETURN NULL;
    END IF;
    
    -- Mặc định: không thấy gì
    RETURN '1=0';
END;
/

-- ============================================
-- 4. GÁN POLICY CHO BẢNG BOOKS
-- ============================================

-- Drop policy cũ nếu có
BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BOOKS', 'VPD_BOOKS_BRANCH');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BOOKS', 'VPD_BOOKS');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Policy cho BOOKS (theo chi nhánh)
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BOOKS',
        policy_name     => 'VPD_BOOKS_BRANCH',
        function_schema => 'LIBRARY',
        policy_function => 'VPD_BOOKS_POLICY',
        statement_types => 'SELECT',
        update_check    => FALSE
    );
END;
/

-- NOTE: VPD cho USER_INFO và BORROW_HISTORY bị bỏ để tránh xung đột
-- Nếu cần, có thể enable lại sau khi test kỹ

-- ============================================
-- 5. THIẾT LẬP FINE-GRAINED AUDITING (FGA)
-- ============================================

-- FGA cho việc xem thông tin nhạy cảm
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'USER_INFO',
        policy_name     => 'FGA_USER_INFO_SELECT',
        audit_condition => 'sensitivity_level IN (''CONFIDENTIAL'', ''TOP_SECRET'')',
        audit_column    => 'email,phone,address',
        statement_types => 'SELECT'
    );
END;
/

-- FGA cho việc sửa/xóa sách
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BOOKS',
        policy_name     => 'FGA_BOOKS_MODIFY',
        statement_types => 'UPDATE,DELETE'
    );
END;
/

-- FGA cho mượn/trả sách
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BORROW_HISTORY',
        policy_name     => 'FGA_BORROW_ALL',
        statement_types => 'INSERT,UPDATE,DELETE'
    );
END;
/

-- ============================================
-- LOG COMPLETION
-- ============================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Script 03 completed successfully!');
    DBMS_OUTPUT.PUT_LINE('Created VPD policies:');
    DBMS_OUTPUT.PUT_LINE('  - VPD_BORROW_HISTORY');
    DBMS_OUTPUT.PUT_LINE('  - VPD_USER_INFO');
    DBMS_OUTPUT.PUT_LINE('  - VPD_BOOKS');
    DBMS_OUTPUT.PUT_LINE('Created FGA policies:');
    DBMS_OUTPUT.PUT_LINE('  - FGA_USER_INFO_SELECT');
    DBMS_OUTPUT.PUT_LINE('  - FGA_BOOKS_MODIFY');
    DBMS_OUTPUT.PUT_LINE('  - FGA_BORROW_ALL');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

COMMIT;
