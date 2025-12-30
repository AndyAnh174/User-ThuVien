# Data Redaction trong Du An Thu Vien

## I. TONG QUAN

**Oracle Data Redaction** la tinh nang che giau (masking) du lieu nhay cam khi hien thi cho nguoi dung, trong khi du lieu goc van duoc luu tru day du trong database.

### Data Redaction khac gi VPD/OLS?

| Tieu chi | VPD/OLS | Data Redaction |
|----------|---------|----------------|
| **Muc dich** | An hoan toan dong du lieu | Che mot phan gia tri cot |
| **Du lieu goc** | Bi filter (khong tra ve) | Van ton tai, chi bi che khi hien thi |
| **Su dung** | Row-level security | Column-level masking |
| **Vi du** | User A khong thay dong X | User A thay SDT: 091****456 |

### Khi nao dung Data Redaction?

- Che so dien thoai: `0913123456` → `091****456`
- Che email: `admin@gmail.com` → `***@gmail.com`
- Che so CMND: `123456789012` → `XXXXXXXXX012`
- Che so the tin dung: `4111111111111111` → `411111******1111`

---

## II. CAC LOAI REDACTION

### 1. Full Redaction

Thay toan bo gia tri bang gia tri mac dinh.

| Kieu du lieu | Gia tri tra ve |
|--------------|----------------|
| NUMBER | 0 |
| VARCHAR2 | ' ' (space) |
| DATE | 01-JAN-2001 |

```sql
-- Vi du: Che hoan toan so dien thoai
DBMS_REDACT.ADD_POLICY(
    object_schema    => 'LIBRARY',
    object_name      => 'USER_INFO',
    column_name      => 'PHONE',
    policy_name      => 'REDACT_PHONE_FULL',
    function_type    => DBMS_REDACT.FULL,
    expression       => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''READER_USER'''
);
```

Ket qua:
```
Truoc: 0913123456
Sau:   (null hoac space)
```

### 2. Partial Redaction

Che mot phan gia tri, giu lai phan khac.

```sql
-- Che phan giua so dien thoai (giu 3 dau, 3 cuoi)
DBMS_REDACT.ADD_POLICY(
    object_schema       => 'LIBRARY',
    object_name         => 'USER_INFO',
    column_name         => 'PHONE',
    policy_name         => 'REDACT_PHONE_PARTIAL',
    function_type       => DBMS_REDACT.PARTIAL,
    function_parameters => DBMS_REDACT.REDACT_US_PHONE_NUM,
    expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') NOT IN (''ADMIN_USER'',''LIBRARIAN_USER'')'
);
```

Ket qua:
```
Truoc: 0913123456
Sau:   091***3456
```

**Parameters cho PARTIAL:**

| Kieu | Parameter | Ket qua |
|------|-----------|---------|
| Phone | REDACT_US_PHONE_NUM | XXX-XXX-1234 |
| SSN | REDACT_US_SSN_F5 | XXXXX1234 |
| Custom | '0,1,5,X,6,4' | Giu 5 ky tu dau, che 6 ky tu tiep theo bang X, giu 4 ky tu cuoi |

### 3. Random Redaction

Thay gia tri bang gia tri ngau nhien.

```sql
DBMS_REDACT.ADD_POLICY(
    object_schema    => 'LIBRARY',
    object_name      => 'USER_INFO',
    column_name      => 'PHONE',
    policy_name      => 'REDACT_PHONE_RANDOM',
    function_type    => DBMS_REDACT.RANDOM,
    expression       => '1=1'  -- Ap dung cho tat ca
);
```

Ket qua:
```
Truoc: 0913123456
Sau:   7829456123  (ngau nhien)
```

### 4. Regexp Redaction

Che theo pattern regex.

```sql
-- Che phan truoc @ trong email
DBMS_REDACT.ADD_POLICY(
    object_schema       => 'LIBRARY',
    object_name         => 'USER_INFO',
    column_name         => 'EMAIL',
    policy_name         => 'REDACT_EMAIL',
    function_type       => DBMS_REDACT.REGEXP,
    regexp_pattern      => '([^@]+)(@.*)',
    regexp_replace_string => '***\2',
    expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''READER_USER'''
);
```

Ket qua:
```
Truoc: admin@gmail.com
Sau:   ***@gmail.com
```

### 5. Null Redaction (No Redaction)

Tra ve NULL hoac khong che gi ca.

```sql
function_type => DBMS_REDACT.NONE
```

