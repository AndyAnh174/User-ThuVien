# Mo hinh Kiem soat Truy cap: DAC, MAC, RBAC

## I. TONG QUAN

Co 3 mo hinh kiem soat truy cap chinh trong bao mat co so du lieu:

| Mo hinh | Ten day du | Mo ta |
|---------|------------|-------|
| **DAC** | Discretionary Access Control | Chu so huu quyet dinh ai truy cap |
| **MAC** | Mandatory Access Control | He thong quyet dinh theo labels |
| **RBAC** | Role-Based Access Control | Truy cap dua tren vai tro |

### So sanh 3 mo hinh

```
┌─────────────────────────────────────────────────────────────┐
│                        DAC                                   │
│  "Toi la chu, toi muon cho ai thi cho"                      │
│  Owner ───GRANT──▶ User A                                   │
│  Owner ───GRANT──▶ User B                                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        MAC                                   │
│  "He thong quyet dinh, khong ai thay doi duoc"              │
│  TOP_SECRET ──────▶ Chi Admin thay                          │
│  CONFIDENTIAL ────▶ Admin, Manager thay                     │
│  PUBLIC ──────────▶ Tat ca thay                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        RBAC                                  │
│  "Ban la gi thi duoc lam cai do"                            │
│  ADMIN_ROLE ──────▶ Full access                             │
│  LIBRARIAN_ROLE ──▶ Quan ly sach                            │
│  READER_ROLE ─────▶ Chi doc                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## II. DAC - DISCRETIONARY ACCESS CONTROL

### 1. Khai niem

DAC cho phep **chu so huu du lieu** quyet dinh ai duoc truy cap du lieu cua ho.

- Chu so huu co the GRANT/REVOKE quyen cho nguoi khac
- Linh hoat nhung co the gay rui ro (chu so huu grant qua nhieu quyen)

### 2. Ap dung trong Oracle

#### a) System Privileges (Quyen he thong)

```sql
-- Cap quyen tao session
GRANT CREATE SESSION TO librarian_user;

-- Cap quyen tao table
GRANT CREATE TABLE TO library;

-- Cap quyen tao view
GRANT CREATE VIEW TO library;

-- Cap quyen tao procedure
GRANT CREATE PROCEDURE TO library;
```

#### b) Object Privileges (Quyen doi tuong)

```sql
-- Cap quyen SELECT tren bang
GRANT SELECT ON library.books TO reader_role;

-- Cap quyen INSERT, UPDATE tren bang
GRANT INSERT, UPDATE ON library.books TO librarian_role;

-- Cap quyen DELETE tren bang
GRANT DELETE ON library.books TO admin_role;

-- Cap tat ca quyen
GRANT ALL ON library.borrow_history TO admin_role;
```

#### c) Thu hoi quyen

```sql
-- Thu hoi quyen SELECT
REVOKE SELECT ON library.books FROM reader_role;

-- Thu hoi tat ca quyen
REVOKE ALL ON library.books FROM staff_role;
```

### 3. Ap dung trong du an

**File:** `server/scripts/setup/01_create_users.sql`

```sql
-- Tao user LIBRARY (chu so huu schema)
CREATE USER library IDENTIFIED BY "Library123"
    DEFAULT TABLESPACE library_data
    QUOTA UNLIMITED ON library_data;

-- Cap quyen he thong cho LIBRARY
GRANT CONNECT, RESOURCE TO library;
GRANT CREATE SESSION TO library;
GRANT CREATE TABLE TO library;
GRANT CREATE VIEW TO library;
GRANT CREATE PROCEDURE TO library;
```

### 4. Oracle Profiles (DAC cho tai nguyen)

Profiles gioi han tai nguyen va mat khau:

```sql
-- Tao profile cho user thong thuong
CREATE PROFILE app_user_profile LIMIT
    SESSIONS_PER_USER 3          -- Toi da 3 session
    IDLE_TIME 30                 -- Timeout sau 30 phut
    PASSWORD_LIFE_TIME 90        -- Mat khau het han sau 90 ngay
    FAILED_LOGIN_ATTEMPTS 5;     -- Khoa sau 5 lan sai

-- Tao profile cho admin
CREATE PROFILE admin_profile LIMIT
    SESSIONS_PER_USER UNLIMITED
    IDLE_TIME UNLIMITED
    PASSWORD_LIFE_TIME 60
    FAILED_LOGIN_ATTEMPTS 3;

