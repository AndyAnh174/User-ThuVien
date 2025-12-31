# 🎬 HƯỚNG DẪN DEMO TÍNH NĂNG BẢO MẬT TRÊN UI

> **Mục tiêu:** Demo trực quan 4 công nghệ bảo mật Oracle trên giao diện web.  
> **URL Frontend:** http://localhost:3000  
> **URL API Docs:** http://localhost:8000/docs

---

## 📋 CHUẨN BỊ TRƯỚC KHI DEMO

### Tài khoản demo:

| Role | Username | Password | Chi nhánh | Mức truy cập |
|------|----------|----------|-----------|---------------|
| 👑 **Admin** | `admin_user` | `Admin123` | Trụ sở chính | Thấy tất cả |
| 📚 **Thủ thư** | `librarian_user` | `Librarian123` | Chi nhánh A | CN mình + HQ |
| 👔 **Nhân viên** | `staff_user` | `Staff123` | Chi nhánh A | Chỉ CN mình |
| 📖 **Độc giả** | `reader_user` | `Reader123` | Chi nhánh A | Tất cả (OLS filter) |

---

## 🛡️ DEMO 1: VPD (Virtual Private Database)
> **"Kính phân cực - Mỗi người thấy dữ liệu theo chi nhánh"**

### Kịch bản: Phân quyền xem sách theo chi nhánh

#### Logic VPD:
- **Admin**: Thấy tất cả sách ở mọi chi nhánh
- **Librarian**: Thấy sách chi nhánh mình + Trụ sở chính (HQ)
- **Staff**: Chỉ thấy sách chi nhánh mình
- **Reader**: Thấy tất cả (OLS sẽ filter theo sensitivity level)

#### Bước 1: Login với `staff_user`
1. Mở http://localhost:3000/login
2. Nhập: `staff_user` / `Staff123`
3. Click **Đăng nhập**
4. Vào menu **Sách** → Đếm số sách (chỉ thấy chi nhánh A)

#### Bước 2: So sánh với Librarian
1. **Logout** (góc trái dưới)
2. Login lại với `librarian_user` / `Librarian123`
3. Vào lại **Sách**
4. **So sánh:** Librarian thấy **NHIỀU sách hơn** (có thêm sách HQ)

#### Bước 3: So sánh với Admin
1. Login với `admin_user` / `Admin123`
2. Vào **Sách** → Thấy TẤT CẢ sách ở mọi chi nhánh

### ✅ Demo thành công khi:
```
┌─────────────────────────────────────────────────────────────┐
│  admin_user:      Thấy 12 sách (tất cả chi nhánh)           │
│  librarian_user:  Thấy 8 sách (Chi nhánh A + HQ)            │
│  staff_user:      Thấy 3 sách (Chỉ Chi nhánh A)             │
│  reader_user:     Thấy 6 sách PUBLIC (OLS filter)           │
└─────────────────────────────────────────────────────────────┘
```

### 📸 Screenshot cần chụp:
1. Màn hình sách khi login `staff_user` (ít sách)
2. Màn hình sách khi login `librarian_user` (nhiều hơn)
3. Màn hình sách khi login `admin_user` (tất cả)
4. So sánh cột "Chi nhánh" giữa các user

---

## 🏷️ DEMO 2: OLS (Oracle Label Security)
> **"Thẻ bài bảo mật - Phân cấp độ mật dữ liệu"**

### Kịch bản: Nhân viên không thấy sách CONFIDENTIAL

#### Bước 1: Login với `staff_user`
1. Login: `staff_user` / `Staff123`
2. Vào **Quản lý sách**

#### Bước 2: Quan sát cột "Độ mật"
- Staff chỉ thấy sách có label: **PUBLIC**, **INTERNAL**
- **KHÔNG** thấy sách **CONFIDENTIAL** hoặc **TOP_SECRET**

#### Bước 3: So sánh với các role khác

| Login với | Sách thấy được |
|-----------|----------------|
| `reader_user` | Chỉ **PUBLIC** |
| `staff_user` | **PUBLIC** + **INTERNAL** |
| `librarian_user` | **PUBLIC** + **INTERNAL** + **CONFIDENTIAL** |
| `admin_user` | Tất cả (bao gồm **TOP_SECRET**) |

### ✅ Demo thành công khi:
- User thấy ĐÚNG số sách theo level của họ
- Không có cách nào để user thấy sách cấp cao hơn

### 📸 Screenshot cần chụp:
1. `reader_user` - chỉ thấy sách PUBLIC
2. `admin_user` - thấy tất cả bao gồm TOP_SECRET
3. Cùng 1 sách TOP_SECRET: Admin thấy, Reader không thấy

---

## 🛡️ DEMO 3: ODV (Oracle Database Vault)
> **"Vùng cấm địa - Ngăn DBA truy cập dữ liệu"**

### Kịch bản: Chứng minh SYS không thể xem dữ liệu

> ⚠️ **Lưu ý:** ODV demo tốt nhất qua SQL command line

#### Bước 1: Mở Terminal/SQL*Plus

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123@//localhost:1521/FREEPDB1 as sysdba
```

#### Bước 2: Thử truy cập bảng LIBRARY.BOOKS

```sql
SELECT * FROM library.books;
```

#### Kết quả mong đợi:
```
ORA-01031: insufficient privileges
```
hoặc
```
ORA-47401: Realm violation for LIBRARY_REALM
```

#### Bước 3: Chứng minh Application User vẫn access được

```sql
-- Đăng nhập với app user
CONNECT admin_user/Admin123@localhost:1521/FREEPDB1

