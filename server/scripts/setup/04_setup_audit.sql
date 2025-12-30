-- ============================================
-- SCRIPT 04: UNIFIED AUDITING (Oracle 23ai)
-- Chạy với SYS AS SYSDBA
-- ============================================
-- Oracle 23ai chỉ hỗ trợ Unified Auditing
-- Traditional AUDIT đã bị deprecated
-- ============================================

-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON;

-- ============================================
-- 1. TẠO AUDIT POLICY CHO LOGIN/LOGOUT
-- ============================================
PROMPT Creating login audit policy...

CREATE AUDIT POLICY library_login_policy
    ACTIONS LOGON, LOGOFF;

AUDIT POLICY library_login_policy;

-- ============================================
-- 2. TẠO AUDIT POLICY CHO USER MANAGEMENT
-- ============================================
PROMPT Creating user management audit policy...

CREATE AUDIT POLICY library_user_mgmt_policy
    PRIVILEGES CREATE USER, ALTER USER, DROP USER,
               CREATE ROLE, ALTER ANY ROLE, DROP ANY ROLE,
               GRANT ANY ROLE, GRANT ANY PRIVILEGE;

AUDIT POLICY library_user_mgmt_policy;

-- ============================================
-- 3. TẠO AUDIT POLICY CHO DỮ LIỆU NHẠY CẢM
-- ============================================
PROMPT Creating sensitive data audit policy...

CREATE AUDIT POLICY library_sensitive_data_policy
    ACTIONS SELECT ON LIBRARY.BOOKS,
            INSERT ON LIBRARY.BOOKS,
            UPDATE ON LIBRARY.BOOKS,
            DELETE ON LIBRARY.BOOKS,
            SELECT ON LIBRARY.USER_INFO,
            UPDATE ON LIBRARY.USER_INFO,
            DELETE ON LIBRARY.USER_INFO,
            SELECT ON LIBRARY.BORROW_HISTORY,
            INSERT ON LIBRARY.BORROW_HISTORY,
            UPDATE ON LIBRARY.BORROW_HISTORY,
            DELETE ON LIBRARY.BORROW_HISTORY;

AUDIT POLICY library_sensitive_data_policy;

-- ============================================
-- 4. TẠO AUDIT POLICY CHO DDL
-- ============================================
PROMPT Creating DDL audit policy...

CREATE AUDIT POLICY library_ddl_policy
    ACTIONS CREATE TABLE, ALTER TABLE, DROP TABLE,
            TRUNCATE TABLE, CREATE VIEW, DROP VIEW;

AUDIT POLICY library_ddl_policy;

-- ============================================
-- 5. TẠO AUDIT POLICY CHO PRIVILEGE ABUSE
-- ============================================
PROMPT Creating privilege abuse audit policy...

CREATE AUDIT POLICY library_priv_abuse_policy
    PRIVILEGES SELECT ANY TABLE, DELETE ANY TABLE, 
               DROP ANY TABLE, ALTER ANY TABLE,
               EXEMPT ACCESS POLICY;

AUDIT POLICY library_priv_abuse_policy;

-- ============================================
-- 6. TẠO VIEW ĐỂ XEM AUDIT TRAIL (Unified)
-- ============================================
PROMPT Creating audit views...

-- View tổng hợp audit
CREATE OR REPLACE VIEW library.v_audit_trail AS
SELECT 
    event_timestamp,
    dbusername AS username,
    action_name,
    object_schema,
    object_name,
    sql_text,
    return_code,
    unified_audit_policies
FROM unified_audit_trail
WHERE object_schema = 'LIBRARY' 
   OR dbusername IN ('ADMIN_USER', 'LIBRARIAN_USER', 'STAFF_USER', 'READER_USER', 'LIBRARY')
ORDER BY event_timestamp DESC;

GRANT SELECT ON library.v_audit_trail TO admin_role;

-- View audit theo user
CREATE OR REPLACE VIEW library.v_audit_by_user AS
SELECT 
    dbusername AS username,
    action_name,
    COUNT(*) AS action_count,
    MAX(event_timestamp) AS last_action
FROM unified_audit_trail
WHERE object_schema = 'LIBRARY'
GROUP BY dbusername, action_name
ORDER BY dbusername, action_count DESC;

GRANT SELECT ON library.v_audit_by_user TO admin_role;

-- View login failures
CREATE OR REPLACE VIEW library.v_failed_logins AS
SELECT 
    event_timestamp,
    dbusername AS username,
    os_username,
    userhost AS client_host,
    return_code,
    unified_audit_policies
FROM unified_audit_trail
WHERE action_name = 'LOGON'
  AND return_code != 0
ORDER BY event_timestamp DESC;

GRANT SELECT ON library.v_failed_logins TO admin_role;

-- ============================================
-- 7. KIỂM TRA AUDIT POLICIES ĐÃ TẠO
-- ============================================
PROMPT Checking audit policies...

SELECT policy_name, enabled_option 
FROM audit_unified_enabled_policies 
WHERE policy_name LIKE 'LIBRARY%';

COMMIT;

PROMPT ============================================
PROMPT Unified Auditing setup completed!
PROMPT View audit data: SELECT * FROM unified_audit_trail;
PROMPT ============================================
