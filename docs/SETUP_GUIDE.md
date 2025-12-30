# HƯỚNG DẪN CÀI ĐẶT - THƯ VIỆN SỐ

## I. YÊU CẦU HỆ THỐNG

| Thành phần | Yêu cầu |
|------------|---------|
| Docker | Phiên bản 20.x trở lên |
| Node.js | Phiên bản 18.x trở lên |
| Python | Phiên bản 3.11 trở lên |
| RAM | Tối thiểu 4GB (khuyến nghị 8GB) |

---

## II. CÀI ĐẶT ORACLE DATABASE

### Bước 1: Khởi động Docker Container

```bash
cd server
docker compose up -d
# Đợi 3-5 phút cho database khởi động
docker logs oracle23ai --tail 50
```

Chờ đến khi thấy: `DATABASE IS READY TO USE!`

### Bước 2: Kết nối Database

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

---

## III. CHẠY CÁC SCRIPTS THEO THỨ TỰ

**QUAN TRỌNG:** Phải chạy đúng thứ tự, chuyển đúng container và restart database đúng lúc!

### Bước 3.1: Enable OLS System (Chạy ở CDB ROOT)

```sql
-- Đang ở CDB ROOT, KHÔNG chuyển container!
@/opt/oracle/scripts/setup/15_enable_ols_system.sql
@/opt/oracle/scripts/setup/16_enable_ols_pdb.sql

EXIT;
```

### Bước 3.2: RESTART DATABASE (BẮT BUỘC!)

```bash
docker restart oracle23ai
# Chờ 2-3 phút
docker logs oracle23ai --tail 20
```

### Bước 3.3: Kết nối lại và tạo Schema

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Tạo users và roles
@/opt/oracle/scripts/setup/01_create_users.sql

-- Tạo tables và sample data
@/opt/oracle/scripts/setup/02_create_tables.sql

-- Grant object privileges (sau khi tables đã tạo)
@/opt/oracle/scripts/setup/01_1_grant_object_privs.sql

-- Setup Unified Auditing
@/opt/oracle/scripts/setup/04_setup_audit.sql

-- Tạo OLS Policy
@/opt/oracle/scripts/setup/05_setup_ols.sql

-- Tạo OLS Trigger
@/opt/oracle/scripts/setup/08_create_ols_trigger.sql

-- Setup Proxy Authentication
@/opt/oracle/scripts/setup/10_setup_proxy_auth.sql

-- Fix OLS Permissions
@/opt/oracle/scripts/setup/17_fix_ols_permissions.sql

EXIT;
```

### Bước 3.4: Cập nhật OLS Labels cho sách

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Cập nhật labels cho tất cả sách
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

-- Kiểm tra
SELECT book_id, title, sensitivity_level, ols_label FROM library.books;

EXIT;
```

### Bước 3.5: Grant quyền cho Audit (QUAN TRỌNG)

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Grant quyền xem audit trail
GRANT SELECT ON audsys.unified_audit_trail TO library;

-- Grant quyền xem profiles
GRANT SELECT ON dba_profiles TO library;
GRANT SELECT ON dba_users TO library;

COMMIT;
EXIT;
```

---

## IV. CÀI ĐẶT BACKEND

### Bước 4.1: Tạo file .env

```bash
cd server
cp .env.example .env
```

Kiểm tra file `.env` có nội dung:

```env
DB_USER=library
DB_PASSWORD=Library123
DB_HOST=localhost
DB_PORT=1521
DB_SERVICE=FREEPDB1

APP_NAME=Library User Management API
APP_VERSION=1.0.0
DEBUG=true
```

### Bước 4.2: Cài đặt dependencies

```bash
pip install -r requirements.txt
```

### Bước 4.3: Chạy Backend

```bash
python main.py
```

Kiểm tra: http://localhost:8000/docs

---

## V. CÀI ĐẶT FRONTEND

```bash
cd client
npm install
npm run dev
```

Truy cập: http://localhost:3000

---

## VI. TÀI KHOẢN MẪU

| Username | Password | Role | Mức truy cập |
|----------|----------|------|--------------|
| admin_user | Admin123 | ADMIN | TOP_SECRET (thấy tất cả) |
| librarian_user | Librarian123 | LIBRARIAN | CONFIDENTIAL |
| staff_user | Staff123 | STAFF | INTERNAL |
| reader_user | Reader123 | READER | PUBLIC |

---

## VII. KIỂM TRA OLS HOẠT ĐỘNG ĐÚNG

| User | Sách phải thấy |
|------|----------------|
| READER | Chỉ sách PUBLIC |
| STAFF | PUBLIC + INTERNAL |
| LIBRARIAN | PUBLIC + INTERNAL + CONFIDENTIAL |
| ADMIN | Tất cả (bao gồm TOP_SECRET) |

---

## VIII. XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi ORA-01017: invalid credential

**Nguyên nhân:** Sai password trong `.env`

**Giải pháp:** 
```env
DB_PASSWORD=Library123
DB_SERVICE=FREEPDB1
```

### Lỗi ORA-28110: VPD policy function has error

**Nguyên nhân:** VPD function bị lỗi

**Giải pháp:** Drop VPD policies

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Liệt kê policies
SELECT policy_name, object_name FROM dba_policies WHERE object_owner = 'LIBRARY';

-- Drop từng policy
BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BOOKS', 'VPD_BOOKS');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'USER_INFO', 'VPD_USER_INFO');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BORROW_HISTORY', 'VPD_BORROW_HISTORY');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

COMMIT;
```

### Lỗi 400 Bad Request cho /api/audit

**Nguyên nhân:** LIBRARY user không có quyền SELECT trên audit trail

**Giải pháp:**
```sql
GRANT SELECT ON audsys.unified_audit_trail TO library;
```

### Lỗi 400 Bad Request cho /api/profiles

**Nguyên nhân:** LIBRARY user không có quyền SELECT trên dba_profiles

**Giải pháp:**
```sql
GRANT SELECT ON dba_profiles TO library;
GRANT SELECT ON dba_users TO library;
```

### Text tiếng Việt bị lỗi ký tự (???)

**Nguyên nhân:** Encoding không đúng khi insert qua sqlplus

**Giải pháp:** 
1. Data mẫu đã được chuyển sang không dấu
2. Thêm data mới qua Frontend (form thêm sách) để đảm bảo UTF-8

---

## IX. DATABASE VAULT (TÙY CHỌN)

**Lưu ý:** Database Vault có thể không khả dụng trong Oracle 23ai Free.

```sql
-- Enable Database Vault
@/opt/oracle/scripts/setup/18_setup_database_vault.sql
EXIT;
```

```bash
docker restart oracle23ai
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
@/opt/oracle/scripts/setup/19_setup_dv_realms.sql
```

---

*Cập nhật: 30/12/2024*
