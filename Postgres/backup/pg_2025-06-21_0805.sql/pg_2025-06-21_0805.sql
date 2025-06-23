--
-- PostgreSQL database cluster dump
--

-- Started on 2025-06-21 02:09:16

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:Ul5Jg4jhSe4+frSSpLh/vQ==$uR/g7mJLeZlusAdOWz4rPdCJrDt+ik4UoJveEu1H1AE=:ihGAQsSvgHRRwPyFCX2BhdDAmMzLB7FVtymb1JUcaAU=';
CREATE ROLE clients;
ALTER ROLE clients WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:ThV+ctwLKD3LE9hTHmXfAg==$wmvvqOAVKqeOzw2UNiSJBNAPwhdIyg6ShcQHtwe7dKA=:I7LOevDJdH9Zt0RVFqyH3n0MCXOYIuJRfev2q11++40=';

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-21 02:09:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2025-06-21 02:09:17

--
-- PostgreSQL database dump complete
--

--
-- Database "CR_Chat" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-21 02:09:17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3513 (class 1262 OID 16384)
-- Name: CR_Chat; Type: DATABASE; Schema: -; Owner: admin
--

CREATE DATABASE "CR_Chat" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE "CR_Chat" OWNER TO admin;

\connect "CR_Chat"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16504)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 290 (class 1255 OID 16548)
-- Name: fn_authorized_user(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_authorized_user(p_phone_number character varying, p_pass character varying, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_authorized_user(p_phone_number character varying, p_pass character varying, p_key character varying) OWNER TO admin;

--
-- TOC entry 282 (class 1255 OID 16542)
-- Name: fn_create_chat(integer, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_create_chat(p_id_user integer, p_id_contact integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_create_chat(p_id_user integer, p_id_contact integer) OWNER TO admin;

--
-- TOC entry 281 (class 1255 OID 16541)
-- Name: fn_create_contact(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_create_contact(p_id_user integer, p_contact_number character varying, p_contact_name character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_create_contact(p_id_user integer, p_contact_number character varying, p_contact_name character varying) OWNER TO admin;

--
-- TOC entry 284 (class 1255 OID 16545)
-- Name: fn_deleted_contact(integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_deleted_contact(p_id_contact integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM contact WHERE id_contact = p_id_contact AND deleted = FALSE) THEN
        RETURN 0;
    END IF;

    UPDATE contact SET deleted = TRUE WHERE id_contact = p_id_contact;
    RETURN 1;
END;
$$;


ALTER FUNCTION public.fn_deleted_contact(p_id_contact integer) OWNER TO admin;

--
-- TOC entry 298 (class 1255 OID 16565)
-- Name: fn_deleted_message(integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_deleted_message(p_id_message integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE message_chat
    SET deleted = TRUE
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_deleted_message(p_id_message integer) OWNER TO admin;

--
-- TOC entry 291 (class 1255 OID 16549)
-- Name: fn_deleted_user(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_deleted_user(p_id_user integer, p_pass character varying, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_deleted_user(p_id_user integer, p_pass character varying, p_key character varying) OWNER TO admin;

--
-- TOC entry 297 (class 1255 OID 16564)
-- Name: fn_edit_message(integer, text, text); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_edit_message(p_id_message integer, p_new_text text, p_key text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE message_chat
    SET text_message = pgp_sym_encrypt(p_new_text, p_key)
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_edit_message(p_id_message integer, p_new_text text, p_key text) OWNER TO admin;

--
-- TOC entry 286 (class 1255 OID 16543)
-- Name: fn_load_contact(integer, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_load_contact(p_lim integer, p_phone_contact character varying, p_contact_name character varying, p_id_user integer) RETURNS TABLE(id_contact integer, id_user integer, contact_number character varying, contact_name character varying, deleted boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF (p_phone_contact IS NULL OR p_phone_contact = '') AND (p_contact_name IS NULL OR p_contact_name = '') THEN
        RETURN QUERY
        SELECT id_contact, id_user, contact_number, contact_name, deleted
        FROM contact
        WHERE id_user = p_id_user
        LIMIT p_lim;
    ELSE
        RETURN QUERY
        SELECT id_contact, id_user, contact_number, contact_name, deleted
        FROM contact
        WHERE id_user = p_id_user
        AND deleted = FALSE
        AND (
            (p_phone_contact IS NOT NULL AND contact_number ILIKE '%' || p_phone_contact || '%')
            OR (p_contact_name IS NOT NULL AND contact_name ILIKE '%' || p_contact_name || '%')
        )
        LIMIT p_lim;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_load_contact(p_lim integer, p_phone_contact character varying, p_contact_name character varying, p_id_user integer) OWNER TO admin;

--
-- TOC entry 296 (class 1255 OID 16563)
-- Name: fn_load_message(integer, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_load_message(p_id_chat integer, p_key character varying) RETURNS TABLE(id_message integer, id_chat_sender integer, id_chat_receiver integer, shipping_date timestamp without time zone, delivery_date timestamp without time zone, media_content character varying, text_message text, deleted boolean, delivered boolean, seen boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT m.id_message, m.id_chat_sender, m.id_chat_receiver, m.shipping_date,
           m.delivery_date, m.media_content, pgp_sym_decrypt(m.text_message, p_key)::TEXT, m.deleted, m.delivered, m.seen
    FROM message_chat AS m
    WHERE (m.id_chat_sender = p_id_chat OR m.id_chat_receiver = p_id_chat)
      AND m.deleted = FALSE
    ORDER BY shipping_date DESC
    LIMIT 15;
END;
$$;


ALTER FUNCTION public.fn_load_message(p_id_chat integer, p_key character varying) OWNER TO admin;

--
-- TOC entry 301 (class 1255 OID 16568)
-- Name: fn_logs_message_trigger(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_logs_message_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_action TEXT;
    v_details TEXT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.text_message IS DISTINCT FROM NEW.text_message THEN
            v_action := 'edited';
            v_details := 'The message content was updated.';
        ELSIF OLD.deleted = FALSE AND NEW.deleted = TRUE THEN
            v_action := 'deleted';
            v_details := 'The message was marked as deleted.';
        END IF;

        IF v_action IS NOT NULL THEN
            INSERT INTO logs_message(action, message_affected, date_log, details)
            VALUES (v_action, NEW.id_message, CURRENT_DATE, v_details);
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_logs_message_trigger() OWNER TO admin;

--
-- TOC entry 285 (class 1255 OID 16552)
-- Name: fn_logs_register_client(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_logs_register_client() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN 
    INSERT INTO logs_register_client(id_user)
    VALUES(NEW.id_user);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_logs_register_client() OWNER TO admin;

--
-- TOC entry 299 (class 1255 OID 16566)
-- Name: fn_mark_delivered(integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_mark_delivered(p_id_message integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE message_chat
    SET delivered = TRUE,
        delivery_date = CURRENT_TIMESTAMP
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_mark_delivered(p_id_message integer) OWNER TO admin;

--
-- TOC entry 300 (class 1255 OID 16567)
-- Name: fn_mark_seen(integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_mark_seen(p_id_message integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE message_chat
    SET seen = TRUE
    WHERE id_message = p_id_message;

    IF FOUND THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_mark_seen(p_id_message integer) OWNER TO admin;

--
-- TOC entry 292 (class 1255 OID 16550)
-- Name: fn_reactive_user(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_reactive_user(p_phone_number character varying, p_pass character varying, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_reactive_user(p_phone_number character varying, p_pass character varying, p_key character varying) OWNER TO admin;

--
-- TOC entry 289 (class 1255 OID 16547)
-- Name: fn_read_profile(integer); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_read_profile(p_id_user integer) RETURNS TABLE(id_user integer, username character varying, phone_number character varying, profile_picture character varying, profile_description character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT u.id_user, u.username, u.phone_number, u.profile_picture, u.profile_description
    FROM usr as u
    WHERE u.id_user = p_id_user;
END;
$$;


ALTER FUNCTION public.fn_read_profile(p_id_user integer) OWNER TO admin;

--
-- TOC entry 288 (class 1255 OID 16546)
-- Name: fn_register_user(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_register_user(p_username character varying, p_phone_number character varying, p_email character varying, p_pass character varying, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_register_user(p_username character varying, p_phone_number character varying, p_email character varying, p_pass character varying, p_key character varying) OWNER TO admin;

--
-- TOC entry 294 (class 1255 OID 16556)
-- Name: fn_send_message(integer, character varying, character varying, integer, integer, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_send_message(p_id_chat_sender integer, p_content_media character varying, p_text_content character varying, p_id_user integer, p_id_receiver integer, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE          
    v_id_chat_receiver INT;
    v_user_number VARCHAR; 
    v_id_contact INT;    
BEGIN
    BEGIN
        -- Obtener ID del chat inverso
        SELECT id_chat INTO v_id_chat_receiver 
        FROM chat 
        WHERE id_receiver = p_id_user AND id_sender = p_id_receiver;

        -- Obtener número de teléfono del usuario
        SELECT phone_number INTO v_user_number 
        FROM usr 
        WHERE id_user = p_id_user;

        -- Si no existe el chat inverso, crear contacto y chat
        IF v_id_chat_receiver IS NULL THEN
            -- Crear contacto si no existe
            IF NOT EXISTS (
                SELECT 1 FROM contact 
                WHERE id_user = p_id_receiver AND contact_number = v_user_number
            ) THEN
                INSERT INTO contact(id_user, contact_number)
                VALUES(p_id_receiver, v_user_number)
                RETURNING id_contact INTO v_id_contact;
            END IF;

            -- Obtener id_contact si no se obtuvo antes
            IF v_id_contact IS NULL THEN
                SELECT id_contact INTO v_id_contact
                FROM contact
                WHERE id_user = p_id_receiver AND contact_number = v_user_number
                LIMIT 1;
            END IF;

            -- Crear chat inverso
            INSERT INTO chat(id_sender, id_receiver, id_contact)
            VALUES(p_id_receiver, p_id_user, v_id_contact)
            RETURNING id_chat INTO v_id_chat_receiver;
        END IF;

        -- Insertar mensaje
        INSERT INTO message_chat(id_chat_sender, id_chat_receiver, media_content, text_message)
        VALUES(p_id_chat_sender, v_id_chat_receiver, p_content_media, pgp_sym_encrypt(p_text_content, p_key));
        RETURN 1;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error: %', SQLERRM;
            RETURN 0;
    END;
END;
$$;


ALTER FUNCTION public.fn_send_message(p_id_chat_sender integer, p_content_media character varying, p_text_content character varying, p_id_user integer, p_id_receiver integer, p_key character varying) OWNER TO admin;

--
-- TOC entry 283 (class 1255 OID 16544)
-- Name: fn_update_contact(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_update_contact(p_id_contact integer, p_phone_contact character varying, p_contact_name character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_update_contact(p_id_contact integer, p_phone_contact character varying, p_contact_name character varying) OWNER TO admin;

--
-- TOC entry 287 (class 1255 OID 16554)
-- Name: fn_update_logs(); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_update_logs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.fn_update_logs() OWNER TO admin;

--
-- TOC entry 293 (class 1255 OID 16551)
-- Name: fn_update_user(integer, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.fn_update_user(p_id_user integer, p_username character varying, p_pass character varying, p_profile_picture character varying, p_profile_description character varying, p_key character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
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
$$;


ALTER FUNCTION public.fn_update_user(p_id_user integer, p_username character varying, p_pass character varying, p_profile_picture character varying, p_profile_description character varying, p_key character varying) OWNER TO admin;

--
-- TOC entry 295 (class 1255 OID 16562)
-- Name: sp_load_chat(integer); Type: PROCEDURE; Schema: public; Owner: admin
--

CREATE PROCEDURE public.sp_load_chat(IN p_id_user integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN 

    INSERT INTO chats
    SELECT id_chat, id_sender, id_reciver, id_contact    
    FROM chat c
    JOIN (
        SELECT mc.id_chat_receiver, MAX(mc.shipping_time) AS ultimo_mensaje
        FROM message_chat mc
        WHERE mc.shipping_time >= CURRENT_DATE - INTERVAL '5 days'
        GROUP BY mc.id_chat_receiver
    ) ult ON ult.id_chat_receiver = c.id_chat
    WHERE c.id_reciver = p_id_user
    ORDER BY ult.ultimo_mensaje DESC
    LIMIT 15;

END;
$$;


ALTER PROCEDURE public.sp_load_chat(IN p_id_user integer) OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 16417)
-- Name: chat; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.chat (
    id_chat integer NOT NULL,
    id_sender integer,
    id_receiver integer,
    id_contact integer
);


ALTER TABLE public.chat OWNER TO admin;

--
-- TOC entry 224 (class 1259 OID 16416)
-- Name: chat_id_chat_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.chat_id_chat_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chat_id_chat_seq OWNER TO admin;

--
-- TOC entry 3526 (class 0 OID 0)
-- Dependencies: 224
-- Name: chat_id_chat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.chat_id_chat_seq OWNED BY public.chat.id_chat;


--
-- TOC entry 223 (class 1259 OID 16403)
-- Name: contact; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.contact (
    id_contact integer NOT NULL,
    id_user integer NOT NULL,
    contact_number character varying(20) NOT NULL,
    contact_name character varying(100) DEFAULT 'Unknown'::character varying,
    deleted boolean DEFAULT false
);


ALTER TABLE public.contact OWNER TO admin;

--
-- TOC entry 222 (class 1259 OID 16402)
-- Name: contact_id_contact_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.contact_id_contact_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contact_id_contact_seq OWNER TO admin;

--
-- TOC entry 3527 (class 0 OID 0)
-- Dependencies: 222
-- Name: contact_id_contact_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.contact_id_contact_seq OWNED BY public.contact.id_contact;


--
-- TOC entry 231 (class 1259 OID 16477)
-- Name: logs_client; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.logs_client (
    id_log bigint NOT NULL,
    action_log character varying(100),
    user_affected integer,
    date_log date,
    details text
);


ALTER TABLE public.logs_client OWNER TO admin;

--
-- TOC entry 230 (class 1259 OID 16476)
-- Name: logs_client_id_log_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.logs_client_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_client_id_log_seq OWNER TO admin;

--
-- TOC entry 3528 (class 0 OID 0)
-- Dependencies: 230
-- Name: logs_client_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.logs_client_id_log_seq OWNED BY public.logs_client.id_log;


--
-- TOC entry 233 (class 1259 OID 16491)
-- Name: logs_message; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.logs_message (
    id_log bigint NOT NULL,
    action character varying(100),
    message_affected integer,
    date_log date,
    details text
);


ALTER TABLE public.logs_message OWNER TO admin;

--
-- TOC entry 232 (class 1259 OID 16490)
-- Name: logs_message_id_log_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.logs_message_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_message_id_log_seq OWNER TO admin;

--
-- TOC entry 3529 (class 0 OID 0)
-- Dependencies: 232
-- Name: logs_message_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.logs_message_id_log_seq OWNED BY public.logs_message.id_log;


--
-- TOC entry 229 (class 1259 OID 16462)
-- Name: logs_register_client; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.logs_register_client (
    id_record integer NOT NULL,
    id_user integer NOT NULL,
    user_db character varying(100) DEFAULT CURRENT_USER,
    creation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_session_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    phone_number_change_date date,
    deletion_date date
);


ALTER TABLE public.logs_register_client OWNER TO admin;

--
-- TOC entry 228 (class 1259 OID 16461)
-- Name: logs_register_client_id_record_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.logs_register_client_id_record_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.logs_register_client_id_record_seq OWNER TO admin;

--
-- TOC entry 3530 (class 0 OID 0)
-- Dependencies: 228
-- Name: logs_register_client_id_record_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.logs_register_client_id_record_seq OWNED BY public.logs_register_client.id_record;


--
-- TOC entry 227 (class 1259 OID 16439)
-- Name: message_chat; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.message_chat (
    id_message integer NOT NULL,
    id_chat_sender integer NOT NULL,
    id_chat_receiver integer NOT NULL,
    shipping_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    delivery_date timestamp without time zone,
    media_content character varying(255),
    text_message bytea NOT NULL,
    deleted boolean DEFAULT false,
    delivered boolean DEFAULT false,
    seen boolean DEFAULT false
);


ALTER TABLE public.message_chat OWNER TO admin;

--
-- TOC entry 226 (class 1259 OID 16438)
-- Name: message_chat_id_message_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.message_chat_id_message_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.message_chat_id_message_seq OWNER TO admin;

--
-- TOC entry 3531 (class 0 OID 0)
-- Dependencies: 226
-- Name: message_chat_id_message_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.message_chat_id_message_seq OWNED BY public.message_chat.id_message;


--
-- TOC entry 221 (class 1259 OID 16387)
-- Name: usr; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.usr (
    id_user integer NOT NULL,
    username character varying(255) NOT NULL,
    email bytea NOT NULL,
    phone_number character varying(20) NOT NULL,
    pass bytea NOT NULL,
    profile_picture character varying(255) DEFAULT 'default'::character varying,
    profile_description character varying(255) DEFAULT 'Hey there, I am using CR_Chat'::character varying,
    deleted boolean DEFAULT false,
    tkr character varying(255)
);


ALTER TABLE public.usr OWNER TO admin;

--
-- TOC entry 220 (class 1259 OID 16386)
-- Name: usr_id_user_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.usr_id_user_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usr_id_user_seq OWNER TO admin;

--
-- TOC entry 3532 (class 0 OID 0)
-- Dependencies: 220
-- Name: usr_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.usr_id_user_seq OWNED BY public.usr.id_user;


--
-- TOC entry 3307 (class 2604 OID 16420)
-- Name: chat id_chat; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.chat ALTER COLUMN id_chat SET DEFAULT nextval('public.chat_id_chat_seq'::regclass);


--
-- TOC entry 3304 (class 2604 OID 16406)
-- Name: contact id_contact; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contact ALTER COLUMN id_contact SET DEFAULT nextval('public.contact_id_contact_seq'::regclass);


--
-- TOC entry 3317 (class 2604 OID 16480)
-- Name: logs_client id_log; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_client ALTER COLUMN id_log SET DEFAULT nextval('public.logs_client_id_log_seq'::regclass);


--
-- TOC entry 3318 (class 2604 OID 16494)
-- Name: logs_message id_log; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_message ALTER COLUMN id_log SET DEFAULT nextval('public.logs_message_id_log_seq'::regclass);


--
-- TOC entry 3313 (class 2604 OID 16465)
-- Name: logs_register_client id_record; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_register_client ALTER COLUMN id_record SET DEFAULT nextval('public.logs_register_client_id_record_seq'::regclass);


--
-- TOC entry 3308 (class 2604 OID 16442)
-- Name: message_chat id_message; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.message_chat ALTER COLUMN id_message SET DEFAULT nextval('public.message_chat_id_message_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 16390)
-- Name: usr id_user; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usr ALTER COLUMN id_user SET DEFAULT nextval('public.usr_id_user_seq'::regclass);


--
-- TOC entry 3499 (class 0 OID 16417)
-- Dependencies: 225
-- Data for Name: chat; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.chat (id_chat, id_sender, id_receiver, id_contact) FROM stdin;
\.


--
-- TOC entry 3497 (class 0 OID 16403)
-- Dependencies: 223
-- Data for Name: contact; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.contact (id_contact, id_user, contact_number, contact_name, deleted) FROM stdin;
\.


--
-- TOC entry 3505 (class 0 OID 16477)
-- Dependencies: 231
-- Data for Name: logs_client; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.logs_client (id_log, action_log, user_affected, date_log, details) FROM stdin;
\.


--
-- TOC entry 3507 (class 0 OID 16491)
-- Dependencies: 233
-- Data for Name: logs_message; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.logs_message (id_log, action, message_affected, date_log, details) FROM stdin;
\.


--
-- TOC entry 3503 (class 0 OID 16462)
-- Dependencies: 229
-- Data for Name: logs_register_client; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.logs_register_client (id_record, id_user, user_db, creation_date, last_session_date, phone_number_change_date, deletion_date) FROM stdin;
1	1	admin	2025-06-21 01:53:23.324436	2025-06-21 01:53:23.324436	\N	\N
2	2	admin	2025-06-21 01:53:23.348122	2025-06-21 01:53:23.348122	\N	\N
3	3	admin	2025-06-21 01:53:23.351739	2025-06-21 01:53:23.351739	\N	\N
4	4	admin	2025-06-21 01:53:23.356409	2025-06-21 01:53:23.356409	\N	\N
5	5	admin	2025-06-21 01:53:23.360367	2025-06-21 01:53:23.360367	\N	\N
6	6	admin	2025-06-21 01:53:23.364626	2025-06-21 01:53:23.364626	\N	\N
7	7	admin	2025-06-21 01:53:23.369265	2025-06-21 01:53:23.369265	\N	\N
\.


--
-- TOC entry 3501 (class 0 OID 16439)
-- Dependencies: 227
-- Data for Name: message_chat; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.message_chat (id_message, id_chat_sender, id_chat_receiver, shipping_date, delivery_date, media_content, text_message, deleted, delivered, seen) FROM stdin;
\.


--
-- TOC entry 3495 (class 0 OID 16387)
-- Dependencies: 221
-- Data for Name: usr; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.usr (id_user, username, email, phone_number, pass, profile_picture, profile_description, deleted, tkr) FROM stdin;
1	Juan Perez	\\xc30d040703021f8b9a31e5a246d976d23e01b0f4fc7b90c95f8da73d9d2580d0725d352c74c264954f9dc09d92441c7b9eead87a99bea2ce128f0e9392a8d611c54714a9a9f6a8d25af9606d144657	1234567890	\\xc30d040703027714000cfe36c9a363d23c014608b4777183f9643ca514007f55e0bc5b3ad5023a33bb472d5d3a369681c6a2861719c4e446bebee848b3c8f89ecf415bd23016a913ddfd31efa5	default	Hey there, I am using CR_Chat	f	\N
2	Maria Lopez	\\xc30d04070302187073de050c25e775d23f01be86b06557ba1011a6eb52f5c1d268a57b04611075444d71795282f587307fffc8f3058623b1c1e711baf6e59accdf4d3515d4d1bca3500acbe3503c0616	3216549870	\\xc30d040703028647244980ba454862d239015c1ed43361c9e02642a4d2267e61f37e855764b86f0395c3c613d3a81bf45ab6c52e2794f725535840c1e21b534c5a97aac4242059563359	default	Hey there, I am using CR_Chat	f	\N
3	Carlos Ruiz	\\xc30d04070302d325c8a1cc483cb967d24001b920acc377baff4ce4d52aa855027d79ccef768e4f6be21db73b3d2b3db44283162980cbcf845990b42cb7ac278437bb964b68847bd8d5f5ab9a35b482a3e2	7894561230	\\xc30d040703023a1297f687a68c6470d23a01ae66b5f4426821f5ddfb0ea614afa1736ed408327c55d14fa2418d5df411f1a90538c7b6a5ec94f9c1ff9f21e6d8e330145625265831bc1ab5	default	Hey there, I am using CR_Chat	f	\N
4	Ana Torres	\\xc30d04070302b7c240d9c7abda6f7ed23d013324afb548d04368b736073538c898390382f9bdef2c725450d1d5e8aa94b0375416282ab3713c26c54dae10499120904594f74e4bf885a51c02e810	1472583690	\\xc30d040703020c6ec509beff7a9c72d23701a44bb4ef4faa1d4183af013fa8496e683f5b5f206323a37fc12bf0e7669bd656651bc8695e3ffb936ef1ab4fcbea3357a330afb3731d	default	Hey there, I am using CR_Chat	f	\N
5	Luis Gómez	\\xc30d040703029d13087a6b949f737fd23e015f02e59fc579a4d843264ed68b14cb9e670185e58e845efb064ad160115e6510bd1ab76a0592fc92ba98258093de6908d53c347153bf109a0fb14c1f4a	9638527410	\\xc30d04070302ebf8c3025a9bac946cd2380193b3b48ec3af5faaa4493a860e4dfccfae5a22224ffd2ab0702d16cec70dec48c8c2a4dd9fb962d584eed13412dc68c03d7768506d50a1	default	Hey there, I am using CR_Chat	f	\N
6	Lucía Ramos	\\xc30d0407030254bf9ccf004d8b7776d23f01ac84fcdd5ba0ca082edac0f07d19b548b2447f6fd0ef9f7adc1e2518a4dd79db0dd4ce013f3463fa7177231753c04bd09ba911ce110dd0db4a6968309652	5556667777	\\xc30d04070302385ae1dde7c54a9763d23901d914cc29908451acfeb0eb1788f2e9237b20a19c7c769cc1f377eb851651613c25f4f0cf76813f9b62d48ff2c9a5ce1ac36c15e937e8b69d	default	Hey there, I am using CR_Chat	f	\N
7	Andrés Márquez	\\xc30d040703029aacd5d4990a8c8f6cd24001585297255b322b96d0e2795910739324a8e3cab8c2bdcd1c86161dba5703328f643d2aa02ec3bff9238c57f02d23e3f7a669a98c2b920ee71da8e11b4b6cfe	4445556666	\\xc30d04070302cb069f007b3756296cd23a015634a2c5c09ee01f1977353ee0d055ab939f80fdc6c6c927613266a2ab895831455b7c3ac6d33bd75aeb2bf7196056622f2cc3475dfdc71b65	default	Hey there, I am using CR_Chat	f	\N
\.


--
-- TOC entry 3533 (class 0 OID 0)
-- Dependencies: 224
-- Name: chat_id_chat_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.chat_id_chat_seq', 1, false);


--
-- TOC entry 3534 (class 0 OID 0)
-- Dependencies: 222
-- Name: contact_id_contact_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.contact_id_contact_seq', 1, false);


--
-- TOC entry 3535 (class 0 OID 0)
-- Dependencies: 230
-- Name: logs_client_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.logs_client_id_log_seq', 1, false);


--
-- TOC entry 3536 (class 0 OID 0)
-- Dependencies: 232
-- Name: logs_message_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.logs_message_id_log_seq', 1, false);


--
-- TOC entry 3537 (class 0 OID 0)
-- Dependencies: 228
-- Name: logs_register_client_id_record_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.logs_register_client_id_record_seq', 7, true);


--
-- TOC entry 3538 (class 0 OID 0)
-- Dependencies: 226
-- Name: message_chat_id_message_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.message_chat_id_message_seq', 1, false);


--
-- TOC entry 3539 (class 0 OID 0)
-- Dependencies: 220
-- Name: usr_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.usr_id_user_seq', 7, true);


--
-- TOC entry 3328 (class 2606 OID 16422)
-- Name: chat chat_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.chat
    ADD CONSTRAINT chat_pkey PRIMARY KEY (id_chat);


--
-- TOC entry 3326 (class 2606 OID 16410)
-- Name: contact contact_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contact
    ADD CONSTRAINT contact_pkey PRIMARY KEY (id_contact);


--
-- TOC entry 3334 (class 2606 OID 16484)
-- Name: logs_client logs_client_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_client
    ADD CONSTRAINT logs_client_pkey PRIMARY KEY (id_log);


--
-- TOC entry 3336 (class 2606 OID 16498)
-- Name: logs_message logs_message_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_message
    ADD CONSTRAINT logs_message_pkey PRIMARY KEY (id_log);


--
-- TOC entry 3332 (class 2606 OID 16470)
-- Name: logs_register_client logs_register_client_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_register_client
    ADD CONSTRAINT logs_register_client_pkey PRIMARY KEY (id_record);


--
-- TOC entry 3330 (class 2606 OID 16450)
-- Name: message_chat message_chat_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.message_chat
    ADD CONSTRAINT message_chat_pkey PRIMARY KEY (id_message);


--
-- TOC entry 3320 (class 2606 OID 16399)
-- Name: usr usr_email_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usr
    ADD CONSTRAINT usr_email_key UNIQUE (email);


--
-- TOC entry 3322 (class 2606 OID 16401)
-- Name: usr usr_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usr
    ADD CONSTRAINT usr_phone_number_key UNIQUE (phone_number);


--
-- TOC entry 3324 (class 2606 OID 16397)
-- Name: usr usr_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.usr
    ADD CONSTRAINT usr_pkey PRIMARY KEY (id_user);


--
-- TOC entry 3348 (class 2620 OID 16569)
-- Name: message_chat tr_logs_message_changes; Type: TRIGGER; Schema: public; Owner: admin
--

CREATE TRIGGER tr_logs_message_changes AFTER UPDATE ON public.message_chat FOR EACH ROW EXECUTE FUNCTION public.fn_logs_message_trigger();


--
-- TOC entry 3346 (class 2620 OID 16553)
-- Name: usr trigger_log_usr; Type: TRIGGER; Schema: public; Owner: admin
--

CREATE TRIGGER trigger_log_usr AFTER INSERT ON public.usr FOR EACH ROW EXECUTE FUNCTION public.fn_logs_register_client();


--
-- TOC entry 3347 (class 2620 OID 16555)
-- Name: usr trigger_update; Type: TRIGGER; Schema: public; Owner: admin
--

CREATE TRIGGER trigger_update AFTER UPDATE ON public.usr FOR EACH ROW EXECUTE FUNCTION public.fn_update_logs();


--
-- TOC entry 3338 (class 2606 OID 16423)
-- Name: chat chat_id_contact_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.chat
    ADD CONSTRAINT chat_id_contact_fkey FOREIGN KEY (id_contact) REFERENCES public.contact(id_contact) ON DELETE CASCADE;


--
-- TOC entry 3339 (class 2606 OID 16433)
-- Name: chat chat_id_receiver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.chat
    ADD CONSTRAINT chat_id_receiver_fkey FOREIGN KEY (id_receiver) REFERENCES public.usr(id_user) ON DELETE CASCADE;


--
-- TOC entry 3340 (class 2606 OID 16428)
-- Name: chat chat_id_sender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.chat
    ADD CONSTRAINT chat_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.usr(id_user) ON DELETE CASCADE;


--
-- TOC entry 3337 (class 2606 OID 16411)
-- Name: contact contact_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contact
    ADD CONSTRAINT contact_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.usr(id_user) ON DELETE CASCADE;


--
-- TOC entry 3344 (class 2606 OID 16485)
-- Name: logs_client logs_client_user_affected_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_client
    ADD CONSTRAINT logs_client_user_affected_fkey FOREIGN KEY (user_affected) REFERENCES public.usr(id_user) ON DELETE CASCADE;


--
-- TOC entry 3345 (class 2606 OID 16499)
-- Name: logs_message logs_message_message_affected_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_message
    ADD CONSTRAINT logs_message_message_affected_fkey FOREIGN KEY (message_affected) REFERENCES public.message_chat(id_message) ON DELETE CASCADE;


--
-- TOC entry 3343 (class 2606 OID 16471)
-- Name: logs_register_client logs_register_client_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logs_register_client
    ADD CONSTRAINT logs_register_client_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.usr(id_user) ON DELETE CASCADE;


--
-- TOC entry 3341 (class 2606 OID 16456)
-- Name: message_chat message_chat_id_chat_receiver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.message_chat
    ADD CONSTRAINT message_chat_id_chat_receiver_fkey FOREIGN KEY (id_chat_receiver) REFERENCES public.chat(id_chat) ON DELETE CASCADE;


--
-- TOC entry 3342 (class 2606 OID 16451)
-- Name: message_chat message_chat_id_chat_sender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.message_chat
    ADD CONSTRAINT message_chat_id_chat_sender_fkey FOREIGN KEY (id_chat_sender) REFERENCES public.chat(id_chat) ON DELETE CASCADE;


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 290
-- Name: FUNCTION fn_authorized_user(p_phone_number character varying, p_pass character varying, p_key character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_authorized_user(p_phone_number character varying, p_pass character varying, p_key character varying) TO clients;


--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION fn_create_chat(p_id_user integer, p_id_contact integer); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_create_chat(p_id_user integer, p_id_contact integer) TO clients;


--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 281
-- Name: FUNCTION fn_create_contact(p_id_user integer, p_contact_number character varying, p_contact_name character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_create_contact(p_id_user integer, p_contact_number character varying, p_contact_name character varying) TO clients;


--
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION fn_deleted_contact(p_id_contact integer); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_deleted_contact(p_id_contact integer) TO clients;


--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 291
-- Name: FUNCTION fn_deleted_user(p_id_user integer, p_pass character varying, p_key character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_deleted_user(p_id_user integer, p_pass character varying, p_key character varying) TO clients;


--
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION fn_load_contact(p_lim integer, p_phone_contact character varying, p_contact_name character varying, p_id_user integer); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_load_contact(p_lim integer, p_phone_contact character varying, p_contact_name character varying, p_id_user integer) TO clients;


--
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 292
-- Name: FUNCTION fn_reactive_user(p_phone_number character varying, p_pass character varying, p_key character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_reactive_user(p_phone_number character varying, p_pass character varying, p_key character varying) TO clients;


--
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 289
-- Name: FUNCTION fn_read_profile(p_id_user integer); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_read_profile(p_id_user integer) TO clients;


--
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION fn_register_user(p_username character varying, p_phone_number character varying, p_email character varying, p_pass character varying, p_key character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_register_user(p_username character varying, p_phone_number character varying, p_email character varying, p_pass character varying, p_key character varying) TO clients;


--
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION fn_update_contact(p_id_contact integer, p_phone_contact character varying, p_contact_name character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_update_contact(p_id_contact integer, p_phone_contact character varying, p_contact_name character varying) TO clients;


--
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 293
-- Name: FUNCTION fn_update_user(p_id_user integer, p_username character varying, p_pass character varying, p_profile_picture character varying, p_profile_description character varying, p_key character varying); Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON FUNCTION public.fn_update_user(p_id_user integer, p_username character varying, p_pass character varying, p_profile_picture character varying, p_profile_description character varying, p_key character varying) TO clients;


-- Completed on 2025-06-21 02:09:18

--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-06-21 02:09:19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2025-06-21 02:09:19

--
-- PostgreSQL database dump complete
--

-- Completed on 2025-06-21 02:09:19

--
-- PostgreSQL database cluster dump complete
--

