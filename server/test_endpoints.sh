#!/bin/bash
echo "=== Testing Audit Endpoint ==="
curl -s -u admin_user:Admin123 "http://localhost:8000/api/audit?limit=5" | python3 -m json.tool

echo -e "\n=== Testing Create User ==="
curl -s -X POST -u admin_user:Admin123 \
  -H "Content-Type: application/json" \
  -d '{"username":"TEST_USER_XYZ","password":"Test1234","full_name":"Test User XYZ","user_type":"READER","branch_id":1}' \
  "http://localhost:8000/api/users" | python3 -m json.tool

echo -e "\n=== Testing Books (Librarian) ==="
curl -s -u librarian_user:Librarian123 "http://localhost:8000/api/books" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'Count: {len(data)}'); print(f'Branches: {set([b[\"branch_name\"] for b in data])}'); print(f'Levels: {set([b[\"sensitivity_level\"] for b in data])}')"

echo -e "\n=== Testing Books (Staff) ==="
curl -s -u staff_user:Staff123 "http://localhost:8000/api/books" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f'Count: {len(data)}'); print(f'Branches: {set([b[\"branch_name\"] for b in data])}'); print(f'Levels: {set([b[\"sensitivity_level\"] for b in data])}')"

