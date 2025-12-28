# ĐỒ ÁN MÔN HỌC: BẢO MẬT CƠ SỞ DỮ LIỆU

## 📚 Tên đề tài: Web Quản lý Người dùng Thư viện

---

## I. THÔNG TIN CHUNG

| Thông tin | Chi tiết |
|-----------|----------|
| **Môn học** | Bảo mật Cơ sở dữ liệu |
| **Đề tài** | Xây dựng ứng dụng Web quản lý người dùng Thư viện |
| **CSDL** | Oracle Database 23ai Free Edition |
| **Ngôn ngữ Backend** | Python (FastAPI) |
| **Ngôn ngữ Frontend** | HTML/CSS/JavaScript hoặc React |
| **Nhóm** | 3-4 sinh viên |

---

## II. MÔ TẢ ĐỀ TÀI

### 1. Tổng quan

Xây dựng ứng dụng web **"Quản lý Người dùng Thư viện"** theo mô hình 3 lớp (3-layer architecture):

```
┌─────────────────────────────────────────────────────────────┐
│                        USER (Browser)                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│              PRESENTATION LAYER (Frontend)                   │
│         HTML/CSS/JS hoặc React + REST API Client             │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTP/REST
┌─────────────────────────▼───────────────────────────────────┐
│                BUSINESS LAYER (Backend)                      │
│              Python FastAPI + Business Logic                 │
└─────────────────────────┬───────────────────────────────────┘
                          │ Oracle Driver (oracledb)
┌─────────────────────────▼───────────────────────────────────┐
│                   DATA LAYER (Database)                      │
│                    Oracle Database 23ai                      │
│    ┌─────────────────────────────────────────────────┐      │
│    │  🔒 VPD  │  🏷️ OLS  │  📊 Audit  │  🛡️ ODV    │      │
│    └─────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 2. Bối cảnh ứng dụng

Hệ thống **Thư viện** với các loại người dùng:

| Vai trò | Mô tả | Quyền hạn |
|---------|-------|-----------|
| **Admin** | Quản trị viên hệ thống | Toàn quyền quản lý users, roles, profiles |
| **Librarian** | Thủ thư | Quản lý sách, mượn/trả |
| **Staff** | Nhân viên | Xem thông tin, hỗ trợ độc giả |
| **Reader** | Độc giả | Xem thông tin cá nhân, lịch sử mượn |

---

## III. CÁC CÔNG NGHỆ BẢO MẬT ORACLE ÁP DỤNG

### 🔐 Mô hình kiểm soát truy cập

Đồ án áp dụng kết hợp các mô hình (**Không sử dụng DAC**):

| Mô hình | Mô tả | Cách áp dụng |
|---------|-------|--------------|
| **MAC** (Mandatory Access Control) | Kiểm soát truy cập bắt buộc dựa trên nhãn bảo mật | Oracle Label Security (OLS) |
| **RBAC** (Role-Based Access Control) | Kiểm soát theo vai trò | Tạo roles: ADMIN_ROLE, LIBRARIAN_ROLE, STAFF_ROLE, READER_ROLE |

> ⚠️ **Lưu ý:** Đồ án **KHÔNG sử dụng DAC** (Discretionary Access Control - GRANT/REVOKE trực tiếp). Thay vào đó, việc kiểm soát truy cập được thực hiện thông qua:
> - **OLS (Oracle Label Security):** Kiểm soát bắt buộc theo mức độ nhạy cảm của dữ liệu
> - **VPD (Virtual Private Database):** Kiểm soát ở mức dòng dữ liệu
> - **ODV (Oracle Database Vault):** Bảo vệ dữ liệu khỏi người dùng đặc quyền
> - **Audit:** Giám sát và ghi nhận mọi hoạt động

---

### 1. 🛡️ VPD - Virtual Private Database (Bảo mật mức dòng)

**Mục đích:** Giới hạn truy xuất dữ liệu ở mức dòng (row-level security) một cách trong suốt.

**Áp dụng trong đồ án:**

| Chính sách | Bảng áp dụng | Mô tả |
|------------|--------------|-------|
| `policy_reader_history` | `BORROW_HISTORY` | Reader chỉ xem được lịch sử mượn sách của chính mình |
| `policy_staff_department` | `STAFF_INFO` | Nhân viên chỉ xem được thông tin nhân viên cùng phòng ban |
| `policy_book_access` | `BOOKS` | Một số sách đặc biệt chỉ librarian mới xem được |

**Tham khảo:** `docs/04_Oracle-Virtual-Private-Database.md`, `docs/05_Oracle-Virtual-Private-Database.md`

---

### 2. 🏷️ OLS - Oracle Label Security (Bảo mật đa cấp)

**Mục đích:** Phân loại dữ liệu và người dùng theo mức độ nhạy cảm, áp dụng mô hình MAC.

**Áp dụng trong đồ án:**

#### Cấu trúc nhãn (Labels):

| Thành phần | Giá trị | Mô tả |
|------------|---------|-------|
| **Level** | `PUBLIC`, `INTERNAL`, `CONFIDENTIAL`, `TOP_SECRET` | Độ nhạy cảm của dữ liệu |
| **Compartment** | `HR`, `FINANCE`, `LIBRARY`, `IT` | Lĩnh vực hoạt động |
| **Group** | `HQ`, `BRANCH_A`, `BRANCH_B` | Chi nhánh thư viện |

#### Gán nhãn cho người dùng:

| User Role | Max Level | Compartments | Groups |
|-----------|-----------|--------------|--------|
| Admin | TOP_SECRET | HR, FINANCE, LIBRARY, IT | HQ |
| Librarian | CONFIDENTIAL | LIBRARY | HQ, BRANCH_A, BRANCH_B |
| Staff | INTERNAL | LIBRARY | BRANCH_A |
| Reader | PUBLIC | - | - |

**Tham khảo:** `docs/06_Oracle-Label-Security.md`, `docs/07_Oracle-Label-Security.md`, `docs/lab-08_Oracle-Label-Security.md`

---

### 3. 📊 Audit - Giám sát hoạt động

**Mục đích:** Ghi lại và theo dõi mọi hoạt động trên CSDL để phát hiện hành vi bất thường.

**Áp dụng trong đồ án:**

| Loại Audit | Mô tả | Đối tượng giám sát |
|------------|-------|-------------------|
| **Statement Auditing** | Giám sát câu lệnh SQL | `CREATE USER`, `DROP USER`, `ALTER USER` |
| **Privilege Auditing** | Giám sát sử dụng quyền | `SELECT ANY TABLE`, `DELETE ANY TABLE` |
| **Object Auditing** | Giám sát trên đối tượng cụ thể | `SELECT`, `UPDATE`, `DELETE` trên bảng `USER_INFO`, `BOOKS` |

#### Các sự kiện cần audit:

```sql
-- Giám sát đăng nhập/đăng xuất
AUDIT SESSION BY ACCESS;

