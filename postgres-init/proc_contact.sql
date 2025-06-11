
CREATE OR REPLACE FUNCTION fn_create_contact(
    p_id_usr INT,
    p_contact_number VARCHAR,
    p_contact_name VARCHAR
) 
RETURNS INT 
LANGUAGE plpgsql
AS $$
BEGIN 
    
    IF NOT EXISTS (SELECT 1 FROM contact WHERE id_usr = p_id_usr) THEN
        RETURN 0;
    ELSIF EXISTS (SELECT 1 FROM contact WHERE id_usr = p_id_usr AND deleted = TRUE) THEN 
        UPDATE contact SET deleted = FALSE, contact_number = p_contact_number, contact_name = p_contact_name
        WHERE contact_number = p_contact_number;
        RETURN 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM usr WHERE phone_number = p_contact_number) THEN
        RETURN 0;
    END IF;

    IF EXISTS( SELECT 1 FROM contact WHERE contact_number = p_contact_number) THEN 
        UPDATE contact SET contact_name = p_contact_name WHERE contact_number = p_contact_number AND id_usr = p_id_usr;
        RETURN 1;
    END IF;

    INSERT INTO contact(id_usr, contact_number, contact_name) VALUES(p_id_usr, p_contact_number, p_contact_name);
    RETURN 1;
END;
$$;

CREATE OR REPLACE FUNCTION fn_create_chat(
    p_id_usr INT,
    p_id_contact INT    
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE          
    v_id_receiver INT;     
BEGIN 

    IF NOT EXISTS(SELECT 1 FROM chat WHERE id_contact = p_id_contact) THEN
        RETURN 0;
    END IF; 

    SELECT c.id_usr, u.id_usr INTO p_id_usr, v_id_receiver
    FROM contact AS c
    JOIN usr AS u ON phone_number = c.contact_number WHERE id_contact = p_id_contact;

    INSERT INTO chat(id_sender, id_receiver, id_contact) VALUES(p_id_usr, v_id_receiver, p_id_contact);
    RETURN 1;
END;
$$;

CREATE TEMP TABLE contacts(
    id_contact INT,
    id_usr INT,
    contact_number VARCHAR(20),
    contact_name VARCHAR(100),
    deleted BOOLEAN
);

CREATE OR REPLACE PROCEDURE sp_load_contact(
    IN p_lim INT,    
    IN p_phone_contact VARCHAR,
    IN p_contact_name VARCHAR,
    IN p_id_usr INT
)
LANGUAGE plpgsql 
AS $$
BEGIN
    IF p_phone_contact IS NULL OR p_phone_contact = '' AND p_contact_name IS NULL OR p_contact_name = ''
    THEN         
        INSERT INTO contacts
        SELECT id_contact, id_usr, contact_number , contact_name, deleted
        FROM contact WHERE id_usr = p_id_usr LIMIT p_lim;
    ELSE   
        INSERT INTO contacts
        SELECT id_contact, id_usr, contact_number , contact_name, deleted
        FROM contact WHERE id_usr = p_id_usr 
        AND deleted = FALSE 
        AND ((p_phone_contact IS NOT NULL AND contact_number ILIKE '%' || p_phone_contact || '%') 
		OR (p_contact_name IS NOT NULL AND contact_name ILIKE '%' || p_contact_name || '%') )
        LIMIT p_lim;   
    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_update_contact(
    p_id_contact INT, 
    p_phone_contact VARCHAR, 
    p_contact_name VARCHAR    
)
RETURNS INT 
LANGUAGE plpgsql
$$
BEGIN
    
    IF NOT EXISTS(SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        RETURN 0;
    ELSE
        Update contact 
        SET 
        phone_contact = CASE 
                            WHEN p_phone_contact IS NOT NULL AND p_phone_number = '' 
                            THEN p_phone_contact
                            ELSE phone_contact,
        contact_name = CASE 
                            WHEN p_contact_name IS NOT NULL AND p_contact_name = '' 
                            THEN p_contact_name
                            ELSE contact_name
        WHERE id_contact = p_id_contact; 
        RETURN 1;
    END IF; 

END;
$$;


CREATE OR REPLACE FUNCTION fn_deleted_contact(
      p_id_contact INT 
)
RETURNS INT 
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM contact WHERE id_contact = p_id_contact AND deleted = FALSE) THEN
        RETURN 0;
    ELSE
        UPDATE contact SET deleted = TRUE WHERE id_contact = p_id_contact;
        RETURN 1;
    END IF;
END;
$$;

