# Script Test ODV Setup
# Chạy sau khi init_db_windows.ps1 hoàn thành

$Container = "oracle23ai"
$CDBSecAdmin = "c##sec_admin/SecAdmin123"
$PDBSecAdmin = "sec_admin/SecAdmin123@localhost:1521/FREEPDB1"
$SysUser = "sys/Oracle123 as sysdba"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "TEST ODV SETUP" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Test 1: Check CDB DV Status
Write-Host "`n[TEST 1] Checking CDB DV Status..." -ForegroundColor Yellow
$CDBDVCheck = @"
SELECT STATUS FROM DBA_DV_STATUS;
EXIT;
"@
$CDBDVResult = $CDBDVCheck | docker exec -i $Container bash -c "sqlplus -s '$CDBSecAdmin'" 2>&1
$CDBDVResult | Write-Host
if ($CDBDVResult -match "ENABLED") {
    Write-Host "✅ CDB DV is ENABLED" -ForegroundColor Green
} else {
    Write-Host "❌ CDB DV is NOT enabled" -ForegroundColor Red
}

# Test 2: Check PDB DV Status
Write-Host "`n[TEST 2] Checking PDB DV Status..." -ForegroundColor Yellow
$PDBDVCheck = @"
SELECT STATUS FROM DBA_DV_STATUS;
EXIT;
"@
$PDBDVResult = $PDBDVCheck | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
$PDBDVResult | Write-Host
if ($PDBDVResult -match "ENABLED" -or $PDBDVResult -match "CONFIGURED") {
    Write-Host "✅ PDB DV is configured/enabled" -ForegroundColor Green
} else {
    Write-Host "⚠️ PDB DV may not be fully configured" -ForegroundColor Yellow
}

# Test 3: Check Realms
Write-Host "`n[TEST 3] Checking Realms..." -ForegroundColor Yellow
$RealmCheck = @"
SELECT NAME, ENABLED FROM DVSYS.DBA_DV_REALM WHERE NAME = 'LIBRARY_REALM';
SELECT COUNT(*) as AUTH_COUNT FROM DVSYS.DBA_DV_REALM_AUTH WHERE REALM_NAME = 'LIBRARY_REALM';
EXIT;
"@
$RealmResult = $RealmCheck | docker exec -i $Container bash -c "sqlplus -s '$PDBSecAdmin'" 2>&1
$RealmResult | Write-Host
if ($RealmResult -match "LIBRARY_REALM" -and $RealmResult -match "Y") {
    Write-Host "✅ LIBRARY_REALM exists and is enabled" -ForegroundColor Green
} else {
    Write-Host "❌ LIBRARY_REALM not found or not enabled" -ForegroundColor Red
}

# Test 4: Test SYS cannot access LIBRARY data
Write-Host "`n[TEST 4] Testing SYS access to LIBRARY data (should fail)..." -ForegroundColor Yellow
$SysAccessTest = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM library.books;
EXIT;
"@
$SysAccessResult = $SysAccessTest | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
$SysAccessResult | Write-Host
if ($SysAccessResult -match "ORA-01031" -or $SysAccessResult -match "ORA-28106" -or $SysAccessResult -match "insufficient privileges" -or $SysAccessResult -match "realm violation") {
    Write-Host "✅ ODV Protection WORKING: SYS cannot access LIBRARY data" -ForegroundColor Green
} elseif ($SysAccessResult -match "no rows selected" -or $SysAccessResult -match "COUNT") {
    Write-Host "⚠️ SYS can access LIBRARY data (ODV may not be fully active)" -ForegroundColor Yellow
} else {
    Write-Host "❓ Unexpected result, check manually" -ForegroundColor Yellow
}

# Test 5: Test Authorized User can access
Write-Host "`n[TEST 5] Testing ADMIN_USER access (should succeed)..." -ForegroundColor Yellow
$AdminAccessTest = @"
SELECT COUNT(*) FROM library.books;
EXIT;
"@
$AdminAccessResult = $AdminAccessTest | docker exec -i $Container bash -c "sqlplus -s admin_user/Admin123@localhost:1521/FREEPDB1" 2>&1
$AdminAccessResult | Write-Host
if ($AdminAccessResult -match "COUNT" -or $AdminAccessResult -match "no rows selected") {
    Write-Host "✅ Authorized user (ADMIN_USER) can access LIBRARY data" -ForegroundColor Green
} else {
    Write-Host "❌ Authorized user cannot access (check realm authorization)" -ForegroundColor Red
}

# Test 6: Test Command Rules
Write-Host "`n[TEST 6] Testing Command Rules (DROP TABLE should be blocked)..." -ForegroundColor Yellow
$CommandRuleTest = @"
ALTER SESSION SET CONTAINER = FREEPDB1;
DROP TABLE library.test_table_should_not_exist;
EXIT;
"@
$CommandRuleResult = $CommandRuleTest | docker exec -i $Container bash -c "sqlplus -s '$SysUser'" 2>&1
$CommandRuleResult | Write-Host
if ($CommandRuleResult -match "ORA-47401" -or $CommandRuleResult -match "realm violation" -or $CommandRuleResult -match "command rule") {
    Write-Host "✅ Command Rules WORKING: DROP TABLE is blocked" -ForegroundColor Green
} else {
    Write-Host "⚠️ Command Rules may not be active (or table doesn't exist)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "CDB DV Status: " -NoNewline
if ($CDBDVResult -match "ENABLED") { Write-Host "✅ ENABLED" -ForegroundColor Green } else { Write-Host "❌ NOT ENABLED" -ForegroundColor Red }
Write-Host "PDB DV Status: " -NoNewline
if ($PDBDVResult -match "ENABLED" -or $PDBDVResult -match "CONFIGURED") { Write-Host "✅ CONFIGURED" -ForegroundColor Green } else { Write-Host "⚠️ CHECK MANUALLY" -ForegroundColor Yellow }
Write-Host "Realm Protection: " -NoNewline
if ($SysAccessResult -match "ORA-01031" -or $SysAccessResult -match "ORA-28106" -or $SysAccessResult -match "insufficient privileges") { Write-Host "✅ ACTIVE" -ForegroundColor Green } else { Write-Host "⚠️ CHECK MANUALLY" -ForegroundColor Yellow }

Write-Host "`nFor detailed testing, see TEST_ODV.md" -ForegroundColor Cyan

