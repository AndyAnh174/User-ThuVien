# OLS - Oracle Label Security trong Du An Thu Vien

## I. TONG QUAN

**Oracle Label Security (OLS)** la tinh nang bao mat theo mo hinh **MAC (Mandatory Access Control)** cua Oracle. OLS kiem soat truy cap du lieu dua tren **nhan (labels)** duoc gan cho du lieu va nguoi dung.

### OLS khac gi VPD?

| Tieu chi | VPD | OLS |
|----------|-----|-----|
| Mo hinh | Application-level logic | MAC (Mandatory Access Control) |
| Cach hoat dong | Viet code function | Gan labels |
| Do linh hoat | Cao (viet logic tuy y) | Thap (theo cau truc labels) |
| Bao mat | Phu thuoc vao code | Chuan bao mat cap cao |
| Phu hop cho | Row-level security don gian | Du lieu nhay cam, phan cap bao mat |

### Cau truc nhan OLS

```
LEVEL:COMPARTMENT,COMPARTMENT:GROUP
  |        |                  |
  |        |                  +-- Nhom to chuc (chi nhanh)
  |        +-- Linh vuc hoat dong
  +-- Muc do nhay cam
```

Vi du: `TS:LIB,HR,FIN:HQ`
- Level: TS (TOP_SECRET)
- Compartments: LIB, HR, FIN
- Group: HQ

---

## II. CAU HINH OLS TRONG DU AN

### File Scripts

| Script | Chuc nang |
|--------|-----------|
| `15_enable_ols_system.sql` | Enable OLS o CDB Root |
| `16_enable_ols_pdb.sql` | Enable OLS o PDB (FREEPDB1) |
| `05_setup_ols.sql` | Tao policy, levels, labels, gan cho users |
| `08_create_ols_trigger.sql` | Tao trigger tu dong gan label |
| `17_fix_ols_permissions.sql` | Fix quyen neu bi loi |

---

## III. CAC THANH PHAN OLS

### 1. Policy

**LIBRARY_POLICY** - Policy chinh cho du an

```sql
SA_SYSDBA.CREATE_POLICY(
    policy_name      => 'LIBRARY_POLICY',
    column_name      => 'OLS_LABEL',  -- Ten cot luu label trong bang
    default_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL'
);
```

### 2. Levels (Muc do nhay cam)

| Level Num | Short Name | Long Name | Mo ta |
|-----------|------------|-----------|-------|
| 1000 | PUB | PUBLIC | Cong khai cho tat ca |
| 2000 | INT | INTERNAL | Noi bo, chi nhan vien |
| 3000 | CONF | CONFIDENTIAL | Mat, chi quan ly |
| 4000 | TS | TOP_SECRET | Tuyet mat, chi admin |

```sql
SA_COMPONENTS.CREATE_LEVEL(
    policy_name  => 'LIBRARY_POLICY',
    level_num    => 1000,
    short_name   => 'PUB',
    long_name    => 'PUBLIC'
);
```

### 3. Compartments (Linh vuc)

| Comp Num | Short Name | Long Name | Mo ta |
|----------|------------|-----------|-------|
| 100 | LIB | LIBRARY | Linh vuc thu vien |
| 200 | HR | HUMAN_RESOURCES | Nhan su |
| 300 | FIN | FINANCE | Tai chinh |

```sql
SA_COMPONENTS.CREATE_COMPARTMENT(
    policy_name  => 'LIBRARY_POLICY',
    comp_num     => 100,
    short_name   => 'LIB',
    long_name    => 'LIBRARY'
);
```

### 4. Groups (Chi nhanh)

| Group Num | Short Name | Long Name | Parent |
|-----------|------------|-----------|--------|
| 10 | HQ | HEADQUARTERS | NULL (goc) |
| 20 | BR_A | BRANCH_A | HQ |
| 30 | BR_B | BRANCH_B | HQ |

```sql
SA_COMPONENTS.CREATE_GROUP(
    policy_name  => 'LIBRARY_POLICY',
    group_num    => 10,
    short_name   => 'HQ',
    long_name    => 'HEADQUARTERS'
);

SA_COMPONENTS.CREATE_GROUP(
    policy_name  => 'LIBRARY_POLICY',
    group_num    => 20,
    short_name   => 'BR_A',
    long_name    => 'BRANCH_A',
    parent_name  => 'HQ'  -- Con cua HQ
);
```