---

## III. THIET KE DATA REDACTION CHO DU AN

### Bang USER_INFO

| Cot | Loai Redaction | Ap dung cho | Ket qua |
|-----|----------------|-------------|---------|
| phone | Partial | STAFF, READER | 091****456 |
| email | Regexp | READER | ***@gmail.com |
| address | Full | READER | (hidden) |

### Script cai dat

**File:** `server/scripts/setup/20_setup_data_redaction.sql`

```sql
-- ============================================
-- SCRIPT 20: DATA REDACTION
-- Chay voi SYS AS SYSDBA
-- ============================================

ALTER SESSION SET CONTAINER = FREEPDB1;

-- ============================================
-- 1. CHE SO DIEN THOAI (Partial)
-- ============================================
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema       => 'LIBRARY',
        object_name         => 'USER_INFO',
        column_name         => 'PHONE',
        policy_name         => 'REDACT_PHONE',
        function_type       => DBMS_REDACT.PARTIAL,
        function_parameters => '0,1,3,*,7,3',  -- Giu 3 dau, che 4 giua bang *, giu 3 cuoi
        expression          => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') NOT IN (''ADMIN_USER'',''LIBRARIAN_USER'',''LIBRARY'')'
    );
    DBMS_OUTPUT.PUT_LINE('Phone redaction policy created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Phone: ' || SQLERRM);
END;
/

-- ============================================
-- 2. CHE EMAIL (Regexp)
-- ============================================
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema         => 'LIBRARY',
        object_name           => 'USER_INFO',
        column_name           => 'EMAIL',
        policy_name           => 'REDACT_EMAIL',
        function_type         => DBMS_REDACT.REGEXP,
        regexp_pattern        => '([^@]+)(@.*)',
        regexp_replace_string => '***\2',
        expression            => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''READER_USER'''
    );
    DBMS_OUTPUT.PUT_LINE('Email redaction policy created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Email: ' || SQLERRM);
END;
/

-- ============================================
-- 3. CHE DIA CHI (Full)
-- ============================================
BEGIN
    DBMS_REDACT.ADD_POLICY(
        object_schema    => 'LIBRARY',
        object_name      => 'USER_INFO',
        column_name      => 'ADDRESS',
        policy_name      => 'REDACT_ADDRESS',
        function_type    => DBMS_REDACT.FULL,
        expression       => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''READER_USER'''
    );
    DBMS_OUTPUT.PUT_LINE('Address redaction policy created.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Address: ' || SQLERRM);
END;
/

COMMIT;

PROMPT Data Redaction setup completed!
```

---

## IV. KIEM TRA DATA REDACTION

### 1. Kiem tra policies da tao

```sql
SELECT policy_name, object_owner, object_name, column_name, function_type
FROM redaction_policies
WHERE object_owner = 'LIBRARY';
```

### 2. Test voi READER_USER

```sql
CONNECT reader_user/Reader123@localhost:1521/FREEPDB1

SELECT oracle_username, phone, email, address 
FROM library.user_info;
```

Ket qua mong doi:
```
ORACLE_USERNAME  PHONE        EMAIL              ADDRESS
---------------- ------------ ------------------ --------
ADMIN_USER       091***3456   ***@thuvien.vn     (null)
LIBRARIAN_USER   090***7890   ***@thuvien.vn     (null)
...
```

### 3. Test voi ADMIN_USER

```sql
CONNECT admin_user/Admin123@localhost:1521/FREEPDB1

SELECT oracle_username, phone, email, address 
FROM library.user_info;
```

Ket qua mong doi (khong bi che):
```
ORACLE_USERNAME  PHONE        EMAIL              ADDRESS
---------------- ------------ ------------------ --------
ADMIN_USER       0913123456   admin@thuvien.vn   Quan 1
LIBRARIAN_USER   0901567890   thuthu@thuvien.vn  Quan 3
...
```

---

## V. QUAN LY DATA REDACTION POLICIES

### 1. Xoa policy

```sql
BEGIN
    DBMS_REDACT.DROP_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'REDACT_PHONE'
    );
END;
/
```

### 2. Sua policy (thay doi expression)

```sql
BEGIN
    DBMS_REDACT.ALTER_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'REDACT_PHONE',
        action        => DBMS_REDACT.MODIFY_EXPRESSION,
        expression    => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') NOT IN (''ADMIN_USER'')'
    );
END;
/
```

### 3. Enable/Disable policy