-- Giám sát quản lý user
AUDIT CREATE USER, ALTER USER, DROP USER BY ACCESS;

-- Giám sát thao tác trên dữ liệu nhạy cảm
AUDIT SELECT, INSERT, UPDATE, DELETE ON library.books BY ACCESS;
AUDIT SELECT, UPDATE ON library.user_info BY ACCESS;
```

**Tham khảo:** `docs/lab-09_Audit.md`

---

### 4. 🛡️ ODV - Oracle Database Vault (Bảo vệ dữ liệu khỏi DBA)

**Mục đích:** Ngăn chặn truy cập trái phép từ người dùng đặc quyền (SYS, SYSTEM), thực thi phân tách nhiệm vụ (Separation of Duties).

**Áp dụng trong đồ án:**

#### Realms (Khu vực bảo vệ):

| Realm | Đối tượng bảo vệ | Mô tả |
|-------|------------------|-------|
| `LIBRARY_DATA_REALM` | Schema `LIBRARY` | Bảo vệ dữ liệu thư viện khỏi DBA |
| `SENSITIVE_INFO_REALM` | Bảng `USER_INFO`, `SALARY` | Bảo vệ thông tin nhạy cảm |

#### Command Rules (Luật lệnh):

| Rule | Mô tả |
|------|-------|
| `RESTRICT_DROP_TABLE` | Chặn lệnh DROP TABLE ngoài giờ hành chính |
| `RESTRICT_ALTER_USER` | Chỉ cho phép thay đổi user từ IP nội bộ |
| `PROTECT_AUDIT_TRAIL` | Ngăn xóa audit trail |

#### Factors (Yếu tố ngữ cảnh):

| Factor | Mô tả |
|--------|-------|
| `Client_IP` | Kiểm tra IP truy cập |
| `Session_User` | Kiểm tra user đang đăng nhập |
| `Time_Of_Day` | Kiểm tra thời gian truy cập (giờ hành chính) |

**Tham khảo:** `docs/ODV.md`, `docs/dv-techreport.md`

---

## IV. CHỨC NĂNG ỨNG DỤNG

### A. Chức năng cơ bản (Theo yêu cầu đề)

#### 1. Đăng nhập (Login)
- Áp dụng mã hóa password (SHA-256 hoặc bcrypt)
- Xác thực qua Oracle Database

#### 2. Quản lý User
| Thao tác | Thông tin |
|----------|-----------|
| Tạo/Xóa/Sửa | Username, Password, Default_tablespace, Temporary_tablespace, Quota, Account status, Profile, Role |

#### 3. Quản lý Profile
| Resource | Mô tả |
|----------|-------|
| `SESSIONS_PER_USER` | Số session tối đa |
| `CONNECT_TIME` | Thời gian kết nối tối đa |
| `IDLE_TIME` | Thời gian rảnh tối đa |

#### 4. Quản lý Role
- Tạo/xóa/thay đổi role
- Role có password hoặc không
- Gán quyền cho role

#### 5. Gán/Thu hồi Quyền

**Quyền hệ thống:**
```sql
CREATE PROFILE, ALTER PROFILE, DROP PROFILE
CREATE ROLE, ALTER ANY ROLE, DROP ANY ROLE, GRANT ANY ROLE
CREATE SESSION
CREATE ANY TABLE, ALTER ANY TABLE, DROP ANY TABLE
SELECT ANY TABLE, DELETE ANY TABLE, INSERT ANY TABLE, UPDATE ANY TABLE
CREATE USER, ALTER USER, DROP USER
```

**Quyền đối tượng:**
```sql
SELECT, INSERT, UPDATE, DELETE ON table_name
SELECT, INSERT ON table_name(column_name)
```

#### 6. Hiển thị thông tin (Tables)
- Table quản lý quyền
- Table quản lý role
- Table quản lý profile
- Table quản lý thông tin user

---

### B. Chức năng nghiệp vụ Thư viện (Mở rộng)

| Chức năng | Mô tả | Bảo mật áp dụng |
|-----------|-------|-----------------|
| Quản lý sách | CRUD thông tin sách | VPD (phân quyền theo chi nhánh) |
| Quản lý độc giả | CRUD thông tin độc giả | OLS (phân loại mức nhạy cảm) |
| Mượn/Trả sách | Ghi nhận giao dịch | Audit (giám sát hành vi) |
| Báo cáo thống kê | Dashboard cho admin | ODV (bảo vệ khỏi DBA) |

---

## V. CẤU TRÚC DATABASE

### Các bảng chính

```sql
-- Bảng thông tin người dùng (mở rộng từ Oracle users)
CREATE TABLE user_info (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    oracle_username VARCHAR2(50) NOT NULL UNIQUE,
    full_name VARCHAR2(100),
    email VARCHAR2(100),
    phone VARCHAR2(20),
    address VARCHAR2(255),
    department VARCHAR2(50),        -- Cho VPD phân quyền theo phòng ban
    branch_id NUMBER,               -- Cho OLS phân quyền theo chi nhánh
    sensitivity_level VARCHAR2(20), -- Cho OLS
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng sách
CREATE TABLE books (
    book_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn VARCHAR2(20) UNIQUE,
    title VARCHAR2(255) NOT NULL,
    author VARCHAR2(100),
    category VARCHAR2(50),
    branch_id NUMBER,               -- Chi nhánh sở hữu
    sensitivity_label NUMBER,       -- OLS label tag
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng lịch sử mượn sách
CREATE TABLE borrow_history (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id NUMBER REFERENCES user_info(user_id),
    book_id NUMBER REFERENCES books(book_id),
    borrow_date DATE DEFAULT SYSDATE,
    return_date DATE,
    status VARCHAR2(20) DEFAULT 'BORROWING',
    created_by VARCHAR2(50)         -- Cho VPD kiểm tra
);
```

---

## VI. TÀI LIỆU THAM KHẢO

| File | Nội dung |
|------|----------|
| `docs/04_Oracle-Virtual-Private-Database.md` | VPD cơ bản, Row-level Security |
| `docs/05_Oracle-Virtual-Private-Database.md` | VPD nâng cao, Column Sensitive |
| `docs/06_Oracle-Label-Security.md` | OLS cơ bản, Labels, Levels, Compartments |
| `docs/07_Oracle-Label-Security.md` | OLS nâng cao, User Labels, Policies |
| `docs/lab-08_Oracle-Label-Security.md` | OLS thực hành, Labeling Function |
| `docs/lab-09_Audit.md` | Standard Auditing |
| `docs/ODV.md` | Oracle Database Vault thực hành |
| `docs/dv-techreport.md` | Database Vault Technical Report |
| `docs/MAC.md` | Lý thuyết mô hình MAC/DAC/RBAC |

---

## VII. HƯỚNG DẪN CHẠY PROJECT

### 1. Khởi động Oracle Database

```bash
cd server
docker compose up -d
# Đợi 5-10 phút cho database khởi tạo
docker compose logs -f oracle-db
```

### 2. Kết nối Database

| Thông số | Giá trị |
|----------|---------|
| Host | `localhost` |
| Port | `1521` |
| Service Name | `THUVIEN_PDB` |
| SYS Password | `Oracle123` |

### 3. Chạy Backend

```bash
cd server
pip install -r requirements.txt
python main.py
```

### 4. Truy cập ứng dụng

- **API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **Oracle EM Express:** https://localhost:5500/em

---

## VIII. PHÂN CÔNG CÔNG VIỆC

| STT | Công việc | Thành viên | Deadline |
|-----|-----------|------------|----------|
| 1 | Setup Oracle + Docker | | |
| 2 | Thiết kế Database Schema | | |
| 3 | Implement VPD | | |
| 4 | Implement OLS | | |
| 5 | Implement Audit | | |
| 6 | Implement ODV | | |
| 7 | Backend API | | |
| 8 | Frontend UI | | |
| 9 | Testing & Documentation | | |

---

*Cập nhật lần cuối: 29/12/2024*