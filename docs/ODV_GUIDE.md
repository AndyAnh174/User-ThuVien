# ODV - Oracle Database Vault trong Du An Thu Vien

## I. TONG QUAN

**Oracle Database Vault (ODV)** la tinh nang bao mat ngan chan nguoi dung dac quyen (DBA, SYS) truy cap du lieu nhay cam cua ung dung. ODV ap dung nguyen tac **Separation of Duties** (Phan tach nhiem vu).

### Tai sao can Database Vault?

Trong Oracle thong thuong:
- **SYS/SYSTEM** co the xem, sua, xoa BAT KY du lieu nao
- DBA co the truy cap du lieu nhay cam (luong, thong tin ca nhan, ...)

```
Truoc khi co ODV:
┌─────────────────────────────────────────────────────────────┐
│  DBA (SYS)  ────────────────────▶  Moi du lieu (OK)         │
│                                                              │
│  Application User ───────────────▶  Du lieu cho phep (OK)   │
└─────────────────────────────────────────────────────────────┘

Sau khi co ODV:
┌─────────────────────────────────────────────────────────────┐
│  DBA (SYS)  ────────X────────────▶  Du lieu LIBRARY (BI CHAN)│
│                                                              │
│  Application User ───────────────▶  Du lieu cho phep (OK)   │
└─────────────────────────────────────────────────────────────┘
```

---

## II. CAC THANH PHAN ODV

### 1. Roles dac biet

| Role | User | Chuc nang |
|------|------|-----------|
| **DV_OWNER** | dv_owner | Quan ly realms, command rules |
| **DV_ACCTMGR** | dv_acctmgr | Quan ly users (tao, xoa user) |

**Separation of Duties:**
- DBA ko the quan ly bao mat (DV_OWNER)
- DBA ko the quan ly users (DV_ACCTMGR)
- DV_OWNER ko quan ly duoc users
- DV_ACCTMGR ko quan ly duoc bao mat

### 2. Realms (Vung bao ve)

Realm la mot nhom objects (tables, views, procedures) duoc bao ve.

### 3. Command Rules

Quy tac kiem soat lenh SQL (VD: cam DROP TABLE)

### 4. Factors

Yeu to ngu canh (IP, thoi gian) de ra quyet dinh

### 5. Rule Sets

Tap hop cac rules

---

## III. CAI DAT ODV TRONG DU AN

### File Scripts

| Script | Chuc nang |
|--------|-----------|
| `18_setup_database_vault.sql` | Enable ODV, tao DV_OWNER, DV_ACCTMGR |
| `19_setup_dv_realms.sql` | Tao realm bao ve LIBRARY schema |

### Thu tu thuc hien

```
1. Chay script 18 (voi SYS)
2. Restart database: docker restart oracle23ai
3. Chay script 19 (voi DV_OWNER)
```

---

## IV. CHI TIET SCRIPT 18 - ENABLE DATABASE VAULT

### 1. Tao users

```sql
-- DV Owner - quan ly realms va rules
CREATE USER dv_owner IDENTIFIED BY "DVOwner#123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 50M ON library_data;

-- DV Account Manager - quan ly users
CREATE USER dv_acctmgr IDENTIFIED BY "DVAcctMgr#123"
    DEFAULT TABLESPACE library_data
    TEMPORARY TABLESPACE library_temp
    QUOTA 10M ON library_data;

GRANT CREATE SESSION TO dv_owner;
GRANT CREATE SESSION TO dv_acctmgr;
```

### 2. Configure Database Vault

```sql
BEGIN
    DVSYS.CONFIGURE_DV(
        dvowner_uname         => 'DV_OWNER',
        dvacctmgr_uname       => 'DV_ACCTMGR'
    );
END;
/
```

### 3. Enable Database Vault

```sql
BEGIN
    DVSYS.DBMS_MACADM.ENABLE_DV;
END;
/
```

**QUAN TRONG:** Phai restart database sau buoc nay!

```bash
docker restart oracle23ai
```

---

## V. CHI TIET SCRIPT 19 - TAO REALM

### 1. Tao Realm bao ve LIBRARY

```sql
BEGIN
    DVSYS.DBMS_MACADM.CREATE_REALM(
        realm_name        => 'LIBRARY_REALM',
        description       => 'Bao ve du lieu thu vien khoi truy cap trai phep',
        enabled           => DVSYS.DBMS_MACUTL.G_YES,
        audit_options     => DVSYS.DBMS_MACUTL.G_REALM_AUDIT_FAIL,
        realm_type        => 0  -- Regular realm
    );
END;
/
```

