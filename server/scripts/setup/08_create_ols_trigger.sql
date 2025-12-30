-- ============================================
-- SCRIPT 08: TRIGGER ĐỒNG BỘ OLS LABEL
-- Chạy với LBACSYS
-- ============================================

-- Kết nối PDB
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Trigger tự động gán OLS Label dựa trên cột sensitivity_level của bảng BOOKS
CREATE OR REPLACE TRIGGER library.trg_books_ols_sync
BEFORE INSERT OR UPDATE OF sensitivity_level ON library.books
FOR EACH ROW
BEGIN
    IF :NEW.sensitivity_level = 'PUBLIC' THEN
        :NEW.ols_label := CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB');
    ELSIF :NEW.sensitivity_level = 'INTERNAL' THEN
        :NEW.ols_label := CHAR_TO_LABEL('LIBRARY_POLICY', 'INT:LIB');
    ELSIF :NEW.sensitivity_level = 'CONFIDENTIAL' THEN
        :NEW.ols_label := CHAR_TO_LABEL('LIBRARY_POLICY', 'CONF:LIB');
    ELSIF :NEW.sensitivity_level = 'TOP_SECRET' THEN
        :NEW.ols_label := CHAR_TO_LABEL('LIBRARY_POLICY', 'TS:LIB,HR,FIN:HQ');
    ELSE
        -- Default to PUBLIC if unknown
        :NEW.ols_label := CHAR_TO_LABEL('LIBRARY_POLICY', 'PUB');
    END IF;
END;
/

-- Trigger tương tự cho bảng USER_INFO (nếu thay đổi sensitivity_level - dù cột này hiện tại ít dùng để set OLS cho user, thường set trực tiếp)
-- Nhưng để nhất quán, ta cũng có thể thêm. Tuy nhiên bảng user_info OLS chủ yếu set bằng thủ tục SA_USER_ADMIN.
-- Nên ta chỉ tập trung vào books.

COMMIT;
