-- ============================================
-- SCRIPT 09: FIX OLS PRIVILEGES & LABELS
-- Chạy với LBACSYS
-- Mục đích: Loại bỏ quyền READ (bypass) thừa thãi của Librarian/Staff
-- ============================================

-- Kết nối PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

BEGIN
    -- 1. FIX LIBRARIAN
    -- Trước đây lỡ cấp quyền 'READ' (Xem tất cả bất kể nhãn). Cần thu hồi về NULL.
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'LIBRARIAN_USER',
        privileges  => NULL 
    );
    
    -- Đảm bảo Label đúng (CONFIDENTIAL)
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name    => 'LIBRARY_POLICY',
        user_name      => 'LIBRARIAN_USER',
        max_read_label => 'CONF:LIB:HQ'
    );
    
    -- 2. FIX STAFF
    -- Đảm bảo không có quyền bypass
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'STAFF_USER',
        privileges  => NULL
    );
    
    -- Đảm bảo Label đúng (INTERNAL)
    SA_USER_ADMIN.SET_USER_LABELS(
        policy_name    => 'LIBRARY_POLICY',
        user_name      => 'STAFF_USER',
        max_read_label => 'INT:LIB:BR_A'
    );
    
    -- 3. FIX ADMIN (Giữ quyền FULL để quản lý)
    SA_USER_ADMIN.SET_USER_PRIVS(
        policy_name => 'LIBRARY_POLICY',
        user_name   => 'ADMIN_USER',
        privileges  => 'FULL,READ'
    );
END;
/

-- 4. UPDATE DATA LABELS (Đồng bộ lại lần nữa cho chắc)
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

COMMIT;

PROMPT Fix completed. Privileges revoked from Librarian/Staff.
