USE CR_Chat;

-- Usuario 1
SELECT fn_register_user(
  'Juan Perez',
  AES_ENCRYPT('juan@mail.com', 'clave123'),
  '1234567890',
  SHA2('password123', 256),
  'key123'
);

-- Usuario 2
SELECT fn_register_user(
  'Maria Lopez',
  AES_ENCRYPT('maria@mail.com', 'clave123'),
  '3216549870',
  SHA2('maria456', 256),
  'key456'
);

-- Usuario 3
SELECT fn_register_user(
  'Carlos Ruiz',
  AES_ENCRYPT('carlos@mail.com', 'clave123'),
  '7894561230',
  SHA2('carlos789', 256),
  'key789'
);

-- Usuario 4
SELECT fn_register_user(
  'Ana Torres',
  AES_ENCRYPT('ana@mail.com', 'clave123'),
  '1472583690',
  SHA2('ana321', 256),
  'key321'
);

-- Usuario 5
SELECT fn_register_user(
  'Luis Gómez',
  AES_ENCRYPT('luis@mail.com', 'clave123'),
  '9638527410',
  SHA2('luis654', 256),
  'key654'
);

-- Usuario 6
SELECT fn_register_user(
  'Lucía Ramos',
  AES_ENCRYPT('lucia@mail.com', 'clave123'),
  '5556667777',
  SHA2('lucia987', 256),
  'key987'
);

-- Usuario 7
SELECT fn_register_user(
  'Andrés Márquez',
  AES_ENCRYPT('andres@mail.com', 'clave123'),
  '4445556666',
  SHA2('andres159', 256),
  'key159'
);

CALL sp_update_user(
  1,
  'Juan Actualizado',
  SHA2('nuevaClave123', 256),
  '0987654321',
  'path/to/new/profile.jpg',
  'Descripción actualizada'
);


-- Crear contacto con el número de María
SELECT fn_create_contact(1, '3216549870', 'María');

-- Crear contacto con el número de Carlos
SELECT fn_create_contact(1, '7894561230', 'Carlos');

-- Crear contacto con número inexistente (debería insertarlo igual, aunque no cree chat)
SELECT fn_create_contact(1, '0001112222', 'Desconocido');

-- Buscar el ID del contacto creado (opcional)
SELECT * FROM contact WHERE id_usr = 1;



-- Crear chat con María (suponiendo id_contact = 1)
SELECT fn_create_chat(1);

-- Crear chat con Carlos (suponiendo id_contact = 2)
SELECT fn_create_chat(2);

-- Intentar crear chat con número inexistente (contacto desconocido), debería retornar 0
SELECT fn_create_chat(3);


