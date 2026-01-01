# Script tự động sửa lỗi Windows (CRLF) và chạy khởi tạo Database
Write-Host "dang ket noi vao container Oracle de sua loi..." -ForegroundColor Cyan

# Kiem tra container co chay khong
$container = docker ps -q -f name=oracle23ai
if (-not $container) {
    Write-Host "Loi: Container 'oracle23ai' chua chay. Hay chay 'docker compose up -d' truoc." -ForegroundColor Red
    exit
}

# 1. Cai thien quyen thuc thi (chmod +x)
Write-Host "1. Cap quyen thuc thi cho cac file scripts..."
docker exec oracle23ai bash -c "chmod +x /opt/oracle/scripts/startup/*.sh"

# 2. Sua loi CRLF (Windows line endings) bang sed
Write-Host "2. Chuyen doi dinh dang file tu Windows (CRLF) sang Linux (LF)..."
docker exec oracle23ai bash -c "find /opt/oracle/scripts -name '*.sh' -exec sed -i 's/\r$//' {} +"

# 3. Chay script khoi tao
Write-Host "3. Dang chay script khoi tao database (vui long doi)..." -ForegroundColor Yellow
docker exec oracle23ai bash -c "/opt/oracle/scripts/startup/00_init_all.sh"

if ($?) {
    Write-Host "XONG! Database da duoc khoi tao thanh cong." -ForegroundColor Green
} else {
    Write-Host "Co loi xay ra khi chay script." -ForegroundColor Red
}

Read-Host -Prompt "Nhan Enter de thoat"
