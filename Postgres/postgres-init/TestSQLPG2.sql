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


-- Ana agrega a Luis como contacto
SELECT * FROM fn_create_contact(4, '9638527410', 'Luis Gómez');

-- Crear chat (suponiendo id_contact = 4)
SELECT * FROM fn_create_chat(4, 4);

-- Intercambio de mensajes
SELECT * FROM fn_send_message(1, NULL, 'Hola Luis, ¿cómo estás?', 4, 5, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, NULL, '¿Tienes tiempo para revisar el informe?', 4, 5, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, NULL, 'Claro Ana, estoy revisando ahora.', 5, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, NULL, 'Perfecto, gracias.', 4, 5, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, NULL, '¿Te llegó el archivo adjunto?', 5, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, 'docs/informe.pdf', 'Aquí va el informe actualizado.', 5, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(1, NULL, 'Sí, ya lo tengo. ¡Gracias!', 4, 5, 'clientdecryption2025');

-- Lucía agrega a Andrés
SELECT * FROM fn_create_contact(6, '4445556666', 'Andrés Márquez');

-- Crear chat (id_contact = 5)
SELECT * FROM fn_create_chat(6, 5);

-- Mensajes entre ellos
SELECT * FROM fn_send_message(2, NULL, '¡Hola Andrés! ¿Cómo va todo?', 6, 7, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, 'Hola Lucía, todo bien. ¿Y tú?', 7, 6, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, 'Bien, gracias. ¿Nos vemos el viernes?', 6, 7, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, 'Sí, tengo libre en la tarde.', 7, 6, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, 'Perfecto, te paso la dirección.', 6, 7, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, 'Gracias, nos vemos entonces.', 7, 6, 'clientdecryption2025');
SELECT * FROM fn_send_message(2, NULL, '¡Nos vemos! 😊', 6, 7, 'clientdecryption2025');

-- Carlos agrega a Ana
SELECT * FROM fn_create_contact(3, '1472583690', 'Ana Torres');

-- Crear chat (id_contact = 6)
SELECT * FROM fn_create_chat(3, 6);

-- Envío de mensajes
SELECT * FROM fn_send_message(3, NULL, 'Hola Ana, ¿cómo va la app del proyecto?', 3, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, 'Hola Carlos, ya casi terminamos el módulo principal.', 4, 3, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, '¡Genial! ¿Puedo ver una demo esta semana?', 3, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, 'Claro, te la muestro el jueves.', 4, 3, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, 'Perfecto, mándame la hora.', 3, 4, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, 'A las 4pm. ¿Te sirve?', 4, 3, 'clientdecryption2025');
SELECT * FROM fn_send_message(3, NULL, 'Sí, nos vemos entonces. Gracias Ana.', 3, 4, 'clientdecryption2025');