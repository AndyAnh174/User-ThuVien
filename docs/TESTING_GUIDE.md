# 🧪 HƯỚNG DẪN KIỂM TRA PHÂN QUYỀN

Tài liệu này hướng dẫn cách verify các chính sách bảo mật đang hoạt động đúng.

---

## 1. 🛡️ Kiểm tra VPD (Virtual Private Database)

### Nguyên tắc test:
> **Cùng một câu query, khác user → khác kết quả**

### Ví dụ test:

```sql
-- ==========================================
-- SETUP: Tạo policy VPD cho bảng BORROW_HISTORY
-- Reader chỉ thấy lịch sử mượn của chính mình
-- ==========================================

-- 1. Tạo policy function (chạy với SEC_ADMIN)
CREATE OR REPLACE FUNCTION policy_reader_history (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
BEGIN
    -- Nếu là ADMIN thì không filter
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') = 'ADMIN' THEN
        RETURN NULL; -- NULL = không thêm điều kiện = thấy hết
    END IF;
    
    -- Các user khác chỉ thấy record của mình
    RETURN 'username = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
END;
/

-- 2. Gán policy cho bảng
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BORROW_HISTORY',
        policy_name     => 'READER_HISTORY_POLICY',
        function_schema => 'SEC_ADMIN',
        policy_function => 'policy_reader_history',
        statement_types => 'SELECT,UPDATE,DELETE'
    );
END;
/

-- ==========================================
-- TEST: Kiểm tra policy có hoạt động không
-- ==========================================

-- Bước 1: Thêm dữ liệu test (chạy với ADMIN)
INSERT INTO borrow_history (username, book_id, borrow_date) VALUES ('READER1', 1, SYSDATE);
INSERT INTO borrow_history (username, book_id, borrow_date) VALUES ('READER1', 2, SYSDATE);
INSERT INTO borrow_history (username, book_id, borrow_date) VALUES ('READER2', 3, SYSDATE);
INSERT INTO borrow_history (username, book_id, borrow_date) VALUES ('LIBRARIAN1', 4, SYSDATE);
COMMIT;

-- Bước 2: Login ADMIN, đếm số dòng
CONN admin/password@THUVIEN_PDB
SELECT COUNT(*) FROM library.borrow_history;
-- ✅ Kỳ vọng: 4 rows (thấy hết)

-- Bước 3: Login READER1, đếm số dòng  
CONN reader1/password@THUVIEN_PDB
SELECT COUNT(*) FROM library.borrow_history;
-- ✅ Kỳ vọng: 2 rows (chỉ thấy của READER1)

-- Bước 4: Login READER2, đếm số dòng
CONN reader2/password@THUVIEN_PDB
SELECT COUNT(*) FROM library.borrow_history;
-- ✅ Kỳ vọng: 1 row (chỉ thấy của READER2)
```

### ✅ VPD hoạt động đúng nếu:
- ADMIN thấy 4 rows
- READER1 thấy 2 rows
- READER2 thấy 1 row
- Cùng một query `SELECT *` nhưng kết quả khác nhau

---

## 2. 🏷️ Kiểm tra OLS (Oracle Label Security)

### Nguyên tắc test:
> **User có label thấp không thể đọc data có label cao**

### Ví dụ test:

