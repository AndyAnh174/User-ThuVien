# Oracle Database 23ai Free - Docker Setup

## 🔐 BƯỚC 1: Đăng ký và lấy Auth Token

### 1.1 Tạo tài khoản Oracle (miễn phí)

1. Truy cập: https://profile.oracle.com/myprofile/account/create-account.jspx
2. Điền thông tin và tạo tài khoản
3. Xác nhận email

### 1.2 Chấp nhận License và lấy Auth Token

1. Truy cập: https://container-registry.oracle.com
2. Nhấn **Sign In** (góc trên phải) → đăng nhập với tài khoản Oracle
3. Tìm **Database** → chọn **free**
4. Nhấn **Continue** để chấp nhận License Agreement
5. Sau khi accept, vào trang: https://container-registry.oracle.com/ords/ocr/ba/database/free
6. Tìm phần **Auth Token** → **Copy** token

### 1.3 Docker Login

```bash
docker login container-registry.oracle.com
# Username: email_oracle_của_bạn@gmail.com
# Password: <paste Auth Token đã copy>
```

Khi thấy **"Login Succeeded"** là thành công!

---

## 🚀 BƯỚC 2: Khởi động Database

```bash
cd server

# Khởi động Oracle (lần đầu pull ~3GB, mất 10-15 phút)
docker compose up -d

# Xem logs - đợi đến khi thấy "DATABASE IS READY TO USE!"
docker compose logs -f oracle-db
```

⏱️ **Lần đầu khởi động mất 5-10 phút** để tạo database.

---

## 📋 Thông tin kết nối

| Thông số          | Giá trị         |
|-------------------|-----------------|
| Host              | `localhost`     |
| Port              | `1521`          |
| Service Name      | `THUVIEN_PDB`   |
| SYS Password      | `Oracle123`     |
| SYSTEM Password   | `Oracle123`     |
| PDBADMIN Password | `Oracle123`     |

---

## 🔗 Kết nối SQL*Plus

```bash
# Kết nối với SYS (admin)
docker exec -it oracle23ai sqlplus sys/Oracle123@//localhost:1521/THUVIEN_PDB as sysdba

# Kết nối với LIBRARY user (sau khi chạy scripts)
docker exec -it oracle23ai sqlplus library/Library#123@//localhost:1521/THUVIEN_PDB
```

---

## 📝 BƯỚC 3: Chạy SQL Scripts

Sau khi database khởi động xong (thấy "DATABASE IS READY TO USE!"), chạy các scripts:

```bash
# Vào SQL*Plus với SYS
docker exec -it oracle23ai sqlplus sys/Oracle123@//localhost:1521/THUVIEN_PDB as sysdba
```

Trong SQL*Plus, chạy theo thứ tự:

```sql
-- 1. Tạo users và roles
@/opt/oracle/scripts/setup/01_create_users.sql

-- 2. Tạo tables (chuyển sang user LIBRARY)
CONN library/Library#123@//localhost:1521/THUVIEN_PDB
@/opt/oracle/scripts/setup/02_create_tables.sql

-- 3. Setup VPD
CONN sys/Oracle123@//localhost:1521/THUVIEN_PDB as sysdba
@/opt/oracle/scripts/setup/03_setup_vpd.sql

-- 4. Setup Audit
@/opt/oracle/scripts/setup/04_setup_audit.sql

-- 5. Setup OLS (Oracle Label Security)
@/opt/oracle/scripts/setup/05_setup_ols.sql
```

---

## 🛑 Dừng / Xóa

```bash
# Dừng container (giữ data)
docker compose down

# Dừng và XÓA TẤT CẢ DATA (reset hoàn toàn)
docker compose down -v
```

---

## ⚠️ Troubleshooting

### Lỗi "unauthorized" khi pull image

```bash
# Đảm bảo đã chấp nhận license tại:
# https://container-registry.oracle.com/ords/ocr/ba/database/free

# Sau đó login lại với Auth Token
docker login container-registry.oracle.com
```

### Container không khởi động

```bash
# Xem logs chi tiết
docker compose logs oracle-db

# Kiểm tra RAM (cần ít nhất 2GB free)
docker stats
```

### Reset database hoàn toàn

```bash
docker compose down -v
docker compose up -d
```

---

## 📁 Cấu trúc Scripts

```text
scripts/setup/
├── 01_create_users.sql    # Users: lib_project, lib_admin, system_orcl_free, library
├── 02_create_tables.sql   # Tables: branches, user_info, categories, books, borrow_history
├── 03_setup_vpd.sql       # VPD policies (row-level security)
├── 04_setup_audit.sql     # Standard Auditing + FGA
└── 05_setup_ols.sql       # Oracle Label Security (MAC)
```

---

## 🔒 Security Users (Separation of Duties)

| User              | Trách nhiệm                    |
|-------------------|--------------------------------|
| `lib_project`     | Quản lý VPD + Fine-Grained Audit |
| `lib_admin`       | Quản lý OLS (Oracle Label Security) |
| `system_orcl_free`| Quản lý ODV (Oracle Database Vault) |
| `library`         | Schema chứa dữ liệu ứng dụng   |
