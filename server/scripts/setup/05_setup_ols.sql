-- ============================================
-- SCRIPT 05: THIẾT LẬP ORACLE LABEL SECURITY (OLS)
-- Thực hiện MAC (Mandatory Access Control)
-- Chạy với LBACSYS hoặc user có quyền OLS
-- ============================================

-- ============================================
-- BƯỚC 1: KIỂM TRA VÀ KÍCH HOẠT OLS
-- (Chạy với SYS AS SYSDBA)
-- ============================================

-- Kiểm tra OLS đã được cài đặt chưa
-- SELECT * FROM DBA_REGISTRY WHERE COMP_NAME LIKE '%Label%';

-- Nếu chưa cài, chạy:
-- @?/rdbms/admin/catols.sql

-- Mở khóa tài khoản LBACSYS
ALTER USER lbacsys ACCOUNT UNLOCK;
ALTER USER lbacsys IDENTIFIED BY "Lbacsys#123";

-- Kết nối vào PDB
ALTER SESSION SET CONTAINER = THUVIEN_PDB;

-- ============================================
-- BƯỚC 2: TẠO POLICY OLS
-- (Chạy với LBACSYS)
-- ============================================

-- Kết nối: CONN lbacsys/Lbacsys#123@THUVIEN_PDB

BEGIN
    -- Tạo policy cho thư viện
    SA_SYSDBA.CREATE_POLICY(
        policy_name      => 'LIBRARY_POLICY',
        column_name      => 'OLS_LABEL',
        default_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL'
    );
END;
/

-- ============================================
-- BƯỚC 3: TẠO CÁC LEVELS (Mức độ nhạy cảm)
-- ============================================

BEGIN
    -- Level 1: PUBLIC - Công khai
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 1000,
        short_name   => 'PUB',
        long_name    => 'PUBLIC'
    );
    
    -- Level 2: INTERNAL - Nội bộ
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 2000,
        short_name   => 'INT',
        long_name    => 'INTERNAL'
    );
    
    -- Level 3: CONFIDENTIAL - Bí mật
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 3000,
        short_name   => 'CONF',
        long_name    => 'CONFIDENTIAL'
    );
    
    -- Level 4: TOP_SECRET - Tối mật
    SA_COMPONENTS.CREATE_LEVEL(
        policy_name  => 'LIBRARY_POLICY',
        level_num    => 4000,
        short_name   => 'TS',
        long_name    => 'TOP_SECRET'
    );
END;
/

-- ============================================
-- BƯỚC 4: TẠO CÁC COMPARTMENTS (Lĩnh vực)
-- ============================================

BEGIN
    -- Compartment: LIBRARY - Thư viện
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 100,
        short_name   => 'LIB',
        long_name    => 'LIBRARY'
    );
    
    -- Compartment: HR - Nhân sự
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 200,
        short_name   => 'HR',
        long_name    => 'HUMAN_RESOURCES'
    );
    
    -- Compartment: FIN - Tài chính
    SA_COMPONENTS.CREATE_COMPARTMENT(
        policy_name  => 'LIBRARY_POLICY',
        comp_num     => 300,
        short_name   => 'FIN',
        long_name    => 'FINANCE'
    );
END;
/

-- ============================================
-- BƯỚC 5: TẠO CÁC GROUPS (Chi nhánh)
-- ============================================

BEGIN
    -- Group: HQ - Trụ sở chính
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 10,
        short_name   => 'HQ',
        long_name    => 'HEADQUARTERS',
        parent_name  => NULL
    );
    
    -- Group: BR_A - Chi nhánh A (thuộc HQ)
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 20,
        short_name   => 'BR_A',
        long_name    => 'BRANCH_A',
        parent_name  => 'HQ'
    );
    
    -- Group: BR_B - Chi nhánh B (thuộc HQ)
    SA_COMPONENTS.CREATE_GROUP(
        policy_name  => 'LIBRARY_POLICY',
        group_num    => 30,
        short_name   => 'BR_B',
        long_name    => 'BRANCH_B',
        parent_name  => 'HQ'
    );
END;
/

-- ============================================
-- BƯỚC 6: TẠO CÁC LABELS
-- ============================================

BEGIN
    -- Label cho dữ liệu PUBLIC
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 1000,
        label_value  => 'PUB'
    );
    
    -- Label cho dữ liệu INTERNAL trong thư viện
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 2100,
        label_value  => 'INT:LIB'
    );
    
    -- Label cho dữ liệu CONFIDENTIAL trong thư viện
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 3100,
        label_value  => 'CONF:LIB'
    );
    
    -- Label cho dữ liệu CONFIDENTIAL trong HR
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 3200,
        label_value  => 'CONF:HR'
    );
    
    -- Label cho dữ liệu TOP_SECRET
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 4000,
        label_value  => 'TS:LIB,HR,FIN:HQ'
    );
    
    -- Labels cho các chi nhánh
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 2120,
        label_value  => 'INT:LIB:BR_A'
    );
    
    SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name  => 'LIBRARY_POLICY',
        label_tag    => 2130,
        label_value  => 'INT:LIB:BR_B'
    );
