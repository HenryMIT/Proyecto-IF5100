
CREATE OR REPLACE FUNCTION fn_create_contact(
    p_id_user INT,
    p_contact_number VARCHAR,
    p_contact_name VARCHAR
) 
RETURNS INT 
LANGUAGE plpgsql
AS $$
BEGIN 
    IF EXISTS (SELECT 1 FROM contact WHERE id_user = p_id_user AND contact_number = p_contact_number AND deleted = FALSE) THEN
        RETURN 0;    
    ELSIF EXISTS (SELECT 1 FROM contact WHERE id_user = p_id_user AND contact_number = p_contact_number AND deleted = TRUE) THEN 
        UPDATE contact 
        SET deleted = FALSE, contact_name = p_contact_name
        WHERE contact_number = p_contact_number AND id_user = p_id_user;
        RETURN 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM usr WHERE phone_number = p_contact_number) THEN
        RETURN 0;
    END IF;

    IF EXISTS(SELECT 1 FROM contact WHERE contact_number = p_contact_number AND id_user = p_id_user) THEN 
        UPDATE contact 
        SET contact_name = p_contact_name 
        WHERE contact_number = p_contact_number AND id_user = p_id_user;
        RETURN 1;
    END IF;

    INSERT INTO contact(id_user, contact_number, contact_name) 
    VALUES(p_id_user, p_contact_number, p_contact_name);
    RETURN 1;
END;
$$
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_create_chat(
    p_id_user INT,
    p_id_contact INT    
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE          
    v_id_receiver INT;     
BEGIN 
    IF EXISTS(SELECT 1 FROM chat WHERE id_contact = p_id_contact) THEN
        RETURN 0;
    END IF; 

    SELECT u.id_user INTO v_id_receiver
    FROM contact AS c
    JOIN usr AS u ON u.phone_number = c.contact_number
    WHERE c.id_contact = p_id_contact;

    INSERT INTO chat(id_sender, id_receiver, id_contact) 
    VALUES(p_id_user, v_id_receiver, p_id_contact);
    RETURN 1;
END;
$$
SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_load_contact(
    p_lim INT,
    p_phone_contact VARCHAR,
    p_contact_name VARCHAR,
    p_id_user INT
)
RETURNS TABLE (
    id_contact INT,
    id_user INT,
    contact_number VARCHAR,
    contact_name VARCHAR,
    deleted BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF (p_phone_contact IS NULL OR p_phone_contact = '') AND (p_contact_name IS NULL OR p_contact_name = '') THEN
        RETURN QUERY
        SELECT c.id_contact, c.id_user, c.contact_number, c.contact_name, c.deleted
        FROM contact as c
        WHERE c.id_user = p_id_user
        LIMIT p_lim;
    ELSE
        RETURN QUERY
        SELECT c.id_contact, c.id_user, c.contact_number, c.contact_name, c.deleted
        FROM contact as c
        WHERE c.id_user = p_id_user 
        AND c.deleted = FALSE
        AND (
            (p_phone_contact IS NOT NULL AND c.contact_number ILIKE '%' || p_phone_contact || '%')
            OR (p_contact_name IS NOT NULL AND c.contact_name ILIKE '%' || p_contact_name || '%')
        )
        LIMIT p_lim;
    END IF;
END;
$$
SECURITY DEFINER;



CREATE OR REPLACE FUNCTION fn_update_contact(
    p_id_contact INT, 
    p_phone_contact VARCHAR, 
    p_contact_name VARCHAR    
)
RETURNS INT 
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM contact WHERE id_contact = p_id_contact) THEN
        RETURN 0;
    END IF;

    UPDATE contact 
    SET 
        contact_number = CASE 
            WHEN p_phone_contact IS NOT NULL AND p_phone_contact <> '' 
            THEN p_phone_contact 
            ELSE contact_number 
        END,
        contact_name = CASE 
            WHEN p_contact_name IS NOT NULL AND p_contact_name <> '' 
            THEN p_contact_name 
            ELSE contact_name 
        END
    WHERE id_contact = p_id_contact; 

    RETURN 1;
END;
$$
SECURITY DEFINER;


CREATE OR REPLACE FUNCTION fn_deleted_contact(
    p_id_contact INT 
)
RETURNS INT 
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM contact WHERE id_contact = p_id_contact AND deleted = FALSE) THEN
        RETURN 0;
    END IF;

    UPDATE contact SET deleted = TRUE WHERE id_contact = p_id_contact;
    RETURN 1;
END;
$$
SECURITY DEFINER;
