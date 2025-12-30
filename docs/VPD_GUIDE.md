# VPD - Virtual Private Database trong Du An Thu Vien

## I. TONG QUAN

**Virtual Private Database (VPD)** la tinh nang bao mat cua Oracle cho phep kiem soat truy cap o muc dong (Row-Level Security) mot cach trong suot voi ung dung.

### VPD hoat dong nhu the nao?

```
┌─────────────────────────────────────────────────────────────┐
│                     USER chay query                          │
│                SELECT * FROM books;                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPD Policy Function                       │
│     Tra ve WHERE clause dua tren user hien tai               │
│     VD: "sensitivity_level = 'PUBLIC'"                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Query thuc te                             │
│   SELECT * FROM books WHERE sensitivity_level = 'PUBLIC';   │
└─────────────────────────────────────────────────────────────┘
```

---

## II. CAC VPD POLICIES TRONG DU AN

### 1. VPD_BORROW_HISTORY - Kiem soat lich su muon sach

**File:** `server/scripts/setup/03_setup_vpd.sql` (dong 11-51)

**Muc dich:** Gioi han nguoi dung chi thay lich su muon sach theo vai tro

| User Type | Quyen xem |
|-----------|-----------|
| ADMIN, LIBRARIAN | Thay tat ca lich su muon sach |
| STAFF | Chi thay lich su cua doc gia cung chi nhanh |
| READER | Chi thay lich su cua chinh minh |

**Logic:**

```sql
CREATE OR REPLACE FUNCTION vpd_borrow_history_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
BEGIN
    -- Admin users: thay tat ca
    IF v_user IN ('SYS', 'SYSTEM', 'LIBRARY', 'ADMIN_USER') THEN
        RETURN NULL;
    END IF;
    
    -- Lay user_type tu bang user_info
    SELECT user_type INTO v_user_type
    FROM library.user_info
    WHERE UPPER(oracle_username) = UPPER(v_user);
    
    -- ADMIN, LIBRARIAN: thay tat ca
    IF v_user_type IN ('ADMIN', 'LIBRARIAN') THEN
        RETURN NULL;
    END IF;
    
    -- STAFF: chi thay cua chi nhanh minh
    IF v_user_type = 'STAFF' THEN
        RETURN 'user_id IN (SELECT user_id FROM library.user_info 
                WHERE branch_id = (SELECT branch_id FROM library.user_info 
                WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER''))))';
    END IF;
    
    -- READER: chi thay cua chinh minh
    IF v_user_type = 'READER' THEN
        RETURN 'user_id = (SELECT user_id FROM library.user_info 
                WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER'')))';
    END IF;
    
    RETURN '1=0'; -- Mac dinh: khong thay gi
END;
```

---

### 2. VPD_USER_INFO - Kiem soat thong tin nguoi dung

**File:** `server/scripts/setup/03_setup_vpd.sql` (dong 56-95)

**Muc dich:** Gioi han nguoi dung chi thay thong tin ca nhan theo vai tro va chi nhanh

| User Type | Quyen xem |
|-----------|-----------|
| ADMIN, LIBRARIAN | Thay tat ca nguoi dung |
| STAFF | Chi thay nguoi dung cung chi nhanh |
| READER | Chi thay thong tin cua chinh minh |

**Logic:**

```sql
CREATE OR REPLACE FUNCTION vpd_user_info_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_user_type VARCHAR2(20);
BEGIN
    -- Admin users
    IF v_user IN ('SYS', 'SYSTEM', 'LIBRARY', 'ADMIN_USER') THEN
        RETURN NULL;
    END IF;
    
    SELECT user_type INTO v_user_type
    FROM library.user_info
    WHERE UPPER(oracle_username) = UPPER(v_user);
    
    -- ADMIN, LIBRARIAN: thay tat ca
    IF v_user_type IN ('ADMIN', 'LIBRARIAN') THEN
        RETURN NULL;
    END IF;
    
    -- STAFF: chi thay user cung chi nhanh
    IF v_user_type = 'STAFF' THEN
        RETURN 'branch_id = (SELECT branch_id FROM library.user_info 
                WHERE UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER'')))';
    END IF;
    
    -- READER: chi thay thong tin cua chinh minh
    IF v_user_type = 'READER' THEN
        RETURN 'UPPER(oracle_username) = UPPER(SYS_CONTEXT(''USERENV'', ''SESSION_USER''))';
    END IF;
    
    RETURN '1=0';
END;
```

---

### 3. VPD_BOOKS - Kiem soat sach theo muc do nhay cam

**File:** `server/scripts/setup/03_setup_vpd.sql` (dong 100-134)

**Muc dich:** Gioi han sach ma nguoi dung duoc xem dua tren sensitivity_level

| Sensitivity Level | Ai duoc xem |
|-------------------|-------------|
| PUBLIC | Tat ca moi nguoi |
| INTERNAL | STAFF, LIBRARIAN, ADMIN |
| CONFIDENTIAL | LIBRARIAN, ADMIN |
| TOP_SECRET | Chi ADMIN |

**Logic:**

