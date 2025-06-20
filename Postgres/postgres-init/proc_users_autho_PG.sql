
-- Procedure Storage
CREATE OR REPLACE FUNCTION fn_register_user(
    IN p_username varchar,
    IN p_phone_number varchar,
    IN p_email varchar,
    IN p_pass varchar,
    IN p_key varchar
)
RETURNS INT
LANGUAGE plpgsql 
AS $$
DECLARE
    new_id INT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM usr 
        WHERE phone_number = p_phone_number 
        OR pgp_sym_decrypt(email, p_key) = p_email
    ) THEN
        RETURN -1;
    END IF;   

    INSERT INTO usr(username, phone_number, email, pass) 
    VALUES (
        p_username,
        p_phone_number,
        pgp_sym_encrypt(p_email, p_key),
        pgp_sym_encrypt(p_pass, p_key)
    )
    RETURNING id_user INTO new_id;

    RETURN new_id;

EXCEPTION 
    WHEN OTHERS THEN              
        RAISE NOTICE 'Transaction canceled: %', SQLERRM;
        RETURN -1;
END;
$$
SECURITY DEFINER;;


-- Read profile info
CREATE OR REPLACE FUNCTION fn_read_profile(
    p_id_user INT
    )
RETURNS TABLE (
    id_user INT,
    username VARCHAR,
    phone_number VARCHAR,
    profile_picture VARCHAR,
    profile_description VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id_user, u.username, u.phone_number, u.profile_picture, u.profile_description
    FROM usr as u
    WHERE u.id_user = p_id_user;
END;
$$
SECURITY DEFINER;


-- Authorize function
CREATE OR REPLACE FUNCTION fn_authorized_user(
    p_phone_number VARCHAR,
    p_pass VARCHAR,
    p_key VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    msg INT;
BEGIN 
    IF NOT EXISTS (
        SELECT 1 
        FROM usr
        WHERE (phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number)
        AND pgp_sym_decrypt(pass, p_key) = p_pass
        AND deleted = false
    ) THEN
        RETURN -1;
    ELSE
        SELECT id_user INTO msg 
        FROM usr
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number; 
        RETURN msg;
    END IF;
END;
$$
SECURITY DEFINER;

-- Delete function
CREATE OR REPLACE FUNCTION fn_deleted_user(
    p_id_user INT, 
    p_pass VARCHAR,
    p_key VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM usr 
        WHERE 
        id_user = p_id_user AND pgp_sym_decrypt(pass, p_key) = p_pass AND deleted = false
    ) THEN 
        RETURN 0;
    ELSE
        UPDATE usr SET deleted = TRUE WHERE id_user = p_id_user;
        UPDATE logs_register_client SET deletion_date = CURRENT_DATE WHERE id_user = p_id_user;
        RETURN 1;
    END IF;
END;
$$
SECURITY DEFINER;


-- Reactive Function 
CREATE OR REPLACE FUNCTION fn_reactive_user(
    p_phone_number VARCHAR,
    p_pass VARCHAR,
    p_key VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    msg INT;
BEGIN 
    IF NOT EXISTS (
        SELECT 1
        FROM usr 
        WHERE (phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number)
        AND deleted = true
    ) THEN 
        RETURN -1;            
    ELSE 
        UPDATE usr SET deleted = false 
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number;
        SELECT id_user INTO msg FROM usr WHERE phone_number = p_phone_number;       
        RETURN msg;
    END IF;
END;
$$
SECURITY DEFINER;


-- sp update of usr
CREATE OR REPLACE FUNCTION fn_update_user(
    p_id_user INT,
    p_username VARCHAR,
    p_pass VARCHAR,    
    p_profile_picture VARCHAR,
    p_profile_description VARCHAR, 
    p_key VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usr WHERE id_user = p_id_user) THEN
        RETURN 0;
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
        profile_description = CASE 
            WHEN p_profile_description IS NOT NULL AND p_profile_description <> '' THEN p_profile_description ELSE profile_description
        END
        WHERE id_user = p_id_user;
        RETURN 1;
    END IF;
END;
$$
SECURITY DEFINER;

-- Trigger Function: fn_logs_register_client
CREATE OR REPLACE FUNCTION fn_logs_register_client()
RETURNS TRIGGER AS $$
BEGIN 
    INSERT INTO logs_register_client(id_user)
    VALUES(NEW.id_user);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_usr
AFTER INSERT ON usr
FOR EACH ROW
EXECUTE FUNCTION fn_logs_register_client();

-- Trigger Function: fn_update_logs
CREATE OR REPLACE FUNCTION fn_update_logs()
RETURNS TRIGGER AS $$
DECLARE 
    var_action VARCHAR;
    var_detail VARCHAR; 
BEGIN 
    IF OLD.profile_description IS DISTINCT FROM NEW.profile_description THEN
        var_action := 'Profile description update.';
        var_detail := OLD.profile_description;
    ELSIF OLD.profile_picture IS DISTINCT FROM NEW.profile_picture THEN
        var_action := 'Profile picture update.';
        var_detail := OLD.profile_picture;
    ELSIF OLD.username IS DISTINCT FROM NEW.username THEN
        var_action := 'Username update.';
        var_detail := OLD.username;
    ELSIF OLD.phone_number IS DISTINCT FROM NEW.phone_number THEN
        var_action := 'Change of phone number.';
        var_detail := OLD.phone_number;
    ELSIF OLD.pass IS DISTINCT FROM NEW.pass THEN
        var_action := 'Password change.';
        var_detail := 'Pass encrypted.';
    ELSIF OLD.email IS DISTINCT FROM NEW.email THEN
        var_action := 'Change of email.';
        var_detail := 'Email encrypted.';
    END IF;

    IF var_action IS NOT NULL THEN
        INSERT INTO logs_client(action_log, user_affected, date_log, details) 
        VALUES (var_action, NEW.id_user, CURRENT_DATE, var_detail);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update
AFTER UPDATE ON usr
FOR EACH ROW
EXECUTE FUNCTION fn_update_logs();

-- Se le otorga permisos al usuario de utilizar las funciones y sp
GRANT EXECUTE ON FUNCTION fn_register_user(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO Clients;
GRANT EXECUTE ON FUNCTION fn_read_profile(INT) TO Clients;
GRANT EXECUTE ON FUNCTION fn_authorized_User(VARCHAR, VARCHAR, VARCHAR) TO Clients;
GRANT EXECUTE ON FUNCTION fn_deleted_user(INT, VARCHAR, VARCHAR) TO Clients;
GRANT EXECUTE ON FUNCTION fn_reactive_User(VARCHAR, VARCHAR, VARCHAR) TO Clients;
GRANT EXECUTE ON FUNCTION fn_update_user(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO Clients;
