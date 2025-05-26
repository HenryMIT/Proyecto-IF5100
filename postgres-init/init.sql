-- Database: CR_Chat

-- DROP DATABASE IF EXISTS "CR_Chat";

CREATE USER Clients WITH PASSWORD 'client2025';

-- Tabla usr
CREATE TABLE usr (
    id_usr SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email BYTEA UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pass BYTEA NOT NULL, -- Encrypted
    profile_picture VARCHAR(255) DEFAULT 'default',
    profile_description VARCHAR(255) DEFAULT 'Hey there, I am using CR_Chat',
    deleted BOOLEAN DEFAULT FALSE,
    tkR varchar(255)
);

-- Tabla contact
CREATE TABLE contact (
    id_usr INT NOT NULL,
    id_contact INT NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100),
    PRIMARY KEY (id_usr, id_contact),
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr),
    FOREIGN KEY (id_contact) REFERENCES usr(id_usr)
);

-- Tabla message
CREATE TABLE message_chat (
    id_message SERIAL PRIMARY KEY,
    id_usr_sender int NOT NULL,
    id_usr_receiver int NOT NULL,
    shipping_date DATE,
    shipping_time TIMESTAMP,
    delivery_date DATE,
    delivery_time TIMESTAMP,
    media_content VARCHAR(255),
    text_message BYTEA not null, -- encrypted 
    deleted BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN,
    seen BOOLEAN,
    FOREIGN KEY (id_usr_sender) REFERENCES usr(id_usr),
    FOREIGN KEY (id_usr_receiver) REFERENCES usr(id_usr)
);

-- Tabla logs_register_client
CREATE TABLE logs_register_client (
    id_record SERIAL PRIMARY KEY,
    id_usr INT NOT NULL,
    user_db varchar(100) DEFAULT CURRENT_USER, 
    creation_date DATE DEFAULT CURRENT_DATE,
    creation_time TIME DEFAULT CURRENT_TIME,
    last_session_date DATE DEFAULT CURRENT_DATE,
    last_session_time TIME DEFAULT CURRENT_TIME,
    phone_number_change_date DATE,
    deletion_date DATE,
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr)
);

-- Tabla logs_client
CREATE TABLE logs_client (
    id_log BIGSERIAL PRIMARY KEY,
    action_log VARCHAR(100),
    user_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (user_affected) REFERENCES usr(id_usr)
);

-- Tabla logs_message
CREATE TABLE logs_message (
    id_log BIGSERIAL PRIMARY KEY,
    action VARCHAR(100),
    message_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (message_affected) REFERENCES message_chat(id_message)
);

-- User client 


CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Stored Procedures

-- SP when users register


-- Funtion login and register
CREATE OR REPLACE FUNCTION fn_register_user(
    IN p_username varchar
    , IN p_phone_number varchar
    , IN p_email varchar
    , IN p_pass varchar
    , IN p_key varchar
    )
RETURNS TABLE(
    new_usr INT,
    new_username VARCHAR,
    new_phone_number VARCHAR,
    new_profile_picture VARCHAR,
    new_profile_description VARCHAR,
    new_tkR VARCHAR
)
LANGUAGE plpgsql 
AS $$
BEGIN 
    -- Insert new user 
    INSERT INTO usr(username, phone_number, email, pass) 
    values(
        p_username,
        p_phone_number,
        pgp_sym_encrypt(p_email, p_key),
        pgp_sym_encrypt(p_pass, p_key)
    )
    RETURNING id_usr, username, phone_number, 'default', 'Hey there, I am using CR_Chat', null     
    INTO new_usr, new_username, new_phone_number, new_profile_picture, new_profile_description, new_tkr;
    
    RETURN NEXT;

END;    
$$
SECURITY DEFINER;


-- Authorize function
CREATE OR REPLACE FUNCTION fn_authorized_User(
    IN p_phone_number VARCHAR,
    IN p_pass VARCHAR,
    IN p_key VARCHAR
    )
