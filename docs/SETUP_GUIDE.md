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


-- Setup VPD (Virtual Private Database)
@/opt/oracle/scripts/setup/03_setup_vpd.sql

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

| Username | Password | Role | Chi nhánh | Mức truy cập (OLS) |
|----------|----------|------|-----------|---------------------|
| admin_user | Admin123 | ADMIN | Trụ sở chính (HQ) | TOP_SECRET (thấy tất cả) |
| librarian_user | Librarian123 | LIBRARIAN | Chi nhánh A | CONFIDENTIAL |
| staff_user | Staff123 | STAFF | Chi nhánh A | INTERNAL |
| reader_user | Reader123 | READER | Chi nhánh A | PUBLIC |

---

## VII. KIỂM TRA VPD HOẠT ĐỘNG ĐÚNG

### Logic VPD theo chi nhánh:
| Role | Logic | Sách thấy |
|------|-------|----------|
| **Admin** | Thấy tất cả chi nhánh | 12 sách |
| **Librarian** | Chi nhánh mình + HQ | 8 sách |
| **Staff** | Chỉ chi nhánh mình | 3 sách |
| **Reader** | Tất cả (OLS filter) | 6 sách PUBLIC |

---

## VIII. KIỂM TRA OLS HOẠT ĐỘNG ĐÚNG

### OLS filter theo sensitivity level:
| User | Sách phải thấy |
|------|----------------|
| READER | Chỉ sách PUBLIC |
| STAFF | PUBLIC + INTERNAL |
| LIBRARIAN | PUBLIC + INTERNAL + CONFIDENTIAL |
| ADMIN | Tất cả (bao gồm TOP_SECRET) |

---

## IX. XỬ LÝ LỖI THƯỜNG GẶP

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

### Lỗi "/bin/bash^M: bad interpreter" hoặc "$'\r': command not found"

**Nguyên nhân:** File script shell (.sh) bị lưu dưới định dạng Windows (CRLF) thay vì Linux (LF).

**Giải pháp:**
1. Đảm bảo đã pull code mới nhất (có file `.gitattributes`).
2. Chạy lệnh sau để git tự động sửa định dạng file:
   ```bash
   git rm --cached -r .
   git reset --hard
   ```
3. Nếu dùng Docker trên Windows, hãy đảm bảo cấu hình git:
   ```bash
   git config --global core.autocrlf false
   ```
4. Sau đó xóa container và volume cũ để chạy lại:
   ```bash
   docker compose down -v
   docker compose up -d
   ```

---

## X. DATABASE VAULT (ODV) - BẢO VỆ KHỎI DBA

> ⚠️ **Yêu cầu:** Oracle Enterprise Edition với Database Vault license.

Database Vault ngăn chặn DBA (SYS, SYSTEM) truy cập dữ liệu ứng dụng.

### Bước 9.1: Enable Database Vault

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
-- Ở CDB ROOT (không cần chuyển container)
@/opt/oracle/scripts/setup/18_setup_database_vault.sql
EXIT;
```

### Bước 9.2: RESTART DATABASE (BẮT BUỘC!)

```bash
docker restart oracle23ai
# Chờ 2-3 phút cho database khởi động lại
docker logs oracle23ai --tail 30
```

### Bước 9.3: Tạo Realm bảo vệ Schema LIBRARY

```bash
docker exec -it oracle23ai sqlplus sec_admin/SecAdmin123@localhost:1521/FREEPDB1
```

```sql
@/opt/oracle/scripts/setup/19_setup_dv_realms.sql
EXIT;
```

### Bước 9.4: Kiểm tra ODV hoạt động

```bash
# Test: SYS không thể truy cập LIBRARY.BOOKS
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT * FROM library.books;
-- Kết quả mong đợi: ORA-01031: insufficient privileges (BỊ CHẶN!)
```

```sql
-- Test: Application user vẫn truy cập được
CONNECT admin_user/Admin123@localhost:1521/FREEPDB1
SELECT COUNT(*) FROM library.books;
-- Kết quả: Trả về số lượng sách (OK)
```

### ODV Users

| User | Password | Chức năng |
|------|----------|-----------|
| `sec_admin` | `SecAdmin123` | Quản lý Realms, Command Rules (DV Owner) |
| `dv_acctmgr_user` | `DVAcctMgr#123` | Quản lý tài khoản user |

---

*Cập nhật: 31/12/2024*
