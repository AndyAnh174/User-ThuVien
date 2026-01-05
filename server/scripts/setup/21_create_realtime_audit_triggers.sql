ALTER SESSION SET CONTAINER = FREEPDB1;

-- Function để log vào app_audit_log
CREATE OR REPLACE FUNCTION library.log_audit(
    p_action_type VARCHAR2,
    p_table_name VARCHAR2,
    p_record_id NUMBER DEFAULT NULL,
    p_old_values CLOB DEFAULT NULL,
    p_new_values CLOB DEFAULT NULL
) RETURN NUMBER IS
    v_log_id NUMBER;
BEGIN
    INSERT INTO library.app_audit_log (
        action_type, table_name, record_id, old_values, new_values, performed_by, performed_at
    ) VALUES (
        p_action_type, p_table_name, p_record_id, p_old_values, p_new_values, USER, SYSTIMESTAMP
    ) RETURNING log_id INTO v_log_id;
    COMMIT;
    RETURN v_log_id;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error nhưng không fail transaction
        RETURN NULL;
END;
/

-- Trigger cho USER_INFO - INSERT
CREATE OR REPLACE TRIGGER library.trg_audit_user_info_insert
AFTER INSERT ON library.user_info
FOR EACH ROW
DECLARE
    v_new_values CLOB;
BEGIN
    v_new_values := '{\"user_id\":' || :NEW.user_id || 
                   ',\"oracle_username\":\"' || :NEW.oracle_username || 
                   '\",\"user_type\":\"' || :NEW.user_type || 
                   '\",\"branch_id\":' || NVL(TO_CHAR(:NEW.branch_id), 'null') || '}';
    library.log_audit('INSERT', 'USER_INFO', :NEW.user_id, NULL, v_new_values);
EXCEPTION
    WHEN OTHERS THEN NULL; -- Don't fail the insert
END;
/

-- Trigger cho USER_INFO - UPDATE
CREATE OR REPLACE TRIGGER library.trg_audit_user_info_update
AFTER UPDATE ON library.user_info
FOR EACH ROW
DECLARE
    v_old_values CLOB;
    v_new_values CLOB;
BEGIN
    IF :OLD.user_id != :NEW.user_id OR 
       :OLD.oracle_username != :NEW.oracle_username OR
       :OLD.user_type != :NEW.user_type OR
       NVL(:OLD.branch_id, -1) != NVL(:NEW.branch_id, -1) THEN
        v_old_values := '{\"user_id\":' || :OLD.user_id || 
                       ',\"oracle_username\":\"' || :OLD.oracle_username || 
                       '\",\"user_type\":\"' || :OLD.user_type || 
                       '\",\"branch_id\":' || NVL(TO_CHAR(:OLD.branch_id), 'null') || '}';
        v_new_values := '{\"user_id\":' || :NEW.user_id || 
                       ',\"oracle_username\":\"' || :NEW.oracle_username || 
                       '\",\"user_type\":\"' || :NEW.user_type || 
                       '\",\"branch_id\":' || NVL(TO_CHAR(:NEW.branch_id), 'null') || '}';
        library.log_audit('UPDATE', 'USER_INFO', :NEW.user_id, v_old_values, v_new_values);
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho USER_INFO - DELETE
CREATE OR REPLACE TRIGGER library.trg_audit_user_info_delete
AFTER DELETE ON library.user_info
FOR EACH ROW
DECLARE
    v_old_values CLOB;
BEGIN
    v_old_values := '{\"user_id\":' || :OLD.user_id || 
                   ',\"oracle_username\":\"' || :OLD.oracle_username || 
                   '\",\"user_type\":\"' || :OLD.user_type || 
                   '\",\"branch_id\":' || NVL(TO_CHAR(:OLD.branch_id), 'null') || '}';
    library.log_audit('DELETE', 'USER_INFO', :OLD.user_id, v_old_values, NULL);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho BOOKS - INSERT
CREATE OR REPLACE TRIGGER library.trg_audit_books_insert
AFTER INSERT ON library.books
FOR EACH ROW
DECLARE
    v_new_values CLOB;
BEGIN
    v_new_values := '{\"book_id\":' || :NEW.book_id || 
                   ',\"title\":\"' || :NEW.title || 
                   '\",\"isbn\":\"' || :NEW.isbn || 
                   '\",\"sensitivity_level\":\"' || :NEW.sensitivity_level || '\"}';
    library.log_audit('INSERT', 'BOOKS', :NEW.book_id, NULL, v_new_values);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho BOOKS - UPDATE
CREATE OR REPLACE TRIGGER library.trg_audit_books_update
AFTER UPDATE ON library.books
FOR EACH ROW
DECLARE
    v_old_values CLOB;
    v_new_values CLOB;
BEGIN
    IF :OLD.title != :NEW.title OR 
       :OLD.isbn != :NEW.isbn OR
       :OLD.sensitivity_level != :NEW.sensitivity_level OR
       :OLD.quantity != :NEW.quantity THEN
        v_old_values := '{\"book_id\":' || :OLD.book_id || 
                       ',\"title\":\"' || :OLD.title || 
                       '\",\"isbn\":\"' || :OLD.isbn || '\"}';
        v_new_values := '{\"book_id\":' || :NEW.book_id || 
                       ',\"title\":\"' || :NEW.title || 
                       '\",\"isbn\":\"' || :NEW.isbn || '\"}';
        library.log_audit('UPDATE', 'BOOKS', :NEW.book_id, v_old_values, v_new_values);
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho BOOKS - DELETE
CREATE OR REPLACE TRIGGER library.trg_audit_books_delete
AFTER DELETE ON library.books
FOR EACH ROW
DECLARE
    v_old_values CLOB;
BEGIN
    v_old_values := '{\"book_id\":' || :OLD.book_id || 
                   ',\"title\":\"' || :OLD.title || 
                   '\",\"isbn\":\"' || :OLD.isbn || '\"}';
    library.log_audit('DELETE', 'BOOKS', :OLD.book_id, v_old_values, NULL);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho BORROW_HISTORY - INSERT (mượn sách)
CREATE OR REPLACE TRIGGER library.trg_audit_borrow_insert
AFTER INSERT ON library.borrow_history
FOR EACH ROW
DECLARE
    v_new_values CLOB;
BEGIN
    v_new_values := '{\"borrow_id\":' || :NEW.borrow_id || 
                   ',\"user_id\":' || :NEW.user_id || 
                   ',\"book_id\":' || :NEW.book_id || 
                   ',\"status\":\"' || :NEW.status || '\"}';
    library.log_audit('BORROW', 'BORROW_HISTORY', :NEW.borrow_id, NULL, v_new_values);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Trigger cho BORROW_HISTORY - UPDATE (trả sách)
CREATE OR REPLACE TRIGGER library.trg_audit_borrow_update
AFTER UPDATE ON library.borrow_history
FOR EACH ROW
DECLARE
    v_new_values CLOB;
BEGIN
    IF :OLD.status != :NEW.status THEN
        v_new_values := '{\"borrow_id\":' || :NEW.borrow_id || 
                       ',\"status\":\"' || :NEW.status || 
                       '\",\"return_date\":\"' || TO_CHAR(:NEW.return_date, 'YYYY-MM-DD') || '\"}';
        library.log_audit('RETURN', 'BORROW_HISTORY', :NEW.borrow_id, NULL, v_new_values);
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

COMMIT;
SELECT 'Realtime audit triggers created successfully!' FROM DUAL;
EXIT;