-- Gan profile cho user
ALTER USER reader_user PROFILE app_user_profile;
ALTER USER admin_user PROFILE admin_profile;
```

---

## III. MAC - MANDATORY ACCESS CONTROL

### 1. Khai niem

MAC la mo hinh kiem soat **bat buoc** do he thong ap dat. Nguoi dung va du lieu duoc gan **nhan bao mat (labels)**, va he thong tu dong kiem soat truy cap dua tren cac labels nay.

- Nguoi dung **KHONG** the thay doi quyen truy cap
- He thong quyet dinh hoan toan
- Ap dung cho du lieu nhay cam (mat, tuyet mat, ...)

### 2. Cac cap do bao mat

```
          ↑ Cao hon = Nhay cam hon
          │
    ┌─────┴─────┐
    │ TOP_SECRET│    ← Chi Admin
    ├───────────┤
    │CONFIDENTIAL│   ← Admin, Librarian
    ├───────────┤
    │ INTERNAL  │    ← Admin, Librarian, Staff
    ├───────────┤
    │  PUBLIC   │    ← Tat ca
    └───────────┘
          │
          ↓ Thap hon = It nhay cam hon
```

### 3. Ap dung trong Oracle - OLS

**Oracle Label Security (OLS)** la cong nghe MAC trong Oracle.

**File:** `server/scripts/setup/05_setup_ols.sql`

```sql
-- Tao policy
SA_SYSDBA.CREATE_POLICY(
    policy_name      => 'LIBRARY_POLICY',
    column_name      => 'OLS_LABEL'
);

-- Tao cac levels
SA_COMPONENTS.CREATE_LEVEL('LIBRARY_POLICY', 1000, 'PUB', 'PUBLIC');
SA_COMPONENTS.CREATE_LEVEL('LIBRARY_POLICY', 2000, 'INT', 'INTERNAL');
SA_COMPONENTS.CREATE_LEVEL('LIBRARY_POLICY', 3000, 'CONF', 'CONFIDENTIAL');
SA_COMPONENTS.CREATE_LEVEL('LIBRARY_POLICY', 4000, 'TS', 'TOP_SECRET');

-- Gan label cho user
SA_USER_ADMIN.SET_USER_LABELS(
    policy_name   => 'LIBRARY_POLICY',
    user_name     => 'READER_USER',
    max_read_label => 'PUB'  -- Chi doc PUBLIC
);

SA_USER_ADMIN.SET_USER_LABELS(
    policy_name   => 'LIBRARY_POLICY',
    user_name     => 'ADMIN_USER',
    max_read_label => 'TS:LIB,HR,FIN:HQ'  -- Doc tat ca
);
```

### 4. Ap dung trong Oracle - ODV

**Oracle Database Vault (ODV)** cung la MAC, bao ve khoi DBA.

```sql
-- Tao realm bao ve LIBRARY schema
DVSYS.DBMS_MACADM.CREATE_REALM(
    realm_name  => 'LIBRARY_REALM',
    description => 'Bao ve du lieu thu vien'
);

-- Chi cho phep app users truy cap, chan DBA
DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
    realm_name   => 'LIBRARY_REALM',
    grantee      => 'ADMIN_USER',
    auth_options => DVSYS.DBMS_MACUTL.G_REALM_AUTH_PARTICIPANT
);
```

### 5. MAC trong du an

| Cong nghe | Ap dung |
|-----------|---------|
| **OLS** | Kiem soat sach theo sensitivity_level |
| **ODV** | Chan DBA truy cap LIBRARY schema |

---

## IV. RBAC - ROLE-BASED ACCESS CONTROL

### 1. Khai niem

RBAC gan quyen cho **vai tro (role)**, roi gan role cho nguoi dung.

- De quan ly (thay doi role = thay doi quyen cho nhieu user)
- Phu hop voi to chuc co cau truc ro rang
- Ket hop tot voi DAC va MAC

### 2. Ap dung trong Oracle

#### a) Tao Roles

```sql
CREATE ROLE admin_role;
CREATE ROLE librarian_role;
CREATE ROLE staff_role;
CREATE ROLE reader_role;
```

#### b) Cap quyen cho Roles

```sql
-- Admin - Full access
GRANT SELECT, INSERT, UPDATE, DELETE ON library.books TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.user_info TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON library.borrow_history TO admin_role;

-- Librarian - Quan ly sach
GRANT SELECT, INSERT, UPDATE ON library.books TO librarian_role;
GRANT SELECT ON library.user_info TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library.borrow_history TO librarian_role;

-- Staff - Ho tro
GRANT SELECT ON library.books TO staff_role;
GRANT SELECT ON library.borrow_history TO staff_role;

-- Reader - Chi doc
GRANT SELECT ON library.books TO reader_role;
```

#### c) Gan Roles cho Users

```sql
GRANT admin_role TO admin_user;
GRANT librarian_role TO librarian_user;
GRANT staff_role TO staff_user;
GRANT reader_role TO reader_user;
```

#### d) Role Hierarchy (Ke thua)

```sql
-- Librarian ke thua quyen cua Staff
GRANT staff_role TO librarian_role;

-- Admin ke thua quyen cua Librarian
GRANT librarian_role TO admin_role;
```

### 3. Ap dung trong du an

**File:** `server/scripts/setup/01_create_users.sql`

```sql
-- Tao roles
CREATE ROLE admin_role;
CREATE ROLE librarian_role;
CREATE ROLE staff_role;
CREATE ROLE reader_role;

