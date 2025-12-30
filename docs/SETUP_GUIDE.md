# 🛠️ Hướng Dẫn Cài Đặt Chi Tiết (Step-by-Step Setup Guide)

Tài liệu này hướng dẫn bạn dựng lại toàn bộ hệ thống từ mã nguồn (Source Code).

---

## 💻 1. Yêu Cầu Hệ Thống (Prerequisites)

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt:

1.  **Docker Desktop**: Để chạy Oracle Database.
    *   [Tải Docker Desktop](https://www.docker.com/products/docker-desktop/)
    *   *Lưu ý*: Oracle Database khá nặng, hãy cấu hình Docker cho phép dùng ít nhất **4GB RAM**.
2.  **Node.js**: Để chạy trang web (Frontend).
    *   Phiên bản: 18.17.0 trở lên.
    *   [Tải Node.js](https://nodejs.org/)
3.  **Python**: Để chạy API (Backend).
    *   Phiên bản: 3.10 trở lên.
    *   [Tải Python](https://www.python.org/)
4.  **Git**: Để tải mã nguồn (nếu cần).

---

## 🗄️ 2. Cài Đặt Database (Oracle 23ai)

Đây là bước quan trọng nhất. Chúng ta dùng Docker để không phải cài trực tiếp Oracle vào máy (rất nặng và khó gỡ).

### Bước 2.1: Khởi động Database
1.  Mở Terminal (CMD hoặc PowerShell).
2.  Đi vào thư mục `server`:
    ```bash
    cd server
    ```
3.  Chạy lệnh Docker Compose:
    ```bash
    docker-compose up -d
    ```
    *Lần đầu chạy sẽ hơi lâu (khoảng 1-2GB tải về).*
4.  Kiểm tra xem Database đã chạy chưa:
    ```bash
    docker ps
    ```
    Nếu trạng thái là `(healthy)` thì đã sẵn sàng. Nếu đang `(staring)`, hãy đợi thêm vài phút.

### Bước 2.2: Nạp Dữ Liệu & Chính Sách Bảo Mật
Database mới tạo sẽ trống trơn. Chúng ta cần chạy các file kịch bản (script) SQL để tạo bảng và cài đặt bảo mật.

Chạy lần lượt các lệnh sau trong Terminal:

**1. Tạo Users (SysAdmin & Library Owner)**
```bash
docker exec -i oracle23ai sqlplus sys/Oracle123 as sysdba @"/opt/oracle/scripts/setup/01_create_users.sql"
```

**2. Tạo Bảng & Dữ liệu mẫu (Schema & Seed Data)**
```bash
# Lưu ý: Password là Library123
docker exec -i oracle23ai sqlplus library/Library123@localhost:1521/THUVIEN_PDB @"/opt/oracle/scripts/setup/02_create_schema.sql"

docker exec -i oracle23ai sqlplus library/Library123@localhost:1521/THUVIEN_PDB @"/opt/oracle/scripts/setup/03_seed_data.sql"
```

**3. Kích hoạt Bảo mật (Security Features)**
```bash
# VPD (Virtual Private Database)
docker exec -i oracle23ai sqlplus library/Library123@localhost:1521/THUVIEN_PDB @"/opt/oracle/scripts/setup/04_setup_vpd.sql"

# Data Redaction (Che giấu dữ liệu)
docker exec -i oracle23ai sqlplus library/Library123@localhost:1521/THUVIEN_PDB @"/opt/oracle/scripts/setup/05_setup_redaction.sql"

# OLS & Audit (Cần quyền quản trị cao nhất)
docker exec -i oracle23ai sqlplus sys/Oracle123@localhost:1521/THUVIEN_PDB as sysdba @"/opt/oracle/scripts/setup/06_setup_ols_audit.sql"
```

✅ **Xong phần Database!**

---

## ⚙️ 3. Cài Đặt Backend (Python FastAPI)

Backend là cầu nối giữa Web và Database.

### Bước 3.1: Tạo môi trường ảo (Virtual Environment)
Vẫn ở trong thư mục `server`:
```bash
# Tạo môi trường ảo tên là 'venv'
python -m venv venv

# Kích hoạt môi trường (Windows)
venv\Scripts\activate

# Kích hoạt môi trường (Mac/Linux)
# source venv/bin/activate
```
*(Khi kích hoạt thành công, đầu dòng lệnh sẽ có chữ `(venv)`)*

### Bước 3.2: Cài đặt thư viện
```bash
pip install -r requirements.txt
```

### Bước 3.3: Cấu hình kết nối
Kiểm tra file `.env` trong thư mục `server`. Nếu chưa có, hãy copy từ `.env.example`:
```bash
copy .env.example .env
```
Nội dung mặc định thường đã đúng nếu bạn chạy Docker như hướng dẫn trên.

### Bước 3.4: Chạy Server
```bash
python main.py
```
Nếu thấy dòng chữ `Uvicorn running on http://0.0.0.0:8000`, chúc mừng bạn! Backend đã chạy.

---

## 🎨 4. Cài Đặt Frontend (Web App)

Mở một cửa sổ Terminal **mới** (để giữ Backend đang chạy ở cửa sổ cũ).

1.  Đi vào thư mục `client`:
    ```bash
    cd client
    ```
2.  Cài đặt các gói phụ thuộc (Dependencies):
    ```bash
    npm install
    # Hoặc nếu dùng pnpm: pnpm install
    # Hoặc nếu dùng yarn: yarn install
    ```
3.  Chạy ứng dụng:
    ```bash
    npm run dev
    ```
4.  Mở trình duyệt truy cập: `http://localhost:3000`

---

## ❓ 5. Xử Lý Sự Cố (Troubleshooting)

**Q: Lỗi `ORA-12541: TNS:no listener` khi chạy Backend?**
A: Database chưa khởi động xong. Hãy đợi thêm 1-2 phút và thử lại. Dùng `docker ps` để xem trạng thái.

**Q: Lỗi `ORA-28000: the account is locked`?**
A: Tài khoản đăng nhập sai pass nhiều lần bị khóa. Hãy mở khóa bằng lệnh:
```bash
docker exec -i oracle23ai sqlplus sys/Oracle123 as sysdba
ALTER USER <ten_user> ACCOUNT UNLOCK;
```

**Q: Không cài được `cx_Oracle` hay `oracledb` trên Python?**
A: Hãy chắc chắn bạn đã upgrade pip: `python -m pip install --upgrade pip`. Dự án này dùng `oracledb` (Thin mode) nên không cần cài Oracle Instant Client máy trạm.

---
**Chúc bạn thành công!**