```sql
CREATE OR REPLACE FUNCTION vpd_books_policy (
    p_schema IN VARCHAR2,
    p_table IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user VARCHAR2(50) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_sensitivity VARCHAR2(20);
BEGIN
    -- Admin users
    IF v_user IN ('SYS', 'SYSTEM', 'LIBRARY') THEN
        RETURN NULL;
    END IF;
    
    SELECT sensitivity_level INTO v_sensitivity
    FROM library.user_info
    WHERE UPPER(oracle_username) = UPPER(v_user);
    
    -- Xac dinh quyen xem dua tren sensitivity level cua user
    IF v_sensitivity = 'TOP_SECRET' THEN
        RETURN NULL; -- Thay tat ca
    ELSIF v_sensitivity = 'CONFIDENTIAL' THEN
        RETURN 'sensitivity_level IN (''PUBLIC'', ''INTERNAL'', ''CONFIDENTIAL'')';
    ELSIF v_sensitivity = 'INTERNAL' THEN
        RETURN 'sensitivity_level IN (''PUBLIC'', ''INTERNAL'')';
    ELSE
        RETURN 'sensitivity_level = ''PUBLIC''';
    END IF;
END;
```

---

## III. DANG KY VPD POLICIES

Sau khi tao functions, can dang ky policies bang `DBMS_RLS.ADD_POLICY`:

```sql
-- Policy cho BORROW_HISTORY
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BORROW_HISTORY',
        policy_name     => 'VPD_BORROW_HISTORY',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_BORROW_HISTORY_POLICY',
        statement_types => 'SELECT,UPDATE,DELETE',
        update_check    => TRUE
    );
END;
/

-- Policy cho USER_INFO
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'USER_INFO',
        policy_name     => 'VPD_USER_INFO',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_USER_INFO_POLICY',
        statement_types => 'SELECT,UPDATE,DELETE',
        update_check    => TRUE
    );
END;
/

-- Policy cho BOOKS
BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'BOOKS',
        policy_name     => 'VPD_BOOKS',
        function_schema => 'LIB_PROJECT',
        policy_function => 'VPD_BOOKS_POLICY',
        statement_types => 'SELECT',
        update_check    => FALSE
    );
END;
/
```

---

## IV. FINE-GRAINED AUDITING (FGA)

FGA la phan mo rong cua VPD, ghi lai cac truy cap vao du lieu nhay cam.

### FGA Policies trong du an:

| Policy | Bang | Hanh dong | Muc dich |
|--------|------|-----------|----------|
| FGA_USER_INFO_SELECT | USER_INFO | SELECT | Ghi lai khi xem email, phone, address cua user co sensitivity_level = CONFIDENTIAL/TOP_SECRET |
| FGA_BOOKS_MODIFY | BOOKS | UPDATE, DELETE | Ghi lai khi sua/xoa sach |
| FGA_BORROW_ALL | BORROW_HISTORY | INSERT, UPDATE, DELETE | Ghi lai moi thay doi trong lich su muon |

```sql
-- FGA cho viec xem thong tin nhay cam
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'LIBRARY',
        object_name     => 'USER_INFO',
        policy_name     => 'FGA_USER_INFO_SELECT',
        audit_condition => 'sensitivity_level IN (''CONFIDENTIAL'', ''TOP_SECRET'')',
        audit_column    => 'email,phone,address',
        statement_types => 'SELECT'
    );
END;
/
```

---

## V. BIEU DIEN TRONG UNG DUNG

### Giao dien Frontend

Frontend hien thi thong bao VPD dang duoc bat:

```
┌─────────────────────────────────────────────────────────────┐
│  Kho Sach                                                   │
│  Quan ly va tra cuu sach trong he thong (VPD Enabled)       │
└─────────────────────────────────────────────────────────────┘
```

### Kiem tra VPD hoat dong

1. Dang nhap voi **READER_USER** -> Chi thay sach PUBLIC
2. Dang nhap voi **STAFF_USER** -> Thay sach PUBLIC + INTERNAL
3. Dang nhap voi **ADMIN_USER** -> Thay tat ca sach

### Backend Code

File `server/app/routers/books.py`:

```python
@router.get("")
async def get_books(
    conn: oracledb.Connection = Depends(get_user_db)  # Su dung proxy connection
):
    # Query nay se tu dong duoc VPD filter
    return BookRepository.get_all(conn)
```

---

## VI. LUU Y QUAN TRONG

### 1. VPD vs OLS trong du an nay

| VPD | OLS |
|-----|-----|
| Dua tren logic trong policy function | Dua tren labels |
| Linh hoat hon, viet code tuy y | Cau truc nghiem ngat hon |
| De debug | Kho debug hon |
| **Du an nay**: Da disabled VPD, chi dung OLS cho books | **Du an nay**: Dang su dung cho books |

### 2. Tai sao VPD bi disabled?

VPD trong du an da bi loi `ORA-28110` do:
- Policy function bi tao trong schema `LIB_PROJECT` khong ton tai
- Hoac `LIB_PROJECT` khong co quyen truy cap `library.user_info`

**Giai phap:** Dung OLS thay the cho kiem soat sach, va drop VPD policies.

### 3. Cach drop VPD policies neu bi loi

```sql
BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BOOKS', 'VPD_BOOKS');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'USER_INFO', 'VPD_USER_INFO');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    DBMS_RLS.DROP_POLICY('LIBRARY', 'BORROW_HISTORY', 'VPD_BORROW_HISTORY');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
```

---

## VII. KET LUAN

VPD la cong nghe manh me de kiem soat truy cap o muc dong. Trong du an nay:

- **VPD da duoc thiet ke** cho 3 bang: `BOOKS`, `USER_INFO`, `BORROW_HISTORY`
- **Hien tai**: VPD da bi disabled do conflict voi OLS
- **OLS** dang duoc su dung de kiem soat sach theo sensitivity level

Neu muon su dung VPD, can:
1. Tao lai policy functions trong schema `LIBRARY` (khong phai `LIB_PROJECT`)
2. Dam bao khong conflict voi OLS policies

---
