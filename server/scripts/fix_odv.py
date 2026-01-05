import oracledb
import sys
import os
import time

# Connection details
DB_SYS_USER = "sys"
DB_SYS_PWD = "Oracle123"
# Use the service name from docker-compose network
DB_DSN = "oracle-db:1521/FREEPDB1"

def check_and_fix_odv():
    try:
        print(f"Connecting to {DB_DSN} as SYSDBA...")
        conn = oracledb.connect(
            user=DB_SYS_USER,
            password=DB_SYS_PWD,
            dsn=DB_DSN,
            mode=oracledb.SYSDBA
        )
        print("Connected.")
        
        cursor = conn.cursor()
        
        # 1. Check Status
        print("Checking DBA_DV_STATUS...")
        cursor.execute("SELECT * FROM DBA_DV_STATUS")
        columns = [col[0] for col in cursor.description]
        row = cursor.fetchone()
        if row:
            status = dict(zip(columns, row))
            print(f"Current DV Status: {status}")
        else:
            print("Could not get DV Status.")
            return

        is_configured = status.get('DV_CONFIGURE_STATUS') == 'TRUE'
        is_enabled = status.get('DV_ENABLE_STATUS') == 'TRUE'
        
        if not is_configured:
            print("\n--- Configuring Database Vault ---")
            
            # Create Users
            users = {
                "DV_OWNER": "DVOwner#123",
                "DV_ACCTMGR": "DVAcctMgr#123"
            }
            
            for user, pwd in users.items():
                cursor.execute(f"SELECT count(*) FROM all_users WHERE username = '{user}'")
                if cursor.fetchone()[0] == 0:
                    print(f"Creating user {user}...")
                    try:
                        cursor.execute(f'CREATE USER {user} IDENTIFIED BY "{pwd}"')
                        cursor.execute(f'GRANT CREATE SESSION TO {user}')
                        print(f"User {user} created.")
                    except Exception as e:
                        print(f"Error creating {user}: {e}")
                else:
                    print(f"User {user} already exists.")
            
            print("Running DVSYS.CONFIGURE_DV...")
            try:
                cursor.callproc("DVSYS.CONFIGURE_DV", keywordParameters={
                    "dvowner_uname": "DV_OWNER",
                    "dvacctmgr_uname": "DV_ACCTMGR"
                })
                print("DVSYS.CONFIGURE_DV completed.")
            except Exception as e:
                print(f"Error configuring DV: {e}")
                # Can be ORA-47502 generally
        
        # Enable DV
        print("\n--- Enabling Database Vault ---")
        try:
            cursor.callproc("DVSYS.DBMS_MACADM.ENABLE_DV")
            print("DVSYS.DBMS_MACADM.ENABLE_DV completed.")
            print("Database restart required.")
        except Exception as e:
            print(f"Error enabling DV: {e}")

        conn.close()
        
    except Exception as e:
        print(f"Fatal Error: {e}")

if __name__ == "__main__":
    check_and_fix_odv()
