# 📖 Hướng Dẫn Sử Dụng Hệ Thống Thư Viện (Dành cho Người Mới)

Chào mừng bạn đến với Hệ Thống Quản Lý Thư Viện. Đây là tài liệu hướng dẫn từng bước để bạn có thể sử dụng thành thạo các chức năng của phần mềm.

---

## 🏁 1. Bắt đầu

### Trước khi sử dụng
Hãy chắc chắn rằng bạn (hoặc bộ phận kỹ thuật) đã bật hệ thống lên:
1.  **Database Oracle** đang chạy.
2.  **Server (Backend)** đang chạy (màn hình đen hiện chữ `Uvicorn running...`).
3.  **Website (Frontend)** đã mở tại địa chỉ `http://localhost:3000`.

### Đăng nhập
Khi vào trang web, bạn sẽ thấy màn hình Đăng nhập.
- **Tài khoản**: Nhập tên đăng nhập (Username).
- **Mật khẩu**: Nhập mật khẩu.
- Nhấn nút **"Đăng Nhập"**.

> **Mẹo**: Hệ thống phân quyền rất chặt chẽ. Nếu bạn đăng nhập bằng tài khoản "Độc giả", bạn sẽ thấy giao diện khác hẳn với "Thủ thư". Đừng lo lắng, đó là tính năng bảo mật!

---

## 📚 2. Các Chức Năng Chính

### A. Trang Chủ (Dashboard)
Sau khi đăng nhập, bạn sẽ thấy thanh menu bên tay trái (hoặc trên cùng).
- **Books**: Kho sách.
- **Borrow**: Mượn trả sách.
- **Users**: Quản lý người dùng.
- **Audit**: Nhật ký hệ thống (Chỉ Admin thấy).

---

### B. Quản Lý Sách (Dành cho Thủ thư)
Nơi bạn tìm kiếm và quản lý các cuốn sách trong thư viện.

1.  **Xem sách**:
    - Danh sách sách hiện ra ngay khi vào trang.
    - Bạn có thể **Tìm kiếm** bằng cách nhập tên sách vào ô trên cùng.
    - **Lưu ý**: Bạn chỉ nhìn thấy sách thuộc Chi nhánh của mình. (Ví dụ: Bạn làm ở Chi nhánh 1 thì không thấy sách Chi nhánh 2).

2.  **Thêm sách mới**:
    - Bấm nút **"Thêm Sách"** (Màu xanh, có dấu cộng).
    - Nhập thông tin: Tựa đề, Tác giả...
    - **Số lượng**: Tổng số sách nhập về.
    - Bấm **"Tạo Sách"**.

3.  **Xóa sách**:
    - Bấm vào biểu tượng thùng rác màu đỏ ở dòng sách muốn xóa.
    - *Lưu ý*: Nếu sách đang có người mượn, hệ thống sẽ báo lỗi và không cho xóa để bảo vệ dữ liệu.

---

### C. Mượn & Trả Sách (Dành cho Thủ thư)
Đây là nơi bạn làm việc nhiều nhất hàng ngày.

#### 1. Mượn Sách (Cho khách mượn)
- Bấm nút **"Tạo Phiếu Mượn"**.
- Một hộp thoại hiện ra:
    - **Chọn Độc giả**: Chọn người muốn mượn.
    - **Chọn Sách**: Chọn cuốn sách họ muốn (Chỉ hiện sách còn trong kho).
    - **Hạn trả**: Chọn ngày phải trả.
- Bấm **"Xác nhận Mượn"**.

#### 2. Trả Sách (Khách trả lại)
- Tìm tên độc giả hoặc cuốn sách trong danh sách.
- Bấm nút **"Trả sách"** (Màu cam/xanh).
- Hệ thống sẽ hỏi xác nhận và tính tiền phạt (nếu quá hạn).
- Bấm **"Hoàn tất"**.

---

### D. Quản Lý Độc Giả (Dành cho Admin/Thủ thư)
Nơi tạo tài khoản cho nhân viên mới hoặc độc giả mới.

1.  **Tạo người dùng mới**:
    - Bấm **"Thêm Người dùng"**.
    - **Username**: Tên đăng nhập (viết liền không dấu, ví dụ `tranvabc`).
    - **Thông tin cá nhân**: Họ tên, Email, SĐT, Địa chỉ, Phòng ban.
    - **Vai trò**:
        - `READER`: Độc giả (Chỉ xem được lịch sử mình).
        - `STAFF`: Nhân viên (Xem được info độc giả).
        - `LIBRARIAN`: Thủ thư (Quản lý sách).
    - **Chi nhánh**: Chọn nơi họ làm việc/sinh hoạt.
    - **Oracle Profile**: (Chỉ Admin mới thấy) Chọn hồ sơ bảo mật (Ví dụ `STUDENT_PROF` giới hạn thời gian login).

2.  **Sửa/Xóa**:
    - Bấm icon "Bút chì" để sửa tên/chi nhánh.
    - Bấm icon "Thùng rác" để xóa tài khoản.

> **Tính năng hay**: Nếu bạn là Nhân viên, khi xem danh sách này, bạn sẽ thấy Số điện thoại của khách hàng bị che đi (`09***`). Đây là tính năng bảo vệ quyền riêng tư!

---

### E. Xem Nhật Ký - Audit (Dành cho Admin)
Nơi "soi" xem ai đã làm gì trong hệ thống.

- Mỗi dòng là một hành động.
- **Màu đỏ**: Hành động thất bại (Ví dụ: Nhập sai mật khẩu, Cố tình xóa dữ liệu cấm).
- **Màu trắng**: Hành động bình thường.
- Bạn có thể biết chính xác: *Ai? Làm gì? Vào lúc mấy giờ?*

---

## ❓ Câu Hỏi Thường Gặp (Q&A)

**Q: Tại sao tôi không thấy nút "Xóa" sách?**
A: Có thể bạn đang đăng nhập với quyền "Nhân viên" hoặc "Độc giả". Chỉ "Thủ thư" hoặc "Admin" mới được xóa.

**Q: Tại sao tôi tạo độc giả xong nhưng họ không đăng nhập được?**
A: Hãy kiểm tra xem bạn đã viết đúng Username chưa (thường hệ thống tự viết hoa, ví dụ `NGUYENVANA`). Mật khẩu cũng phân biệt hoa thường.

**Q: Lỗi ORA-XXXX gì đó hiện lên là sao?**
A: Đó là thông báo từ "trái tim" Oracle Database. Ví dụ `ORA-01017` nghĩa là sai mật khẩu. Hệ thống sẽ cố gắng dịch sang tiếng Việt dễ hiểu cho bạn.

---

**Chúc bạn sử dụng hệ thống hiệu quả!**
