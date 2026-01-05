# Hướng Dẫn Test ODV Setup

## Bước 1: Reset Database (Xóa hết và build lại)

```powershell
cd D:\Freelance\User-ThuVien\server
docker compose down -v
docker compose up -d --build
```

**Đợi khoảng 3-5 phút** cho database khởi động hoàn toàn (check status: `docker ps`)

## Bước 2: Chạy Init Script

```powershell
.\init_db_windows.ps1
```

Script sẽ tự động:
- ✅ Setup OLS
- ✅ Tạo users và tables
- ✅ Setup VPD, Audit
- ✅ **Setup và Enable ODV (CDB + PDB)**
- ✅ Setup Realms và Rules

## Bước 3: Verify ODV Setup

### 3.1. Check CDB DV Status

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s c##sec_admin/SecAdmin123 <<EOF
SELECT STATUS FROM DBA_DV_STATUS;
EXIT;
EOF"
```

**Kết quả mong đợi:** `STATUS = ENABLED`

### 3.2. Check PDB DV Status

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s sec_admin/SecAdmin123@localhost:1521/FREEPDB1 <<EOF
SELECT STATUS FROM DBA_DV_STATUS;
EXIT;
EOF"
```

**Kết quả mong đợi:** `STATUS = ENABLED` hoặc `CONFIGURED`

### 3.3. Check Realms

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s sec_admin/SecAdmin123@localhost:1521/FREEPDB1 <<EOF
SELECT NAME, ENABLED FROM DVSYS.DBA_DV_REALM WHERE NAME = 'LIBRARY_REALM';
SELECT GRANTEE, AUTH_OPTIONS FROM DVSYS.DBA_DV_REALM_AUTH WHERE REALM_NAME = 'LIBRARY_REALM';
EXIT;
EOF"
```

**Kết quả mong đợi:**
- Realm `LIBRARY_REALM` exists và ENABLED = Y
- Có các users: LIBRARY (Owner), ADMIN_USER, LIBRARIAN_USER, STAFF_USER, READER_USER (Participants)

## Bước 4: Test ODV Protection

### 4.1. Test SYS không thể truy cập LIBRARY data (Realm Protection)

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s sys/Oracle123@FREEPDB1 as sysdba <<EOF
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM library.books;
EXIT;
EOF"
```

**Kết quả mong đợi:** 
- ✅ Nếu ODV hoạt động: `ORA-01031: insufficient privileges` hoặc `ORA-28106: input value for object_owner is not valid`
- ❌ Nếu ODV không hoạt động: Query thành công (có thể thấy data)

### 4.2. Test Authorized User có thể truy cập

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s admin_user/Admin123@localhost:1521/FREEPDB1 <<EOF
SELECT COUNT(*) FROM library.books;
EXIT;
EOF"
```

**Kết quả mong đợi:** Query thành công (vì ADMIN_USER là Participant trong realm)

### 4.3. Test Command Rules (DROP TABLE blocked)

```powershell
docker exec -i oracle23ai bash -c "sqlplus -s sys/Oracle123@FREEPDB1 as sysdba <<EOF
ALTER SESSION SET CONTAINER = FREEPDB1;
DROP TABLE library.books;
EXIT;
EOF"
```

**Kết quả mong đợi:** `ORA-47401: Realm violation occurred` hoặc command bị block

## Bước 5: Test Application

### 5.1. Start Backend

```powershell
cd D:\Freelance\User-ThuVien\server
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### 5.2. Start Frontend

```powershell
cd D:\Freelance\User-ThuVien\client
npm install
npm run dev
```

### 5.3. Test Login

Mở browser: `http://localhost:3000`

Login với:
- **Admin**: `admin_user` / `Admin123`
- **Librarian**: `librarian_user` / `Librarian123`
- **Staff**: `staff_user` / `Staff123`
- **Reader**: `reader_user` / `Reader123`

## Checklist Kết Quả

- [ ] CDB DV Status = ENABLED
- [ ] PDB DV Status = ENABLED hoặc CONFIGURED
- [ ] LIBRARY_REALM exists và enabled
- [ ] SYS không thể truy cập LIBRARY data
- [ ] Authorized users có thể truy cập
- [ ] Command rules hoạt động (DROP TABLE blocked)
- [ ] Application login và hoạt động bình thường

## Troubleshooting

### Nếu CDB DV không enabled:
```powershell
docker exec -i oracle23ai bash -c "sqlplus -s c##sec_admin/SecAdmin123 <<EOF
SELECT STATUS FROM DBA_DV_STATUS;
EXEC DVSYS.DBMS_MACADM.ENABLE_DV;
EXIT;
EOF"
```

### Nếu PDB DV không enabled:
```powershell
docker exec -i oracle23ai bash -c "sqlplus -s sec_admin/SecAdmin123@localhost:1521/FREEPDB1 <<EOF
SELECT STATUS FROM DBA_DV_STATUS;
EXEC DVSYS.DBMS_MACADM.ENABLE_DV;
EXIT;
EOF"
```

### Check logs:
```powershell
docker logs oracle23ai | Select-String -Pattern "DV\|ODV\|Vault" -Context 2
```

