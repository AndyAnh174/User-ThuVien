-- ============================================
-- Script khởi tạo users cho hệ thống Thư viện
-- Chạy tự động khi Oracle container khởi động lần đầu
-- ============================================

-- Kết nối vào PDB
ALTER SESSION SET CONTAINER = THUVIEN_PDB;

-- Tạo tablespace cho ứng dụng
CREATE TABLESPACE thuvien_data
    DATAFILE '/opt/oracle/oradata/FREE/THUVIEN_PDB/thuvien_data01.dbf'
    SIZE 100M
    AUTOEXTEND ON
    NEXT 50M
    MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE thuvien_temp
    TEMPFILE '/opt/oracle/oradata/FREE/THUVIEN_PDB/thuvien_temp01.dbf'
    SIZE 50M
    AUTOEXTEND ON
    NEXT 25M
    MAXSIZE UNLIMITED;

-- ============================================
-- Tạo Admin user (quản lý bảo mật)
-- ============================================
CREATE USER sec_admin IDENTIFIED BY SecAdmin123
    DEFAULT TABLESPACE thuvien_data
    TEMPORARY TABLESPACE thuvien_temp
    QUOTA UNLIMITED ON thuvien_data;

GRANT CONNECT, RESOURCE TO sec_admin;
GRANT CREATE SESSION TO sec_admin;
GRANT CREATE USER TO sec_admin;
GRANT ALTER USER TO sec_admin;
GRANT DROP USER TO sec_admin;
GRANT CREATE ROLE TO sec_admin;
GRANT DROP ANY ROLE TO sec_admin;
GRANT GRANT ANY ROLE TO sec_admin;
GRANT CREATE PROFILE TO sec_admin;
GRANT ALTER PROFILE TO sec_admin;
GRANT DROP PROFILE TO sec_admin;
GRANT SELECT ANY DICTIONARY TO sec_admin;

-- ============================================
-- Tạo App user (cho ứng dụng web kết nối)
-- ============================================
CREATE USER app_user IDENTIFIED BY AppUser123
    DEFAULT TABLESPACE thuvien_data
    TEMPORARY TABLESPACE thuvien_temp
    QUOTA UNLIMITED ON thuvien_data;

GRANT CONNECT, RESOURCE TO app_user;
GRANT CREATE SESSION TO app_user;
GRANT CREATE TABLE TO app_user;
GRANT CREATE VIEW TO app_user;
GRANT CREATE PROCEDURE TO app_user;
GRANT CREATE SEQUENCE TO app_user;

-- ============================================
-- Tạo bảng thông tin cá nhân mẫu
-- ============================================
-- Chuyển sang schema app_user để tạo bảng
ALTER SESSION SET CURRENT_SCHEMA = app_user;

CREATE TABLE user_info (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    full_name VARCHAR2(100),
    email VARCHAR2(100),
    phone VARCHAR2(20),
    address VARCHAR2(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Thêm dữ liệu mẫu
INSERT INTO user_info (username, full_name, email, phone, address)
VALUES ('admin', 'Administrator', 'admin@thuvien.vn', '0901234567', 'Hà Nội, Việt Nam');

INSERT INTO user_info (username, full_name, email, phone, address)
VALUES ('librarian', 'Thủ thư', 'librarian@thuvien.vn', '0907654321', 'TP.HCM, Việt Nam');

COMMIT;

-- Cấp quyền cho sec_admin xem bảng user_info
GRANT SELECT, INSERT, UPDATE, DELETE ON app_user.user_info TO sec_admin;

-- Log completion
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Database initialization completed!');
    DBMS_OUTPUT.PUT_LINE('Users created: sec_admin, app_user');
    DBMS_OUTPUT.PUT_LINE('Tablespaces: thuvien_data, thuvien_temp');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/
