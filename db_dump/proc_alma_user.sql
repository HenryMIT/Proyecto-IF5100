use CR_Chat;
SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- Funciones para el manejo de usuarios en la base de datos CR_Chat
CREATE FUNCTION fn_register_user(
  p_username VARCHAR(255),
  p_email VARBINARY(150),
  p_phone_number VARCHAR(20),
  p_pass VARBINARY(64),
  p_key VARCHAR(255)
)
RETURNS INT
BEGIN
  DECLARE user_id INT;

  IF EXISTS (SELECT 1 FROM usr WHERE phone_number = p_phone_number OR email = p_email) THEN
    RETURN -1; -- Teléfono o email ya existe
  END IF;

  INSERT INTO usr (username, phone_number, email, pass, tkR)
  VALUES (p_username, p_phone_number, p_email, p_pass, p_key);

  SET user_id = LAST_INSERT_ID();

  RETURN user_id;
END $$


-- Función para leer el perfil de un usuario
CREATE PROCEDURE fn_read_profile(
  IN p_id_usr INT,
  IN p_pass VARBINARY(64)
)
BEGIN
  SELECT id_usr, username, phone_number, profile_picture, profile_description
  FROM usr
  WHERE id_usr = p_id_usr AND pass = p_pass AND deleted = FALSE;
END $$


-- Procedimiento para saber si un usuario está autorizado
CREATE PROCEDURE sp_authorized_user(
  IN p_phone_number VARCHAR(20),
  IN p_pass VARBINARY(64),
  IN p_key VARCHAR(255)
)
BEGIN
  DECLARE v_id_user INT;

  SELECT id_usr INTO v_id_user
  FROM usr
  WHERE phone_number = p_phone_number
    AND pass = p_pass
    AND tkr = p_key
    AND deleted = FALSE
  LIMIT 1;

  IF v_id_user IS NULL 
  THEN
    SET v_id_user = -1;
  END IF;

  SELECT v_id_user AS id_usr;
END $$

-- Procedimiento para eliminar un usuario
CREATE PROCEDURE sp_delete_user(
  IN p_id_usr INT,
  IN p_pass VARBINARY(64),
  IN p_key VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM usr
    WHERE id_usr = p_id_usr AND pass = p_pass AND tkr = p_key AND deleted = FALSE
  ) THEN
      -- Actualizar el estado del usuario a eliminado
      UPDATE usr
      SET deleted = TRUE
      WHERE id_usr = p_id_usr;

      SELECT 1 AS status;
  ELSE
      SELECT 0 AS status;
  END IF;
END $$


-- Procedimiento para activar un usuario
CREATE PROCEDURE sp_reactive_User(
  IN p_id_usr INT,
  IN p_pass VARBINARY(64),
  IN p_key VARCHAR(255)
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM usr
    WHERE id_usr = p_id_usr AND pass = p_pass AND tkr = p_key AND deleted = TRUE
  )
  THEN
      -- Actualizar el estado del usuario a no eliminado
      UPDATE usr
      SET deleted = FALSE
      WHERE id_usr = p_id_usr;

      SELECT 1 AS status;
  ELSE
      SELECT 0 AS status;
  END IF;
END $$


CREATE PROCEDURE sp_update_user(
  IN p_id_usr INT,
  IN p_username VARCHAR(255),
  IN p_pass VARBINARY(64),
  IN p_phone_number VARCHAR(20),
  IN p_profile_picture VARCHAR(255),
  IN p_profile_description VARCHAR(255)
)
BEGIN
  IF EXISTS (SELECT 1 FROM usr WHERE id_usr = p_id_usr AND deleted = FALSE) THEN
    UPDATE usr
    SET
      username = COALESCE(p_username, username),
      pass = COALESCE(p_pass, pass),
      phone_number = COALESCE(p_phone_number, phone_number),
      profile_picture = COALESCE(p_profile_picture, profile_picture),
      profile_description = COALESCE(p_profile_description, profile_description)
    WHERE id_usr = p_id_usr;

    SELECT 1 AS status; 
  ELSE
    SELECT 0 AS status; 
  END IF;
END $$


CREATE TRIGGER trigger_logs_register_client AFTER UPDATE ON usr FOR EACH ROW
BEGIN
  -- Cambio en el número de teléfono
  IF OLD.phone_number <> NEW.phone_number THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Change of phone number.', NEW.id_usr, CURDATE(), CONCAT('Old phone: ', OLD.phone_number));
  END IF;

  -- Cambio en la contraseña
  IF OLD.pass <> NEW.pass THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Password change.', NEW.id_usr, CURDATE(), 'Password encrypted.');
  END IF;

  -- Cambio en el email
  IF OLD.email <> NEW.email THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Change of email.', NEW.id_usr, CURDATE(), 'Email encrypted.');
  END IF;
END $$


CREATE TRIGGER trigger_update_logs AFTER UPDATE ON usr FOR EACH ROW
BEGIN
  -- Cambio en el nombre de usuario
  IF OLD.username <> NEW.username THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Username updated.', NEW.id_usr, NOW(), CONCAT('Old username: ', OLD.username, ', New username: ', NEW.username));
  END IF;

  -- Cambio en la foto de perfil
  IF OLD.profile_picture <> NEW.profile_picture THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Profile picture updated.', NEW.id_usr, NOW(), CONCAT('Old picture: ', OLD.profile_picture, ', New picture: ', NEW.profile_picture));
  END IF;

  -- Cambio en la descripción del perfil
  IF OLD.profile_description <> NEW.profile_description THEN
    INSERT INTO logs_client (action_log, user_affected, date_log, details)
    VALUES ('Profile description updated.', NEW.id_usr, NOW(), CONCAT('Old description: ', OLD.profile_description, ', New description: ', NEW.profile_description));
  END IF;
END $$

DELIMITER ;