### 2. Them objects vao Realm

```sql
BEGIN
    -- Bao ve TOAN BO schema LIBRARY
    DVSYS.DBMS_MACADM.ADD_OBJECT_TO_REALM(
        realm_name   => 'LIBRARY_REALM',
        object_owner => 'LIBRARY',
        object_name  => '%',           -- Tat ca objects
        object_type  => '%'            -- Tat ca types (TABLE, VIEW, ...)
    );
END;
/
```

### 3. Cap quyen truy cap Realm

```sql
-- LIBRARY (schema owner) - Full access
DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
    realm_name   => 'LIBRARY_REALM',
    grantee      => 'LIBRARY',
    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_OWNER
);

-- ADMIN_USER - Participant
DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
    realm_name   => 'LIBRARY_REALM',
    grantee      => 'ADMIN_USER',
    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
);

-- Tuong tu cho LIBRARIAN_USER, STAFF_USER, READER_USER
```

**Auth Options:**
- `G_REALM_AUTH_OWNER`: Toan quyen tren realm
- `G_REALM_AUTH_PARTICIPANT`: Quyen truy cap (theo grants da co)

### 4. Tao Command Rules

```sql
-- Ngan DROP TABLE trong schema LIBRARY
DVSYS.DBMS_MACADM.CREATE_COMMAND_RULE(
    command         => 'DROP TABLE',
    rule_set_name   => 'Disabled',
    object_owner    => 'LIBRARY',
    object_name     => '%',
    enabled         => DVSYS.DBMS_MACUTL.G_YES
);

-- Ngan TRUNCATE TABLE trong schema LIBRARY
DVSYS.DBMS_MACADM.CREATE_COMMAND_RULE(
    command         => 'TRUNCATE TABLE',
    rule_set_name   => 'Disabled',
    object_owner    => 'LIBRARY',
    object_name     => '%',
    enabled         => DVSYS.DBMS_MACUTL.G_YES
);
```

---

## VI. KIEM TRA ODV HOAT DONG

### 1. Kiem tra Realm

```sql
SELECT REALM_NAME, ENABLED 
FROM DVSYS.DBA_DV_REALM 
WHERE REALM_NAME = 'LIBRARY_REALM';
```

Ket qua mong doi:
```
REALM_NAME       ENABLED
---------------- -------
LIBRARY_REALM    Y
```

### 2. Kiem tra Realm Authorization

```sql
SELECT GRANTEE, AUTH_OPTIONS 
FROM DVSYS.DBA_DV_REALM_AUTH 
WHERE REALM_NAME = 'LIBRARY_REALM';
```

Ket qua mong doi:
```
GRANTEE          AUTH_OPTIONS
---------------- ------------
LIBRARY          OWNER
ADMIN_USER       PARTICIPANT
LIBRARIAN_USER   PARTICIPANT
STAFF_USER       PARTICIPANT
READER_USER      PARTICIPANT
```

### 3. Test - DBA bi chan

```sql
-- Dang nhap SYS
CONNECT sys/Oracle123 AS SYSDBA

-- Thu truy cap LIBRARY.BOOKS
SELECT * FROM library.books;

-- Ket qua: ORA-01031: insufficient privileges
-- (Da bi Database Vault chan!)
```

### 4. Test - Application User duoc truy cap

```sql
-- Dang nhap ADMIN_USER
CONNECT admin_user/Admin123@localhost:1521/FREEPDB1

-- Thu truy cap LIBRARY.BOOKS
SELECT * FROM library.books;

-- Ket qua: OK (tra ve du lieu)
```

---

## VII. BIEU DIEN TRONG UNG DUNG

### Noi dung bao ve

| Thanh phan | Noi dung |
|------------|----------|
| **Realm** | LIBRARY_REALM bao ve toan bo schema LIBRARY |
| **Tables** | BOOKS, USER_INFO, BORROW_HISTORY, CATEGORIES, BRANCHES |
| **Chan DBA** | SYS, SYSTEM khong the xem du lieu |
| **Command Rules** | Chan DROP TABLE, TRUNCATE TABLE |

### Luong bao mat

