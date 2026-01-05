import oracledb

# Connection details
DV_OWNER_USER = "sec_admin"
DV_OWNER_PWD = "SecAdmin123"
DB_DSN = "oracle-db:1521/FREEPDB1"

try:
    print(f"Connecting to {DB_DSN} as {DV_OWNER_USER}...")
    conn = oracledb.connect(
        user=DV_OWNER_USER,
        password=DV_OWNER_PWD,
        dsn=DB_DSN
    )
    cursor = conn.cursor()
    
    print("Checking columns of DVSYS.DBA_DV_REALM...")
    try:
        cursor.execute("SELECT * FROM DVSYS.DBA_DV_REALM WHERE ROWNUM = 1")
        cols = [col[0] for col in cursor.description]
        print(f"Columns: {cols}")
    except Exception as e:
        print(f"Error selecting from view: {e}")

    conn.close()
except Exception as e:
    print(f"Fatal: {e}")