### 5. Labels (Nhan du lieu)

| Tag | Label String | Mo ta |
|-----|--------------|-------|
| 1000 | PUB | Sach cong khai |
| 2000 | INT:LIB | Sach noi bo thu vien |
| 3000 | CONF:LIB | Sach mat thu vien |
| 3500 | CONF:LIB:HQ | Sach mat tru so |
| 4000 | TS:LIB,HR,FIN:HQ | Tai lieu tuyet mat |

```sql
SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 1000, 'PUB');
SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 2000, 'INT:LIB');
SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 3000, 'CONF:LIB');
SA_LABEL_ADMIN.CREATE_LABEL('LIBRARY_POLICY', 4000, 'TS:LIB,HR,FIN:HQ');
```

---

## IV. GAN LABELS CHO USERS

| User | Max Read Label | Privileges | Quyen xem |
|------|----------------|------------|-----------|
| ADMIN_USER | TS:LIB,HR,FIN:HQ | FULL | Tat ca sach |
| LIBRARIAN_USER | CONF:LIB:HQ | - | PUBLIC, INTERNAL, CONFIDENTIAL |
| STAFF_USER | INT:LIB | - | PUBLIC, INTERNAL |
| READER_USER | PUB | - | Chi PUBLIC |
| LIBRARY | TS:LIB,HR,FIN:HQ | FULL | Tat ca (schema owner) |

```sql
-- Gan label cho ADMIN_USER
SA_USER_ADMIN.SET_USER_LABELS(
    policy_name   => 'LIBRARY_POLICY',
    user_name     => 'ADMIN_USER',
    max_read_label => 'TS:LIB,HR,FIN:HQ'
);

-- Cap quyen FULL cho ADMIN_USER
SA_USER_ADMIN.SET_USER_PRIVS(
    policy_name => 'LIBRARY_POLICY',
    user_name   => 'ADMIN_USER',
    privileges  => 'FULL'
);

-- Gan label cho READER_USER (chi doc PUBLIC)
SA_USER_ADMIN.SET_USER_LABELS(
    policy_name   => 'LIBRARY_POLICY',
    user_name     => 'READER_USER',
    max_read_label => 'PUB'
);
```

---

## V. AP DUNG POLICY LEN BANG

### Bang BOOKS

```sql
SA_POLICY_ADMIN.APPLY_TABLE_POLICY(
    policy_name    => 'LIBRARY_POLICY',
    schema_name    => 'LIBRARY',
    table_name     => 'BOOKS',
    table_options  => 'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL,LABEL_DEFAULT'
);
```

**Table Options:**
- `READ_CONTROL`: Kiem soat doc du lieu
- `WRITE_CONTROL`: Kiem soat ghi du lieu
- `CHECK_CONTROL`: Kiem tra label khi insert/update
- `LABEL_DEFAULT`: Tu dong gan label mac dinh neu khong chi dinh

### Cap nhat labels cho du lieu hien co

```sql
-- Sach PUBLIC
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
WHERE sensitivity_level = 'PUBLIC';

-- Sach INTERNAL
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB')
WHERE sensitivity_level = 'INTERNAL';

-- Sach CONFIDENTIAL
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB')
WHERE sensitivity_level = 'CONFIDENTIAL';

-- Sach TOP_SECRET
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ')
WHERE sensitivity_level = 'TOP_SECRET';

COMMIT;
```

---

## VI. KIEM TRA OLS HOAT DONG

### 1. Kiem tra labels da gan cho users

```sql
SELECT user_name, max_read_label 
FROM lbacsys.dba_sa_user_labels 
WHERE policy_name = 'LIBRARY_POLICY';
```

Ket qua mong doi:

```
USER_NAME        MAX_READ_LABEL
---------------- ----------------
ADMIN_USER       TS:LIB,HR,FIN:HQ
LIBRARIAN_USER   CONF:LIB:HQ
STAFF_USER       INT:LIB
READER_USER      PUB
LIBRARY          TS:LIB,HR,FIN:HQ
```

### 2. Kiem tra labels tren du lieu

```sql
SELECT book_id, title, sensitivity_level, 
       LABEL_TO_CHAR('LIBRARY_POLICY', ols_label) as label_string
FROM library.books;
```

### 3. Test quyen xem

