# 🛡️ Giải Mã Công Nghệ Bảo Mật: Từ Lý Thuyết Đến Code (Deep Dive)

Tài liệu này được soạn thảo đặc biệt để giải thích chi tiết cách 5 công nghệ bảo mật Oracle hoạt động trong dự án, **chúng nằm ở đâu trong mã nguồn**, và **tại sao chúng lại quan trọng**. Phù hợp để giải thích cho người mới bắt đầu.

---

## 🏗️ Kiến trúc Tổng quan (Bức tranh lớn)

Trước khi đi vào chi tiết, hãy tưởng tượng hệ thống như một **Ngân hàng**:
1.  **Frontend (Giao diện Web)**: Là quầy giao dịch, nơi khách hàng yêu cầu dịch vụ.
2.  **Backend (Python API)**: Là nhân viên ngân hàng, nhận yêu cầu và xử lý.
3.  **Oracle Database**: Là kho tiền (Két sắt), nơi chứa dữ liệu quý giá nhất.

**Các công nghệ bảo mật chính là các lớp khóa bảo vệ kho tiền này.**

---

## 1. VPD (Virtual Private Database) - "Kính Phân Cực"
### 💡 Khái niệm đơn giản
Hãy tưởng tượng bạn đeo một chiếc kính đặc biệt. Khi nhìn vào một tủ hồ sơ:
- Nếu bạn là **Trưởng phòng Hà Nội**: Bạn chỉ nhìn thấy hồ sơ của khách hàng Hà Nội.
- Nếu bạn là **Trưởng phòng TP.HCM**: Bạn chỉ nhìn thấy hồ sơ của khách hàng TP.HCM.
Dù cả hai cùng nhìn vào **một tủ hồ sơ duy nhất**, nhưng thấy nội dung khác nhau. Đó là VPD.

### 📂 Cài đặt trong Code (Nó nằm ở đâu?)

#### A. Trong Database (SQL) - *Nơi tạo ra chiếc kính*
- **File:** `server/scripts/setup/03_setup_vpd.sql`
- **Chi tiết:**
    - Chúng ta tạo ra một "Hàm chính sách" (Policy Function) tên là `auth_orders`.
    - Hàm này kiểm tra: "Người đang xem là ai?". Nếu là nhân viên Chi nhánh 1 -> Trả về mệnh đề `branch_id = 1`.
    - Oracle tự động dán mệnh đề này vào sau câu lệnh `SELECT` của mọi người dùng.

#### B. Trong Backend (Python) - *Nơi đeo kính cho user*
- **File:** `server/app/database.py`
- **Hàm:** `init_session`
- **Chi tiết:** Khi người dùng đăng nhập, Python sẽ chạy lệnh:
  ```sql
  CALL DBMS_SESSION.SET_IDENTIFIER(:user_id)
  ```
  Lệnh này báo cho Oracle biết "Ai đang đăng nhập" để Oracle chọn đúng cái "kính" (Chính sách VPD) phù hợp.

---

## 2. Data Redaction - "Bút Xóa Ma Thuật"
### 💡 Khái niệm đơn giản
Giống như khi bạn xem tivi, những cảnh nhạy cảm sẽ bị làm mờ hoặc che đi. Data Redaction làm điều tương tự với dữ liệu. Khi dữ liệu được lấy ra khỏi kho, Oracle dùng "bút xóa" bôi đen số điện thoại hoặc email ngay lập tức trước khi gửi cho người dùng. Dữ liệu gốc trong kho vẫn nguyên vẹn.

### 📂 Cài đặt trong Code

#### A. Trong Database (SQL) - *Nơi quy định cái gì cần che*
- **File:** `server/scripts/setup/01_create_users.sql` (Hoặc đôi khi tách riêng).
- **Chi tiết:** Sử dụng gói `DBMS_REDACT`.
    - Quy định: Cột `email` trong bảng `users`.
    - Cách che: `PARTIAL` (Che một phần). Ví dụ: `v***@gmail.com`.
    - Điều kiện: Nếu người xem KHÔNG phải là ADMIN thì che.

#### B. Trong Backend (Python)
- **Không cần code gì cả!**
- Đây là cái hay của Oracle. Python chỉ việc `SELECT email FROM users`, và dữ liệu nhận được **đã bị che sẵn rồi**. Lập trình viên không cần viết logic che giấu trên Python.

---