```
┌─────────────────────────────────────────────────────────────┐
│                    Database Vault                            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  LIBRARY_REALM                        │   │
│  │                                                       │   │
│  │   ┌─────────┐  ┌─────────┐  ┌─────────────────┐     │   │
│  │   │  BOOKS  │  │  USERS  │  │  BORROW_HISTORY │     │   │
│  │   └─────────┘  └─────────┘  └─────────────────┘     │   │
│  │                                                       │   │
│  │   Authorized Users: LIBRARY, ADMIN_USER,              │   │
│  │   LIBRARIAN_USER, STAFF_USER, READER_USER             │   │
│  │                                                       │   │
│  │   Blocked: SYS, SYSTEM, other DBAs                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Command Rules:                                              │
│  ├── DROP TABLE ──────▶ DISABLED                            │
│  └── TRUNCATE TABLE ──▶ DISABLED                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## VIII. XU LY LOI THUONG GAP

### 1. ORA-47400: Command Rule violation

DBA dang co thuc hien lenh bi cam

```sql
SQL> DROP TABLE library.books;
ORA-47400: Command Rule violation
```

**Nguyen nhan:** Command Rule "DROP TABLE" da duoc tao de chan lenh nay.

### 2. Database Vault khong ton tai (Oracle Free Edition)

```sql
SQL> SELECT * FROM DBA_DV_STATUS;
ORA-00942: table or view does not exist
```

**Nguyen nhan:** Oracle 23ai Free Edition co the khong bao gom Database Vault.

**Giai phap:** Bo qua phan ODV, su dung OLS de bao ve du lieu.

### 3. Bi lock out sau khi enable DV

Neu enable Database Vault ma chua tao dung users, co the bi lock.

**Giai phap:** Restart database ở chế độ maintenance:

```bash
# Vào container
docker exec -it oracle23ai bash

# Start DB ở mode upgrade
sqlplus / as sysdba
STARTUP RESTRICT;

# Disable Database Vault
EXEC DVSYS.DBMS_MACADM.DISABLE_DV;

# Restart lại
SHUTDOWN IMMEDIATE;
STARTUP;
```

---

## IX. LUU Y QUAN TRONG

### 1. Database Vault trong Oracle 23ai Free

**Co the khong kha dung** trong Oracle 23ai Free Edition. Kiem tra truoc:

```sql
SELECT * FROM DBA_DV_STATUS;
```

Neu bao loi `ORA-00942`, Database Vault chua duoc cai dat.

### 2. Restart database la BAT BUOC

Sau khi chay script 18, **phai restart database**:

```bash
docker restart oracle23ai
```

Neu khong restart, Database Vault se khong hoat dong.

### 3. Backup truoc khi enable

Database Vault co the gay mat quyen truy cap neu cau hinh sai. **Luan backup truoc!**

### 4. Test ky truoc khi dua len production

- Test DBA bi chan dung cach
- Test application users van truy cap duoc
- Test command rules hoat dong

---

## X. SO SANH OLS VS ODV

| Tieu chi | OLS | ODV |
|----------|-----|-----|
| **Muc dich** | Bao ve du lieu theo do nhay cam | Bao ve du lieu khoi DBA |
| **Doi tuong** | User thong thuong + DBA | Chi DBA (SYS, SYSTEM) |
| **Cach hoat dong** | Labels tren data va users | Realms bao ve objects |
| **Ket qua** | User thay du lieu phu hop label | DBA khong the xem du lieu |
| **Su dung trong du an** | Bang BOOKS (theo sensitivity) | Toan bo schema LIBRARY |

**Trong du an nay:**
- **OLS**: Kiem soat sach nao user duoc xem (theo muc do mat)
- **ODV**: Chan DBA xem du lieu ung dung

---

## XI. KET LUAN

Oracle Database Vault trong du an Thu Vien:

- **Realm**: LIBRARY_REALM bao ve toan bo schema LIBRARY
- **Command Rules**: Chan DROP TABLE, TRUNCATE TABLE
- **Authorized Users**: LIBRARY, ADMIN_USER, LIBRARIAN_USER, STAFF_USER, READER_USER
- **Blocked Users**: SYS, SYSTEM, tat ca DBAs khac

ODV dam bao **Separation of Duties**:
- DBA quan ly database (backup, tuning)
- Application Owner quan ly du lieu
- Security Admin quan ly access control