```sql
-- ==========================================
-- SETUP: Đã tạo policy ACCESS_LOCATIONS với các level:
-- PUB (1000) < CONF (2000) < SENS (3000)
-- ==========================================

-- Gán label cho users
-- READER1: level = PUB (chỉ thấy dữ liệu PUBLIC)
-- LIBRARIAN1: level = CONF (thấy PUBLIC + CONFIDENTIAL)
-- ADMIN: level = SENS (thấy tất cả)

-- ==========================================
-- TEST: Kiểm tra OLS có hoạt động không
-- ==========================================

-- Bước 1: Thêm dữ liệu với các label khác nhau (chạy với ADMIN)
UPDATE books SET ols_label = CHAR_TO_LABEL('BOOK_POLICY', 'PUB') WHERE category = 'Fiction';
UPDATE books SET ols_label = CHAR_TO_LABEL('BOOK_POLICY', 'CONF') WHERE category = 'Research';
UPDATE books SET ols_label = CHAR_TO_LABEL('BOOK_POLICY', 'SENS') WHERE category = 'Restricted';
COMMIT;

-- Bước 2: Login với từng user và đếm

-- Login READER1 (label = PUB)
CONN reader1/password@THUVIEN_PDB
SELECT category, COUNT(*) FROM library.books GROUP BY category;
-- ✅ Kỳ vọng: Chỉ thấy Fiction

-- Login LIBRARIAN1 (label = CONF)  
CONN librarian1/password@THUVIEN_PDB
SELECT category, COUNT(*) FROM library.books GROUP BY category;
-- ✅ Kỳ vọng: Thấy Fiction + Research

-- Login ADMIN (label = SENS)
CONN admin/password@THUVIEN_PDB
SELECT category, COUNT(*) FROM library.books GROUP BY category;
-- ✅ Kỳ vọng: Thấy Fiction + Research + Restricted
```

### ✅ OLS hoạt động đúng nếu:
- User level thấp KHÔNG thấy data level cao
- **No read up** được tuân thủ

---

## 3. 📊 Kiểm tra Audit

### Nguyên tắc test:
> **Mọi hành động được audit phải xuất hiện trong audit trail**

### Ví dụ test:

```sql
-- ==========================================
-- SETUP: Bật audit cho một số hành động
-- ==========================================

-- Audit mọi thao tác trên bảng BOOKS
AUDIT SELECT, INSERT, UPDATE, DELETE ON library.books BY ACCESS;

-- Audit việc đăng nhập
AUDIT CREATE SESSION BY ACCESS;

-- ==========================================
-- TEST: Kiểm tra audit có hoạt động không
-- ==========================================

-- Bước 1: Thực hiện các hành động
CONN reader1/password@THUVIEN_PDB
SELECT * FROM library.books WHERE book_id = 1;
SELECT * FROM library.books WHERE book_id = 2;

-- Bước 2: Kiểm tra audit trail (chạy với ADMIN hoặc SYS)
CONN sys/Oracle123@THUVIEN_PDB AS SYSDBA

SELECT 
    username,
    action_name,
    obj_name,
    TO_CHAR(timestamp, 'DD/MM/YYYY HH24:MI:SS') as time,
    returncode
FROM dba_audit_trail 
WHERE obj_name = 'BOOKS'
ORDER BY timestamp DESC;

-- ✅ Kỳ vọng: Thấy 2 records SELECT của READER1
```

### ✅ Audit hoạt động đúng nếu:
- Mỗi hành động được audit xuất hiện trong `DBA_AUDIT_TRAIL`
- Thông tin ghi lại đầy đủ: WHO, WHAT, WHEN, WHERE

---

## 4. 🛡️ Kiểm tra ODV (Oracle Database Vault)

### Nguyên tắc test:
> **DBA/SYS không thể truy cập data trong Realm được bảo vệ**

### Ví dụ test:

