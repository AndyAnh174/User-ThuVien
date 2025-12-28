# Oracle Database 23ai - Docker Setup

## 📋 Thông tin kết nối

| Thông số | Giá trị |
|----------|---------|
| **Host** | `localhost` |
| **Port** | `1521` |
| **Service Name** | `THUVIEN_PDB` |
| **SID** | `FREE` |
| **SYS Password** | `Oracle123` |
| **SYSTEM Password** | `Oracle123` |
| **PDBADMIN Password** | `Oracle123` |

### Users được tạo sẵn

| User | Password | Mô tả |
|------|----------|-------|
| `sec_admin` | `SecAdmin123` | Quản lý bảo mật (tạo user, role, profile) |
| `app_user` | `AppUser123` | User cho ứng dụng web |

---

## 🚀 Khởi động

### Lần đầu tiên (cần pull image)

```bash
# Login vào Oracle Container Registry (nếu chưa)
docker login container-registry.oracle.com

# Khởi động
docker compose up -d

# Xem logs (chờ khoảng 5-10 phút cho lần đầu)
docker compose logs -f oracle-db
```

### Các lần sau

```bash
docker compose up -d
```

---

## 📊 Kiểm tra trạng thái

```bash
# Xem trạng thái container
docker compose ps

# Xem logs
docker compose logs oracle-db

# Kiểm tra health
docker inspect oracle23ai --format='{{.State.Health.Status}}'
```

---

## 🔗 Kết nối

### SQL*Plus từ trong container

```bash
docker exec -it oracle23ai sqlplus sys/Oracle123@THUVIEN_PDB as sysdba
```

### Connection String cho ứng dụng

```
# JDBC (Java/Python oracledb)
jdbc:oracle:thin:@localhost:1521/THUVIEN_PDB

# SQLAlchemy (Python)
oracle+oracledb://app_user:AppUser123@localhost:1521/?service_name=THUVIEN_PDB

# cx_Oracle / oracledb (Python)
app_user/AppUser123@localhost:1521/THUVIEN_PDB
```

### Enterprise Manager Express (Web UI)

Truy cập: https://localhost:5500/em

---

## 🛑 Dừng và xóa

```bash
# Dừng container
docker compose down

# Dừng và xóa data (reset hoàn toàn)
docker compose down -v
```

---

## 📁 Cấu trúc thư mục

```
server/
├── docker-compose.yml      # Cấu hình Docker
├── scripts/
│   ├── setup/              # Scripts chạy 1 lần khi khởi tạo DB
│   │   └── 01_create_users.sql
│   └── startup/            # Scripts chạy mỗi lần container start
└── ORACLE_README.md        # File này
```

---

## ⚠️ Lưu ý

1. **Bộ nhớ:** Oracle 23ai cần ít nhất **2GB RAM**, khuyến nghị **4GB+**
2. **Thời gian khởi động:** Lần đầu tiên cần **5-10 phút** để khởi tạo database
3. **Disk space:** Cần ít nhất **10GB** dung lượng trống
4. **Image size:** Oracle 23ai Free image khoảng **3.5GB**

---

## 🔧 Troubleshooting

### Container không khởi động được

```bash
# Kiểm tra logs chi tiết
docker compose logs oracle-db

# Kiểm tra tài nguyên
docker stats oracle23ai
```

### Không kết nối được database

1. Đợi container healthy (khoảng 5 phút)
2. Kiểm tra port 1521 không bị chiếm
3. Kiểm tra firewall Windows

### Reset database

```bash
# Xóa hoàn toàn và khởi tạo lại
docker compose down -v
docker compose up -d
```
