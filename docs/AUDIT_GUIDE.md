# Unified Auditing trong Du An Thu Vien

## I. TONG QUAN

**Oracle Unified Auditing** la he thong ghi nhan va theo doi moi hoat dong tren database. Trong Oracle 23ai, day la phuong phap audit duy nhat duoc ho tro (Traditional Auditing da deprecated).

### Tai sao can Auditing?

- Theo doi ai truy cap du lieu gi, khi nao
- Phat hien hanh vi bat thuong (login that bai nhieu lan, ...)
- Tuan thu quy dinh bao mat (SOX, HIPAA, GDPR, ...)
- Dieu tra su co bao mat

### Traditional vs Unified Auditing

| Tieu chi | Traditional | Unified |
|----------|-------------|---------|
| **Oracle 23ai** | Khong ho tro | Duy nhat |
| **Storage** | AUD$, FGA_LOG$ | AUDSYS.UNIFIED_AUDIT_TRAIL |
| **Performance** | Anh huong nhieu | Toi uu hon |
| **Management** | Nhieu table | 1 view duy nhat |

---

## II. CAC AUDIT POLICIES TRONG DU AN

### File Script

**File:** `server/scripts/setup/04_setup_audit.sql`

### 1. Login/Logout Policy

Ghi nhan dang nhap/dang xuat.

```sql
CREATE AUDIT POLICY library_login_policy
    ACTIONS LOGON, LOGOFF;

AUDIT POLICY library_login_policy;
```

**Ghi nhan:**
- Thoi gian dang nhap
- User
- IP/Host
- Ket qua (thanh cong/that bai)

### 2. User Management Policy

Ghi nhan quan ly user.

```sql
CREATE AUDIT POLICY library_user_mgmt_policy
    PRIVILEGES CREATE USER, ALTER USER, DROP USER,
               CREATE ROLE, ALTER ANY ROLE, DROP ANY ROLE,
               GRANT ANY ROLE, GRANT ANY PRIVILEGE;

AUDIT POLICY library_user_mgmt_policy;
```

**Ghi nhan:**
- Tao user moi
- Xoa user
- Thay doi role
- Cap quyen

### 3. Sensitive Data Policy

Ghi nhan truy cap du lieu nhay cam.

```sql
CREATE AUDIT POLICY library_sensitive_data_policy
    ACTIONS SELECT ON LIBRARY.BOOKS,
            INSERT ON LIBRARY.BOOKS,
            UPDATE ON LIBRARY.BOOKS,
            DELETE ON LIBRARY.BOOKS,
            SELECT ON LIBRARY.USER_INFO,
            UPDATE ON LIBRARY.USER_INFO,
            DELETE ON LIBRARY.USER_INFO,
            SELECT ON LIBRARY.BORROW_HISTORY,
            INSERT ON LIBRARY.BORROW_HISTORY,
            UPDATE ON LIBRARY.BORROW_HISTORY,
            DELETE ON LIBRARY.BORROW_HISTORY;

AUDIT POLICY library_sensitive_data_policy;
```

**Ghi nhan:**
- Xem sach (SELECT)
- Them/sua/xoa sach
- Xem thong tin nguoi dung
- Muon/tra sach

### 4. DDL Policy

Ghi nhan thay doi cau truc database.

```sql
CREATE AUDIT POLICY library_ddl_policy
    ACTIONS CREATE TABLE, ALTER TABLE, DROP TABLE,
            TRUNCATE TABLE, CREATE VIEW, DROP VIEW;

AUDIT POLICY library_ddl_policy;
```

**Ghi nhan:**
- Tao bang moi
- Thay doi cau truc bang
- Xoa bang
- Truncate data

### 5. Privilege Abuse Policy

Ghi nhan su dung quyen dac biet.

```sql
CREATE AUDIT POLICY library_priv_abuse_policy
    PRIVILEGES SELECT ANY TABLE, DELETE ANY TABLE, 
               DROP ANY TABLE, ALTER ANY TABLE,
               EXEMPT ACCESS POLICY;

AUDIT POLICY library_priv_abuse_policy;
```

