import oracledb

DB_SYS_USER = "sys"
DB_SYS_PWD = "Oracle123"
DB_DSN = "oracle-db:1521/FREEPDB1"

try:
    print(f"Connecting to {DB_DSN} as SYSDBA...")
    conn = oracledb.connect(
        user=DB_SYS_USER,
        password=DB_SYS_PWD,
        dsn=DB_DSN,
        mode=oracledb.SYSDBA,
    )
    cursor = conn.cursor()
    
    print("Checking grantees of DV_OWNER role...")
    cursor.execute("SELECT grantee FROM dba_role_privs WHERE granted_role='DV_OWNER'")
    rows = cursor.fetchall()
    print(f"Grantees: {rows}")

    conn.close()
except Exception as e:
    print(f"Error: {e}")
