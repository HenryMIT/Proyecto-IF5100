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
    DECLARE v_contact_id INT DEFAULT NULL;
    DECLARE v_deleted BOOLEAN DEFAULT FALSE;

    -- Asignar valor por defecto si p_contact_name es NULL
    IF p_contact_name IS NULL THEN
        SET p_contact_name = 'Unknown';
    END IF;

    -- Verificar si el contacto ya existe
    SELECT id_contact, deleted
    INTO v_contact_id, v_deleted
    FROM contact
    WHERE id_usr = p_id_usr AND contact_number = p_contact_number
    LIMIT 1;

    -- Si no existe
    IF v_contact_id IS NULL 
    THEN
        INSERT INTO contact (id_usr, contact_number, contact_name, deleted)
        VALUES (p_id_usr, p_contact_number, p_contact_name, FALSE);
        RETURN 1;

    -- Si existe pero está eliminado
    ELSEIF v_deleted = TRUE 
    THEN
        UPDATE contact
        SET contact_name = p_contact_name, deleted = FALSE
        WHERE id_contact = v_contact_id;
        RETURN 1;

    -- Ya existe y no está eliminado
    ELSE
        RETURN 0;
    END IF;
END $$


-- FUNCIÓN PARA CREAR CHAT
CREATE FUNCTION fn_create_chat(
    p_id_contact INT
)
RETURNS INT
BEGIN
    DECLARE v_contact_number VARCHAR(20);
    DECLARE v_id_usr_contact INT;
    DECLARE v_chat_id INT;

    -- Obtener el número de contacto
    SELECT contact_number INTO v_contact_number
    FROM contact
    WHERE id_contact = p_id_contact;

    IF v_contact_number IS NULL 
    THEN
        RETURN 0;
    END IF;

    -- Buscar el usuario con ese número
    SELECT id_usr INTO v_id_usr_contact
    FROM usr
    WHERE phone_number = v_contact_number;

    IF v_id_usr_contact IS NULL 
    THEN
        RETURN 0;
    END IF;

    -- Verificar si ya existe el chat
    SELECT id_chat INTO v_chat_id
    FROM chat
    WHERE id_contact = p_id_contact
    LIMIT 1;

    IF v_chat_id IS NOT NULL 
    THEN
        RETURN 0;
    END IF;

    -- Insertar el chat
    INSERT INTO chat (id_contact, id_sender)
    VALUES (p_id_contact, v_id_usr_contact);

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
    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact) 
    THEN
        SELECT 0 AS result;
    END IF;

    -- Actualizar campos
    UPDATE contact
    SET
        contact_number = CASE WHEN p_phone_contact IS NOT NULL THEN p_phone_contact ELSE contact_number END,
        contact_name = CASE WHEN p_contact_name IS NOT NULL THEN p_contact_name ELSE contact_name END
    WHERE id_contact = p_id_contact;

    SELECT 1 AS result;
END $$


-- PROCEDIMIENTO PARA ELIMINAR CONTACTO
CREATE PROCEDURE sp_deleted_contact(
    IN p_id_contact INT
)
BEGIN
    DECLARE v_deleted BOOLEAN;

    -- Obtener estado
    SELECT deleted INTO v_deleted
    FROM contact
    WHERE id_contact = p_id_contact;

    IF v_deleted IS NULL 
    THEN
        SELECT 0 AS result;
    ELSEIF v_deleted = TRUE 
    THEN
        SELECT 0 AS result;
    ELSE
        UPDATE contact
        SET deleted = TRUE
        WHERE id_contact = p_id_contact;
        SELECT 1 AS result;
    END IF;
END $$

DELIMITER ;
