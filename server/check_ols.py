
import oracledb
import os
from dotenv import load_dotenv

# Load env variables
load_dotenv(".env")

# Config from .env or hardcoded fallback
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "1521")
db_service = os.getenv("DB_SERVICE", "FREEPDB1") 
# User info for check - Using SYS to view everything
db_user = "sys"
db_password = "Oracle123"

dsn = f"{db_host}:{db_port}/{db_service}"

print(f"Connecting to {dsn} as {db_user}...")

try:
    # Init client if needed
    try:
        oracledb.init_oracle_client()
    except:
        pass

    conn = oracledb.connect(
        user=db_user,
        password=db_password,
        dsn=dsn,
        mode=oracledb.SYSDBA
    )
    print("✅ Connected successfully.")
    cursor = conn.cursor()
    
    # 1. CHECK PROXY CONFIG
    print("\n[1] CHECKING PROXY USERS (LIBRARY can proxy for?):")
    print("-" * 50)
    cursor.execute("SELECT CLIENT FROM PROXY_USERS WHERE PROXY = 'LIBRARY'")
    proxies = cursor.fetchall()
    if proxies:
        for row in proxies:
            print(f" - {row[0]}")
    else:
        print("❌ NO PROXY USERS FOUND! OLS will not work with connection pool.")

    # 2. CHECK USER OLS LABELS & PRIVS
    print("\n[2] CHECKING USER OLS LABELS & PRIVS:")
    print("-" * 50)
    cursor.execute("""
        SELECT USER_NAME, MAX_READ_LABEL, PRIVILEGES 
        FROM DBA_SA_USERS 
        WHERE USER_NAME IN ('LIBRARIAN_USER', 'STAFF_USER', 'ADMIN_USER', 'LIBRARY')
    """)
    for row in cursor:
        print(f"User: {row[0]}")
        print(f"  - Max Read Label: {row[1]}")
        print(f"  - Privileges: {row[2]}")
        if row[2] and 'READ' in row[2]:
            print("    ⚠️  WARNING: User has READ privilege (Bypass OLS)!")
            
    # 3. CHECK BOOK DATA LABELS
    print("\n[3] CHECKING BOOK DATA LABELS (Sample TOP_SECRET):")
    print("-" * 50)
    try:
        # Check if SA_UTL works or raw column
        cursor.execute("""
            SELECT sensitivity_level, 
                   lbacsys.sa_session.label_to_char('LIBRARY_POLICY', ols_label)
            FROM library.books 
            WHERE sensitivity_level IN ('TOP_SECRET', 'CONFIDENTIAL')
            FETCH FIRST 5 ROWS ONLY
        """)
        books = cursor.fetchall()
        for book in books:
            print(f"Book Level: {book[0]} | OLS Label: {book[1]}")
    except Exception as e:
        print(f"Error checking books: {e}")

    conn.close()

except Exception as e:
    print(f"❌ Error: {e}")
