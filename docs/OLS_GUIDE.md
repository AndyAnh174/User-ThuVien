# Hướng dẫn Oracle Label Security (OLS)

## Tổng quan

Oracle Label Security (OLS) là tính năng bảo mật cấp hàng (Row-Level Security) của Oracle Database, cho phép kiểm soát truy cập dữ liệu dựa trên nhãn bảo mật.

Trong hệ thống Thư viện này, OLS được sử dụng để:
- Giới hạn quyền xem sách theo mức độ nhạy cảm (Sensitivity Level)
- Đảm bảo nhân viên chỉ thấy dữ liệu phù hợp với vai trò của họ

---

## Cấu trúc OLS trong Project

### 1. Policy: `LIBRARY_POLICY`

Policy này áp dụng cho bảng `BOOKS` với cột nhãn `OLS_LABEL`.

### 2. Các mức bảo mật (Levels)

| Level | Giá trị | Mô tả |
|-------|---------|-------|
| `PUB` | 1000 | PUBLIC - Công khai |
| `INT` | 2000 | INTERNAL - Nội bộ |
| `CONF` | 3000 | CONFIDENTIAL - Bí mật |
| `TS` | 4000 | TOP_SECRET - Tối mật |

### 3. Compartments

| Compartment | Mô tả |
|-------------|-------|
| `LIB` | Thư viện |
| `HR` | Nhân sự |
| `FIN` | Tài chính |

### 4. Groups

| Group | Mô tả |
|-------|-------|
| `HQ` | Trụ sở chính |
| `BR_A` | Chi nhánh A |
| `BR_B` | Chi nhánh B |

---

## Phân quyền User theo OLS

### User Labels

| User | Max Read Label | Privileges | Mô tả |
|------|----------------|------------|-------|
| `ADMIN_USER` | `TS:LIB,HR,FIN:HQ` | `FULL` | Xem TẤT CẢ sách |
| `LIBRARIAN_USER` | `CONF:LIB:HQ` | - | Xem đến CONFIDENTIAL |
| `STAFF_USER` | `INT:LIB:BR_A` | - | Xem đến INTERNAL |
| `READER_USER` | `PUB` | - | Chỉ xem PUBLIC |

### Kết quả mong đợi

| Sensitivity Level | ADMIN | LIBRARIAN | STAFF | READER |
|-------------------|-------|-----------|-------|--------|
| PUBLIC | ✅ | ✅ | ✅ | ✅ |
| INTERNAL | ✅ | ✅ | ✅ | ❌ |
| CONFIDENTIAL | ✅ | ✅ | ❌ | ❌ |
| TOP_SECRET | ✅ | ❌ | ❌ | ❌ |

---

## Proxy Authentication

Hệ thống sử dụng **Proxy Authentication** để áp dụng OLS:

```
Frontend → Backend (FastAPI) → Oracle DB
                    ↓
            LIBRARY[LIBRARIAN_USER]
                    ↓
            Session User = LIBRARIAN_USER
            OLS Policy áp dụng theo label của LIBRARIAN_USER
```

### Cách hoạt động

1. User login với credentials (ví dụ: `LIBRARIAN_USER / Librarian123`)
2. Backend xác thực và lấy `oracle_username` từ `user_info`
3. Backend tạo **Proxy Connection**: `LIBRARY[LIBRARIAN_USER]`
4. Oracle nhận diện session là `LIBRARIAN_USER`
5. OLS tự động lọc dữ liệu theo label của `LIBRARIAN_USER`

### Code Implementation

```python
# server/app/database.py
def get_proxy_connection(cls, username: str) -> oracledb.Connection:
    return oracledb.connect(
        user=f"{settings.DB_USER}[{username.upper()}]",
        password=settings.DB_PASSWORD,
        dsn=settings.DB_DSN
    )
```

---

## Cấu hình Database

### 1. Enable OLS (Chạy 1 lần)

```sql
-- Chạy với SYS AS SYSDBA
ALTER SESSION SET CONTAINER = CDB$ROOT;
EXEC LBACSYS.CONFIGURE_OLS;
EXEC LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;

-- Trong PDB
ALTER SESSION SET CONTAINER = FREEPDB1;
EXEC LBACSYS.CONFIGURE_OLS;
EXEC LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;

-- Restart Database sau khi enable
```

