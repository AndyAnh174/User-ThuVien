-- ============================================
-- SCRIPT 03: THIẾT LẬP VPD (Virtual Private Database)
-- Chạy với user LIB_PROJECT
-- ============================================

-- Kết nối: CONN lib_project/LibProject#123@THUVIEN_PDB

-- ============================================
-- 1. POLICY FUNCTION: Reader chỉ thấy lịch sử mượn của mình
-- ============================================
CREATE OR REPLACE FUNCTION vpd_borrow_history_policy (
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
CREATE OR REPLACE FUNCTION vpd_user_info_policy (
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
-- 3. POLICY FUNCTION: Sách theo mức độ nhạy cảm
-- ============================================
CREATE OR REPLACE FUNCTION vpd_books_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
    v_sensitivity VARCHAR2(20);
BEGIN
    -- Bỏ qua policy cho các user quản trị
    IF v_user IN ('SYS', 'SYSTEM', 'LIB_PROJECT', 'LIB_ADMIN', 'LIBRARY') THEN
        RETURN NULL;
    END IF;
    
    -- Kiểm tra loại user và mức độ nhạy cảm
    BEGIN
        SELECT user_type, sensitivity_level INTO v_user_type, v_sensitivity
        FROM library.user_info
        WHERE UPPER(oracle_username) = UPPER(v_user);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'sensitivity_level = ''PUBLIC'''; -- Chỉ thấy sách công khai
    END;
    
    -- Xác định sách được phép xem dựa trên sensitivity level
    IF v_sensitivity = 'TOP_SECRET' THEN
        RETURN NULL; -- Thấy hết
    ELSIF v_sensitivity = 'CONFIDENTIAL' THEN
        RETURN 'sensitivity_level IN (''PUBLIC'', ''INTERNAL'', ''CONFIDENTIAL'')';
    ELSIF v_sensitivity = 'INTERNAL' THEN
        RETURN 'sensitivity_level IN (''PUBLIC'', ''INTERNAL'')';
    ELSE
        RETURN 'sensitivity_level = ''PUBLIC'''; -- PUBLIC chỉ thấy sách PUBLIC
    END IF;
END;
/

-- ============================================
-- 4. GÁN CÁC POLICIES CHO BẢNG
-- ============================================

-- Cần chạy với user có quyền EXECUTE ON DBMS_RLS
-- Thường là SYS hoặc user được cấp quyền

-- Policy cho BORROW_HISTORY
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BORROW_HISTORY',
        policy_name     => 'VPD_BORROW_HISTORY',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_BORROW_HISTORY_POLICY',
        statement_types => 'SELECT,UPDATE,DELETE',
        update_check    => TRUE
    );
END;
/

-- Policy cho USER_INFO
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'USER_INFO',
        policy_name     => 'VPD_USER_INFO',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_USER_INFO_POLICY',
        statement_types => 'SELECT,UPDATE,DELETE',
        update_check    => TRUE
    );
END;
/

-- Policy cho BOOKS (theo sensitivity level - đây là VPD đơn giản, MAC sẽ dùng OLS)
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BOOKS',
        policy_name     => 'VPD_BOOKS',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_BOOKS_POLICY',
        statement_types => 'SELECT',
        update_check    => FALSE
    );
END;
/

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
