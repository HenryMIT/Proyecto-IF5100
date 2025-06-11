
--Procedure Storage

-- Register user 
CREATE OR REPLACE FUNCTION fn_register_user(
    IN p_username varchar
    , IN p_phone_number varchar
    , IN p_email varchar
    , IN p_pass varchar
    , IN p_key varchar
    )
RETURNS INT
LANGUAGE plpgsql 
AS $$
BEGIN 
    BEGIN
    IF EXISTS (SELECT 1 FROM usr WHERE phone_number = p_phone_number 
    OR pgp_sym_decrypt(email, p_key) = p_email) THEN
        RAISE EXCEPTION 'This phone is already registered.';
        RETURN -1;
    END IF;   
	
    INSERT INTO usr(username, phone_number, email, pass) 
    values(
        p_username,
        p_phone_number,
        pgp_sym_encrypt(p_email, p_key),
        pgp_sym_encrypt(p_pass, p_key)
    )
    RETURN id_usr;
    EXCEPTION 
        WHEN OTHERS THEN              
        RAISE NOTICE 'Transaction canceled: %', SQLERRM;
        RETURN -1;
    END;
END;    
$$;


-- Read profile info
CREATE OR REPLACE PROCEDURE sp_read_profile(
    IN p_id_usr INT, 
    OUT msg INT
)
LANGUAGE plpgsql
AS $$
BEGIN

    SELECT id_usr, username, phone_number, profile_picture, profile_description
    FROM usr
    WHERE id_usr = p_id_usr;
    INSERT INTO usrV;

END;
$$;

-- Authorize function
CREATE OR REPLACE PROCEDURE sp_authorized_User(
    IN p_phone_number VARCHAR,
    IN p_pass VARCHAR,
    IN p_key VARCHAR,
    OUT msg INT
    )
LANGUAGE plpgsql
AS $$
BEGIN 
    IF NOT EXISTS (
        SELECT 1 
        FROM usr
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND pgp_sym_decrypt(pass, p_key) = p_pass AND deleted = false
    ) THEN
        msg:= -1;
    ELSE
        SELECT id_usr INTO msg 
        FROM usr
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number; 
    END IF;       
END;
$$;



-- Delete function
CREATE OR REPLACE PROCEDURE sp_deleted_user(
    IN p_id_usr INT, 
    IN p_pass VARCHAR,
    IN p_key VARCHAR,
    OUT msg INT
    ) 
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM usr 
        WHERE 
        id_usr = p_id_usr AND pgp_sym_decrypt(q_pass, p_key) = p_pass AND deleted = false
    ) THEN 
        msg:= 0;
    END IF;
    ELSE
        -- Update from deleted to true 
        UPDATE usr SET deleted = TRUE WHERE id_usr = p_id_usr;
        -- Update the fn_logs_register_client table
        UPDATE logs_register_client SET deletion_date = CURRENT_DATE WHERE id_usr = p_id_usr;
        msg:= 1;
END;
$$;



-- Reactive Function 
CREATE OR REPLACE PROCEDURE sp_reactive_User(
    IN p_phone_number VARCHAR,
    IN p_pass VARCHAR,
    IN p_key VARCHAR,
    OUT msg INT
    )
LANGUAGE plpgsql
AS $$
BEGIN 
    IF NOT EXISTS(
    SELECT 1
    FROM usr 
    WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND deleted = true
    ) THEN 
        msg:= -1;            
    ELSE 
        UPDATE usr SET deleted = false WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number;
        SELECT id_usr INTO msg FROM usr WHERE phone_number = p_phone_number;       
    END IF;
END;
$$;


-- sp update of usr
CREATE OR REPLACE PROCEDURE sp_update_user(
    IN p_id_usr INT,
    IN p_username VARCHAR,
    IN p_pass VARCHAR,    
    IN p_profile_picture VARCHAR,
    IN p_profile_description VARCHAR, 
    IN p_key VARCHAR,
    OUT msg INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usr WHERE id_usr = p_id_usr) THEN
        msg:=0;
    ELSE 
        UPDATE usr 
        SET 
        username = CASE 
        WHEN p_username IS NOT NULL AND p_username <> '' THEN p_username ELSE username
        END,        
        pass = CASE 
        WHEN p_pass IS NOT NULL AND p_pass <> '' THEN pgp_sym_encrypt(p_pass, p_key) ELSE pass
        END,        
        profile_picture = CASE 
        WHEN p_profile_picture IS NOT NULL AND p_profile_picture <> '' THEN p_profile_picture ELSE profile_picture
        END,
        profile_description CASE 
        WHEN p_profile_description IS NOT NULL AND p_profile_description <> '' THEN p_profile_description ELSE profile_description
        END
        WHERE id_usr = p_id_usr;
        msg:=1;
END;
$$;

-- Triggers funtion  

CREATE OR REPLACE FUNCTION fn_logs_register_client()
RETURNS Trigger AS $$
BEGIN 

    INSERT INTO logs_register_client(id_usr)
    VALUES(NEW.id_usr);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_log_usr
AFTER INSERT ON usr
FOR EACH ROW
EXECUTE FUNCTION fn_logs_register_client();

-- fn_update_photo:
CREATE OR REPLACE FUNCTION fn_update_logs()
RETURNS TRIGGER AS $$
DECLERE 
    var_action VARCHAR;
    var_detail VARCHAR; 
BEGIN 
    IF OLD.profile_description IS DISTINCT FROM NEW.profile_description THEN
        INSERT INTO var_action, var_detail VALUES("Profile description update.", OLD.profile_description)
    END IF;

    IF OLD.profile_picture IS DISTINCT FROM NEW.profile_picture THEN
        INSERT INTO var_action, var_detail VALUES("Profile picture update.", OLD.profile_description)
    END IF;

    IF OLD.username IS DISTINCT FROM NEW.username THEN
        INSERT INTO var_action, var_detail VALUES("Username update.", OLD.profile_description)
    END IF;

    IF OLD.phone_number IS DISTINCT FROM NEW.phone_number THEN
        INSERT INTO var_action, var_detail VALUES("Change of phone number.", OLD.profile_description)
    END IF;

    IF OLD.pass IS DISTINCT FROM NEW.pass THEN
        INSERT INTO var_action, var_detail VALUES("Password change.", "Pass encrypted.")
    END IF;  

    IF OLD.email IS DISTINCT FROM NEW.email THEN
        INSERT INTO var_action, var_detail VALUES("Change of email.", "Email encryted.")
    END IF;  

      INSERT INTO logs_client(action_log, user_affected, date_log, details) 
        VALUES (var_action, NEW.id_usr, CURENT_DATE, var_detail);    

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update
AFTER INSERT ON usr
FOR EACH ROW
EXECUTE FUNCTION fn_update();


-- Se le otorga permisos al usuario de utilizar las funciones y sp
GRANT EXECUTE ON FUNCTION fn_register_user(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_read_profile(VARCHAR, VARCHAR, INT) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_authorized_User(VARCHAR, VARCHAR, VARCHAR, INT) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_deleted_user(INT, VARCHAR, VARCHAR, INT) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_read_profile(VARCHAR, VARCHAR, INT) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_reactive_User(VARCHAR, VARCHAR, VARCHAR, INT) TO Clients;
GRANT EXECUTE ON PROCEDURE sp_update_user(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) TO Clients;
