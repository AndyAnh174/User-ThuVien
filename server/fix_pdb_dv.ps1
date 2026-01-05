# Script Fix PDB DV - Enable PDB Database Vault
# Chạy script này nếu PDB DV chưa được enable sau khi chạy init_db_windows.ps1

$Container = "oracle23ai"
$CDBSecAdmin = "c##sec_admin/SecAdmin123"
$PDBSecAdmin = "sec_admin/SecAdmin123@localhost:1521/FREEPDB1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "FIX PDB DATABASE VAULT" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Step 1: Check CDB DV Status
Write-Host "`n[Step 1] Checking CDB DV Status..." -ForegroundColor Yellow
$CheckCDBDVSql = @"
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
$CDBDVStatus = $CheckCDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$CDBSecAdmin'" 2>&1
$CDBDVStatus | Write-Host

if ($CDBDVStatus -notmatch "DV_ENABLE_STATUS.*TRUE") {
    Write-Host "❌ CDB DV is not enabled. Cannot enable PDB DV." -ForegroundColor Red
    Write-Host "Please enable CDB DV first." -ForegroundColor Yellow
    exit
} else {
    Write-Host "✅ CDB DV is enabled" -ForegroundColor Green
}

# Step 2: Check PDB DV Status
Write-Host "`n[Step 2] Checking PDB DV Status..." -ForegroundColor Yellow
$CheckPDBDVSql = @"
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
$PDBDVStatus = $CheckPDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
$PDBDVStatus | Write-Host

$PDBDVEnabled = ($PDBDVStatus -match "DV_ENABLE_STATUS.*TRUE")
$PDBDVConfigured = ($PDBDVStatus -match "DV_CONFIGURE_STATUS.*TRUE")

if ($PDBDVEnabled) {
    Write-Host "✅ PDB DV is already enabled" -ForegroundColor Green
    Write-Host "No action needed." -ForegroundColor Green
    exit
}

# Step 3: Configure PDB DV (if not configured)
if (-not $PDBDVConfigured) {
    Write-Host "`n[Step 3] Configuring PDB DV..." -ForegroundColor Yellow
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
        DBMS_OUTPUT.PUT_LINE('PDB DV Config Error: ' || SQLERRM);
END;
/
SELECT NAME, STATUS FROM DBA_DV_STATUS;
EXIT;
"@
    $ConfigureResult = $ConfigurePDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
    $ConfigureResult | Write-Host
    
    if ($ConfigureResult -match "DV_CONFIGURE_STATUS.*TRUE") {
        Write-Host "✅ PDB DV configured successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to configure PDB DV" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "✅ PDB DV is already configured" -ForegroundColor Green
}

# Step 4: Enable PDB DV
Write-Host "`n[Step 4] Enabling PDB DV..." -ForegroundColor Yellow
$EnablePDBDVSql = @"
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
$EnableResult = $EnablePDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
$EnableResult | Write-Host

if ($EnableResult -match "DV_ENABLE_STATUS.*TRUE") {
    Write-Host "✅ PDB DV enabled successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to enable PDB DV" -ForegroundColor Red
    exit
}

# Step 5: Restart Database
Write-Host "`n[Step 5] Restarting database to apply changes..." -ForegroundColor Yellow
docker restart $Container

Write-Host "Waiting for database to start..." -ForegroundColor Yellow
$MaxRetries = 60
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
    $Status = $CheckSql | docker exec -i $Container bash -c "sqlplus -s sys/Oracle123 as sysdba" 2>&1
    if ($Status -match "OPEN" -and $Status -match "READ WRITE") {
        $OpenPDBSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
EXIT;
"@
        $OpenPDBSql | docker exec -i $Container bash -c "sqlplus -s sys/Oracle123 as sysdba" | Out-Null
        Start-Sleep -Seconds 2
        $DBReady = $true
        break
    }
    Write-Host -NoNewline "."
    $RetryCount++
}

if (-not $DBReady) {
    Write-Host "`n❌ Database did not start properly" -ForegroundColor Red
    exit
}

Write-Host "`n✅ Database restarted successfully" -ForegroundColor Green

# Step 6: Verify PDB DV after restart
Write-Host "`n[Step 6] Verifying PDB DV after restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$VerifyAfterRestart = $CheckPDBDVSql | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
$VerifyAfterRestart | Write-Host

if ($VerifyAfterRestart -match "DV_ENABLE_STATUS.*TRUE") {
    Write-Host "✅ PDB DV is enabled after restart" -ForegroundColor Green
} else {
    Write-Host "⚠️ PDB DV may need to be re-enabled" -ForegroundColor Yellow
}

# Step 7: Test Realm Protection
Write-Host "`n[Step 7] Testing Realm Protection..." -ForegroundColor Yellow
$TestRealmSql = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM library.books;
EXIT;
"@
$TestRealmResult = $TestRealmSql | docker exec -i $Container bash -c "sqlplus -s sys/Oracle123 as sysdba" 2>&1
$TestRealmResult | Write-Host

if ($TestRealmResult -match "ORA-01031" -or $TestRealmResult -match "insufficient privileges") {
    Write-Host "✅ Realm Protection is WORKING: SYS cannot access LIBRARY data" -ForegroundColor Green
} else {
    Write-Host "⚠️ Realm Protection may not be active" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "FIX COMPLETED!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