```sql
-- ==========================================
-- SETUP: Tạo Realm bảo vệ schema LIBRARY
-- ==========================================

-- Tạo realm (chạy với DV_OWNER)
BEGIN
    DVSYS.DBMS_MACADM.CREATE_REALM(
        realm_name    => 'LIBRARY_REALM',
        description   => 'Bảo vệ dữ liệu thư viện khỏi DBA',
        enabled       => DVSYS.DBMS_MACUTL.G_YES,
        audit_options => DVSYS.DBMS_MACUTL.G_REALM_AUDIT_FAIL
    );
END;
/

-- Thêm schema LIBRARY vào realm
BEGIN
    DVSYS.DBMS_MACADM.ADD_OBJECT_TO_REALM(
        realm_name   => 'LIBRARY_REALM',
        object_owner => 'LIBRARY',
        object_name  => '%',
        object_type  => '%'
    );
END;
/

-- Authorize LIBRARY user (chủ sở hữu) có quyền truy cập
BEGIN
    DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
        realm_name  => 'LIBRARY_REALM',
        grantee     => 'LIBRARY',
        auth_options=> DVSYS.DBMS_MACUTL.G_REALM_AUTH_OWNER
    );
END;
/

-- ==========================================
-- TEST: Kiểm tra ODV có hoạt động không
-- ==========================================

-- Bước 1: Login với SYS (có quyền cao nhất trong Oracle)
CONN sys/Oracle123@THUVIEN_PDB AS SYSDBA

-- Bước 2: Thử SELECT data trong realm
SELECT * FROM library.books;

-- ✅ Kỳ vọng: Lỗi ORA-01031: insufficient privileges
-- hoặc ORA-47401: Realm violation

-- Bước 3: Login với LIBRARY user (được authorize)
CONN library/password@THUVIEN_PDB
SELECT * FROM books;

-- ✅ Kỳ vọng: Query thành công, thấy data
```

### ✅ ODV hoạt động đúng nếu:
- SYS/SYSTEM **BỊ CHẶN** khi truy cập Realm
- Chỉ user được authorize mới truy cập được

---

## 5. 📋 BẢNG TÓM TẮT TEST CASES

| Công nghệ | Test Case | Kỳ vọng | Pass/Fail |
|-----------|-----------|---------|-----------|
| **VPD** | READER1 query bảng BORROW_HISTORY | Chỉ thấy records của READER1 | ⬜ |
| **VPD** | ADMIN query bảng BORROW_HISTORY | Thấy tất cả records | ⬜ |
| **OLS** | User label=PUB query sách SENS | Không thấy | ⬜ |
| **OLS** | User label=SENS query sách PUB | Thấy được | ⬜ |
| **Audit** | SELECT trên bảng được audit | Xuất hiện trong DBA_AUDIT_TRAIL | ⬜ |
| **Audit** | Login thất bại | Ghi nhận trong audit trail | ⬜ |
| **ODV** | SYS truy cập Realm | Bị chặn (ORA-47401) | ⬜ |
| **ODV** | Owner truy cập Realm | Thành công | ⬜ |

---

## 6. 🛠️ SCRIPT TỰ ĐỘNG TEST

```sql
-- Script test nhanh (chạy sau khi setup xong)
SET SERVEROUTPUT ON;

DECLARE
    v_count NUMBER;
    v_user VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TEST SECURITY POLICIES ===');
    DBMS_OUTPUT.PUT_LINE('Current User: ' || v_user);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 1: Đếm records trong bảng (VPD test)
    SELECT COUNT(*) INTO v_count FROM library.borrow_history;
    DBMS_OUTPUT.PUT_LINE('VPD Test - Borrow History Count: ' || v_count);
    
    -- Test 2: Đếm sách theo label (OLS test)  
    SELECT COUNT(*) INTO v_count FROM library.books;
    DBMS_OUTPUT.PUT_LINE('OLS Test - Books Count: ' || v_count);
    
    -- Test 3: Kiểm tra audit trail
    SELECT COUNT(*) INTO v_count 
    FROM dba_audit_trail 
    WHERE timestamp > SYSDATE - 1/24; -- 1 giờ gần nhất
    DBMS_OUTPUT.PUT_LINE('Audit Test - Records last hour: ' || v_count);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST COMPLETED ===');
END;
/
```

---

## 7. 📸 DEMO CHO BÁO CÁO

Khi demo, hãy chụp screenshot các bước sau:

1. **Before**: Query với ADMIN → thấy hết data
2. **After**: Query với READER → chỉ thấy một phần
3. **Error**: SYS bị chặn bởi Database Vault
4. **Trail**: Các hành động được ghi trong audit

Điều này chứng minh các chính sách bảo mật **ĐANG HOẠT ĐỘNG**!

---

*Cập nhật: 29/12/2024*
