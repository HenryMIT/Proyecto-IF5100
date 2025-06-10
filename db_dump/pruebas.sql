USE CR_Chat;

-- Usuario 1
SELECT fn_register_user(
  'Juan Perez',
  'juan@mail.com', 
  '1234567890',
  'password123',
  'clientdecryption2025'
);

-- Usuario 2
SELECT fn_register_user(
  'Maria Lopez',
  'maria@mail.com',
  '3216549870',
  'maria456',
  'clientdecryption2025'
);

-- Usuario 3
SELECT fn_register_user(
  'Carlos Ruiz',
  'carlos@mail.com',
  '7894561230',
  'carlos789',
  'clientdecryption2025'
);

-- Usuario 4
SELECT fn_register_user(
  'Ana Torres',
  'ana@mail.com',
  '1472583690',
  'ana321',
  'clientdecryption2025'
);

-- Usuario 5
SELECT fn_register_user(
  'Luis Gómez',
  'luis@mail.com',
  '9638527410',
  'luis654',
  'clientdecryption2025'
); 


-- Usuario 6
SELECT fn_register_user(
  'Lucía Ramos',
  'lucia@mail.com',
  '5556667777',
  'lucia987',
  'clientdecryption2025'
);

-- Usuario 7
SELECT fn_register_user(
  'Andrés Márquez',
  'andres@mail.com',
  '4445556666',
  'andres159',
  'clientdecryption2025'
);

CALL sp_update_user(
  1,
  'Juan Actualizado',
  'nuevaClave123',
  '0987654321',
  'path/to/new/profile.jpg',
  NULL,
  'clientdecryption2025'
);


-- Crear contacto con el número de María
SELECT fn_create_contact(1, '3216549870', 'María');

-- Crear contacto con el número de Carlos
SELECT fn_create_contact(2, '7894561230', 'Carlos');

-- Crear contacto con número inexistente (debería insertarlo igual, aunque no cree chat)
SELECT fn_create_contact(3, '0001112222', 'Desconocido');

-- Buscar el ID del contacto creado (opcional)
SELECT * FROM contact WHERE id_usr = 1;



-- Crear chat con María (suponiendo id_contact = 1)
SELECT fn_create_chat(1, 2);

-- Crear chat con Carlos (suponiendo id_contact = 2)
SELECT fn_create_chat(2, 3);

-- Intentar crear chat con número inexistente (contacto desconocido), debería retornar 0
SELECT fn_create_chat(3, 1);

-- Enviar mensaje de Juan a María
CALL sp_send_message(
  1,                -- p_id_chat_sender
  'img/saludo.png', -- p_media_content
  '¡Hola María!',   -- p_text_message
  1,                -- p_id_sender
  2,                 -- p_id_receiver
  'clientdecryption2025'
);

CALL sp_send_message(
  1,
  NULL,
  '¿Estás ahí?',
  1,
  3,
  'clientdecryption2025'
);


CALL sp_edit_message(
  2,
  'Mensaje corregido y editado.', 
  'clientdecryption2025'
);