## 3. OLS (Oracle Label Security) - "Thẻ Bài Bảo Mật"
### 💡 Khái niệm đơn giản
Mỗi tài liệu mật được dán một cái tem: **TOP SECRET (Tối Mật)**, **CONFIDENTIAL (Mật)**, hoặc **PUBLIC (Công khai)**.
Mỗi nhân viên cũng được phát một cái thẻ bài tương ứng.
- Ông có thẻ **CONFIDENTIAL** thì xem được hồ sơ **CONFIDENTIAL** và **PUBLIC**.
- Nhưng ông KHÔNG thể xem hồ sơ **TOP SECRET**.

### 📂 Cài đặt trong Code

#### A. Trong Database (SQL)
- **File:** `server/scripts/setup/05_setup_ols.sql`
- **Chi tiết:**
    - Tạo các Policy, Level (Mức độ mật).
    - Gán nhãn cho từng dòng dữ liệu (Row).

#### B. Trong Backend (Python) - *Trao thẻ bài*
- **File:** `server/app/routers/auth.py` (Lúc Login)
- **Chi tiết:** Khi user đăng nhập thành công, hệ thống Oracle tự động kiểm tra "thẻ bài" (Label) của user đó trong DB. Python không cần can thiệp logic so sánh, chỉ việc hiển thị kết quả. Nếu user không đủ quyền, Oracle sẽ trả về kết quả rỗng (như thể dữ liệu đó không tồn tại).

---

## 4. Oracle Database Vault (ODV) - "Vùng Cấm Địa"
### 💡 Khái niệm đơn giản
Bình thường, ông chủ (Super Admin/SYS) có quyền vào mọi phòng ban.
Nhưng Database Vault tạo ra một "Két Sắt Riêng" (Realm) chứa thông tin lương thưởng.
Quy định: **"Ngay cả ông chủ cũng không được vào Két Sắt này, chỉ có Kế Toán Trưởng mới được vào"**.
Điều này ngăn chặn Admin hệ thống (IT) tò mò xem trộm dữ liệu nhạy cảm của nghiệp vụ.

### 📂 Cài đặt trong Code
- **Cấu hình:** Thường được cấu hình qua giao diện Console hoặc Script SQL đặc biệt (trong dự án này là giả lập logic qua Role/Privileges vì bản Oracle Free có hạn chế về DV đầy đủ, nhưng logic được mô phỏng trong `06_fix_admin_privs.sql`).
- **Trong Python:** Python sẽ nhận được lỗi `ORA-01031: insufficient privileges` nếu cố tình dùng tài khoản Admin hạ tầng để truy cập dữ liệu nghiệp vụ được bảo vệ.

---

## 5. Unified Auditing - "Camera Giám Sát"
### 💡 Khái niệm đơn giản
Hệ thống Camera ghi lại mọi hành động:
- Ai đã vào kho lúc mấy giờ?
- Ai đã thử mở két sắt nhưng sai mật khẩu?
- Ai đã lấy đi hồ sơ nào?

### 📂 Cài đặt trong Code

#### A. Trong Database (SQL) - *Lắp đặt Camera*
- **File:** `server/scripts/setup/04_setup_audit.sql`
- **Chi tiết:** Tạo `AUDIT POLICY`.
    - `CREATE AUDIT POLICY all_actions_pol ACTIONS ALL`: Ghi lại tất cả.
    - `AUDIT POLICY all_actions_pol`: Bật camera lên.

#### B. Trong Backend (Python) - *Phòng quan sát Camera*
- **File:** `server/app/repositories/audit_repository.py`
- **Chi tiết:**
    - Hàm `get_audit_trail`: Chạy câu lệnh `SELECT * FROM UNIFIED_AUDIT_TRAIL`.
    - Đây chính là việc trích xuất băng ghi hình từ Camera để hiển thị lên màn hình (Frontend) cho Admin xem.

---

## 📝 Tóm tắt File Code quan trọng

| Công nghệ | File SQL (Cài đặt) | File Python (Sử dụng) |
| :--- | :--- | :--- |
| **VPD** | `scripts/setup/03_setup_vpd.sql` | `app/database.py` (Session Init) |
| **Audit** | `scripts/setup/04_setup_audit.sql` | `app/repositories/audit_repository.py` |
| **OLS** | `scripts/setup/05_setup_ols.sql` | Tự động (Transparent) |
| **Redaction**| `scripts/setup/01_create_users.sql`| Tự động (Transparent) |
| **Users** | `scripts/setup/01_create_users.sql`| `app/routers/users.py` |

Hy vọng tài liệu này giúp bạn hiểu rõ "bộ máy" bên dưới mui xe! 🚗💨
