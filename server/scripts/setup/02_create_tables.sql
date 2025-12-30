-- ============================================
-- SCRIPT 02: TẠO BẢNG DỮ LIỆU
-- Chạy với user LIBRARY
-- ============================================

-- Kết nối: CONN library/Library#123@THUVIEN_PDB

-- ============================================
-- 1. CLEANUP (XÓA BẢNG CŨ)
-- ============================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE borrow_history CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE books CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE categories CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE user_info CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE branches CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ============================================
-- 1. BẢNG THÔNG TIN CHI NHÁNH
-- ============================================
CREATE TABLE branches (
    branch_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_code VARCHAR2(10) NOT NULL UNIQUE,
    branch_name VARCHAR2(100) NOT NULL,
    address VARCHAR2(255),
    phone VARCHAR2(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dữ liệu mẫu
INSERT INTO branches (branch_code, branch_name, address) VALUES ('HQ', 'Trụ sở chính', 'Quận 1, TP.HCM');
INSERT INTO branches (branch_code, branch_name, address) VALUES ('BR_A', 'Chi nhánh A', 'Quận 3, TP.HCM');
INSERT INTO branches (branch_code, branch_name, address) VALUES ('BR_B', 'Chi nhánh B', 'Quận 7, TP.HCM');

-- ============================================
-- 2. BẢNG THÔNG TIN NGƯỜI DÙNG
-- ============================================
CREATE TABLE user_info (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    oracle_username VARCHAR2(50) NOT NULL UNIQUE,
    full_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    phone VARCHAR2(20),
    address VARCHAR2(255),
    department VARCHAR2(50),
    branch_id NUMBER REFERENCES branches(branch_id),
    user_type VARCHAR2(20) DEFAULT 'READER' CHECK (user_type IN ('ADMIN', 'LIBRARIAN', 'STAFF', 'READER')),
    sensitivity_level VARCHAR2(20) DEFAULT 'PUBLIC',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_user_info_branch ON user_info(branch_id);
CREATE INDEX idx_user_info_type ON user_info(user_type);

-- Dữ liệu mẫu
INSERT INTO user_info (oracle_username, full_name, email, department, branch_id, user_type, sensitivity_level)
VALUES ('ADMIN_USER', 'Quản trị viên', 'admin@thuvien.vn', 'IT', 1, 'ADMIN', 'TOP_SECRET');

INSERT INTO user_info (oracle_username, full_name, email, department, branch_id, user_type, sensitivity_level)
VALUES ('LIBRARIAN_USER', 'Nguyễn Văn Thủ', 'thuthu@thuvien.vn', 'LIBRARY', 1, 'LIBRARIAN', 'CONFIDENTIAL');

INSERT INTO user_info (oracle_username, full_name, email, department, branch_id, user_type, sensitivity_level)
VALUES ('STAFF_USER', 'Trần Thị Nhân', 'nhanvien@thuvien.vn', 'LIBRARY', 2, 'STAFF', 'INTERNAL');

INSERT INTO user_info (oracle_username, full_name, email, department, branch_id, user_type, sensitivity_level)
VALUES ('READER_USER', 'Lê Văn Đọc', 'docgia@gmail.com', NULL, 2, 'READER', 'PUBLIC');

-- ============================================
-- 3. BẢNG DANH MỤC SÁCH
-- ============================================
CREATE TABLE categories (
    category_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_code VARCHAR2(20) NOT NULL UNIQUE,
    category_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(500)
);

-- Dữ liệu mẫu
INSERT INTO categories (category_code, category_name, description) VALUES ('FICTION', 'Tiểu thuyết', 'Sách văn học, tiểu thuyết');
INSERT INTO categories (category_code, category_name, description) VALUES ('SCIENCE', 'Khoa học', 'Sách khoa học tự nhiên');
INSERT INTO categories (category_code, category_name, description) VALUES ('TECH', 'Công nghệ', 'Sách công nghệ thông tin');
INSERT INTO categories (category_code, category_name, description) VALUES ('RESEARCH', 'Nghiên cứu', 'Tài liệu nghiên cứu nội bộ');
INSERT INTO categories (category_code, category_name, description) VALUES ('RESTRICTED', 'Hạn chế', 'Tài liệu mật');

-- ============================================
-- 4. BẢNG SÁCH
-- ============================================
CREATE TABLE books (
    book_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn VARCHAR2(20) UNIQUE,
    title VARCHAR2(255) NOT NULL,
    author VARCHAR2(100),
    publisher VARCHAR2(100),
    publish_year NUMBER(4),
    category_id NUMBER REFERENCES categories(category_id),
    branch_id NUMBER REFERENCES branches(branch_id),
    quantity NUMBER DEFAULT 1,
    available_qty NUMBER DEFAULT 1,
    sensitivity_level VARCHAR2(20) DEFAULT 'PUBLIC',
    -- Cột cho OLS (sẽ được thêm sau khi enable OLS)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_books_branch ON books(branch_id);
CREATE INDEX idx_books_category ON books(category_id);
CREATE INDEX idx_books_sensitivity ON books(sensitivity_level);

-- Dữ liệu mẫu
INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, branch_id, quantity, available_qty, sensitivity_level)
VALUES ('978-604-1', 'Lập trình Python', 'Nguyễn Văn A', 'NXB Giáo dục', 2023, 3, 1, 5, 5, 'PUBLIC');

INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, branch_id, quantity, available_qty, sensitivity_level)
VALUES ('978-604-2', 'Cơ sở dữ liệu Oracle', 'Trần Văn B', 'NXB KHKT', 2022, 3, 1, 3, 3, 'PUBLIC');

INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, branch_id, quantity, available_qty, sensitivity_level)
VALUES ('978-604-3', 'Bảo mật hệ thống', 'Lê Văn C', 'NXB ĐHQG', 2024, 3, 2, 2, 2, 'INTERNAL');

INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, branch_id, quantity, available_qty, sensitivity_level)
VALUES ('978-604-4', 'Nghiên cứu AI', 'Phạm Văn D', 'Nội bộ', 2024, 4, 1, 1, 1, 'CONFIDENTIAL');

INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, branch_id, quantity, available_qty, sensitivity_level)
VALUES ('978-604-5', 'Tài liệu mật', 'Ban lãnh đạo', 'Nội bộ', 2024, 5, 1, 1, 1, 'TOP_SECRET');

-- ============================================
-- 5. BẢNG LỊCH SỬ MƯỢN SÁCH
-- ============================================
CREATE TABLE borrow_history (
    borrow_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER NOT NULL REFERENCES user_info(user_id),
    book_id NUMBER NOT NULL REFERENCES books(book_id),
    borrow_date DATE DEFAULT SYSDATE NOT NULL,
    due_date DATE,
    return_date DATE,
    status VARCHAR2(20) DEFAULT 'BORROWING' CHECK (status IN ('BORROWING', 'RETURNED', 'OVERDUE', 'LOST')),
    fine_amount NUMBER(10,2) DEFAULT 0,
    notes VARCHAR2(500),
    created_by VARCHAR2(50) DEFAULT USER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_borrow_user ON borrow_history(user_id);
CREATE INDEX idx_borrow_book ON borrow_history(book_id);
CREATE INDEX idx_borrow_status ON borrow_history(status);
CREATE INDEX idx_borrow_created_by ON borrow_history(created_by);

-- Dữ liệu mẫu
INSERT INTO borrow_history (user_id, book_id, borrow_date, due_date, status, created_by)
VALUES (4, 1, SYSDATE - 7, SYSDATE + 7, 'BORROWING', 'LIBRARIAN_USER');

INSERT INTO borrow_history (user_id, book_id, borrow_date, due_date, return_date, status, created_by)
VALUES (4, 2, SYSDATE - 30, SYSDATE - 16, SYSDATE - 17, 'RETURNED', 'LIBRARIAN_USER');

-- ============================================
-- 6. BẢNG AUDIT LOG (cho ứng dụng)
-- ============================================
CREATE TABLE app_audit_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type VARCHAR2(50) NOT NULL,
    table_name VARCHAR2(50),
    record_id NUMBER,
    old_values CLOB,
    new_values CLOB,
    performed_by VARCHAR2(50) DEFAULT USER,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR2(50),
    user_agent VARCHAR2(255)
);

-- Index
CREATE INDEX idx_audit_action ON app_audit_log(action_type);
CREATE INDEX idx_audit_table ON app_audit_log(table_name);
CREATE INDEX idx_audit_user ON app_audit_log(performed_by);
CREATE INDEX idx_audit_time ON app_audit_log(performed_at);

-- ============================================
-- 7. CẤP QUYỀN CHO CÁC ROLES
-- ============================================

-- Admin role: Toàn quyền
GRANT SELECT, INSERT, UPDATE, DELETE ON library.user_info TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.books TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.borrow_history TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.categories TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.branches TO admin_role;
GRANT SELECT ON library.app_audit_log TO admin_role;

-- Librarian role: Quản lý sách và mượn/trả
GRANT SELECT ON library.user_info TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library.books TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library.borrow_history TO librarian_role;
GRANT SELECT ON library.categories TO librarian_role;
GRANT SELECT ON library.branches TO librarian_role;

-- Staff role: Xem thông tin
GRANT SELECT ON library.user_info TO staff_role;
GRANT SELECT ON library.books TO staff_role;
GRANT SELECT ON library.borrow_history TO staff_role;
GRANT SELECT ON library.categories TO staff_role;
GRANT SELECT ON library.branches TO staff_role;

-- Reader role: Xem sách và lịch sử cá nhân
GRANT SELECT ON library.books TO reader_role;
GRANT SELECT ON library.borrow_history TO reader_role;
GRANT SELECT ON library.categories TO reader_role;
GRANT SELECT ON library.branches TO reader_role;

-- Cấp quyền cho security users
GRANT SELECT, INSERT, UPDATE, DELETE ON library.user_info TO lib_project;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.books TO lib_project;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.borrow_history TO lib_project;
GRANT SELECT ON library.categories TO lib_project;
GRANT SELECT ON library.branches TO lib_project;

-- ============================================
-- LOG COMPLETION
-- ============================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Script 02 completed successfully!');
    DBMS_OUTPUT.PUT_LINE('Created tables:');
    DBMS_OUTPUT.PUT_LINE('  - branches, user_info, categories');
    DBMS_OUTPUT.PUT_LINE('  - books, borrow_history, app_audit_log');
    DBMS_OUTPUT.PUT_LINE('Granted permissions to roles');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

COMMIT;