**Dang nhap READER_USER:**
```sql
CONNECT reader_user/Reader123@localhost:1521/FREEPDB1
SELECT COUNT(*) FROM library.books;
-- Ket qua: Chi thay sach PUBLIC
```

**Dang nhap ADMIN_USER:**
```sql
CONNECT admin_user/Admin123@localhost:1521/FREEPDB1
SELECT COUNT(*) FROM library.books;
-- Ket qua: Thay tat ca sach
```

---

## VII. MO HINH DOMINANCE (CHI PHOI)

OLS su dung mo hinh **dominance** de kiem tra quyen:

```
User Label: CONF:LIB:HQ

Co the doc:
  - PUB           (level thap hon, khong compartment)
  - INT:LIB       (level thap hon, compartment LIB)
  - CONF:LIB      (level bang, compartment LIB)
  - CONF:LIB:HQ   (level bang, compartment LIB, group HQ)

KHONG the doc:
  - TS:...        (level cao hon)
  - CONF:HR       (compartment khac)
  - CONF:LIB:BR_A (group khac)
```

**Quy tac:**
1. Level cua user >= Level cua du lieu
2. User phai co TAT CA compartments cua du lieu
3. User phai thuoc group cua du lieu (hoac group cha)

---

## VIII. BIEU DIEN TRONG UNG DUNG

### Frontend

Trang Sach hien thi cot "Do Mat (OLS)":

```
┌─────────────────────────────────────────────────────────────┐
│  ID  │  TEN SACH           │  DO MAT (OLS)  │  SO LUONG    │
├──────┼─────────────────────┼────────────────┼──────────────┤
│  1   │  Lap trinh Python   │  CONG KHAI     │     5        │
│  2   │  Co so du lieu      │  CONG KHAI     │     3        │
│  3   │  Bao mat he thong   │  NOI BO        │     2        │
│  4   │  Nghien cuu AI      │  BI MAT        │     1        │
│  5   │  Tai lieu mat       │  TUYET MAT     │     1        │
└─────────────────────────────────────────────────────────────┘
```

**READER_USER** chi thay sach #1, #2 (CONG KHAI)
**ADMIN_USER** thay tat ca 5 sach

### Backend

Su dung Proxy Connection de OLS tu dong ap dung:

```python
# server/app/dependencies.py
def get_user_db(user: dict = Depends(get_current_user_info)):
    oracle_username = user.get("oracle_username")
    return Database.get_proxy_connection(oracle_username)
```

---

## IX. XU LY LOI THUONG GAP

### 1. ORA-12416: policy already exists

Policy da ton tai, bo qua loi nay hoac drop truoc:

```sql
BEGIN
    SA_SYSDBA.DROP_POLICY('LIBRARY_POLICY', TRUE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
```

### 2. ORA-06598: insufficient INHERIT PRIVILEGES

Thieu quyen:

```sql
GRANT INHERIT PRIVILEGES ON USER SYS TO LBACSYS;
GRANT INHERIT PRIVILEGES ON USER LBACSYS TO SYS;
```

### 3. User khong thay du lieu (tat ca bi filter)

Kiem tra label cua user:

```sql
SELECT user_name, max_read_label 
FROM lbacsys.dba_sa_user_labels 
WHERE user_name = 'LIBRARIAN_USER';
```

Neu max_read_label NULL hoac sai, gan lai:

```sql
SA_USER_ADMIN.SET_USER_LABELS(
    policy_name   => 'LIBRARY_POLICY',
    user_name     => 'LIBRARIAN_USER',
    max_read_label => 'CONF:LIB:HQ'
);
```

### 4. Sach khong co ols_label

Cap nhat labels:

```sql
UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
WHERE sensitivity_level = 'PUBLIC' AND ols_label IS NULL;
```

---

## X. KET LUAN

OLS trong du an Thu Vien:

- **Mo hinh**: MAC (Mandatory Access Control)
- **Bang ap dung**: BOOKS
- **4 Levels**: PUBLIC, INTERNAL, CONFIDENTIAL, TOP_SECRET
- **3 Compartments**: LIB, HR, FIN
- **3 Groups**: HQ, BR_A, BR_B
- **5 Users**: ADMIN, LIBRARIAN, STAFF, READER, LIBRARY

OLS dam bao nguoi dung chi thay sach phu hop voi muc do bao mat cua ho, **khong the bypass** ke ca co quyen SYS (tru khi co privilege FULL).
