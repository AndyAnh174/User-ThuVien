ALTER SESSION SET CONTAINER = FREEPDB1;

-- Cấp quyền User Management cho user 'library' (User mà Backend dùng để kết nối)
GRANT CREATE USER TO library;
GRANT DROP USER TO library;
GRANT ALTER USER TO library;
GRANT GRANT ANY ROLE TO library;
GRANT GRANT ANY PRIVILEGE TO library;
GRANT SELECT ANY DICTIONARY TO library;

-- Cấp quyền Audit cho user 'library'
GRANT AUDIT SYSTEM TO library;
GRANT AUDIT ANY TO library;
-- UNIFIED_AUDIT_TRAIL thuộc về user AUDSYS hoặc SYS, cần grant select
GRANT SELECT ON SYS.UNIFIED_AUDIT_TRAIL TO library;
-- Nếu dùng view DBA_AUDIT_TRAIL cũ
GRANT SELECT ANY TABLE TO library;

-- Đảm bảo library có thể thao tác trên tablespace
GRANT UNLIMITED TABLESPACE TO library WITH ADMIN OPTION;

COMMIT;
SELECT 'Library privileges granted successfully!' FROM DUAL;
EXIT;