**Ghi nhan:**
- Dung SELECT ANY TABLE
- Dung DELETE ANY TABLE
- Bypass VPD policy

---

## III. XEM AUDIT DATA

### 1. View unified_audit_trail

```sql
SELECT event_timestamp, dbusername, action_name, 
       object_schema, object_name, sql_text, return_code
FROM unified_audit_trail
WHERE object_schema = 'LIBRARY'
ORDER BY event_timestamp DESC
FETCH FIRST 100 ROWS ONLY;
```

### 2. Cac cot quan trong

| Cot | Mo ta |
|-----|-------|
| event_timestamp | Thoi gian xay ra |
| dbusername | User thuc hien |
| action_name | Hanh dong (SELECT, INSERT, LOGON, ...) |
| object_schema | Schema chua object |
| object_name | Ten object (table, view) |
| sql_text | Cau lenh SQL (neu co) |
| return_code | 0 = thanh cong, khac 0 = loi |
| os_username | User he dieu hanh |
| userhost | IP/hostname client |
| unified_audit_policies | Policies triggerred |

### 3. Cac views tuy chinh

Du an tao san cac views de xem audit:

```sql
-- View tong hop
SELECT * FROM library.v_audit_trail;

-- View theo user
SELECT * FROM library.v_audit_by_user;

-- View login that bai
SELECT * FROM library.v_failed_logins;
```

---

## IV. BIEU DIEN TRONG UNG DUNG

### Frontend - Trang Audit

Trang `/dashboard/audit` hien thi audit logs:

```
┌─────────────────────────────────────────────────────────────┐
│  He thong Nhat ky (Audit Trail)                             │
│  Giam sat va theo doi moi hoat dong trong he thong          │
├─────────────────────────────────────────────────────────────┤
│  Filter: [User ▼] [Action ▼] [Refresh]                      │
├─────────────────────────────────────────────────────────────┤
│  Thoi gian       │ User        │ Action  │ Object │ Status  │
├──────────────────┼─────────────┼─────────┼────────┼─────────┤
│  15:30:25        │ ADMIN_USER  │ SELECT  │ BOOKS  │ OK      │
│  15:29:10        │ READER_USER │ LOGON   │ -      │ OK      │
│  15:28:45        │ HACKER      │ LOGON   │ -      │ FAILED  │
│  15:25:00        │ LIBRARIAN   │ UPDATE  │ BOOKS  │ OK      │
└─────────────────────────────────────────────────────────────┘
```

### Backend - API Audit

**File:** `server/app/routers/audit.py`

```python
@router.get("")
async def get_audit_trail(
    limit: int = 100,
    username: Optional[str] = None,
    action: Optional[str] = None,
    user_info: dict = Depends(require_admin),  # Chi ADMIN duoc xem
    conn = Depends(get_db)
):
    return AuditRepository.get_audit_trail(conn, limit, username, action)
```

**File:** `server/app/repositories/audit_repository.py`

```python
query = """
    SELECT dbusername, action_name, object_name, 
           TO_CHAR(event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') as time,
           return_code, system_privilege_used, terminal
    FROM unified_audit_trail
    WHERE 1=1
"""
```

---

## V. QUAN LY AUDIT POLICIES

### 1. Xem policies hien co

```sql
SELECT policy_name, enabled_option 
FROM audit_unified_enabled_policies;
```

### 2. Disable policy

```sql
NOAUDIT POLICY library_login_policy;
```

### 3. Enable policy

```sql
AUDIT POLICY library_login_policy;
```

### 4. Drop policy

```sql
DROP AUDIT POLICY library_login_policy;
```

### 5. Audit chi voi user cu the

```sql
AUDIT POLICY library_sensitive_data_policy BY admin_user, librarian_user;
```

---

## VI. FINE-GRAINED AUDITING (FGA)

