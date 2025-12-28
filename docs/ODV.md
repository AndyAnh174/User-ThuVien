Dưới đây là nội dung từ file PDF bạn gửi đã được chuyển đổi sang định dạng Markdown.

# Thực hành Oracle Database Vault (ODV)

## 1. Mục tiêu và Tổng quan

Để thực hành Oracle Database Vault (ODV), cần hiểu mục tiêu là **bảo vệ dữ liệu nhạy cảm khỏi quản trị viên có đặc quyền (SYS/SYSTEM)**, **thực thi phân tách nhiệm vụ (SoD)** và thiết lập **khu vực bảo vệ (Realms)**, **luật (Rules)**, **yếu tố ngữ cảnh (Factors)** để kiểm soát truy cập.

Cách thực hành bao gồm:
*   Cài đặt, cấu hình các chính sách.
*   Định nghĩa **Realms** để quản lý truy cập bảng.
*   Định nghĩa **Rules** để kiểm soát các lệnh SQL.
*   Sử dụng các **Factor** như giờ làm việc/địa chỉ IP để tăng cường bảo mật.

Mục đích nhằm đảm bảo tuân thủ và giảm thiểu rủi ro từ nội bộ.

> **Thông tin cấu hình:**
> *   **Pass configure Oracle Database Vault:** `ChauODV#123`

---

## 2. Hình ảnh minh họa cấu hình (Tóm tắt)

*(Tài liệu bao gồm các ảnh chụp màn hình quá trình cấu hình trên Oracle Database Configuration Assistant - DBCA và SQL Developer)*

*   **Kết nối cơ sở dữ liệu:** Thiết lập kết nối cho `SYS` và user `ChauODV`.
*   **DBCA - Step 4:** Chọn "Configure Oracle Database Vault". Thiết lập `Database Vault owner` (SYSTEM) và tạo tài khoản quản lý riêng (`Create a separate account manager`).
*   **DBCA - Step 5:** Chọn chế độ kết nối (Dedicated server mode).
*   **DBCA - Step 6:** Cấu hình Oracle Machine Learning (nếu có).
*   **DBCA - Summary & Finish:** Tổng hợp và hoàn tất quá trình cài đặt.
*   **Lưu ý:** Cấu hình cho Pluggable Database.

---

## 3. Các bước thực hành Oracle Database Vault cơ bản

### 1. Cài đặt và Kích hoạt
*   Đảm bảo bạn có phiên bản Oracle Database hỗ trợ ODV (thường là Enterprise Edition) và đã mua license phù hợp.
*   Cài đặt tùy chọn [Database Vault](https://docs.oracle.com/en/database/) trong quá trình cài đặt hoặc thêm vào sau.
*   Kích hoạt Database Vault bằng tài khoản có đặc quyền cao (ví dụ: `SYS` với quyền `DBA` và `DV_SYS_ADMIN`).

### 2. Cấu hình các Thành phần Chính
*   **Realm (Khu vực bảo vệ):**
    *   Định nghĩa các bảng, view, procedure nhạy cảm (ví dụ: bảng lương, thông tin khách hàng) vào một Realm.
*   **Rules (Luật):**
    *   Tạo các luật để ngăn chặn hoặc cho phép các lệnh `SELECT`, `INSERT`, `UPDATE`, `DELETE` trên các đối tượng trong Realm, ngay cả với người dùng có đặc quyền như `SYS`.
    *   *Ví dụ:* Ngăn mọi truy cập vào bảng `EMPLOYEES` trừ khi truy cập qua một ứng dụng đã được định nghĩa hoặc giờ làm việc nhất định.
*   **Factors (Yếu tố):**
    *   Xác định các điều kiện ngữ cảnh (ví dụ: thời gian truy cập, địa chỉ IP nguồn, ứng dụng sử dụng) để tăng cường kiểm soát truy cập.
*   **Separation of Duties (Phân tách nhiệm vụ):**
    *   Tạo các Role (ví dụ: `DV_OWNER`, `DV_ADMIN`, `DV_ACCTMGR`) và chỉ định người dùng vào các role này để phân quyền quản trị, không cho phép một người kiểm soát mọi thứ.

### 3. Thực hành và Kiểm tra
*   Thử đăng nhập với tài khoản `SYS` và cố gắng truy cập/thay đổi dữ liệu trong Realm đã bảo vệ bằng luật (để kiểm chứng việc bị chặn).
*   Thử truy cập từ một IP hoặc thời gian không được phép, hệ thống sẽ chặn lại.
*   Sử dụng các giao diện quản trị của ODV (như `DBMS_MACADM` package, hoặc giao diện người dùng) để kiểm tra các chính sách đã thiết lập.