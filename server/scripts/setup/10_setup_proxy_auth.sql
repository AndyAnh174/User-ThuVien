-- ============================================
-- SCRIPT 10: SETUP PROXY AUTHENTICATION
-- Chạy với SYS AS SYSDBA
-- Mục đích: Cho phép user LIBRARY kết nối thay mặt các user con (Proxy)
-- để OLS/VPD hoạt động đúng với connection pool.
-- ============================================

-- Kết nối PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

BEGIN
    -- Grant Connect Through cho các user có sẵn
    EXECUTE IMMEDIATE 'ALTER USER ADMIN_USER GRANT CONNECT THROUGH LIBRARY';
    EXECUTE IMMEDIATE 'ALTER USER LIBRARIAN_USER GRANT CONNECT THROUGH LIBRARY';
    EXECUTE IMMEDIATE 'ALTER USER STAFF_USER GRANT CONNECT THROUGH LIBRARY';
    EXECUTE IMMEDIATE 'ALTER USER READER_USER GRANT CONNECT THROUGH LIBRARY';
    
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error granting proxy: ' || SQLERRM);
END;
/

-- Kiểm tra
SELECT * FROM PROXY_USERS WHERE PROXY = 'LIBRARY';

PROMPT Proxy Authentication setup completed.
