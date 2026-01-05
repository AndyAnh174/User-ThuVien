# Script khoi tao Database cho Windows (thay the 00_init_all.sh)
# Cach chay: Chuot phai -> Run with PowerShell

$Container = "oracle23ai"
$SysUser = "sys/Oracle123 as sysdba"
$SetupDir = "/opt/oracle/scripts/setup"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "KHOI TAO DATABASE THU VIEN (WINDOWS MODE)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Kiem tra container
if (!(docker ps -q -f name=$Container)) {
    Write-Host "Loi: Container '$Container' chua chay!" -ForegroundColor Red
    exit
}

# Ham chay SQL file thong qua Docker exec
# Ham chay SQL file thong qua Docker exec
function Run-SqlFile ($File, $Mode) {
    Write-Host "Dang chay script: $File ($Mode)..." -ForegroundColor Yellow
    
    $Sql = "@$File`nEXIT;"
    if ($Mode -eq "CDB") {
        $Sql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
    } else {
        $Sql = "ALTER SESSION SET CONTAINER = FREEPDB1;`n@$File`nEXIT;"
        $Sql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
    }
}

# Ham chay lenh SQL truc tiep
function Run-SqlCmd ($Cmd, $Mode) {
    # Ensure EXIT is appended
    $Cmd = "$Cmd`nEXIT;"
    if ($Mode -eq "CDB") {
        $Cmd | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
    } else {
        $Cmd = "ALTER SESSION SET CONTAINER = FREEPDB1;`n$Cmd"
        $Cmd | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
    }
}

# === PHASE 1: ENABLE OLS (CDB) ===
Write-Host "`nPHASE 1: Enable OLS at System Level (CDB)" -ForegroundColor Green
Run-SqlFile "$SetupDir/15_enable_ols_system.sql" "CDB"
Run-SqlFile "$SetupDir/16_enable_ols_pdb.sql" "CDB"

# Can restart DB de OLS co hieu luc
Write-Host "`nDang RESTART database de kich hoat OLS (mat khoang 2-3 phut)..." -ForegroundColor Magenta
docker restart $Container

Write-Host "Dang cho database khoi dong lai..." -ForegroundColor Yellow
# Loop check cho den khi database ready
$MaxRetries = 60 # 60 * 5s = 5 phut
$RetryCount = 0
$DBReady = $false

while ($RetryCount -lt $MaxRetries) {
    Start-Sleep -Seconds 5
    $CheckSql = @"
SET PAGESIZE 0 FEEDBACK OFF;
SELECT status FROM v`$instance;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
    $Status = $CheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
    
    if ($Status -match "OPEN" -and $Status -match "READ WRITE") {
        # Ensure PDB is open
        $OpenPDBSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT;
"@
        $OpenPDBSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" | Out-Null
        Start-Sleep -Seconds 2
        $DBReady = $true
        break
    }
    Write-Host -NoNewline "."
    $RetryCount++
}

if (-not $DBReady) {
    Write-Host "`nLoi: Database khong khoi dong duoc sau 5 phut." -ForegroundColor Red
    exit
}

Write-Host "`nDatabase da san sang! Tiep tuc setup..." -ForegroundColor Green

# === PHASE 2: SETUP SCHEMA & TABLES (PDB) ===
Write-Host "`nPHASE 2: Setup Schema and Tables (PDB)" -ForegroundColor Green
Run-SqlFile "$SetupDir/01_create_users.sql" "PDB"
Run-SqlFile "$SetupDir/02_create_tables.sql" "PDB"
Run-SqlFile "$SetupDir/03_setup_vpd.sql" "PDB"

