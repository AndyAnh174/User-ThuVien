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
        mode=oracledb.SYSDBA
    )
    cursor = conn.cursor()
    
    cursor.execute("SELECT count(*) FROM DBA_USERS WHERE USERNAME='DV_OWNER'")
    is_user = cursor.fetchone()[0]
    print(f"Is User: {is_user}")
    
    cursor.execute("SELECT count(*) FROM DBA_ROLES WHERE ROLE='DV_OWNER'")
    is_role = cursor.fetchone()[0]
    print(f"Is Role: {is_role}")

    conn.close()
except Exception as e:
    print(f"Error: {e}")