### 2. Cấp quyền Proxy

```sql
-- Cho phép LIBRARY proxy cho các user
ALTER USER ADMIN_USER GRANT CONNECT THROUGH LIBRARY;
ALTER USER LIBRARIAN_USER GRANT CONNECT THROUGH LIBRARY;
ALTER USER STAFF_USER GRANT CONNECT THROUGH LIBRARY;
ALTER USER READER_USER GRANT CONNECT THROUGH LIBRARY;
```

### 3. Set User Labels

```sql
BEGIN
    -- ADMIN - Full access
    SA_USER_ADMIN.SET_USER_PRIVS('LIBRARY_POLICY', 'ADMIN_USER', 'FULL');
    SA_USER_ADMIN.SET_USER_LABELS('LIBRARY_POLICY', 'ADMIN_USER', 'TS:LIB,HR,FIN:HQ');
    
    -- LIBRARIAN - Up to CONFIDENTIAL
    SA_USER_ADMIN.SET_USER_LABELS('LIBRARY_POLICY', 'LIBRARIAN_USER', 'CONF:LIB:HQ');
    
    -- STAFF - Up to INTERNAL
    SA_USER_ADMIN.SET_USER_LABELS('LIBRARY_POLICY', 'STAFF_USER', 'INT:LIB:BR_A');
    
    -- READER - PUBLIC only
    SA_USER_ADMIN.SET_USER_LABELS('LIBRARY_POLICY', 'READER_USER', 'PUB');
END;
/
```

---

## Troubleshooting

### 1. User thấy tất cả dữ liệu

**Nguyên nhân có thể:**
- OLS chưa được enable
- Proxy connection không hoạt động
- User có privilege `FULL` hoặc `READ`

**Cách kiểm tra:**

```sql
-- Check OLS enabled
SELECT VALUE FROM V$OPTION WHERE PARAMETER = 'Oracle Label Security';

-- Check user privileges
SELECT * FROM LBACSYS.ALL_SA_USERS WHERE POLICY_NAME = 'LIBRARY_POLICY';

-- Check session user (trong Backend log)
SELECT SYS_CONTEXT('USERENV', 'SESSION_USER'), 
       SYS_CONTEXT('USERENV', 'PROXY_USER') 
FROM DUAL;
```

### 2. Lỗi ORA-12458: Oracle Label Security is not enabled

**Giải pháp:**
```sql
-- Chạy với SYS
EXEC LBACSYS.CONFIGURE_OLS;
EXEC LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;
-- Restart Database
```

### 3. Proxy connection trả về session_user = LIBRARY

**Nguyên nhân:** Pool không hỗ trợ proxy trong thin mode.

**Giải pháp:** Sử dụng direct connection với cú pháp `LIBRARY[USER]`:
```python
oracledb.connect(user=f"LIBRARY[{username}]", password=..., dsn=...)
```

---

## Scripts Setup

| Script | Mô tả |
|--------|-------|
| `05_setup_ols.sql` | Tạo Policy, Levels, Compartments, Groups |
| `08_create_ols_trigger.sql` | Trigger tự động gán label cho sách mới |
| `09_fix_ols_labels.sql` | Fix lại labels cho users |
| `10_setup_proxy_auth.sql` | Cấp quyền proxy |
| `15_enable_ols_system.sql` | Enable OLS system-wide |
| `16_enable_ols_pdb.sql` | Enable OLS trong PDB |
| `17_fix_ols_permissions.sql` | Fix permissions cho tất cả users |

---

## Testing Checklist

- [ ] Login với `admin_user` → Thấy TẤT CẢ sách
- [ ] Login với `librarian_user` → KHÔNG thấy sách TOP_SECRET
- [ ] Login với `staff_user` → Chỉ thấy PUBLIC và INTERNAL
- [ ] Tạo sách mới với sensitivity_level → Label tự động được gán
- [ ] Check Backend log → `session_user` phải khớp với user login

---

## Tài liệu tham khảo

- [Oracle Label Security Administrator's Guide](https://docs.oracle.com/en/database/oracle/oracle-database/23/olsag/)
- [python-oracledb Documentation](https://python-oracledb.readthedocs.io/)
