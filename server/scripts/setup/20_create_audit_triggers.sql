ALTER SESSION SET CONTAINER = FREEPDB1;

-- Trigger để log INSERT vào user_info
CREATE OR REPLACE TRIGGER trg_audit_user_info_insert
AFTER INSERT ON library.user_info
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, new_values, performed_by
    ) VALUES (
        'INSERT', 'USER_INFO', :NEW.user_id,
        '{"oracle_username":"' || :NEW.oracle_username || '","user_type":"' || :NEW.user_type || '"}',
        USER
    );
END;
/

-- Trigger để log UPDATE vào user_info
CREATE OR REPLACE TRIGGER trg_audit_user_info_update
AFTER UPDATE ON library.user_info
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, old_values, new_values, performed_by
    ) VALUES (
        'UPDATE', 'USER_INFO', :NEW.user_id,
        '{"oracle_username":"' || :OLD.oracle_username || '","user_type":"' || :OLD.user_type || '"}',
        '{"oracle_username":"' || :NEW.oracle_username || '","user_type":"' || :NEW.user_type || '"}',
        USER
    );
END;
/

-- Trigger để log DELETE vào user_info
CREATE OR REPLACE TRIGGER trg_audit_user_info_delete
AFTER DELETE ON library.user_info
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, old_values, performed_by
    ) VALUES (
        'DELETE', 'USER_INFO', :OLD.user_id,
        '{"oracle_username":"' || :OLD.oracle_username || '","user_type":"' || :OLD.user_type || '"}',
        USER
    );
END;
/

-- Trigger để log INSERT vào books
CREATE OR REPLACE TRIGGER trg_audit_books_insert
AFTER INSERT ON library.books
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, new_values, performed_by
    ) VALUES (
        'INSERT', 'BOOKS', :NEW.book_id,
        '{"title":"' || :NEW.title || '","isbn":"' || :NEW.isbn || '"}',
        USER
    );
END;
/

-- Trigger để log UPDATE vào books
CREATE OR REPLACE TRIGGER trg_audit_books_update
AFTER UPDATE ON library.books
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, old_values, new_values, performed_by
    ) VALUES (
        'UPDATE', 'BOOKS', :NEW.book_id,
        '{"title":"' || :OLD.title || '"}',
        '{"title":"' || :NEW.title || '"}',
        USER
    );
END;
/

-- Trigger để log DELETE vào books
CREATE OR REPLACE TRIGGER trg_audit_books_delete
AFTER DELETE ON library.books
FOR EACH ROW
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, old_values, performed_by
    ) VALUES (
        'DELETE', 'BOOKS', :OLD.book_id,
        '{"title":"' || :OLD.title || '"}',
        USER
    );
END;
/

-- Insert một số dữ liệu mẫu vào audit log
INSERT INTO library.app_audit_log (action_type, table_name, performed_by, performed_at)
VALUES ('LOGIN', 'SYSTEM', 'ADMIN_USER', SYSDATE - 1);

INSERT INTO library.app_audit_log (action_type, table_name, performed_by, performed_at)
VALUES ('LOGIN', 'SYSTEM', 'LIBRARIAN_USER', SYSDATE - 0.5);

INSERT INTO library.app_audit_log (action_type, table_name, record_id, performed_by, performed_at)
VALUES ('INSERT', 'USER_INFO', 1, 'ADMIN_USER', SYSDATE - 2);

INSERT INTO library.app_audit_log (action_type, table_name, record_id, performed_by, performed_at)
VALUES ('UPDATE', 'BOOKS', 1, 'LIBRARIAN_USER', SYSDATE - 1.5);

COMMIT;

SELECT 'Audit triggers created and sample data inserted!' FROM DUAL;
EXIT;

