# Báo cáo Kiểm thử Hệ thống Quản lý Thư viện

**Ngày kiểm thử:** 28/12/2025
**Người thực hiện:** Antigravity AI Agent
**Phiên bản:** 1.0.2 (Sau khi khắc phục lỗi Frontend)

## 1. Tổng quan
Đã thực hiện kiểm thử toàn trình (End-to-End Testing) các chức năng quản lý người dùng, sách, mượn trả và hệ thống profile Oracle.

## 2. Chi tiết Kết quả Kiểm thử

### 2.1. Frontend & Giao diện (Đã khắc phục lỗi)
- [x] **Hydration Mismatch**: Đã khắc phục lỗi crash trang tại `layout.tsx`.
- [x] **Missing State Variables**: Đã khôi phục đầy đủ logic cho trang Users, Books, Borrow, Profiles.
- [x] **Notifications**: Hệ thống Toast hoạt động tốt thay thế cho Alert cũ.

### 2.2. Chức năng Nghiệp vụ

| STT | Chức năng | Kết quả | Chi tiết |
| :-- | :--- | :---: | :--- |
| 1 | **Đăng nhập** | ✅ OK | Đăng nhập thành công với quyền Admin. |
| 2 | **Quản lý Sách** | ✅ OK | Thêm mới, cập nhật, xóa sách thành công. Tìm kiếm hoạt động tốt. |
| 3 | **Mượn/Trả Sách** | ✅ OK | Quy trình mượn sách và trả sách cập nhật đúng trạng thái kho. |
| 4 | **Quản lý Profiles**| ✅ OK | Tạo mới và xóa Profile Oracle thành công. |
| 5 | **Quản lý Users** | ⚠️ Warning | Giao diện hoạt động tốt. Tuy nhiên thao tác **Tạo User** bị từ chối bởi Database (`ORA-01031: insufficient privileges`). Cần cấp thêm quyền cho `admin_user` trong DB. |
| 6 | **Audit Log** | ⚠️ Warning | Trang load thành công nhưng không hiển thị dữ liệu log. |

## 3. Các vấn đề còn tồn tại (Backend/Environment)
Các vấn đề này thuộc về cấu hình Database Backend, không ảnh hưởng đến mã nguồn Frontend:
1.  **Lỗi ORA-01031**: User `admin_user` cần được cấp quyền `CREATE USER` và `UNLIMITED TABLESPACE` cụ thể hơn trong Oracle PDB.
2.  **Audit Trail**: Cần kiểm tra lại Policy Audit và quyền `SELECT` trên bảng `UNIFIED_AUDIT_TRAIL`.

## 4. Kết luận
Hệ thống Client đã sẵn sàng demo. Các chức năng chính (Sách, Mượn/Trả) hoạt động ổn định.
