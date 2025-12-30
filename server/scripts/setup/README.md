# Huong dan chay Scripts - Thu Vien So

## THONG TIN KET NOI

```bash
# Ket noi SYS AS SYSDBA
docker exec -it oracle23ai sqlplus sys/Oracle123 as sysdba

# Ket noi voi user cu the
docker exec -it oracle23ai sqlplus <username>/<password>@localhost:1521/FREEPDB1
```

---

## THU TU CHAY SCRIPTS

### BUOC 1: Enable OLS (CDB ROOT - KHONG chuyen PDB!)

| # | Script | User | Lenh ket noi |
|---|--------|------|--------------|
| 1 | `15_enable_ols_system.sql` | **SYS AS SYSDBA** | `sqlplus sys/Oracle123 as sysdba` |
| 2 | `16_enable_ols_pdb.sql` | **SYS AS SYSDBA** | (tiep tuc session tren) |

```sql
-- Dang o CDB ROOT, KHONG chay ALTER SESSION SET CONTAINER!
@/opt/oracle/scripts/setup/15_enable_ols_system.sql
@/opt/oracle/scripts/setup/16_enable_ols_pdb.sql
EXIT;
```

### BUOC 2: RESTART DATABASE (BAT BUOC!)

```bash
docker restart oracle23ai
# Cho 2-3 phut
docker logs oracle23ai --tail 20
```

### BUOC 3: Tao Users va Tables

| # | Script | User | Container | Mo ta |
|---|--------|------|-----------|-------|
| 3 | `01_create_users.sql` | **SYS AS SYSDBA** | FREEPDB1 | Tao users, roles |
| 4 | `02_create_tables.sql` | **SYS AS SYSDBA** | FREEPDB1 | Tao tables, sample data |

```sql
-- Ket noi
sqlplus sys/Oracle123 as sysdba

-- Chuyen sang PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Chay scripts
@/opt/oracle/scripts/setup/01_create_users.sql
@/opt/oracle/scripts/setup/02_create_tables.sql
```

### BUOC 4: Setup Audit va OLS

| # | Script | User | Container | Mo ta |
|---|--------|------|-----------|-------|
| 5 | `04_setup_audit.sql` | **SYS AS SYSDBA** | FREEPDB1 | Unified Auditing |
| 6 | `05_setup_ols.sql` | **SYS AS SYSDBA** | FREEPDB1 | OLS Policy, Labels |
| 7 | `08_create_ols_trigger.sql` | **SYS AS SYSDBA** | FREEPDB1 | OLS Trigger |
| 8 | `17_fix_ols_permissions.sql` | **SYS AS SYSDBA** | FREEPDB1 | Fix OLS perms |

```sql
-- (Tiep tuc session truoc)
@/opt/oracle/scripts/setup/04_setup_audit.sql
@/opt/oracle/scripts/setup/05_setup_ols.sql
@/opt/oracle/scripts/setup/08_create_ols_trigger.sql
@/opt/oracle/scripts/setup/17_fix_ols_permissions.sql
```

### BUOC 5: Setup Proxy Auth

| # | Script | User | Container | Mo ta |
|---|--------|------|-----------|-------|
| 9 | `10_setup_proxy_auth.sql` | **SYS AS SYSDBA** | FREEPDB1 | Proxy Authentication |

```sql
@/opt/oracle/scripts/setup/10_setup_proxy_auth.sql
COMMIT;
EXIT;
```

### BUOC 6: (TUY CHON) Database Vault

| # | Script | User | Container | Mo ta |
|---|--------|------|-----------|-------|
| 10 | `18_setup_database_vault.sql` | **SYS AS SYSDBA** | FREEPDB1 | Enable ODV |
| - | RESTART | - | - | docker restart oracle23ai |
| 11 | `19_setup_dv_realms.sql` | **DV_OWNER** | FREEPDB1 | Tao Realms |

```sql
-- Script 18
sqlplus sys/Oracle123 as sysdba
ALTER SESSION SET CONTAINER = FREEPDB1;
@/opt/oracle/scripts/setup/18_setup_database_vault.sql
EXIT;
```

```bash
docker restart oracle23ai
```