FGA cho phep audit co dieu kien (chi audit khi thoa dieu kien).

### Vi du: Chi audit khi xem du lieu nhay cam

```sql
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'USER_INFO',
        policy_name     => 'FGA_SENSITIVE_USER_INFO',
        audit_condition => 'sensitivity_level IN (''CONFIDENTIAL'', ''TOP_SECRET'')',
        audit_column    => 'phone,email,address',
        statement_types => 'SELECT'
    );
END;
/
```

### Xem FGA logs

```sql
SELECT * FROM dba_fga_audit_trail;
```

---

## VII. GRANT QUYEN XEM AUDIT

### 1. Grant cho LIBRARY user

```sql
GRANT SELECT ON audsys.unified_audit_trail TO library;
```

### 2. Grant cho role

```sql
GRANT AUDIT_VIEWER TO admin_user;
```

---

## VIII. XU LY LOI THUONG GAP

### 1. ORA-46401: No new traditional AUDIT configuration is allowed

Oracle 23ai chi ho tro Unified Auditing.

**Giai phap:** Dung `CREATE AUDIT POLICY` thay vi `AUDIT SELECT ON ...`

```sql
-- SAI (Traditional)
AUDIT SELECT ON library.books BY ACCESS;

-- DUNG (Unified)
CREATE AUDIT POLICY my_policy ACTIONS SELECT ON library.books;
AUDIT POLICY my_policy;
```

### 2. ORA-00942 khi query unified_audit_trail

User khong co quyen SELECT.

**Giai phap:**
```sql
GRANT SELECT ON audsys.unified_audit_trail TO library;
```

### 3. Audit data qua lon

Purge audit data cu:

```sql
-- Xoa audit data cu hon 30 ngay
BEGIN
    DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
        audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
        use_last_arch_timestamp => FALSE
    );
END;
/
```

---

## IX. BAO CAO AUDIT

### 1. Thong ke action theo user

```sql
SELECT dbusername, action_name, COUNT(*) as count
FROM unified_audit_trail
WHERE event_timestamp > SYSDATE - 7  -- 7 ngay gan nhat
GROUP BY dbusername, action_name
ORDER BY count DESC;
```

### 2. Login that bai

```sql
SELECT event_timestamp, dbusername, userhost, return_code
FROM unified_audit_trail
WHERE action_name = 'LOGON' 
  AND return_code != 0
ORDER BY event_timestamp DESC;
```

### 3. Hoat dong ngoai gio lam viec

```sql
SELECT event_timestamp, dbusername, action_name, object_name
FROM unified_audit_trail
WHERE TO_CHAR(event_timestamp, 'HH24') NOT BETWEEN '08' AND '18'
  AND TO_CHAR(event_timestamp, 'DY') NOT IN ('SAT', 'SUN')
ORDER BY event_timestamp DESC;
```

### 4. Privilege abuse detection

```sql
SELECT dbusername, system_privilege_used, COUNT(*) as count
FROM unified_audit_trail
WHERE system_privilege_used IS NOT NULL
GROUP BY dbusername, system_privilege_used
HAVING COUNT(*) > 10
ORDER BY count DESC;
```

---

## X. KET LUAN

Unified Auditing trong du an Thu Vien:

### Policies da tao:

| Policy | Ghi nhan |
|--------|----------|
| library_login_policy | Dang nhap/dang xuat |
| library_user_mgmt_policy | Quan ly user, role |
| library_sensitive_data_policy | Truy cap BOOKS, USER_INFO, BORROW_HISTORY |
| library_ddl_policy | Thay doi cau truc DB |
| library_priv_abuse_policy | Su dung quyen dac biet |

### Loi ich:

- Theo doi moi hoat dong trong he thong
- Phat hien truy cap trai phep
- Ho tro dieu tra su co
- Tuan thu quy dinh bao mat

### Luu y:

- Chi ADMIN duoc xem audit logs
- Purge audit data dinh ky de tranh day disk
- Ket hop voi alerting de phat hien som su co
