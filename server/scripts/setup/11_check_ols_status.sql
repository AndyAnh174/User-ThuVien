-- ============================================
-- SCRIPT 11: CHECK OLS CONFIGURATION
-- Chạy với SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

SET LINESIZE 200
SET PAGESIZE 100
COL USER_NAME FORMAT A20
COL MAX_READ_LABEL FORMAT A20
COL MAX_WRITE_LABEL FORMAT A20
COL PRIVILEGES FORMAT A20
COL PROXY FORMAT A20
COL CLIENT FORMAT A20
COL LABEL_VAL FORMAT A40

PROMPT ======================================
PROMPT 1. CHECK PROXY USERS
PROMPT ======================================
SELECT * FROM PROXY_USERS WHERE PROXY = 'LIBRARY';

PROMPT ======================================
PROMPT 2. CHECK OLS DATA LABELS
PROMPT ======================================
-- Note: Must access as table owner or authorized user to see hidden column
SELECT book_id, sensitivity_level, 
       ols_label as raw_label, 
       char_to_label('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ') as ts_val
FROM library.books
WHERE sensitivity_level = 'TOP_SECRET'
FETCH FIRST 5 ROWS ONLY;

PROMPT ======================================
PROMPT 3. CHECK USER LABELS AND PRIVS
PROMPT ======================================
SELECT USER_NAME, MAX_READ_LABEL, PRIVILEGES
FROM DBA_SA_USERS 
WHERE USER_NAME IN ('LIBRARIAN_USER', 'STAFF_USER', 'ADMIN_USER', 'LIBRARY');

PROMPT ======================================
PROMPT 4. CHECK USER SYSTEM PRIVILEGES
PROMPT ======================================
SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS 
WHERE GRANTEE IN ('LIBRARIAN_USER', 'STAFF_USER', 'LIBRARY');

EXIT;