```sql
-- Disable
BEGIN
    DBMS_REDACT.ALTER_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'REDACT_PHONE',
        action        => DBMS_REDACT.DISABLE
    );
END;
/

-- Enable
BEGIN
    DBMS_REDACT.ALTER_POLICY(
        object_schema => 'LIBRARY',
        object_name   => 'USER_INFO',
        policy_name   => 'REDACT_PHONE',
        action        => DBMS_REDACT.ENABLE
    );
END;
/
```

---

## VI. BIEU DIEN TRONG UNG DUNG

### Frontend - Trang Nguoi dung

```
┌─────────────────────────────────────────────────────────────┐
│  Danh sach Nguoi dung                                       │
├─────────────────────────────────────────────────────────────┤
│  Username    │  Phone       │  Email         │  Address     │
├──────────────┼──────────────┼────────────────┼──────────────┤
│  admin_user  │ 091****456   │ ***@gmail.com  │  (hidden)    │  ← READER thay
│  admin_user  │ 0913123456   │ admin@gmail.com│  Quan 1      │  ← ADMIN thay
└─────────────────────────────────────────────────────────────┘
```

### Backend - Khong can thay doi code

Data Redaction hoat dong o **database layer**, khong can thay doi code backend:

```python
# server/app/repositories/user_repository.py
# Query binh thuong, Oracle tu dong che du lieu
cursor.execute("SELECT phone, email, address FROM library.user_info")
# Ket qua da duoc che truoc khi tra ve cho Python
```

---

## VII. LUU Y QUAN TRONG

### 1. Data Redaction CHI che khi SELECT

- INSERT, UPDATE van luu gia tri goc
- Chi che khi nguoi dung SELECT du lieu

### 2. Khong bao ve khoi DBA

- SYS, SYSTEM van thay du lieu goc (tru khi ket hop voi ODV)
- Data Redaction la "display-level" security

### 3. Expression rat quan trong

Expression quyet dinh khi nao che:

```sql
-- Chi che voi READER_USER
expression => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') = ''READER_USER'''

-- Che voi tat ca tru ADMIN
expression => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') != ''ADMIN_USER'''

-- Luon luon che (testing)
expression => '1=1'
```

### 4. Ket hop voi OLS/VPD

Data Redaction co the dung cung OLS/VPD:
- **OLS/VPD**: An hoan toan dong khong duoc phep
- **Data Redaction**: Che cot nhay cam trong dong duoc phep xem

---

## VIII. XU LY LOI THUONG GAP

### 1. ORA-28081: policy already exists

Policy da ton tai.

```sql
-- Xoa policy cu truoc
BEGIN
    DBMS_REDACT.DROP_POLICY('LIBRARY', 'USER_INFO', 'REDACT_PHONE');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
-- Tao lai
```

### 2. ORA-28082: column has redaction policy

Cot da co policy, can xoa truoc khi tao moi.

### 3. ORA-01031: insufficient privileges

Thieu quyen. Chay voi SYS AS SYSDBA hoac grant:

```sql
GRANT EXECUTE ON SYS.DBMS_REDACT TO library;
```

### 4. Data Redaction khong kha dung (Free Edition)

Kiem tra:
```sql
SELECT * FROM DBA_REDACTION_POLICIES;
```

Neu loi, Data Redaction co the khong co trong Oracle Free Edition.

---

## IX. SO SANH VOI CAC TINH NANG KHAC

| Tinh nang | Muc do bao ve | Doi tuong | Cach hoat dong |
|-----------|---------------|-----------|----------------|
| **GRANT/REVOKE** | Object-level | Tables, columns | An toan bo object |
| **VPD** | Row-level | Rows | Filter WHERE clause |
| **OLS** | Row-level (MAC) | Rows | Labels |
| **Data Redaction** | Column-level | Columns | Che gia tri khi hien thi |
| **ODV** | Schema-level | Realms | Chan DBA |

---

## X. KET LUAN

Data Redaction trong du an Thu Vien:

- **Muc dich**: Che thong tin ca nhan khi hien thi
- **Cot ap dung**: phone, email, address trong bang USER_INFO
- **Nguoi bi che**: STAFF_USER, READER_USER
- **Nguoi thay day du**: ADMIN_USER, LIBRARIAN_USER

Data Redaction giup:
- Bao ve thong tin ca nhan (PII - Personally Identifiable Information)
- Tuan thu quy dinh bao mat du lieu (GDPR, ...)
- Khong can thay doi code ung dung
