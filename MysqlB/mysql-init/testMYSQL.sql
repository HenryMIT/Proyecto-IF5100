USE CR_Chat;

-- Usuario 1
CALL sp_register_user(
  'Juan Perez',
  'juan@mail.com', 
  '1234567890',
  'password123',
  'clientdecryption2025!'
);

-- Usuario 2
CALL sp_register_user(
  'Maria Lopez',
  'maria@mail.com',
  '3216549870',
  'maria456',
  'clientdecryption2025!'
);

-- Usuario 3
CALL sp_register_user(
  'Carlos Ruiz',
  'carlos@mail.com',
  '7894561230',
  'carlos789',
  'clientdecryption2025!'
);

-- Usuario 4
CALL sp_register_user(
  'Ana Torres',
  'ana@mail.com',
  '1472583690',
  'ana321',
  'clientdecryption2025!'
);

-- Usuario 5
CALL sp_register_user(
  'Luis Gómez',
  'luis@mail.com',
  '9638527410',
  'luis654',
  'clientdecryption2025!'
); 


-- Usuario 6
CALL sp_register_user(
  'Lucía Ramos',
  'lucia@mail.com',
  '5556667777',
  'lucia987',
  'clientdecryption2025!'
);

-- Usuario 7
CALL sp_register_user(
  'Andrés Márquez',
  'andres@mail.com',
  '4445556666',
  'andres159',
  'clientdecryption2025!'
);

CALL sp_update_user(
  1,
  'Juan Actualizado',
  'nuevaClave123',
  '0987654321',
  'path/to/new/profile.jpg',
  NULL,
  'clientdecryption2025!'
);
