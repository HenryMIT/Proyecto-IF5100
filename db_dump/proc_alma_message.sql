USE CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;


DELIMITER $$

-- PROCEDIMIENTO PARA ENVIAR MENSAJE
CREATE PROCEDURE sp_send_message(
    IN p_id_contact_sender INT,
    IN p_media_content VARCHAR(255),
    IN p_text_content TEXT,
    IN p_id_user INT,
    IN p_id_receiver INT,
    IN p_key VARCHAR(255)
)
BEGIN
    DECLARE id_chat_receiver INT;
    DECLARE v_text_message_BLOB BLOB;

     SET v_text_message_BLOB = AES_ENCRYPT(p_text_content, p_key);
   
   -- Buscar chat entre usuarios
    SELECT id_chat INTO id_chat_receiver
    FROM chat
    WHERE 
        (id_sender = p_id_user AND id_reciver = p_id_receiver)
        OR
        (id_sender = p_id_receiver AND id_reciver = p_id_user)
    LIMIT 1;

    IF id_chat_receiver IS NULL THEN
        SELECT 0 AS status; 
    ELSE
        INSERT INTO message_chat (
            media_content, 
            text_message, 
            id_chat_sender, 
            id_chat_receiver, 
            shipping_date, 
            shipping_time, 
            deleted, 
            delivered, 
            seen
        )
        VALUES (
            p_media_content, 
            v_text_message_BLOB, 
            p_id_contact_sender, 
            id_chat_receiver, 
            CURDATE(), 
            NOW(), 
            FALSE, 
            FALSE, 
            FALSE
        );

        SELECT 1 AS status;
    END IF;
END $$

-- PROCEDIMIENTO PARA CARGAR CHATS
CREATE PROCEDURE sp_load_chat(
    IN p_id_usr INT
)
BEGIN 
    SELECT 
        c.id_chat, 
        c.id_sender, 
        c.id_receiver, 
        c.id_contact
    FROM chat AS c
    WHERE c.id_sender = p_id_usr
    ORDER BY (
        SELECT MAX(shipping_date) 
        FROM message_chat 
        WHERE id_chat_sender = c.id_chat OR id_chat_receiver = c.id_chat
    ) DESC
    LIMIT 15;
END $$


-- PROCEDIMIENTO PARA CARGAR MENSAJES
CREATE PROCEDURE sp_load_message(
    IN p_id_chat INT
)
BEGIN
    SELECT *
    FROM message_chat
    WHERE (id_chat_sender = p_id_chat OR id_chat_receiver = p_id_chat)
      AND deleted = FALSE
    ORDER BY shipping_date DESC
    LIMIT 15;
END $$


-- PROCEDIMIENTO PARA EDITAR MENSAJE
CREATE PROCEDURE sp_edit_message(
    IN p_id_message INT,
    IN p_new_text TEXT,
    IN p_key VARCHAR(255)
)
BEGIN
    DECLARE v_text_message BLOB;
    
    SET v_text_message = AES_ENCRYPT(p_new_text, p_key);

    IF EXISTS (
        SELECT 1
        FROM message_chat
        WHERE id_message = p_id_message AND deleted = FALSE
    ) THEN
        UPDATE message_chat
        SET text_message = v_text_message
        WHERE id_message = p_id_message;

        SELECT 1 AS status;
    ELSE
        SELECT 0 AS status;
    END IF;
END $$

-- PROCEDIMIENTO PARA ELIMINAR MENSAJE
CREATE PROCEDURE sp_delete_message(
    IN p_id_message INT
)
BEGIN
    IF EXISTS (SELECT 1 FROM message_chat WHERE id_message = p_id_message AND deleted = FALSE) THEN
        UPDATE message_chat
        SET deleted = TRUE
        WHERE id_message = p_id_message;

        SELECT 1 AS status;
    ELSE
        SELECT 0 AS status;
    END IF;
END $$


-- TRIGGER PARA LOGS DE MENSAJES
CREATE TRIGGER fn_logs_message 
AFTER UPDATE ON message_chat 
FOR EACH ROW
BEGIN
    DECLARE v_details TEXT;

    IF OLD.text_message <> NEW.text_message THEN
        SET v_details = CONCAT('Mensaje #', NEW.id_message, ' editado');
        INSERT INTO logs_message (action, message_affected, date_log, details)
        VALUES ('edit', NEW.id_message, NOW(), v_details);
    END IF;

    IF OLD.deleted = FALSE AND NEW.deleted = TRUE THEN
        SET v_details = 'Mensaje eliminado';
        INSERT INTO logs_message (action, message_affected, date_log, details)
        VALUES ('delete', NEW.id_message, NOW(), v_details);
    END IF;
END $$

DELIMITER ;
