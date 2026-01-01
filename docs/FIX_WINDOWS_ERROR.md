# HƯỚNG DẪN SỬA LỖI $'\r': command not found TRÊN WINDOWS

Nếu bạn gặp lỗi sau khi chạy Docker trên Windows:
```
/opt/oracle/scripts/startup/00_init_all.sh: line 6: $'\r': command not found
...
sleep: invalid time interval '30\r'
...
/bin/bash^M: bad interpreter: No such file or directory
```

## NGUYÊN NHÂN
Do Windows sử dụng ký tự xuống dòng `CRLF` (\r\n), trong khi Linux (Docker) chỉ hiểu `LF` (\n). Khi file script bash (`.sh`) bị lưu sai định dạng này, nó sẽ không chạy được trong container.

## CÁCH KHẮC PHỤC THỦ CÔNG (NHANH NHẤT)

Làm theo các bước sau để sửa lỗi trực tiếp bên trong container:

### Bước 1: Truy cập vào terminal của container Oracle
Mở CMD hoặc PowerShell và chạy:
```bash
docker exec -it oracle23ai bash
```

### Bước 2: Chạy lệnh sửa lỗi tự động
Copy và paste toàn bộ dòng lệnh dưới đây vào terminal rồi nhấn Enter (lệnh này sẽ xóa các ký tự `\r` thừa):

```bash
find /opt/oracle/scripts -name "*.sh" -exec sed -i 's/\r$//' {} +
```

### Bước 3: Chạy script khởi tạo thủ công
Sau khi đã sửa lỗi, chạy lệnh sau để bắt đầu khởi tạo database:

```bash
bash /opt/oracle/scripts/startup/00_init_all.sh
```

---

## CÁCH KHẮC PHỤC TRIỆT ĐỂ (CHO LẦN SAU)

Để tránh lỗi này lặp lại khi xóa container đi chạy lại:

1. Trên Windows, mở PowerShell admin và chạy:
   ```bash
   git config --global core.autocrlf false
   ```

2. Xóa folder code cũ và Clone lại code mới về.

3. Hoặc nếu dùng VS Code:
   - Mở file `server/scripts/startup/00_init_all.sh`
   - Nhìn xuống góc dưới cùng bên phải cửa sổ VS Code
   - Bấm vào chữ **CRLF** và chọn **LF**
   - Lưu file lại (Ctrl+S)
   - Làm tương tự cho các file `.sh` khác.
