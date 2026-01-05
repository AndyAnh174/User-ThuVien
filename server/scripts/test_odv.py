import oracledb
import sys

# Connect as SYS
DB_SYS_USER = "sys"
DB_SYS_PWD = "Oracle123"
DB_DSN = "oracle-db:1521/FREEPDB1"

def test_odv():
    print("\n============================================")
    print("TESTING ORACLE DATABASE VAULT PROTECTION")
    print("============================================")
    
    conn = None
    try:
        print(f"1. Connecting as SYSDBA to {DB_DSN}...")
        conn = oracledb.connect(
            user=DB_SYS_USER,
            password=DB_SYS_PWD,
            dsn=DB_DSN,
            mode=oracledb.SYSDBA
        )
        cursor = conn.cursor()
        print("   Connected successfully.")
        
        # Test 1: Realm Violation (SELECT)
        print("\n2. Testing Realm Protection (SELECT from LIBRARY.BOOKS)...")
        try:
            cursor.execute("SELECT count(*) FROM LIBRARY.BOOKS")
            print("   [FAIL] SYS was able to query LIBRARY.BOOKS!")
            print("   (ODV might not be enabled or Realm is missing)")
        except oracledb.DatabaseError as e:
            error, = e.args
            # ORA-47401: Realm violation for select
            # ORA-47408: Realm violation
            # ORA-01031: Insufficient privileges (Standard Realm Violation)
            if error.code in [47401, 47408, 47400, 1031]:
                print(f"   [PASS] Access Denied: {error.message}")
            else:
                print(f"   [WARN] Denied with unexpected error: {error.message}")

        # Test 2: Command Rule (DROP TABLE)
        # We try to drop a non-existent table in LIBRARY schema
        # The Command Rule should trigger regardless of existence if it checks 'DROP TABLE' on 'LIBRARY.%'
        print("\n3. Testing Command Rule (DROP TABLE LIBRARY.DUMMY)...")
        try:
            cursor.execute("DROP TABLE LIBRARY.DUMMY_TABLE_TEST")
            print("   [FAIL] SYS was able to execute DROP TABLE!")
        except oracledb.DatabaseError as e:
            error, = e.args
            # ORA-47400: Command Rule violation
            # ORA-00942: Table not found (means Rule allowed it passed!)
            
            if error.code in [47400, 47401]:
                print(f"   [PASS] Command Blocked: {error.message}")
            elif error.code == 942:
                print("   [FAIL] Rule allowed execution (Table not found error).")
            else:
                print(f"   [WARN] Unexpected error: {error.message}")

    except Exception as e:
        print(f"FATAL ERROR: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    test_odv()