-- Gan roles cho users
GRANT admin_role TO admin_user;
GRANT librarian_role TO librarian_user;
GRANT staff_role TO staff_user;
GRANT reader_role TO reader_user;
```

### 4. Ma tran quyen trong du an

| Quyen | ADMIN | LIBRARIAN | STAFF | READER |
|-------|-------|-----------|-------|--------|
| Xem sach | ✅ | ✅ | ✅ | ✅ (OLS filter) |
| Them sach | ✅ | ✅ | ❌ | ❌ |
| Sua sach | ✅ | ✅ | ❌ | ❌ |
| Xoa sach | ✅ | ❌ | ❌ | ❌ |
| Quan ly user | ✅ | ❌ | ❌ | ❌ |
| Xem audit | ✅ | ❌ | ❌ | ❌ |
| Quan ly profiles | ✅ | ❌ | ❌ | ❌ |

---

## V. KET HOP 3 MO HINH TRONG DU AN

### Kien truc bao mat tong the

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION                               │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            RBAC (Vai tro)                             │   │
│  │  ADMIN ─▶ LIBRARIAN ─▶ STAFF ─▶ READER               │   │
│  └───────────────────────┬──────────────────────────────┘   │
│                          │                                   │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │            DAC (GRANT/REVOKE)                         │   │
│  │  Quyen tren BOOKS, USER_INFO, BORROW_HISTORY         │   │
│  └───────────────────────┬──────────────────────────────┘   │
│                          │                                   │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │            MAC (OLS Labels)                           │   │
│  │  PUBLIC < INTERNAL < CONFIDENTIAL < TOP_SECRET       │   │
│  └───────────────────────┬──────────────────────────────┘   │
│                          │                                   │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │            MAC (Database Vault)                       │   │
│  │  Chan DBA truy cap                                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Luong kiem tra quyen

```
User request ──▶ RBAC ──▶ DAC ──▶ MAC ──▶ Data

1. RBAC: User co role phu hop khong?
2. DAC: Role co quyen tren object khong?
3. MAC (OLS): User label co dominates data label khong?
4. MAC (ODV): User co trong realm khong?

Tat ca OK ──▶ Tra ve data
Bat ky FAIL ──▶ Access Denied
```

---

## VI. VI DU CU THE TRONG DU AN

### Vi du 1: READER xem sach

```
1. RBAC: reader_user co reader_role ✅
2. DAC: reader_role co SELECT ON library.books ✅
3. MAC (OLS): 
   - READER label: PUB
   - Sach TOP_SECRET label: TS:LIB,HR,FIN:HQ
   - PUB KHONG dominates TS ❌
4. Ket qua: Chi thay sach PUBLIC
```

### Vi du 2: ADMIN xem sach

```
1. RBAC: admin_user co admin_role ✅
2. DAC: admin_role co SELECT ON library.books ✅
3. MAC (OLS): 
   - ADMIN label: TS:LIB,HR,FIN:HQ
   - Sach TOP_SECRET label: TS:LIB,HR,FIN:HQ
   - TS dominates TS ✅
4. Ket qua: Thay tat ca sach
```

### Vi du 3: DBA (SYS) truy cap

```
1. RBAC: Khong ap dung (SYS la privileged user)
2. DAC: SYS co moi quyen ✅
3. MAC (OLS): SYS co quyen FULL (bypass) ✅
4. MAC (ODV): 
   - SYS KHONG co trong LIBRARY_REALM ❌
   - Database Vault chan
5. Ket qua: Access Denied (neu ODV enabled)
```

---

## VII. SCRIPTS TRONG DU AN

| Script | Mo hinh | Noi dung |
|--------|---------|----------|
| `01_create_users.sql` | DAC, RBAC | Tao users, roles |
| `05_setup_ols.sql` | MAC | Oracle Label Security |
| `18_setup_database_vault.sql` | MAC | Database Vault |
| `19_setup_dv_realms.sql` | MAC | Realms bao ve |

---

## VIII. KET LUAN

Du an Thu Vien su dung **ket hop ca 3 mo hinh**:

| Mo hinh | Cong nghe | Ap dung |
|---------|-----------|---------|
| **DAC** | GRANT/REVOKE, Profiles | Quyen tren objects, gioi han tai nguyen |
| **MAC** | OLS, ODV | Kiem soat theo labels, chan DBA |
| **RBAC** | Roles | Quan ly quyen theo vai tro |

### Loi ich ket hop:

1. **DAC**: Linh hoat, de quan ly quyen co ban
2. **RBAC**: De quan ly khi co nhieu user cung vai tro
3. **MAC**: Bao mat bat buoc, khong the bypass

### Thu tu uu tien:

```
MAC (nghiem ngat nhat) > RBAC > DAC (linh hoat nhat)
```

Neu MAC tu choi, RBAC va DAC khong the override.
