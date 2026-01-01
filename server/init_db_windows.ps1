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
function Run-SqlFile ($File, $Mode) {
    Write-Host "Dang chay script: $File ($Mode)..." -ForegroundColor Yellow
    
    if ($Mode -eq "CDB") {
        # Chay o CDB
        docker exec $Container bash -c "echo '@$File' | sqlplus -s '$SysUser'"
    } else {
        # Chay o PDB (FREEPDB1)
        docker exec $Container bash -c "echo 'ALTER SESSION SET CONTAINER = FREEPDB1; @$File' | sqlplus -s '$SysUser'"
    }
}

# Ham chay lenh SQL truc tiep
function Run-SqlCmd ($Cmd, $Mode) {
    if ($Mode -eq "CDB") {
        docker exec $Container bash -c "echo '$Cmd' | sqlplus -s '$SysUser'"
    } else {
        docker exec $Container bash -c "echo 'ALTER SESSION SET CONTAINER = FREEPDB1; $Cmd' | sqlplus -s '$SysUser'"
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
    $Status = docker exec $Container bash -c "echo 'SELECT status FROM v`$instance;' | sqlplus -s '$SysUser'"
    
    if ($Status -match "OPEN") {
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

# === DONE ===
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "HOAN TAT QUA TRINH KHOI TAO!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Database san sang su dung."
Write-Host "Test Users: admin_user / librarian_user / staff_user / reader_user"

Read-Host -Prompt "Nhan Enter de thoat"