-- Truy cập data
SELECT COUNT(*) FROM library.books;

-- Kết quả: 20 (hoặc số sách có trong DB)
```

### ✅ Demo thành công khi:
```
┌────────────────────────────────────────────┐
│  SYS (DBA):       ❌ BỊ CHẶN               │
│  SYSTEM (DBA):    ❌ BỊ CHẶN               │
│  admin_user:      ✅ Truy cập OK           │
│  librarian_user:  ✅ Truy cập OK           │
└────────────────────────────────────────────┘
```

### 📸 Screenshot cần chụp:
1. Lỗi ORA-01031 hoặc ORA-47401 khi SYS query
2. Query thành công khi dùng admin_user

---

## 📊 DEMO 4: AUDIT (Unified Auditing)
> **"Camera giám sát - Ghi lại mọi hành động"**

### Kịch bản: Xem ai đã truy cập dữ liệu và khi nào

#### Bước 1: Login với `admin_user`
1. Login: `admin_user` / `Admin123`

#### Bước 2: Mở trang Audit Log
1. Vào menu **Audit Log** hoặc **Lịch sử hoạt động**
2. Xem danh sách các hoạt động được ghi nhận

#### Bước 3: Tìm kiếm hoạt động
- Filter theo **Username**
- Filter theo **Thời gian**
- Filter theo **Loại hành động** (SELECT, INSERT, UPDATE, DELETE)

### Thông tin trong Audit Log:

| Cột | Mô tả | Ví dụ |
|-----|-------|-------|
| **Thời gian** | Khi nào hành động xảy ra | 31/12/2024 15:30:00 |
| **Username** | Ai thực hiện | LIBRARIAN_USER |
| **Action** | Loại hành động | SELECT |
| **Object** | Đối tượng tác động | LIBRARY.BOOKS |
| **IP Address** | Từ đâu | 192.168.1.100 |
| **Return Code** | Thành công/thất bại | 0 (OK) |

#### Bước 4: Demo phát hiện hành vi bất thường

1. **Login thất bại nhiều lần:**
   - Thử login sai password 3 lần
   - Vào Audit Log → Thấy ghi nhận "LOGIN FAILED"

2. **Truy cập ngoài giờ:**
   - Filter theo giờ → Phát hiện access lúc 2AM chẳng hạn

### ✅ Demo thành công khi:
- Mọi SELECT, INSERT, UPDATE, DELETE đều được ghi nhận
- Login thất bại được ghi nhận
- Có thể truy vết: AI, LÀM GÌ, KHI NÀO

### 📸 Screenshot cần chụp:
1. Trang Audit Log với danh sách hoạt động
2. Filter theo username cụ thể
3. Chi tiết 1 record audit (nếu có)

---

## 🎯 KỊCH BẢN DEMO TỔNG HỢP (5 PHÚT)

### Phút 1-2: VPD + OLS

```
1. Mở 2 tab browser cạnh nhau:
   - Tab 1: Login admin_user
   - Tab 2: Login reader_user
   
2. Cả 2 cùng vào "Quản lý sách"

3. HIGHLIGHT: 
   - Admin thấy 20 sách (tất cả level)
   - Reader thấy 5 sách (chỉ PUBLIC)
```

### Phút 3: ODV

```
1. Mở Terminal, chạy:
   docker exec -it oracle23ai sqlplus sys/Oracle123@//localhost:1521/FREEPDB1 as sysdba

2. Query:
   SELECT * FROM library.books;
   
3. HIGHLIGHT: Lỗi "insufficient privileges"
   → DBA bị chặn, dữ liệu an toàn!
```

### Phút 4-5: Audit

```
1. Quay lại browser, login admin_user
2. Vào "Audit Log"
3. HIGHLIGHT: 
   - Tất cả login vừa thực hiện đều được ghi nhận
   - Mọi thao tác có thể truy vết
```

---

## 📝 SLIDE TÓM TẮT CHO BÁO CÁO

### Kết quả Demo:

| Công nghệ | Chức năng | Demo thành công |
|-----------|-----------|-----------------|
| **VPD** | Row-level security theo chi nhánh | ✅ |
| **OLS** | Phân cấp độ mật dữ liệu | ✅ |
| **ODV** | Chặn DBA truy cập data | ✅ |
| **Audit** | Ghi nhận mọi hoạt động | ✅ |

### Kết luận:
> Hệ thống áp dụng mô hình **"Security in Depth"** - bảo mật đa tầng từ Database đến Application, đảm bảo **"ai có quyền gì, thấy gì"** được kiểm soát chặt chẽ.

---

## 🔗 API ENDPOINTS ĐỂ TEST

Nếu muốn demo qua API (Swagger UI):

| Endpoint | Mô tả |
|----------|-------|
| `GET /api/books` | Lấy danh sách sách (VPD + OLS apply) |
| `GET /api/users` | Danh sách users (chỉ Admin) |
| `GET /api/audit` | Audit logs (chỉ Admin) |
| `GET /api/health` | Health check |

### Cách test với Swagger:
1. Mở http://localhost:8000/docs
2. Click **Authorize** (góc phải)
3. Nhập username/password
4. Thử các endpoint

---

*Cập nhật: 31/12/2024*
