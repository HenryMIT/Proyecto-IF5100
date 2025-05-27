use CR_Chat;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_register_user$$

CREATE PROCEDURE sp_register_user(
    IN p_username VARCHAR(255),
    IN p_phone_number VARCHAR(20),
    IN p_email VARBINARY(50),
    IN p_pass VARBINARY(20),
    IN p_key VARCHAR(255),

    OUT new_usr INT,
    OUT new_username VARCHAR(255),
    OUT new_phone_number VARCHAR(20),
    OUT new_profile_picture VARCHAR(255),
    OUT new_profile_description VARCHAR(255),
    OUT new_tkR VARCHAR(255)
)
BEGIN
    DECLARE _cant INT;

    SELECT COUNT(*) INTO _cant
    FROM usr
    WHERE phone_number = p_phone_number;

    IF _cant = 0 THEN
        INSERT INTO usr(username, phone_number, email, pass)
        VALUES (
            p_username,
            p_phone_number,
            AES_ENCRYPT(p_email, p_key),
            AES_ENCRYPT(p_pass, p_key)
        );

        SET new_usr = LAST_INSERT_ID();
        SET new_username = p_username;
        SET new_phone_number = p_phone_number;
        SET new_profile_picture = 'default';
        SET new_profile_description = 'Hey there, I am using CR_Chat';
        SET new_tkR = NULL;
    ELSE
        SET new_usr = 0;
        SET new_username = NULL;
        SET new_phone_number = NULL;
        SET new_profile_picture = NULL;
        SET new_profile_description = NULL;
        SET new_tkR = NULL;
    END IF;
END$$

CREATE TRIGGER trg_before_insert_logs_register_client
BEFORE INSERT ON logs_register_client
FOR EACH ROW
BEGIN
  IF NEW.creation_date IS NULL THEN
    SET NEW.creation_date = CURDATE();
  END IF;

  IF NEW.creation_time IS NULL THEN
    SET NEW.creation_time = CURTIME();
  END IF;

  IF NEW.last_session_date IS NULL THEN
    SET NEW.last_session_date = CURDATE();
  END IF;

  IF NEW.last_session_time IS NULL THEN
    SET NEW.last_session_time = CURTIME();
  END IF;

  IF NEW.user_db IS NULL OR NEW.user_db = '' THEN
    SET NEW.user_db = CURRENT_USER();
  END IF;
END$$ 

DELIMITER ;
