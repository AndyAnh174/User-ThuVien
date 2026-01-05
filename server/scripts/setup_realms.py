import oracledb
import sys
import time

# Connection details
DV_OWNER_USER = "sec_admin"
DV_OWNER_PWD = "SecAdmin123"
DB_DSN = "oracle-db:1521/FREEPDB1"

def setup_realms():
    print("STARTING SETUP REALMS...")
    try:
        print(f"Connecting to {DB_DSN} as {DV_OWNER_USER}...")
        conn = oracledb.connect(
            user=DV_OWNER_USER,
            password=DV_OWNER_PWD,
            dsn=DB_DSN
        )
        print("Connected.")
        cursor = conn.cursor()
        
        print("\n--- 1. Creating LIBRARY_REALM ---")
        cursor.execute("SELECT count(*) FROM DVSYS.DBA_DV_REALM WHERE NAME = 'LIBRARY_REALM'")
        cnt = cursor.fetchone()[0]
        print(f"Realm count: {cnt}")
        
        if cnt == 0:
            print("Creating realm...")
            # Using literals carefully
            cursor.execute("""
            BEGIN
                DVSYS.DBMS_MACADM.CREATE_REALM(
                    realm_name    => 'LIBRARY_REALM', 
                    description   => 'Protect Library Data', 
                    enabled       => 'Y', 
                    audit_options => 0, -- None for now
                    realm_type    => 0
                );
            END;
            """)
            print("LIBRARY_REALM created.")
        else:
            print("LIBRARY_REALM already exists.")

        print("\n--- 2. Adding Objects to Realm ---")
        try:
             cursor.execute("""
             BEGIN
                DVSYS.DBMS_MACADM.ADD_OBJECT_TO_REALM(
                    realm_name   => 'LIBRARY_REALM', 
                    object_owner => 'LIBRARY', 
                    object_name  => '%', 
                    object_type  => '%'
                );
             END;
             """)
             print("Objects added to realm.")
        except oracledb.DatabaseError as e:
             error, = e.args
             if error.code == 47605: 
                  print("Object already in realm.")
             else:
                  print(f"Add object result: {error.message}")

        print("\n--- 3. Authorizing Users ---")
        users = [
            ('LIBRARY', 0), 
            ('ADMIN_USER', 1), 
            ('LIBRARIAN_USER', 1),
            ('STAFF_USER', 1),
            ('READER_USER', 1)
        ]
        
        for user, auth_val in users:
            print(f"Authorizing {user}...")
            try:
                cursor.execute(f"""
                BEGIN
                    DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(
                        realm_name    => 'LIBRARY_REALM', 
                        grantee       => '{user}', 
                        rule_set_name => NULL, 
                        auth_options  => {auth_val}
                    );
                END;
                """)
                print(f"{user} authorized.")
            except oracledb.DatabaseError as e:
                # ORA-47610: Realm authorization already exists
                if 'ORA-47610' in str(e) or e.code == 47610:
                    print(f"{user} already authorized.")
                else:
                    print(f"Error authorizing {user}: {e}")

        print("\n--- 4. Creating Command Rules ---")
        rules = ['DROP TABLE', 'TRUNCATE TABLE']
        for cmd in rules:
            print(f"Creating rule for {cmd}...")
            try:
                cursor.execute(f"""
                BEGIN
                    DVSYS.DBMS_MACADM.CREATE_COMMAND_RULE(
                        command         => '{cmd}', 
                        rule_set_name   => 'Disabled', 
                        object_owner    => 'LIBRARY', 
                        object_name     => '%', 
                        enabled         => 'Y'
                    );
                END;
                """)
                print(f"Rule for {cmd} created.")
            except oracledb.DatabaseError as e:
                # ORA-47615: Command rule already exists
                if 'ORA-47615' in str(e) or e.code == 47615:
                     print(f"Rule for {cmd} already exists.")
                else:
                     print(f"Error creating rule {cmd}: {e}")

        conn.commit()
        print("\nRun setup_realms completed successfully.")
        conn.close()

    except Exception as e:
        print(f"\nFATAL ERROR: {e}")

if __name__ == "__main__":
    setup_realms()
