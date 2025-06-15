
-- ==============================================
-- DEMO DE USO DE PROCEDIMIENTOS CR_Chat (versión sin OUT)
-- Fecha de generación: 2025-06-13 14:30:44
-- ==============================================

USE CR_Chat;

-- 1. Registrar dos usuarios
CALL sp_register_user('Ana Torres', 'ana@correo.com', '70001111', 'ana123', 'ana123');
CALL sp_register_user('Marco Rojas', 'marco@correo.com', '70002222', 'marco456', 'marco456');

-- 2. Crear contactos cruzados
-- Ana agrega a Marco
CALL sp_create_contact(1, '70002222', 'Marco');
-- Marco agrega a Ana
CALL sp_create_contact(2, '70001111', 'Ana');

-- 3. Crear chat entre ambos contactos
-- Supón que Ana tiene id_contact = 1 y Marco id_contact = 2 (puedes verificar con: SELECT * FROM contact)
CALL sp_create_chat(1, 2);

-- 4. Enviar mensaje desde Ana (id_user=1) a Marco (id_user=2)
CALL sp_send_message(1, NULL, '¡Hola Marco!', 1, 2, 'ana123');

-- 5. Consultar mensajes del chat recién creado
CALL sp_load_message(1);

-- 6. Consultar logs si existen acciones registradas
SELECT * FROM logs_message ORDER BY date_log DESC;

-- 7. Ver contactos registrados
CALL sp_load_contact(10, 0, NULL, NULL);
