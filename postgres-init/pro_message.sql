

CREATE OR REPLACE FUNCTION fn_send_message(
    p_id_chat_sender INT, 
    p_content_media VARCHAR, 
    p_text_content VARCHAR, 
    p_id_user INT, 
    p_id_receiver INT, 
    p_key VARCHAR
) 
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE          
    v_id_chat_receiver INT;
    v_user_number VARCHAR; 
    v_id_contact INT;    
BEGIN
    BEGIN
        -- Obtener ID del chat inverso
        SELECT id_chat INTO v_id_chat_receiver 
        FROM chat 
        WHERE id_receiver = p_id_user AND id_sender = p_id_receiver;

        -- Obtener número de teléfono del usuario
        SELECT phone_number INTO v_user_number 
        FROM usr 
        WHERE id_user = p_id_user;

        -- Si no existe el chat inverso, crear contacto y chat
        IF v_id_chat_receiver IS NULL THEN
            -- Crear contacto si no existe
            IF NOT EXISTS (
                SELECT 1 FROM contact 
                WHERE id_user = p_id_receiver AND phone_number = v_user_number
            ) THEN
                INSERT INTO contact(id_user, contact_number)
                VALUES(p_id_receiver, v_user_number)
                RETURNING id_contact INTO v_id_contact;
            END IF;

            -- Obtener id_contact si no se obtuvo antes
            IF v_id_contact IS NULL THEN
                SELECT id_contact INTO v_id_contact
                FROM contact
                WHERE id_user = p_id_receiver AND phone_number = v_user_number
                LIMIT 1;
            END IF;

            -- Crear chat inverso
            INSERT INTO chat(id_sender, id_receiver, id_contact)
            VALUES(p_id_receiver, p_id_user, v_id_contact)
            RETURNING id_chat INTO v_id_chat_receiver;
        END IF;

        -- Insertar mensaje
        INSERT INTO message_chat(id_chat_sender, id_chat_receiver, media_content, text_message)
        VALUES(p_id_chat_sender, v_id_chat_receiver, p_content_media, pgp_sym_encrypt(p_text_content, p_key));
        RETURN 1;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error: %', SQLERRM;
            RETURN 0;
    END;
END;
$$;

CREATE TEMP TABLE chats(
    id_chat INT,
    id_sender INT, 
    id_reciver INT,
    id_contact INT
);

CREATE OR REPLACE PROCEDURE sp_load_chat(
    IN p_id_usr INT    
)
LANGUAGE plpgsql
AS $$
BEGIN 

    INSERT INTO chats
    SELECT id_chat, id_sender, id_reciver, id_contact    
    FROM chat c
    JOIN (
        SELECT mc.id_chat_receiver, MAX(mc.shipping_time) AS ultimo_mensaje
        FROM message_chat mc
        WHERE mc.shipping_time >= CURRENT_DATE - INTERVAL '5 days'
        GROUP BY mc.id_chat_receiver
    ) ult ON ult.id_chat_receiver = c.id_chat
    WHERE c.id_reciver = :p_id_usr
    ORDER BY ult.ultimo_mensaje DESC
    LIMIT 15;

END;
$$;


CREATE OR REPLACE PROCEDURE sp_load_message(
    IN p_id_chat INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO messages_temp(id_message, id_chat_sender, id_chat_receiver, shipping_date,
                              delivery_date, media_content, text_message, deleted, delivered, seen)
    SELECT id_message, id_chat_sender, id_chat_receiver, shipping_date,
           delivery_date, media_content, text_message, deleted, delivered, seen
    FROM message_chat
    WHERE (id_chat_sender = p_id_chat OR id_chat_receiver = p_id_chat)
      AND deleted = FALSE
    ORDER BY shipping_date DESC
    LIMIT 15;
END;
$$;

CREATE OR REPLACE FUNCTION fn_edit_message(
    p_id_message INT,
    p_new_text TEXT,
    p_key TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE message_chat
    SET text_message = pgp_sym_encrypt(p_new_text, p_key)
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_deleted_message(
    p_id_message INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE message_chat
    SET deleted = TRUE
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_mark_delivered(
    p_id_message INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE message_chat
    SET delivered = TRUE,
        delivery_date = CURRENT_TIMESTAMP
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_mark_seen(
    p_id_message INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE message_chat
    SET seen = TRUE
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_logs_message_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_action TEXT;
    v_details TEXT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.text_message IS DISTINCT FROM NEW.text_message THEN
            v_action := 'edited';
            v_details := 'The message content was updated.';
        ELSIF OLD.deleted = FALSE AND NEW.deleted = TRUE THEN
            v_action := 'deleted';
            v_details := 'The message was marked as deleted.';
        END IF;

        IF v_action IS NOT NULL THEN
            INSERT INTO logs_message(action, message_affected, date_log, details)
            VALUES (v_action, NEW.id_message, CURRENT_DATE, v_details);
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_logs_message_changes
AFTER UPDATE ON message_chat
FOR EACH ROW
EXECUTE FUNCTION fn_logs_message_trigger();

