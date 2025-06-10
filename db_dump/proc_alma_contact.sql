USE CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- FUNCIÓN PARA CREAR CONTACTO
CREATE FUNCTION fn_create_contact(
    p_id_usr INT,
    p_contact_number VARCHAR(20),
    p_contact_name VARCHAR(100)
)
RETURNS INT
BEGIN
    DECLARE v_contact_name VARCHAR(100);

    -- Asignar valor por defecto si p_contact_name es NULL
    IF p_contact_name IS NULL THEN
        SET v_contact_name = 'Unknown';
    ELSE
        SET v_contact_name = p_contact_name;
    END IF;

    -- Si no existe contacto, insertar y devolver 1
    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_usr = p_id_usr AND contact_number = p_contact_number) 
    THEN
        INSERT INTO contact (id_usr, contact_number, contact_name, deleted)
        VALUES (p_id_usr, p_contact_number, v_contact_name, FALSE);
        
    IF EXISTS (SELECT 1 FROM contact WHERE id_usr = p_id_usr AND contact_number = p_contact_number AND deleted = TRUE) 
    THEN
        UPDATE contact
        SET contact_name = v_contact_name, deleted = FALSE
        WHERE id_usr = p_id_usr AND contact_number = p_contact_number;
        RETURN 1;
    END IF;
        UPDATE contact
        SET contact_name = v_contact_name, deleted = FALSE
        WHERE id_usr = p_id_usr AND contact_number = p_contact_number;
        RETURN 1;
    END IF;

    -- Si existe y no está eliminado, devolver 0
    RETURN 0;
END $$

-- FUNCIÓN PARA CREAR CHAT
CREATE FUNCTION fn_create_chat(
    p_id_contact_sender INT,
    p_id_contact_receiver INT
)
RETURNS INT
BEGIN
    DECLARE v_contact_number_sender VARCHAR(20);
    DECLARE v_contact_number_receiver VARCHAR(20);
    DECLARE id_user_sender INT;
    DECLARE id_user_receiver INT;

    -- Verificar si existen ambos contactos
    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact_sender) 
        OR NOT EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact_receiver) 
    THEN
        RETURN 0;
    END IF;

    -- Obtener el número y usuario dueño del contacto sender
    SELECT contact_number, id_usr
    INTO v_contact_number_sender, id_user_sender
    FROM contact
    WHERE id_contact = p_id_contact_sender;

    -- Obtener el número y usuario dueño del contacto receiver
    SELECT contact_number, id_usr
    INTO v_contact_number_receiver, id_user_receiver
    FROM contact
    WHERE id_contact = p_id_contact_receiver;

    -- Verificar si los datos son válidos
    IF v_contact_number_sender IS NULL OR id_user_sender IS NULL 
        OR v_contact_number_receiver IS NULL OR id_user_receiver IS NULL
    THEN
        RETURN 0;
    END IF;

    -- Verificar si ya existe el chat entre estos dos contactos
    IF EXISTS (
        SELECT 1 FROM chat 
        WHERE (id_sender = id_user_sender AND id_reciver = id_user_receiver)
           OR (id_sender = id_user_receiver AND id_reciver = id_user_sender)
    ) 
    THEN
        RETURN 0;
    END IF;

    -- Insertar el chat
    INSERT INTO chat (id_contact, id_sender, id_reciver)
    VALUES (p_id_contact_sender, id_user_sender, id_user_receiver);

    RETURN 1;
END $$


-- PROCEDIMIENTO PARA CARGAR CONTACTOS
CREATE PROCEDURE sp_load_contact(
    IN p_lim INT,
    IN p_pag INT,
    IN p_phone_contact VARCHAR(20),
    IN p_contact_name VARCHAR(100)
)
BEGIN
    IF p_phone_contact IS NULL AND p_contact_name IS NULL 
    THEN
        SELECT id_contact, contact_number, contact_name
        FROM contact
        WHERE deleted = FALSE
        LIMIT p_pag, p_lim;
    ELSE
        SELECT id_contact, contact_number, contact_name
        FROM contact
        WHERE deleted = FALSE
          AND (
              (p_phone_contact IS NOT NULL AND contact_number LIKE CONCAT('%', p_phone_contact, '%'))
              OR
              (p_contact_name IS NOT NULL AND contact_name LIKE CONCAT('%', p_contact_name, '%'))
          )
        LIMIT p_pag, p_lim;
    END IF;
END $$


-- PROCEDIMIENTO PARA ACTUALIZAR CONTACTO
CREATE PROCEDURE sp_update_contact(
    IN p_id_contact INT,
    IN p_phone_contact VARCHAR(20),
    IN p_contact_name VARCHAR(100)
)
BEGIN
    -- Verificar existencia
    IF EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        -- Actualizar campos
        UPDATE contact
        SET
            contact_number = CASE WHEN p_phone_contact IS NOT NULL THEN p_phone_contact ELSE contact_number END,
            contact_name = CASE WHEN p_contact_name IS NOT NULL THEN p_contact_name ELSE contact_name END
        WHERE id_contact = p_id_contact;

        SELECT 1 AS result;
    ELSE
        SELECT 0 AS result;
    END IF;
END $$


-- PROCEDIMIENTO PARA ELIMINAR CONTACTO
CREATE PROCEDURE sp_deleted_contact(
    IN p_id_contact INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        SELECT 0 AS result;
    ELSE
        IF EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact AND deleted = TRUE) THEN
            SELECT 0 AS result;
        ELSE
            UPDATE contact
            SET deleted = TRUE
            WHERE id_contact = p_id_contact;
            SELECT 1 AS result;
        END IF;
    END IF;
END $$

DELIMITER ;
