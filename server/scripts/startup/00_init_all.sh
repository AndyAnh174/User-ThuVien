#!/bin/bash
# ============================================
# ORACLE INITIALIZATION SCRIPT
# Chạy tự động khi container khởi động lần đầu
# ============================================

echo "============================================"
echo "Starting Library Database Initialization..."
echo "============================================"

# Wait for Oracle to be ready
sleep 30

ORACLE_PWD=${ORACLE_PWD:-Oracle123}
PDB_NAME=${ORACLE_PDB:-FREEPDB1}

# Function to run SQL
run_sql() {
    local user=$1
    local sql=$2
    local container=$3
    
    echo "Running: $sql as $user"
    
    if [ "$container" == "CDB" ]; then
        sqlplus -s "$user" <<EOF
$sql
EXIT;
EOF
    else
        sqlplus -s "$user" <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
$sql
EXIT;
EOF
    fi
}

# Function to run SQL file
run_sql_file() {
    local user=$1
    local file=$2
    local container=$3
    
    echo "============================================"
    echo "Running: $file"
    echo "============================================"
    
    if [ "$container" == "CDB" ]; then
        sqlplus -s "$user" @"$file"
    else
        sqlplus -s "$user" <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
@$file
EXIT;
EOF
    fi
}

SETUP_DIR="/opt/oracle/scripts/setup"
SYS_CONN="sys/${ORACLE_PWD} as sysdba"

echo ""
echo "============================================"
echo "PHASE 1: Enable OLS at System Level (CDB)"
echo "============================================"

# Enable OLS - chạy ở CDB ROOT
run_sql_file "$SYS_CONN" "$SETUP_DIR/15_enable_ols_system.sql" "CDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/16_enable_ols_pdb.sql" "CDB"

echo ""
echo "============================================"
echo "PHASE 2: Setup Schema and Tables (PDB)"
echo "============================================"

# Chạy các scripts trong PDB
run_sql_file "$SYS_CONN" "$SETUP_DIR/01_create_users.sql" "PDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/02_create_tables.sql" "PDB"

echo ""
echo "============================================"
echo "PHASE 3: Setup Security Features (PDB)"
echo "============================================"

run_sql_file "$SYS_CONN" "$SETUP_DIR/04_setup_audit.sql" "PDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/05_setup_ols.sql" "PDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/08_create_ols_trigger.sql" "PDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/10_setup_proxy_auth.sql" "PDB"
run_sql_file "$SYS_CONN" "$SETUP_DIR/17_fix_ols_permissions.sql" "PDB"

echo ""
echo "============================================"
echo "PHASE 4: Update OLS Labels"
echo "============================================"

sqlplus -s "$SYS_CONN" <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB')
WHERE sensitivity_level = 'PUBLIC';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB')
WHERE sensitivity_level = 'INTERNAL';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB')
WHERE sensitivity_level = 'CONFIDENTIAL';

UPDATE library.books 
SET ols_label = CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ')
WHERE sensitivity_level = 'TOP_SECRET';

COMMIT;
EXIT;
EOF

echo ""
echo "============================================"
echo "PHASE 5: Grant Audit Permissions"
echo "============================================"

sqlplus -s "$SYS_CONN" <<EOF
ALTER SESSION SET CONTAINER = $PDB_NAME;
GRANT SELECT ON audsys.unified_audit_trail TO library;
GRANT SELECT ON dba_profiles TO library;
GRANT SELECT ON dba_users TO library;
COMMIT;
EXIT;
EOF

echo ""
echo "============================================"
echo "PHASE 6: Database Vault (Optional)"
echo "============================================"

# Kiểm tra Database Vault có khả dụng không
DV_CHECK=$(sqlplus -s "$SYS_CONN" <<EOF
SET HEADING OFF FEEDBACK OFF
SELECT COUNT(*) FROM dba_registry WHERE comp_name LIKE '%Vault%';
EXIT;
EOF
)

if [[ $DV_CHECK -gt 0 ]]; then
    echo "Database Vault available. Setting up..."
    run_sql_file "$SYS_CONN" "$SETUP_DIR/18_setup_database_vault.sql" "PDB"
    echo "NOTE: Database Vault requires restart to take effect."
    echo "Run script 19_setup_dv_realms.sql after restart."
else
    echo "Database Vault not available in this edition. Skipping..."
fi

echo ""
echo "============================================"
echo "INITIALIZATION COMPLETE!"
echo "============================================"
echo "Database is ready for use."
echo ""
echo "Test Users:"
echo "  admin_user / Admin123"
echo "  librarian_user / Librarian123"
echo "  staff_user / Staff123"
echo "  reader_user / Reader123"
echo "============================================"