```sql
-- Script 19 (voi DV_OWNER)
sqlplus dv_owner/"DVOwner#123"@localhost:1521/FREEPDB1
@/opt/oracle/scripts/setup/19_setup_dv_realms.sql
EXIT;
```

---

## DANH SACH SCRIPTS CHI TIET

| Script | User chay | Container | Chuc nang |
|--------|-----------|-----------|-----------|
| `01_create_users.sql` | SYS AS SYSDBA | FREEPDB1 | Tao tablespaces, users, roles |
| `02_create_tables.sql` | SYS AS SYSDBA | FREEPDB1 | Tao tables, sample data |
| `03_setup_vpd.sql` | LIB_PROJECT | FREEPDB1 | VPD policies (KHONG DUNG) |
| `04_setup_audit.sql` | SYS AS SYSDBA | FREEPDB1 | Unified Auditing policies |
| `05_setup_ols.sql` | SYS AS SYSDBA | FREEPDB1 | OLS policy, levels, labels |
| `06_fix_admin_privs.sql` | SYS AS SYSDBA | FREEPDB1 | Fix quyen admin |
| `07_fix_library_privs.sql` | SYS AS SYSDBA | FREEPDB1 | Fix quyen library |
| `08_create_ols_trigger.sql` | SYS AS SYSDBA | FREEPDB1 | Trigger gan OLS label |
| `09_fix_ols_labels.sql` | SYS AS SYSDBA | FREEPDB1 | Fix OLS labels |
| `10_setup_proxy_auth.sql` | SYS AS SYSDBA | FREEPDB1 | Proxy Authentication |
| `11_check_ols_status.sql` | SYS AS SYSDBA | FREEPDB1 | Kiem tra OLS status |
| `12_force_ols_apply.sql` | SYS AS SYSDBA | FREEPDB1 | Force apply OLS |
| `13_update_ols_data.sql` | SYS AS SYSDBA | FREEPDB1 | Update OLS labels cho data |
| `14_force_apply_ols_v2.sql` | SYS AS SYSDBA | FREEPDB1 | Force apply OLS v2 |
| `15_enable_ols_system.sql` | SYS AS SYSDBA | **CDB ROOT** | Enable OLS o CDB |
| `16_enable_ols_pdb.sql` | SYS AS SYSDBA | **CDB ROOT** | Enable OLS cho PDB |
| `17_fix_ols_permissions.sql` | SYS AS SYSDBA | FREEPDB1 | Fix OLS permissions |
| `18_setup_database_vault.sql` | SYS AS SYSDBA | FREEPDB1 | Enable Database Vault |
| `19_setup_dv_realms.sql` | **DV_OWNER** | FREEPDB1 | Tao DV Realms |

---

## THONG TIN USERS

### Users he thong

| User | Password | Vai tro |
|------|----------|---------|
| SYS | Oracle123 | SYSDBA - Quan tri toan he thong |
| LIBRARY | Library123 | Schema owner - Backend connect qua day |

### Users ung dung

| User | Password | Role | OLS Label |
|------|----------|------|-----------|
| ADMIN_USER | Admin123 | ADMIN | TS:LIB,HR,FIN:HQ |
| LIBRARIAN_USER | Librarian123 | LIBRARIAN | CONF:LIB:HQ |
| STAFF_USER | Staff123 | STAFF | INT:LIB |
| READER_USER | Reader123 | READER | PUB |

### Users Database Vault

| User | Password | Vai tro |
|------|----------|---------|
| DV_OWNER | DVOwner#123 | Quan ly realms, rules |
| DV_ACCTMGR | DVAcctMgr#123 | Quan ly users |

---

## LUU Y QUAN TRONG

1. **Thu tu scripts 15, 16 phai chay o CDB ROOT** (khong chuyen PDB)
2. **Restart database sau scripts 15-16** (OLS) va 18 (ODV)
3. **Script 03 (VPD)** hien khong su dung vi conflict voi OLS
4. **Script 19 chay voi DV_OWNER**, khong phai SYS
5. Cac script khac deu chay voi **SYS AS SYSDBA** sau khi chuyen sang FREEPDB1
