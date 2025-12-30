# 📚 Hệ Thống Quản Lý Thư Viện Bảo Mật (Secure Library Management System)

> **Dự án Mẫu (Capstone Project)**: Trình diễn giải pháp bảo mật dữ liệu toàn diện trên nền tảng **Oracle Database 23ai**, tích hợp với ứng dụng web hiện đại (Next.js + FastAPI).

![Project Status](https://img.shields.io/badge/Status-Completed-success)
![Oracle Database](https://img.shields.io/badge/Oracle-23ai-red)
![Frontend](https://img.shields.io/badge/Frontend-Next.js_16-black)
![Backend](https://img.shields.io/badge/Backend-FastAPI-teal)

---

## 📖 Giới Thiệu

Đây không chỉ là một phần mềm quản lý thư viện thông thường. Dự án này được xây dựng để giải quyết bài toán cốt lõi của mọi doanh nghiệp số: **Làm sao để chia sẻ dữ liệu cho nhân viên làm việc nhưng vẫn đảm bảo an toàn tuyệt đối?**

Hệ thống áp dụng kiến trúc **"Security in Depth"** (Bảo mật chiều sâu), đưa các luật lệ bảo mật từ tầng Ứng dụng xuống thẳng tầng Database, đảm bảo không ai - kể cả Admin hệ thống - có thể lạm quyền.

---

## 🛡️ Điểm Nhấn Công Nghệ (Core Features)

Hệ thống tích hợp 5 công nghệ bảo mật tiên tiến nhất của Oracle.
*(Bạn có thể xem giải thích chi tiết và vị trí code của từng công nghệ tại tài liệu [Giải Mã Công Nghệ Bảo Mật - Deep Dive](./docs/SECURITY_DEEP_DIVE.md))*

### 1. VPD (Virtual Private Database)
*   **Chức năng**: "Kính phân cực" - Mỗi người chỉ thấy dữ liệu mình được phép thấy.
*   **Demo**: Thủ thư Chi nhánh 1 không thể thấy sách của Chi nhánh 2.

### 2. Data Redaction
*   **Chức năng**: "Bút xóa ma thuật" - Che dữ liệu nhạy cảm (SĐT, Email) ngay khi xuất ra màn hình.
*   **Demo**: Nhân viên nhìn thấy email khách hàng dưới dạng `n***@gmail.com`.

### 3. OLS (Oracle Label Security)
*   **Chức năng**: "Thẻ bài bảo mật" - Phân cấp dữ liệu (Mật/Tối Mật/Công Khai).
*   **Demo**: Nhân viên thường không thể truy cập hồ sơ khách hàng VIP (dán nhãn CONFIDENTIAL).

### 4. Oracle Database Vault
*   **Chức năng**: "Vùng cấm địa" - Ngăn chặn Super Admin truy cập dữ liệu nghiệp vụ nhạy cảm.
*   **Demo**: Admin hệ thống (IT) không thể vào xem bảng Lương hoặc Lịch sử mượn trả.

### 5. Unified Auditing
*   **Chức năng**: "Camera giám sát" - Ghi lại mọi hành động khả nghi.
*   **Demo**: Giao diện Audit Log cho phép truy vết ai đã xóa dữ liệu, vào lúc nào.

---

## 🚀 Hướng Dẫn Cài Đặt (Quick Start)

> **Lưu ý**: Đây là hướng dẫn nhanh. Nếu bạn cần hướng dẫn từng bước chi tiết (Screenshot, giải thích lệnh), vui lòng xem: **[📘 Hướng Dẫn Cài Đặt Chi Tiết (Setup Guide)](./docs/SETUP_GUIDE.md)**.

### Yêu cầu hệ thống
*   Docker Desktop & Docker Compose
*   Node.js 18+
*   Python 3.10+

### Bước 1: Khởi tạo Database (Trái tim hệ thống)
```bash
cd server
docker-compose up -d
# ☕ Pha một tách cà phê và đợi khoảng 3-5 phút để Oracle khởi động xong (Health: healthy)
```

### Bước 2: Nạp Dữ liệu & Kích hoạt Bảo mật
Chạy lần lượt các script SQL trong thư mục `server/scripts/setup`.
*(Lưu ý: Nếu không rành SQL, bạn có thể dùng tool như SQL Developer hoặc DBeaver kết nối và chạy)*.

Hoặc dùng command line (nếu đã cài sqlplus trong docker):
```bash
# Script 1: Tạo users
docker exec -i oracle23ai sqlplus sys/Oracle123 as sysdba @"/opt/oracle/scripts/setup/01_create_users.sql"
# ... (Tương tự cho các script 02 đến 06)
```

### Bước 3: Chạy Backend (API)
```bash
cd server
# Tạo môi trường ảo
python -m venv venv
# Kích hoạt (Windows): venv\Scripts\activate
# Kích hoạt (Mac/Linux): source venv/bin/activate

# Cài thư viện
pip install -r requirements.txt

# Chạy server
python main.py
# ✅ API sẵn sàng tại: http://localhost:8000
```

### Bước 4: Chạy Frontend (Web App)
```bash
cd client
npm install
npm run dev
# ✅ Web App sẵn sàng tại: http://localhost:3000
```

---

## 👤 Tài Khoản Demo (Test Users)

| Role | Username | Password | Kịch bản Test |
| :--- | :--- | :--- | :--- |
| **Super Admin** | `admin_user` | `Admin123` | Quản trị toàn hệ thống. Test Audit Log, Users. |
| **Thủ thư (CN1)** | `librarian_user`| `Librarian123`| Chỉ thấy Sách/Phiếu mượn tại **Chi nhánh 1** (Test VPD). |
| **Nhân viên** | `staff_user` | `Staff123` | Thấy thông tin độc giả bị che SĐT/Email (Test Redaction). |
| **Độc giả** | `nguyen_van_a` | `User123` | Chỉ thấy lịch sử mượn sách của chính mình. |

---

## 📂 Tài Liệu Tham Khảo
- [📖 Hướng Dẫn Sử Dụng Chi Tiết](./USER_GUIDE.md): Cách dùng các chức năng trên Web.
- [🛡️ Giải Mã Công Nghệ - Deep Dive](./docs/SECURITY_DEEP_DIVE.md): Giải thích code và nguyên lý hoạt động (Dành cho Dev/Giáo viên).

---

## 🤝 Đóng Góp
Dự án được thực hiện bởi **[Tên Bạn]** với sự hỗ trợ của **Antigravity AI**.
Mọi ý kiến đóng góp xin gửi về Issues hoặc Pull Request.
