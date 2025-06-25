USE CR_Chat;

-- DROP DATABASE IF EXISTS CR_Chat;

-- Tabla usr
DROP TABLE IF EXISTS usr;
CREATE TABLE usr (
    id_user INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    username VARCHAR(255) NOT NULL,
    email VARBINARY(150) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pass VARBINARY(64) NOT NULL,
    profile_picture VARCHAR(255) DEFAULT 'default',
    profile_description VARCHAR(255) DEFAULT 'Hey there, I am using CR_Chat',
    deleted BOOLEAN DEFAULT FALSE,
    tkR varchar(255)
);

-- Tabla contact
DROP TABLE IF EXISTS contact;
CREATE TABLE contact (
    id_contact INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    id_user INT NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100) DEFAULT 'Unknown',
    deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_user) REFERENCES usr(id_user)
);

-- Crear tabla de chats
DROP TABLE IF EXISTS chat;
CREATE TABLE chat(
    id_chat INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_sender INT,
    id_receiver INT,
    id_contact INT,
    FOREIGN KEY (id_contact) REFERENCES contact(id_contact),
    FOREIGN KEY (id_sender) REFERENCES usr(id_user)
);

-- Tabla message
DROP TABLE IF EXISTS message_chat;
CREATE TABLE message_chat (
    id_message INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_chat_sender int NOT NULL,
    id_chat_receiver int NOT NULL,
    shipping_date TIMESTAMP DEFAULT now(),
    delivery_date TIMESTAMP,
    media_content VARCHAR(255),
    text_message BLOB not null, -- encrypted 
    deleted BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN,
    seen BOOLEAN,
    FOREIGN KEY (id_chat_sender) REFERENCES chat(id_chat),
    FOREIGN KEY (id_chat_receiver) REFERENCES chat(id_chat)
);

-- Tabla logs_register_client
DROP TABLE IF EXISTS logs_register_client;
CREATE TABLE logs_register_client (
    id_record INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    user_db varchar(100),
    creation_datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_session_datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
    phone_number_change_date DATE,
    deletion_date DATE,
    FOREIGN KEY (id_user) REFERENCES usr(id_user)
);

-- Tabla logs_client
DROP TABLE IF EXISTS logs_client;
CREATE TABLE logs_client (
    id_log BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    action_log VARCHAR(100),
    user_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (user_affected) REFERENCES usr(id_user)
);

-- Tabla logs_message
DROP TABLE IF EXISTS logs_message;
CREATE TABLE logs_message (
    id_log BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100),
    message_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (message_affected) REFERENCES message_chat(id_message)
);






