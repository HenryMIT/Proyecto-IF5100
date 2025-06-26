use CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- función para registrar un nuevo usuario
CREATE PROCEDURE sp_register_user(
  IN p_username VARCHAR(255),
  IN p_phone_number VARCHAR(20),
  IN p_email VARCHAR(150),
  IN p_pass VARCHAR(64),
  IN p_key VARCHAR(255)
)
BEGIN
  DECLARE bin_email VARBINARY(150);
  DECLARE bin_pass VARBINARY(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT -2 AS result; -- error inesperado
  END;

  SET bin_pass = AES_ENCRYPT(p_pass, p_key);
  SET bin_email = AES_ENCRYPT(p_email, p_key);

  START TRANSACTION;

  IF EXISTS (
    SELECT 1 FROM usr WHERE phone_number = p_phone_number OR email = bin_email
  ) THEN
    ROLLBACK;
    SELECT -1 AS result; -- usuario ya existe
  ELSE
    INSERT INTO usr (username, phone_number, email, pass)
    VALUES (p_username, p_phone_number, bin_email, bin_pass);

    COMMIT;
    SELECT LAST_INSERT_ID() AS result; -- ID del usuario nuevo
  END IF;
END$$

-- Función para leer el perfil de un usuario
CREATE PROCEDURE sp_read_profile(
  IN p_id_user INT
)
BEGIN
  SELECT id_user, username, phone_number, profile_picture, profile_description
  FROM usr
  WHERE id_user = p_id_user AND deleted = FALSE;
END $$

-- Procedimiento para verificar si un usuario está autorizado
CREATE PROCEDURE sp_authorized_user(
  IN p_phone_number VARCHAR(20),
  IN p_pass VARCHAR(64),
  IN p_key VARCHAR(255)
)
BEGIN
   DECLARE v_id_user INT;
  DECLARE bin_pass VARBINARY(64);
  DECLARE bin_email VARBINARY(64);

  SET bin_pass = AES_ENCRYPT(p_pass, p_key);
  SET bin_email = AES_ENCRYPT(p_phone_number, p_key);

  -- Convertimos la contraseÃ±a a VARBINARY para comparar con la almacenada
  SELECT id_user INTO v_id_user
  FROM usr
  WHERE phone_number = p_phone_number OR email = p_phone_number
    AND pass = bin_pass
    AND deleted = FALSE
  LIMIT 1;

  -- Si no se encontrÃ³ el usuario, se retorna -1
  IF v_id_user IS NULL THEN
    SET v_id_user = -1;
  END IF;

  SELECT v_id_user AS id_user;
END $$


-- Procedimiento para eliminar un usuario
CREATE PROCEDURE sp_delete_user(
  IN p_id_user INT,
  IN p_pass VARCHAR(64),
  IN p_key VARCHAR(255)
)
BEGIN
  DECLARE bin_pass VARBINARY(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 0 AS status;
  END;

  SET bin_pass = AES_ENCRYPT(p_pass, p_key);

  START TRANSACTION;

  IF EXISTS (
    SELECT 1 FROM usr
    WHERE id_user = p_id_user AND pass = bin_pass AND deleted = FALSE
  ) THEN
      UPDATE usr
      SET deleted = TRUE
      WHERE id_user = p_id_user;

      COMMIT;
      SELECT 1 AS status;
  ELSE
      ROLLBACK;
      SELECT 0 AS status;
  END IF;
END$$


-- Procedimiento para activar un usuario
CREATE PROCEDURE sp_reactive_User(
  IN p_phone_number VARCHAR(50),
  IN p_pass VARCHAR(64),
  IN p_key VARCHAR(255)
)
BEGIN
  DECLARE bin_pass VARBINARY(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 0 AS status;
  END;

  SET bin_pass = AES_ENCRYPT(p_pass, p_key);

  START TRANSACTION;

  IF EXISTS (
    SELECT 1 FROM usr
    WHERE phone_number = p_phone_number AND pass = bin_pass AND deleted = TRUE
  ) THEN
      UPDATE usr
      SET deleted = FALSE
      WHERE phone_number = p_phone_number;

      COMMIT;
      SELECT 1 AS status;
  ELSE
      ROLLBACK;
      SELECT 0 AS status;
  END IF;
END$$


CREATE PROCEDURE sp_update_user(
  IN p_id_user INT,
  IN p_username VARCHAR(255),
  IN p_pass VARCHAR(64),
  IN p_phone_number VARCHAR(20),
  IN p_profile_picture VARCHAR(255),
  IN p_profile_description VARCHAR(255),  
  IN p_key VARCHAR(255)
)
BEGIN
  DECLARE bin_pass VARBINARY(64);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 0 AS status;
  END;

  SET bin_pass = AES_ENCRYPT(p_pass, p_key);

  START TRANSACTION;

  IF EXISTS (SELECT 1 FROM usr WHERE id_user = p_id_user AND deleted = FALSE) 
  THEN
    UPDATE usr
    SET
      username = CASE WHEN p_username IS NOT NULL THEN p_username ELSE username END,
      pass = CASE WHEN p_pass IS NOT NULL THEN bin_pass ELSE pass END,
      phone_number = CASE WHEN p_phone_number IS NOT NULL THEN p_phone_number ELSE phone_number END,
      profile_picture = CASE WHEN p_profile_picture IS NOT NULL THEN p_profile_picture ELSE profile_picture END,
      profile_description = CASE WHEN p_profile_description IS NOT NULL THEN p_profile_description ELSE profile_description END
    WHERE id_user = p_id_user;

    COMMIT;
    SELECT 1 AS status; 
  ELSE
    ROLLBACK;
    SELECT 0 AS status; 
  END IF;
END$$


CREATE PROCEDURE sp_verify_tokens(
    IN p_id_user INT,
    IN p_tkr VARCHAR(255)
)
BEGIN
    IF EXISTS ( SELECT 1 FROM usr WHERE id_user = p_id_user AND tkR = p_tkr ) THEN
        SELECT 1 AS result;
    ELSE
        SELECT 0 AS result;
    END IF;
END$$

CREATE PROCEDURE sp_update_tkr(
    IN p_id_user INT,
    IN p_tkr VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT -1 AS result; -- Error durante el update
    END;

    START TRANSACTION;

    UPDATE usr
    SET tkR = p_tkr
    WHERE id_user = p_id_user;

    COMMIT;
    SELECT 1 AS result; -- Éxito
END$$

CREATE TRIGGER trigger_logs_register_client AFTER UPDATE ON usr FOR EACH ROW
BEGIN
  -- Cambio en el número de teléfono
  IF OLD.phone_number <> NEW.phone_number THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Change of phone number.', NEW.id_user, CURDATE(), CONCAT('Old phone: ', OLD.phone_number));
  END IF;

  -- Cambio en la contraseña
  IF OLD.pass <> NEW.pass THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Password change.', NEW.id_user, CURDATE(), 'Password encrypted.');
  END IF;

  -- Cambio en el email
  IF OLD.email <> NEW.email THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Change of email.', NEW.id_user, CURDATE(), 'Email encrypted.');
  END IF;
END $$


CREATE TRIGGER trigger_update_logs AFTER UPDATE ON usr FOR EACH ROW
BEGIN
  -- Cambio en el nombre de usuario
  IF OLD.username <> NEW.username THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Username updated.', NEW.id_user, NOW(), CONCAT('Old username: ', OLD.username, ', New username: ', NEW.username));
  END IF;

  -- Cambio en la foto de perfil
  IF OLD.profile_picture <> NEW.profile_picture THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Profile picture updated.', NEW.id_user, NOW(), CONCAT('Old picture: ', OLD.profile_picture, ', New picture: ', NEW.profile_picture));
  END IF;

  -- Cambio en la descripción del perfil
  IF OLD.profile_description <> NEW.profile_description THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Profile description updated.', NEW.id_user, NOW(), CONCAT('Old description: ', OLD.profile_description, ', New description: ', NEW.profile_description));
  END IF;
END $$

DELIMITER ;