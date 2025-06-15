
SELECT public.fn_register_user(
'Henry', 
'61167541', 
'henrygherrera@gmail.com', 
'HeNrYGGH84!', 
'clientdecryption2025!');

DO $$
DECLARE
    v_auth_result INT;
BEGIN
    SELECT public.fn_authorized_user('61167541', 'HeNrYGGH84!', 'clientdecryption2025!') INTO v_auth_result;

    IF v_auth_result > 0 THEN
        SELECT * public.sp_read_profile(v_auth_result);           	
    ELSE
        RAISE NOTICE 'Autenticación fallida.';
    END IF;
END;
$$;

SELECT id_usr, username, email,phone_number,phone_number, pgp_sym_decrypt(pass, 'clientdecryption2025!') AS passD ,profile_picture,profile_description 
FROM usr;
