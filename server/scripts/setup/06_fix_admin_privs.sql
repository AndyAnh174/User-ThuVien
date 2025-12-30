-- ============================================
-- SCRIPT 06: CẤP QUYỀN TẠO USER CHO ADMIN
-- Chạy với SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

-- 1. Cấp quyền cho ADMIN_ROLE (Best practice)
GRANT CREATE USER TO admin_role;
GRANT DROP USER TO admin_role;
GRANT ALTER USER TO admin_role;
GRANT GRANT ANY ROLE TO admin_role;
GRANT GRANT ANY PRIVILEGE TO admin_role;
GRANT SELECT ANY DICTIONARY TO admin_role;

-- 2. Cấp quyền trực tiếp cho ADMIN_USER (Để đảm bảo chắc chắn hoạt động)
GRANT CREATE USER TO admin_user;
GRANT DROP USER TO admin_user;
GRANT ALTER USER TO admin_user;
GRANT GRANT ANY ROLE TO admin_user;
GRANT GRANT ANY PRIVILEGE TO admin_user;
GRANT SELECT ANY DICTIONARY TO admin_user;

-- 3. Cấp thêm Quota nếu cần tạo object trong schema khác (không bắt buộc với create user)
-- GRANT UNLIMITED TABLESPACE TO admin_user;

COMMIT;

SELECT 'Admin privileges granted successfully!' FROM DUAL;
EXIT;
