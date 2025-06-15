-- Usuario 1
SELECT * FROM fn_register_user(
  'Juan Perez',
  '1234567890',
  'juan@mail.com',
  'password123',
  'clientdecryption2025'
);

-- Usuario 2
SELECT * FROM fn_register_user(
  'Maria Lopez',
  '3216549870',
  'maria@mail.com',
  'maria456',
  'clientdecryption2025'
);

-- Usuario 3
SELECT * FROM fn_register_user(
  'Carlos Ruiz',
  '7894561230',
  'carlos@mail.com',
  'carlos789',
  'clientdecryption2025'
);

-- Usuario 4
SELECT * FROM fn_register_user(
  'Ana Torres',
  '1472583690',
  'ana@mail.com',
  'ana321',
  'clientdecryption2025'
);

-- Usuario 5
SELECT * FROM fn_register_user(
  'Luis Gómez',
  '9638527410',
  'luis@mail.com',
  'luis654',
  'clientdecryption2025'
);

-- Usuario 6
SELECT * FROM fn_register_user(
  'Lucía Ramos',
  '5556667777',
  'lucia@mail.com',
  'lucia987',
  'clientdecryption2025'
);

-- Usuario 7
SELECT * FROM fn_register_user(
  'Andrés Márquez',
  '4445556666',
  'andres@mail.com',
  'andres159',
  'clientdecryption2025'
);

-- Actualizar usuario
SELECT * FROM fn_update_user(
  1,
  'Juan Actualizado',
  'nuevaClave123',
  'path/to/new/profile.jpg',
  NULL,
  'clientdecryption2025'
);

-- Crear contacto con el número de María
SELECT * FROM fn_create_contact(1, '3216549870', 'María');

-- Crear contacto con el número de Carlos
SELECT * FROM fn_create_contact(2, '7894561230', 'Carlos');

SELECT * FROM fn_create_contact(1, '9638527410', 'Luis Gómez');

-- Crear chat con María (suponiendo id_contact = 2)
SELECT * FROM fn_create_chat(1, 2);

-- Crear chat con Carlos (suponiendo id_contact = 3)
SELECT * FROM fn_create_chat(2, 3);

-- Intentar crear chat con número inexistente
SELECT * FROM fn_create_chat(1, 3);

-- Enviar mensaje de Juan a María
SELECT * FROM fn_send_message(
  1,                -- p_id_chat_sender
  'img/saludo.png', -- p_content_media
  '¡Hola María!',   -- p_text_content
  1,                -- p_id_user
  2,                -- p_id_receiver
  'clientdecryption2025'
);

-- Enviar segundo mensaje
SELECT * FROM fn_send_message(
  1,
  NULL,
  '¿Estás ahí?',
  1,
  3,
  'clientdecryption2025'
);

-- Editar mensaje con ID 2
SELECT * FROM fn_edit_message(
  2,
  'Mensaje corregido y editado.',
  'clientdecryption2025'
);
