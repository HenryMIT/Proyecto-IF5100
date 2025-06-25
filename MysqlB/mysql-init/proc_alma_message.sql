USE CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;


DELIMITER $$

-- PROCEDIMIENTO PARA ENVIAR MENSAJE

CREATE PROCEDURE sp_send_message(
    IN p_id_chat_sender INT, 
    IN p_content_media VARCHAR(255), 
    IN p_text_content VARCHAR(255), 
    IN p_id_user INT, 
    IN p_id_receiver INT, 
    IN p_key VARCHAR(255)
)
BEGIN
    DECLARE v_id_chat_receiver INT DEFAULT NULL;
    DECLARE v_user_number VARCHAR(50);
    DECLARE v_id_contact INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 0 AS status;
    END;

    START TRANSACTION;

    SELECT id_chat INTO v_id_chat_receiver
    FROM chat
    WHERE id_receiver = p_id_user AND id_sender = p_id_receiver
    LIMIT 1;

    SELECT phone_number INTO v_user_number
    FROM usr
    WHERE id_user = p_id_user
    LIMIT 1;

    IF v_id_chat_receiver IS NULL THEN

        IF NOT EXISTS (
            SELECT 1 FROM contact 
            WHERE id_user = p_id_receiver AND contact_number = v_user_number
        ) THEN
            INSERT INTO contact(id_user, contact_number)
            VALUES(p_id_receiver, v_user_number);

            SET v_id_contact = LAST_INSERT_ID();
        END IF;

        IF v_id_contact IS NULL THEN
            SELECT id_contact INTO v_id_contact
            FROM contact
            WHERE id_user = p_id_receiver AND contact_number = v_user_number
            LIMIT 1;
        END IF;

        INSERT INTO chat(id_sender, id_receiver, id_contact)
        VALUES(p_id_receiver, p_id_user, v_id_contact);

        SET v_id_chat_receiver = LAST_INSERT_ID();
    END IF;

    INSERT INTO message_chat(id_chat_sender, id_chat_receiver, media_content, text_message)
    VALUES(p_id_chat_sender, v_id_chat_receiver, p_content_media, AES_ENCRYPT(p_text_content, p_key));

    COMMIT;
    SELECT 1 AS status;
END$$

-- PROCEDIMIENTO PARA CARGAR CHATS
CREATE PROCEDURE sp_load_chat(
    IN p_id_user INT
)
BEGIN 
    SELECT 
        c.id_chat, 
        c.id_sender, 
        c.id_receiver, 
        c.id_contact
    FROM chat AS c
    WHERE c.id_sender = p_id_user
    ORDER BY (
        SELECT MAX(shipping_date) 
        FROM message_chat 
        WHERE id_chat_sender = c.id_chat OR id_chat_receiver = c.id_chat
    ) DESC
    LIMIT 15;
END $$


-- PROCEDIMIENTO PARA CARGAR MENSAJES
CREATE PROCEDURE sp_load_message(
    IN p_id_chat INT,
    IN p_key VARCHAR(50)
)
BEGIN
    SELECT id_message, id_chat_sender, id_chat_receiver, shipping_date, delivery_date, media_content, CAST(aes_decrypt(text_message, p_key)as character) as text, deleted, delivered, seen
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 0 AS status;
    END;

    START TRANSACTION;

    -- Encriptar el nuevo mensaje
    SET v_text_message = AES_ENCRYPT(p_new_text, p_key);

    -- Verificar que el mensaje no esté eliminado
    IF EXISTS (
        SELECT 1 FROM message_chat WHERE id_message = p_id_message AND deleted = FALSE
    ) THEN
        -- Actualizar mensaje
        UPDATE message_chat
        SET text_message = v_text_message
        WHERE id_message = p_id_message;

        COMMIT;
        SELECT 1 AS status;
    ELSE
        ROLLBACK;
        SELECT 0 AS status;
    END IF;
END$$

-- PROCEDIMIENTO PARA ELIMINAR MENSAJE
CREATE PROCEDURE sp_delete_message(
    IN p_id_message INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 0 AS status;
    END;

    START TRANSACTION;

    -- Verificar que el mensaje no esté ya eliminado
    IF EXISTS (
        SELECT 1 FROM message_chat WHERE id_message = p_id_message AND deleted = FALSE
    ) THEN
        -- Marcar como eliminado
        UPDATE message_chat
        SET deleted = TRUE
        WHERE id_message = p_id_message;

        COMMIT;
        SELECT 1 AS status;
    ELSE
        ROLLBACK;
        SELECT 0 AS status;
    END IF;
END$$

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
