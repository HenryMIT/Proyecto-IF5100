USE CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- FUNCIÓN PARA CREAR CONTACTO
CREATE PROCEDURE sp_create_contact(
    IN p_id_user INT,
    IN p_contact_number VARCHAR(20),
    IN p_contact_name VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT -1 AS result; -- Error inesperado
    END;

    START TRANSACTION;

    -- Contacto activo ya existe
    IF EXISTS (
        SELECT 1 FROM contact 
        WHERE id_user = p_id_user AND contact_number = p_contact_number AND deleted = FALSE
    ) THEN
        ROLLBACK;
        SELECT 0 AS result; -- Ya existe y está activo

    -- Contacto existe pero está eliminado
    ELSEIF EXISTS (
        SELECT 1 FROM contact 
        WHERE id_user = p_id_user AND contact_number = p_contact_number AND deleted = TRUE
    ) THEN
        UPDATE contact 
        SET deleted = FALSE, contact_name = p_contact_name
        WHERE contact_number = p_contact_number AND id_user = p_id_user;

        COMMIT;
        SELECT 1 AS result; -- Restaurado

    -- Número no está registrado como usuario
    ELSEIF NOT EXISTS (
        SELECT 1 FROM usr WHERE phone_number = p_contact_number
    ) THEN
        ROLLBACK;
        SELECT 0 AS result; -- Número no registrado

    -- Contacto existe (nombre necesita actualización)
    ELSEIF EXISTS (
        SELECT 1 FROM contact 
        WHERE contact_number = p_contact_number AND id_user = p_id_user
    ) THEN 
        UPDATE contact 
        SET contact_name = p_contact_name 
        WHERE contact_number = p_contact_number AND id_user = p_id_user;

        COMMIT;
        SELECT 1 AS result;

    -- Caso final: crear contacto nuevo
    ELSE
        INSERT INTO contact(id_user, contact_number, contact_name) 
        VALUES(p_id_user, p_contact_number, p_contact_name);

        COMMIT;
        SELECT 1 AS result;
    END IF;
END$$


-- FUNCIÓN PARA CREAR CHAT
CREATE PROCEDURE sp_create_chat(
    IN p_id_user INT,
    IN p_id_contact INT
)
BEGIN
    DECLARE v_id_receiver INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT -1 AS result; -- error inesperado
    END;

    START TRANSACTION;

    -- Validar si ya existe el chat con ese contacto
    IF EXISTS (
        SELECT 1 FROM chat WHERE id_contact = p_id_contact
    ) THEN
        ROLLBACK;
        SELECT 0 AS result; -- chat ya existe
    ELSE
        -- Obtener el id del receptor a partir del número del contacto
        SELECT u.id_user INTO v_id_receiver
        FROM contact AS c
        JOIN usr AS u ON u.phone_number = c.contact_number
        WHERE c.id_contact = p_id_contact
        LIMIT 1;

        -- Verificar si lo encontró
        IF v_id_receiver IS NULL THEN
            ROLLBACK;
            SELECT -2 AS result; -- receptor no encontrado
        ELSE
            -- Insertar chat
            INSERT INTO chat(id_sender, id_receiver, id_contact)
            VALUES(p_id_user, v_id_receiver, p_id_contact);

            COMMIT;
            SELECT 1 AS result; -- éxito
        END IF;
    END IF;
END$$


-- PROCEDIMIENTO PARA CARGAR CONTACTOS
CREATE PROCEDURE sp_load_contact(
    IN p_lim INT,
    IN p_pag INT,
    IN p_phone_contact VARCHAR(20),
    IN p_contact_name VARCHAR(100),
    IN p_id_user INT 
)
BEGIN    
        SELECT id_contact, id_user, contact_number, contact_name
        FROM contact
        WHERE deleted = FALSE AND id_user = p_id_user
          AND (
              (p_phone_contact IS NOT NULL AND contact_number LIKE CONCAT('%', p_phone_contact, '%'))
              AND
              (p_contact_name IS NOT NULL AND contact_name LIKE CONCAT('%', p_contact_name, '%'))
          )
        LIMIT p_pag, p_lim;    
END $$


-- PROCEDIMIENTO PARA ACTUALIZAR CONTACTO
CREATE PROCEDURE sp_update_contact(
    IN p_id_contact INT,
    IN p_phone_contact VARCHAR(20),
    IN p_contact_name VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 0 AS result;
    END;

    START TRANSACTION;

    IF EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        UPDATE contact
        SET
            contact_number = CASE WHEN p_phone_contact IS NOT NULL THEN p_phone_contact ELSE contact_number END,
            contact_name = CASE WHEN p_contact_name IS NOT NULL THEN p_contact_name ELSE contact_name END
        WHERE id_contact = p_id_contact;

        COMMIT;
        SELECT 1 AS result;
    ELSE
        ROLLBACK;
        SELECT 0 AS result;
    END IF;
END$$


-- PROCEDIMIENTO PARA ELIMINAR CONTACTO
CREATE PROCEDURE sp_deleted_contact(
    IN p_id_contact INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 0 AS result;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        ROLLBACK;
        SELECT 0 AS result;
    ELSE
        IF EXISTS (SELECT 1 FROM contact WHERE id_contact = p_id_contact AND deleted = TRUE) THEN
            ROLLBACK;
            SELECT 0 AS result;
        ELSE
            UPDATE contact
            SET deleted = TRUE
            WHERE id_contact = p_id_contact;
            
            COMMIT;
            SELECT 1 AS result;
        END IF;
    END IF;
END$$

DELIMITER ;