# === PHASE 3: SECURITY FEATURES (PDB) ===
Write-Host "`nPHASE 3: Setup Security Features (PDB)" -ForegroundColor Green
Run-SqlFile "$SetupDir/04_setup_audit.sql" "PDB"
Run-SqlFile "$SetupDir/05_setup_ols.sql" "PDB"
Run-SqlFile "$SetupDir/08_create_ols_trigger.sql" "PDB"
Run-SqlFile "$SetupDir/10_setup_proxy_auth.sql" "PDB"
Run-SqlFile "$SetupDir/17_fix_ols_permissions.sql" "PDB"

# === PHASE 4: UPDATE OLS LABELS ===
Write-Host "`nPHASE 4: Update OLS Labels" -ForegroundColor Green
$UpdateLabelsSql = @"
UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB') WHERE sensitivity_level = 'PUBLIC';
UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB') WHERE sensitivity_level = 'INTERNAL';
UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB') WHERE sensitivity_level = 'CONFIDENTIAL';
UPDATE library.books SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ') WHERE sensitivity_level = 'TOP_SECRET';
COMMIT;
"@
Run-SqlCmd $UpdateLabelsSql "PDB"

# === PHASE 5: GRANT AUDIT PERMISSIONS ===
Write-Host "`nPHASE 5: Grant Audit Permissions" -ForegroundColor Green
$GrantAuditSql = @"
GRANT SELECT ON audsys.unified_audit_trail TO library;
GRANT SELECT ON dba_profiles TO library;
GRANT SELECT ON dba_users TO library;
COMMIT;
"@
Run-SqlCmd $GrantAuditSql "PDB"

# === PHASE 6: SETUP DATABASE VAULT (ODV) ===
Write-Host "`nPHASE 6: Setup Oracle Database Vault (ODV)" -ForegroundColor Green
Write-Host "Luu y: ODV yeu cau Enterprise Edition. Neu ban dung ban Free/Community co the bo qua hoac gap loi." -ForegroundColor Yellow

# Check if ODV is supported
Write-Host "Checking if Oracle Database Vault is supported..." -ForegroundColor Yellow
# Check multiple ways: v$option (CDB), DBA_DV_STATUS, and DVSYS package existence
$CheckODVCDB = @"
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM v`$option WHERE parameter = 'Oracle Database Vault' AND value = 'TRUE') THEN 'TRUE'
    ELSE 'FALSE'
END FROM dual;
EXIT;
"@
$CheckODVPDB = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM all_objects WHERE owner = 'DVSYS' AND object_name = 'DBMS_MACADM') THEN 'TRUE'
    WHEN EXISTS (SELECT 1 FROM dba_registry WHERE comp_id = 'DV') THEN 'TRUE'
    ELSE 'FALSE'
END FROM dual;
EXIT;
"@

$ODVStatusCDB = ($CheckODVCDB | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1) -join "`n"
$ODVStatusPDB = ($CheckODVPDB | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1) -join "`n"

$ODVAvailable = ($ODVStatusCDB -match "TRUE") -or ($ODVStatusPDB -match "TRUE")

if (-not $ODVAvailable) {
    Write-Host "WARNING: Oracle Database Vault is NOT supported/enabled in this Database Edition." -ForegroundColor Red
    Write-Host "CDB Check: $ODVStatusCDB" -ForegroundColor Yellow
    Write-Host "PDB Check: $ODVStatusPDB" -ForegroundColor Yellow
    Write-Host "Skipping Phase 6 setup." -ForegroundColor Yellow
    
    # === DONE ===
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "HOAN TAT QUA TRINH KHOI TAO (WITHOUT ODV)!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    # Skip Read-Host in non-interactive mode
    try {
        if ([Environment]::UserInteractive) {
            Read-Host -Prompt "Nhan Enter de thoat"
        }
    } catch {
        # Ignore Read-Host errors in non-interactive mode
    }
    exit
}
Write-Host "ODV is available. Proceeding with setup..." -ForegroundColor Green

