-- ============================================
-- SCRIPT 04: THIẾT LẬP STANDARD AUDITING
-- Chạy với SYS AS SYSDBA
-- ============================================

-- Kết nối: CONN sys/Oracle123@THUVIEN_PDB AS SYSDBA

ALTER SESSION SET CONTAINER = FREEPDB1;

-- ============================================
-- 1. BẬT AUDITING (nếu chưa bật)
-- ============================================
-- Kiểm tra trạng thái audit
-- SHOW PARAMETER audit_trail;

-- Nếu audit_trail = NONE, cần chạy (cần restart DB):
-- ALTER SYSTEM SET audit_trail = DB SCOPE = SPFILE;

-- ============================================
-- 2. AUDIT SESSION (Đăng nhập/Đăng xuất)
-- ============================================

-- Giám sát tất cả các lần đăng nhập
AUDIT CREATE SESSION BY ACCESS;

-- Giám sát đăng nhập thất bại
AUDIT CREATE SESSION WHENEVER NOT SUCCESSFUL;

-- ============================================
-- 3. AUDIT QUẢN LÝ USER
-- ============================================

-- Giám sát tạo/sửa/xóa user
AUDIT CREATE USER BY ACCESS;
AUDIT ALTER USER BY ACCESS;
AUDIT DROP USER BY ACCESS;

-- Giám sát quản lý role
AUDIT CREATE ROLE BY ACCESS;
AUDIT ALTER ANY ROLE BY ACCESS;
AUDIT DROP ANY ROLE BY ACCESS;
AUDIT GRANT ANY ROLE BY ACCESS;

-- Giám sát quản lý profile
AUDIT CREATE PROFILE BY ACCESS;
AUDIT ALTER PROFILE BY ACCESS;
AUDIT DROP PROFILE BY ACCESS;

-- ============================================
-- 4. AUDIT TRÊN CÁC BẢNG NHẠY CẢM
-- ============================================

-- Giám sát bảng USER_INFO
AUDIT SELECT ON library.user_info BY ACCESS;
AUDIT INSERT ON library.user_info BY ACCESS;
AUDIT UPDATE ON library.user_info BY ACCESS;
AUDIT DELETE ON library.user_info BY ACCESS;

-- Giám sát bảng BOOKS
AUDIT SELECT ON library.books BY ACCESS;
AUDIT INSERT ON library.books BY ACCESS;
AUDIT UPDATE ON library.books BY ACCESS;
AUDIT DELETE ON library.books BY ACCESS;

-- Giám sát bảng BORROW_HISTORY
AUDIT INSERT ON library.borrow_history BY ACCESS;
AUDIT UPDATE ON library.borrow_history BY ACCESS;
AUDIT DELETE ON library.borrow_history BY ACCESS;

-- ============================================
-- 5. AUDIT QUYỀN HỆ THỐNG QUAN TRỌNG
-- ============================================

-- Giám sát sử dụng quyền nguy hiểm
AUDIT SELECT ANY TABLE BY ACCESS;
AUDIT DELETE ANY TABLE BY ACCESS;
AUDIT DROP ANY TABLE BY ACCESS;
AUDIT ALTER ANY TABLE BY ACCESS;

-- Giám sát GRANT/REVOKE
AUDIT GRANT ANY PRIVILEGE BY ACCESS;
AUDIT GRANT ANY OBJECT PRIVILEGE BY ACCESS;

-- ============================================
-- 6. AUDIT EXEMPT ACCESS POLICY (VPD bypass)
-- ============================================
AUDIT EXEMPT ACCESS POLICY BY ACCESS;

-- ============================================
-- 7. TẠO VIEW ĐỂ XEM AUDIT TRAIL DỄ DÀNG
-- ============================================

CREATE OR REPLACE VIEW library.v_audit_trail AS
SELECT 
    username AS "User",
    action_name AS "Action",
    obj_name AS "Object",
    TO_CHAR(timestamp, 'DD/MM/YYYY HH24:MI:SS') AS "Time",
    CASE returncode
        WHEN 0 THEN 'SUCCESS'
        ELSE 'FAILED (' || returncode || ')'
    END AS "Result",
    priv_used AS "Privilege Used",
    terminal AS "Terminal",
    os_username AS "OS User"
FROM dba_audit_trail
ORDER BY timestamp DESC;

GRANT SELECT ON library.v_audit_trail TO admin_role;

-- ============================================
-- 8. TẠO VIEW XEM AUDIT THEO USER CỤ THỂ
-- ============================================

CREATE OR REPLACE VIEW library.v_audit_by_user AS
SELECT 
    username,
    action_name,
    COUNT(*) AS action_count,
    MAX(timestamp) AS last_action
FROM dba_audit_trail
GROUP BY username, action_name
ORDER BY username, action_count DESC;

GRANT SELECT ON library.v_audit_by_user TO admin_role;

-- ============================================
-- 9. TẠO VIEW XEM ĐĂNG NHẬP THẤT BẠI
-- ============================================

CREATE OR REPLACE VIEW library.v_failed_logins AS
SELECT 
    username,
    terminal,
    os_username,
    TO_CHAR(timestamp, 'DD/MM/YYYY HH24:MI:SS') AS "Time",
    returncode AS error_code
FROM dba_audit_trail
WHERE action_name = 'LOGON'
AND returncode != 0
ORDER BY timestamp DESC;

GRANT SELECT ON library.v_failed_logins TO admin_role;

-- ============================================
-- LOG COMPLETION
-- ============================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Script 04 completed successfully!');
    DBMS_OUTPUT.PUT_LINE('Enabled auditing for:');
    DBMS_OUTPUT.PUT_LINE('  - Sessions (login/logout)');
    DBMS_OUTPUT.PUT_LINE('  - User management (CREATE/ALTER/DROP USER)');
    DBMS_OUTPUT.PUT_LINE('  - Role management');
    DBMS_OUTPUT.PUT_LINE('  - Profile management');
    DBMS_OUTPUT.PUT_LINE('  - Tables: user_info, books, borrow_history');
    DBMS_OUTPUT.PUT_LINE('  - Dangerous privileges');
    DBMS_OUTPUT.PUT_LINE('Created views:');
    DBMS_OUTPUT.PUT_LINE('  - v_audit_trail');
    DBMS_OUTPUT.PUT_LINE('  - v_audit_by_user');
    DBMS_OUTPUT.PUT_LINE('  - v_failed_logins');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

COMMIT;