END;
/

-- ============================================
-- BƯỚC 7: GÁN LABELS CHO USERS
-- ============================================

BEGIN
    -- ADMIN_USER: Full access (TOP_SECRET, tất cả compartments, HQ)
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name   => 'LIBRARY_POLICY',
        user_name     => 'ADMIN_USER',
        max_read_label => 'TS:LIB,HR,FIN:HQ'
    );
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'ADMIN_USER',
        privileges  => 'FULL,READ'
    );
    
    -- LIBRARIAN_USER: CONFIDENTIAL, LIBRARY compartment, tất cả branches
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name    => 'LIBRARY_POLICY',
        user_name      => 'LIBRARIAN_USER',
        max_read_label => 'CONF:LIB:HQ'
    );
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'LIBRARIAN_USER',
        privileges  => 'READ'
    );
    
    -- STAFF_USER: INTERNAL, LIBRARY compartment, Branch A only
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name    => 'LIBRARY_POLICY',
        user_name      => 'STAFF_USER',
        max_read_label => 'INT:LIB:BR_A'
    );
    
    -- READER_USER: PUBLIC only
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name    => 'LIBRARY_POLICY',
        user_name      => 'READER_USER',
        max_read_label => 'PUB'
    );
END;
/

-- ============================================
-- BƯỚC 8: ÁP DỤNG POLICY CHO BẢNG BOOKS
-- ============================================

-- Thêm cột OLS_LABEL vào bảng books (nếu chưa có)
-- ALTER TABLE library.books ADD (ols_label NUMBER);

BEGIN
    -- Áp dụng policy cho bảng BOOKS
    SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
        policy_name    => 'LIBRARY_POLICY',
        schema_name    => 'LIBRARY',
        table_name     => 'BOOKS',
        table_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL',
        label_function => NULL,
        predicate      => NULL
    );
END;
/

-- ============================================
-- BƯỚC 9: ÁP DỤNG POLICY CHO BẢNG USER_INFO
-- ============================================

BEGIN
    SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
        policy_name    => 'LIBRARY_POLICY',
        schema_name    => 'LIBRARY',
        table_name     => 'USER_INFO',
        table_options  => 'READ_CONTROL,CHECK_CONTROL',
        label_function => NULL,
        predicate      => NULL
    );
END;
/

-- ============================================
-- BƯỚC 10: GÁN LABELS CHO DỮ LIỆU MẪU
-- ============================================

-- Cập nhật labels cho sách
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
WHERE sensitivity_level = 'PUBLIC';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB')
WHERE sensitivity_level = 'INTERNAL';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB')
WHERE sensitivity_level = 'CONFIDENTIAL';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ')
WHERE sensitivity_level = 'TOP_SECRET';

-- Cập nhật labels cho user_info
UPDATE library.user_info
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ')
WHERE user_type = 'ADMIN';

UPDATE library.user_info
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB')
WHERE user_type = 'LIBRARIAN';

UPDATE library.user_info
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB')
WHERE user_type = 'STAFF';

UPDATE library.user_info
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
WHERE user_type = 'READER';

COMMIT;

-- ============================================
-- BƯỚC 11: CẤP QUYỀN CHO LIB_ADMIN
-- ============================================

-- Cấp quyền quản lý OLS cho LIB_ADMIN
GRANT EXECUTE ON sa_components TO lib_admin;
GRANT EXECUTE ON sa_label_admin TO lib_admin;
GRANT EXECUTE ON sa_user_admin TO lib_admin;
GRANT EXECUTE ON sa_policy_admin TO lib_admin;

-- Cấp quyền policy admin
GRANT LIBRARY_POLICY_DBA TO lib_admin;

-- ============================================
-- LOG COMPLETION
-- ============================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Script 05 - OLS Setup completed!');
    DBMS_OUTPUT.PUT_LINE('Created:');
    DBMS_OUTPUT.PUT_LINE('  - Policy: LIBRARY_POLICY');
    DBMS_OUTPUT.PUT_LINE('  - Levels: PUBLIC, INTERNAL, CONFIDENTIAL, TOP_SECRET');
    DBMS_OUTPUT.PUT_LINE('  - Compartments: LIBRARY, HR, FINANCE');
    DBMS_OUTPUT.PUT_LINE('  - Groups: HQ, BRANCH_A, BRANCH_B');
    DBMS_OUTPUT.PUT_LINE('Applied to tables:');
    DBMS_OUTPUT.PUT_LINE('  - LIBRARY.BOOKS');
    DBMS_OUTPUT.PUT_LINE('  - LIBRARY.USER_INFO');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/
