# Hướng dẫn Cài đặt và Chạy Hệ thống Thư viện

## Yêu cầu hệ thống

### Docker
- Docker Desktop (Windows/Mac) hoặc Docker Engine (Linux)
- Tối thiểu 4GB RAM cho Oracle Database

### Backend (Python)
- Python 3.10+
- pip

### Frontend (Next.js)
- Node.js 18+
- npm hoặc yarn

---

## Bước 1: Khởi động Oracle Database

```bash
# Pull và chạy Oracle 23ai Free
docker run -d \
  --name oracle23ai \
  -p 1521:1521 \
  -e ORACLE_PWD=Oracle123 \
  -v ./server/scripts/setup:/opt/oracle/scripts/setup \
  container-registry.oracle.com/database/free:latest

# Chờ database khởi động (khoảng 2-5 phút)
docker logs -f oracle23ai
# Khi thấy "DATABASE IS READY TO USE!" thì tiếp tục
```

---

## Bước 2: Setup Database Schema

**⚠️ QUAN TRỌNG:** Phải chạy đúng thứ tự và restart database đúng chỗ!

### Bước 2.1: Tạo Users và Tables

```bash
# Kết nối vào container với SYS
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Chạy scripts cơ bản
@/opt/oracle/scripts/setup/01_create_users.sql
@/opt/oracle/scripts/setup/02_create_tables.sql
@/opt/oracle/scripts/setup/03_setup_vpd.sql
@/opt/oracle/scripts/setup/04_setup_audit.sql
```

### Bước 2.2: Enable OLS (Oracle Label Security)

```sql
-- Chuyển về CDB Root để enable OLS
ALTER SESSION SET CONTAINER = CDB$ROOT;
@/opt/oracle/scripts/setup/15_enable_ols_system.sql

-- Enable OLS trong PDB
ALTER SESSION SET CONTAINER = FREEPDB1;
@/opt/oracle/scripts/setup/16_enable_ols_pdb.sql

-- Thoát để restart database
EXIT;
```

### Bước 2.3: Restart Database (BẮT BUỘC!)

```bash
docker restart oracle23ai
# Chờ 1-2 phút cho database khởi động lại
```

### Bước 2.4: Tạo OLS Policy (SAU khi restart)

```bash
# Kết nối lại
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba
```

```sql
-- Chuyển sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Tạo OLS Policy
@/opt/oracle/scripts/setup/05_setup_ols.sql

-- Setup các components còn lại
@/opt/oracle/scripts/setup/08_create_ols_trigger.sql
@/opt/oracle/scripts/setup/10_setup_proxy_auth.sql
@/opt/oracle/scripts/setup/17_fix_ols_permissions.sql

EXIT;
```

---

## Bước 3: Cài đặt Backend

```bash
cd server

# Tạo virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Cài đặt dependencies
pip install -r requirements.txt

# Tạo file .env (copy từ .env.example)
copy .env.example .env

# Chạy server
python main.py
```

Server chạy tại: `http://localhost:8000`

---

## Bước 4: Cài đặt Frontend

```bash
cd client

# Cài đặt dependencies
npm install

# Chạy development server
npm run dev
```

Frontend chạy tại: `http://localhost:3000`

---

## Tài khoản Test

| Username | Password | Role | Quyền xem sách |
|----------|----------|------|----------------|
| `ADMIN_USER` | `Admin123` | Admin | Tất cả |
| `LIBRARIAN_USER` | `Librarian123` | Librarian | Đến Confidential |
| `STAFF_USER` | `Staff123` | Staff | Đến Internal |
| `READER_USER` | `Reader123` | Reader | Chỉ Public |

---

## Cấu trúc thư mục

```
WebThuVien/
├── client/                 # Frontend Next.js
│   ├── app/               # App Router
│   │   ├── dashboard/     # Các trang dashboard
│   │   └── page.tsx       # Trang login
│   └── lib/               # Utilities
│
├── server/                 # Backend FastAPI
│   ├── app/
│   │   ├── routers/       # API endpoints
│   │   ├── repositories/  # Database queries
│   │   ├── models/        # Pydantic schemas
│   │   └── database.py    # Database connection
│   └── scripts/
│       └── setup/         # SQL setup scripts
│
└── docs/                   # Documentation
    ├── OLS_GUIDE.md       # Hướng dẫn OLS
    └── SETUP_GUIDE.md     # File này
```

---

## Troubleshooting

### 1. Không thể kết nối database

```bash
# Kiểm tra container đang chạy
docker ps

# Kiểm tra logs
docker logs oracle23ai

# Kiểm tra port 1521
netstat -an | grep 1521
```

### 2. Backend báo lỗi connection

Kiểm tra file `.env`:
```
DB_USER=library
DB_PASSWORD=Library123
DB_DSN=localhost:1521/FREEPDB1
```

### 3. Frontend không load được dữ liệu

- Kiểm tra Backend đang chạy (`http://localhost:8000/docs`)
- Kiểm tra CORS settings
- Xem Console log trong browser

### 4. OLS không hoạt động

Xem chi tiết trong file `docs/OLS_GUIDE.md`.

---

## API Endpoints

### Authentication
- `POST /api/auth/login` - Đăng nhập

### Books
- `GET /api/books` - Lấy danh sách sách
- `GET /api/books/{id}` - Chi tiết sách
- `POST /api/books` - Thêm sách mới
- `PUT /api/books/{id}` - Cập nhật sách
- `DELETE /api/books/{id}` - Xóa sách

### Users
- `GET /api/users` - Lấy danh sách users
- `POST /api/users` - Thêm user mới

### Borrow
- `GET /api/borrow` - Danh sách mượn trả
- `POST /api/borrow` - Mượn sách
- `PUT /api/borrow/{id}/return` - Trả sách

---

## Swagger Documentation

Khi Backend đang chạy, truy cập:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