# 6.1 Enable ODV in CDB (Require first restart)
# Note: CDB DV must be enabled by C##SEC_ADMIN after granting DV_OWNER role
Write-Host "Setting up CDB DV users and configuration..." -ForegroundColor Yellow
Run-SqlFile "$SetupDir/18a_setup_dv_cdb.sql" "CDB"

Write-Host "`n[CDB] Restarting database to enable ODV in ROOT..." -ForegroundColor Magenta
docker restart $Container

# Wait for DB and PDB
Write-Host "Waiting for DB startup..." -ForegroundColor Yellow
$RetryCount = 0
$DBReady = $false
while ($RetryCount -lt $MaxRetries) {
    Start-Sleep -Seconds 5
    $CheckSql = @"
SET PAGESIZE 0 FEEDBACK OFF;
SELECT status FROM v`$instance;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
    $Status = $CheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
    if ($Status -match "OPEN" -and $Status -match "READ WRITE") { 
        $DBReady = $true
        # Ensure PDB is open
        $OpenPDBSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT;
"@
        $OpenPDBSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" | Out-Null
        # Wait a bit more for listener to register
        Start-Sleep -Seconds 3
        break 
    }
    Write-Host -NoNewline "."
    $RetryCount++
}

if (-not $DBReady) { 
    Write-Host "`nFailed to start after CDB ODV enable" -ForegroundColor Red
    Write-Host "Checking database status..." -ForegroundColor Yellow
    $StatusSql = @"
SELECT instance_name, status FROM v`$instance;
SELECT name, open_mode FROM v`$pdbs;
EXIT;
"@
    $StatusSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
    exit 
}

# 6.1b Enable DV in CDB (must be done by C##SEC_ADMIN after restart)
Write-Host "Enabling DV in CDB (running as C##SEC_ADMIN)..." -ForegroundColor Yellow
$CDBSecAdmin = "c##sec_admin/SecAdmin123"
$EnableCDBDVSql = @"
SET SERVEROUTPUT ON;
-- Check if already enabled first
DECLARE
    v_status VARCHAR2(20);