RETURNS TABLE(
    status_t VARCHAR, 
    new_usr INT,
    new_username VARCHAR,
    new_phone_number VARCHAR,
    new_profile_picture VARCHAR,
    new_profile_description VARCHAR,
    new_tkR VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN 

 IF NOT EXISTS (
        SELECT 1 FROM usr
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND deleted = false
    ) THEN
        RETURN QUERY
        SELECT 'Unregistered Number or Email'::VARCHAR as status_query, NULL, NULL, NULL, NULL, NULL, NULL;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM usr
        WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND pgp_sym_decrypt(pass, p_key) = p_pass AND deleted = false
    ) THEN
        RETURN QUERY
        SELECT 'Incorrect password'::VARCHAR as status_query, NULL, NULL, NULL, NULL, NULL, NULL;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        'OK'::VARCHAR as status_query,
        id_usr,
        username,
        phone_number,
        profile_picture,
        profile_description,
        tkR 
    FROM usr
    WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND pgp_sym_decrypt(pass, p_key) = p_pass AND deleted = false;

END;
$$
SECURITY DEFINER;


-- Delete function
CREATE OR REPLACE FUNCTION fn_Deleted_user(
    IN p_id_usr INT, 
    IN p_pass VARCHAR,
    IN p_key VARCHAR
    ) 
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE 
    q_pass BYTEA;
BEGIN

    IF (SELECT COUNT(*) FROM usr WHERE id_usr = p_id_usr) > 0 THEN 
    RETURN 'User not found.';
    END IF;

    SELECT pass INTO q_pass FROM usr WHERE id_usr = p_id_usr; 
    
    IF pgp_sym_decrypt(q_pass, p_key) <> p_pass THEN
     RETURN 'Incorrect password.';
    END IF; 

    -- Update from deleted to true 
    UPDATE usr SET deleted = TRUE WHERE id_usr = p_id_usr;
    -- Update the fn_logs_register_client table
    UPDATE logs_register_client SET deletion_date = CURRENT_DATE WHERE id_usr = p_id_usr;

    RETURN 'User successfully deleted';
END;
$$
SECURITY DEFINER;


-- Reactive Function 
CREATE OR REPLACE FUNCTION fn_reactive_User(
    IN p_phone_number VARCHAR,
    IN p_pass VARCHAR,
    IN p_key VARCHAR
    )
RETURNS TABLE(
    message_response VARCHAR, 
    new_usr INT,
    new_username VARCHAR,
    new_phone_number VARCHAR,
    new_profile_picture VARCHAR,
    new_profile_description VARCHAR,
    new_tkR VARCHAR
    )
LANGUAGE plpgsql
AS $$
DECLARE
    q_id_usr INT;
    q_pass VARCHAR;
    q_deleted BOOLEAN;
BEGIN 

    SELECT id_usr, pgp_sym_decrypt(pass, p_key) as pass_d, deleted INTO q_id_usr, q_pass, q_deleted
    FROM usr 
    WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number AND deleted = true;
    
    
    IF q_id_usr = null
     THEN
    RETURN QUERY
        SELECT 'User not found.'::VARCHAR as message_response, null::INT, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR;
    RETURN;
    END IF;

    IF q_deleted = false THEN
    RETURN QUERY
        SELECT 'The User is still active.'::VARCHAR as message_response, null::INT, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR;
    RETURN;
    END IF;

    IF q_pass <> p_pass THEN
    RETURN QUERY
        SELECT 'Incorrect password.'::VARCHAR as message_response,  null::INT, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR, null::VARCHAR;
    RETURN;
    END IF;

    UPDATE usr SET deleted = false WHERE phone_number = p_phone_number OR pgp_sym_decrypt(email, p_key) = p_phone_number;

    RETURN QUERY
    SELECT 
        'User successfully reactivated'::VARCHAR as message_response,
        id_usr,
        username,
        phone_number,
        profile_picture,
        profile_description,
        tkR     
    FROM usr WHERE id_usr = q_id_usr;

END;
$$
SECURITY DEFINER;    


-- CREATE OR REPLACE FUNCTION fn_create_contact(
--     IN p_id_usr INT,
--     IN p_number_contact VARCHAR,
--     IN p_contact_name VARCHAR
--     )
-- DECLARE
--     q_id_contact INT;
--     q_contact_number VARCHAR;
--     q_contact_name VARCHAR;
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN 

--     IF NOT 
    

-- END;
-- $$
-- SECURITY DEFINER;

--  


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

    -- Data sensitive
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



--GRANT CONNECT ON DATABASE CR_Chat TO Clients;
GRANT EXECUTE ON FUNCTION fn_register_user(varchar,varchar,varchar,varchar) TO Clients;