BEGIN
    SELECT STATUS INTO v_status FROM DBA_DV_STATUS WHERE ROWNUM = 1;
    IF v_status = 'ENABLED' THEN
        DBMS_OUTPUT.PUT_LINE('CDB Database Vault already enabled.');
    ELSE
        DVSYS.DBMS_MACADM.ENABLE_DV;
        DBMS_OUTPUT.PUT_LINE('CDB Database Vault enabled.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Not configured, try to enable
        DVSYS.DBMS_MACADM.ENABLE_DV;
        DBMS_OUTPUT.PUT_LINE('CDB Database Vault enabled.');
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%already%' OR SQLERRM LIKE '%enabled%' THEN
            DBMS_OUTPUT.PUT_LINE('CDB Database Vault already enabled.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CDB DV Enable Error: ' || SQLERRM);
            RAISE;
        END IF;
END;
/
-- Verify CDB DV is enabled
SELECT STATUS FROM DBA_DV_STATUS;
EXIT;
"@
$EnableCDBDVOutput = $EnableCDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$CDBSecAdmin'" 2>&1
$EnableCDBDVOutput | Write-Host

# Verify CDB DV is enabled before proceeding
# CDB DV status shows as "TRUE" for ENABLE_STATUS
$CDBDVEnabled = $false
if ($EnableCDBDVOutput -match "DV_ENABLE_STATUS\s+TRUE" -or $EnableCDBDVOutput -match "TRUE\s+TRUE" -or ($EnableCDBDVOutput -match "ENABLED" -and $EnableCDBDVOutput -notmatch "NOT")) {
    $CDBDVEnabled = $true
    Write-Host "✅ CDB Database Vault is enabled. Proceeding with PDB setup..." -ForegroundColor Green
} else {
    Write-Host "Checking CDB DV status in detail..." -ForegroundColor Yellow
    $CheckCDBDVSql = @"
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
    $CDBDVStatus = $CheckCDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$CDBSecAdmin'" 2>&1
    $CDBDVStatus | Write-Host
    # Check for DV_ENABLE_STATUS = TRUE
    if ($CDBDVStatus -match "DV_ENABLE_STATUS\s+TRUE") {
        $CDBDVEnabled = $true
        Write-Host "✅ CDB Database Vault is enabled. Proceeding with PDB setup..." -ForegroundColor Green
    } else {
        Write-Host "ERROR: CDB Database Vault is not enabled. Cannot proceed with PDB DV setup." -ForegroundColor Red
        Write-Host "CDB DV Status output: $CDBDVStatus" -ForegroundColor Yellow
        Write-Host "Please check CDB DV configuration manually." -ForegroundColor Yellow
        exit
    }
}

# 6.2a Create DV Users in PDB (Run as SYS)
Write-Host "Creating DV users in PDB..." -ForegroundColor Yellow
Run-SqlFile "$SetupDir/18_setup_database_vault.sql" "PDB"

# 6.2b Grant necessary privileges to SEC_ADMIN
Write-Host "Granting DV privileges to SEC_ADMIN..." -ForegroundColor Yellow
$GrantSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
BEGIN
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.CONFIGURE_DV TO SEC_ADMIN';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.DBMS_MACADM TO SEC_ADMIN';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DVSYS.DBMS_MACUTL TO SEC_ADMIN';
EXCEPTION 
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Grant Warning: ' || SQLERRM);
END;
/
EXIT;
"@
$GrantSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" | Out-Null

# Wait a bit for CDB DV to be fully active after restart
Write-Host "Waiting for CDB DV to be fully active..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 6.2c Enable DV in PDB (Run as SEC_ADMIN)
# IMPORTANT: PDB DV can only be enabled if CDB DV is enabled
# Use the verified CDB DV status from above
if (-not $CDBDVEnabled) {
    Write-Host "ERROR: CDB Database Vault is not enabled. Cannot enable PDB DV." -ForegroundColor Red
    Write-Host "Skipping PDB DV enable. Realms will be set up but DV protection may not be active." -ForegroundColor Yellow
} else {
    Write-Host "✅ CDB DV is enabled. Proceeding with PDB DV setup..." -ForegroundColor Green
    # Wait for listener to be ready first
    Write-Host "Waiting for listener to register PDB service..." -ForegroundColor Yellow
    $ListenerReady = $false
    $ListenerRetry = 0
    while ($ListenerRetry -lt 30) {
        Start-Sleep -Seconds 2
        $LsnrCheck = docker exec $Container bash -c "lsnrctl status | grep -i FREEPDB1" 2>&1
        if ($LsnrCheck -match "FREEPDB1") {
            $ListenerReady = $true
            break
        }
        $ListenerRetry++
    }
    if (-not $ListenerReady) {
        Write-Host "Warning: Listener may not be ready, but continuing..." -ForegroundColor Yellow
    }

    # Connect to PDB directly using service name format
    Write-Host "Enabling DV in PDB (running as SEC_ADMIN)..." -ForegroundColor Yellow
    # Try connecting via local connection first (inside container)
    $SecAdminConnect = "sec_admin/SecAdmin123@localhost:1521/FREEPDB1"
    
    # First configure PDB DV
    Write-Host "Configuring PDB DV..." -ForegroundColor Yellow
    $ConfigurePDBDVSql = @"
SET SERVEROUTPUT ON;
BEGIN
    DVSYS.CONFIGURE_DV(
        dvowner_uname         => 'SEC_ADMIN',
        dvacctmgr_uname       => 'DV_ACCTMGR_USER'
    );
    DBMS_OUTPUT.PUT_LINE('PDB Database Vault configured.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Config Warning: ' || SQLERRM);
END;
/
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
    $ConfigureOutput = $ConfigurePDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$SecAdminConnect'" 2>&1
    $ConfigureOutput | Write-Host
    
    # Then enable PDB DV
    Write-Host "Enabling PDB DV..." -ForegroundColor Yellow
    $EnableDVSql = @"
SET SERVEROUTPUT ON;
BEGIN
    DVSYS.DBMS_MACADM.ENABLE_DV;
    DBMS_OUTPUT.PUT_LINE('PDB Database Vault enabled. RESTART REQUIRED.');
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PDB DV Enable Error: ' || SQLERRM);
END;
/
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
    $EnableDVOutput = $EnableDVSql | docker exec -i $Container bash -c "sqlplus -s '$SecAdminConnect'" 2>&1
    $EnableDVOutput | Write-Host

    # Verify PDB DV was enabled successfully
    Write-Host "Verifying PDB DV status..." -ForegroundColor Yellow
    $VerifyPDBDVSql = @"
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
    $PDBDVStatus = $VerifyPDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$SecAdminConnect'" 2>&1
    $PDBDVStatus | Write-Host
    
    $PDBDVEnabled = ($PDBDVStatus -match "DV_ENABLE_STATUS\s+TRUE")
    $PDBDVConfigured = ($PDBDVStatus -match "DV_CONFIGURE_STATUS\s+TRUE")

    # Check if enable was successful or already enabled
    if (-not $PDBDVEnabled -and ($EnableDVOutput -match "ORA-12514" -or $EnableDVOutput -match "ORA-47503" -or ($EnableDVOutput -match "ORA-" -and $EnableDVOutput -notmatch "already enabled" -and $EnableDVOutput -notmatch "already exists" -and $EnableDVOutput -notmatch "ORA-00942"))) {
    Write-Host "Warning: DV enable had errors, trying alternative method with SYS..." -ForegroundColor Yellow
    # Try using 18c_force_configure_sys.sql as fallback (run as SYS)
    Run-SqlFile "$SetupDir/18c_force_configure_sys.sql" "PDB"
    
    # Restart again if we used fallback
    Write-Host "Restarting database after fallback enable..." -ForegroundColor Magenta
    docker restart $Container
    
    # Wait for DB
    Write-Host "Waiting for DB startup..." -ForegroundColor Yellow
    $RetryCount = 0
    $DBReady = $false
    while ($RetryCount -lt $MaxRetries) {
        Start-Sleep -Seconds 5
        $CheckSql = @"
SET PAGESIZE 0 FEEDBACK OFF;
SELECT status FROM v`$instance;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
        $Status = $CheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
        if ($Status -match "OPEN" -and $Status -match "READ WRITE") {
            # Check if PDB needs to be opened
            $PDBCheckSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
            $PDBStatus = $PDBCheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
            if ($PDBStatus -notmatch "READ WRITE") {
                $OpenPDBSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT;
"@
                $OpenPDBSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" | Out-Null
            }
            Start-Sleep -Seconds 3
            $DBReady = $true
            break
        }
        Write-Host -NoNewline "."
        $RetryCount++
    }
    if (-not $DBReady) {
        Write-Host "`nFailed to start after fallback enable" -ForegroundColor Red
        exit
    }
}

    # Only restart if PDB DV was successfully enabled
    if ($PDBDVEnabled) {
        Write-Host "✅ PDB DV enabled successfully. Restarting database..." -ForegroundColor Green
        Write-Host "`n[PDB] Restarting database to apply ODV in PDB..." -ForegroundColor Magenta
        docker restart $Container
    } else {
        Write-Host "⚠️ PDB DV may not be fully enabled. Skipping restart for now." -ForegroundColor Yellow
        Write-Host "You may need to manually enable PDB DV and restart." -ForegroundColor Yellow
        $DBReady = $true  # Skip restart wait
    }

    # Wait for DB again (only if we restarted)
    if ($PDBDVEnabled) {
        Write-Host "Waiting for DB startup..." -ForegroundColor Yellow
        $RetryCount = 0
        $DBReady = $false
        while ($RetryCount -lt $MaxRetries) {
            Start-Sleep -Seconds 5
            $CheckSql = @"
SET PAGESIZE 0 FEEDBACK OFF;
SELECT status FROM v`$instance;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
            $Status = $CheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
            if ($Status -match "OPEN" -and $Status -match "READ WRITE") {
                $DBReady = $true
                break
            }
            Write-Host -NoNewline "."
            $RetryCount++
        }

        if (-not $DBReady) { 
            Write-Host "`nFailed to start after PDB ODV enable" -ForegroundColor Red
            Write-Host "Checking database status..." -ForegroundColor Yellow
            $StatusSql = @"
SELECT instance_name, status FROM v`$instance;
SELECT name, open_mode FROM v`$pdbs;
EXIT;
"@
            $StatusSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'"
            exit 
        }

        # Ensure PDB is open after restart (with safe check)
        Write-Host "Ensuring PDB is open..." -ForegroundColor Yellow
        $PDBCheckSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT open_mode FROM v`$pdbs WHERE name = 'FREEPDB1';
EXIT;
"@
        $PDBStatus = $PDBCheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
        # Only open if not already open/opening
        if ($PDBStatus -match "MOUNTED" -or $PDBStatus -notmatch "READ WRITE") {
            # Wait a bit to ensure PDB is not in opening state
            Start-Sleep -Seconds 3
            $PDBStatusCheck = $PDBCheckSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
            if ($PDBStatusCheck -match "MOUNTED") {
                $OpenPDBSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT;
"@
                $OpenPDBSql | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" | Out-Null
                Start-Sleep -Seconds 2
            }
        }
        
        # Verify PDB DV still enabled after restart
        Write-Host "Verifying PDB DV after restart..." -ForegroundColor Yellow
        $VerifyAfterRestart = $VerifyPDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$SecAdminConnect'" 2>&1
        $VerifyAfterRestart | Write-Host
        if ($VerifyAfterRestart -match "DV_ENABLE_STATUS.*TRUE") {
            Write-Host "✅ PDB DV is enabled after restart" -ForegroundColor Green
        } else {
            Write-Host "⚠️ PDB DV may need to be re-enabled after restart" -ForegroundColor Yellow
        }
    }
}

# 6.3 Setup Realms (Run as sec_admin)
Write-Host "`nSetting up DV Realms (running as SEC_ADMIN)..." -ForegroundColor Green
# Wait for listener again
Start-Sleep -Seconds 3
$SecAdminUser = "sec_admin/SecAdmin123@localhost:1521/FREEPDB1"
# Note: SEC_ADMIN cannot use ALTER SESSION SET CONTAINER, so script 19 must be fixed
# Connect directly to PDB using service name
$RealmSql = "@$SetupDir/19_setup_dv_realms.sql`nEXIT;"
$RealmOutput = $RealmSql | docker exec -i $Container bash -c "sqlplus -s '$SecAdminUser'" 2>&1
$RealmOutput | Write-Host
if ($RealmOutput -match "ORA-" -and $RealmOutput -notmatch "already exists" -and $RealmOutput -notmatch "ORA-00942") {
    Write-Host "Warning: Realm setup had some errors, but continuing..." -ForegroundColor Yellow
}


# === DONE ===
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "HOAN TAT QUA TRINH KHOI TAO!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Database san sang su dung."
Write-Host "Test Users: admin_user / librarian_user / staff_user / reader_user"
Write-Host "ODV Admin: sec_admin / SecAdmin123"
Write-Host "CDB DV Admin: c##sec_admin / SecAdmin123"

# Skip Read-Host in non-interactive mode
try {
    if ([Environment]::UserInteractive) {
        Read-Host -Prompt "Nhan Enter de thoat"
    }
} catch {
    # Ignore Read-Host errors in non-interactive mode
}
