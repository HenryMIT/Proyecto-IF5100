-- Database: CR_Chat

-- DROP DATABASE IF EXISTS "CR_Chat";

CREATE USER Clients WITH PASSWORD 'client2025';

-- Tabla usr
CREATE TABLE usr (
    id_usr SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email BYTEA UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pass BYTEA NOT NULL, -- Encrypted
    profile_picture VARCHAR(255) DEFAULT 'default',
    profile_description VARCHAR(255) DEFAULT 'Hey there, I am using CR_Chat',
    deleted BOOLEAN DEFAULT FALSE,
    tkR varchar(255)
);

-- Tabla contact
CREATE TABLE contact (
    id_contact SERIAL PRIMARY KEY,
    id_usr INT NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100) DEFAULT 'Unknown',
    deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr)   
);

CREATE TABLE chat(
    id_chat SERIAL PRIMARY KEY,
    id_sender INT, 
    id_reciver INT,
    id_contact INT,    
    FOREIGN KEY (id_contact) REFERENCES contact(id_contact)
    FOREIGN KEY (id_sender) REFERENCES usr(id_usr)
);

-- Tabla message
CREATE TABLE message_chat (
    id_message SERIAL PRIMARY KEY,
    id_chat_sender int NOT NULL,
    id_chat_receiver int NOT NULL,
    shipping_date DATE,
    shipping_time TIMESTAMP,
    delivery_date DATE,
    delivery_time TIMESTAMP,
    media_content VARCHAR(255),
    text_message BYTEA not null, -- encrypted 
    deleted BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN,
    seen BOOLEAN,
    FOREIGN KEY (id_chat_sender) REFERENCES chat(id_chat),
    FOREIGN KEY (id_chat_receiver) REFERENCES chat(id_chat)
);

-- Tabla logs_register_client
CREATE TABLE logs_register_client (
    id_record SERIAL PRIMARY KEY,
    id_usr INT NOT NULL,
    user_db varchar(100) DEFAULT CURRENT_USER, 
    creation_date DATE DEFAULT CURRENT_DATE,
    creation_time TIME DEFAULT CURRENT_TIME,
    last_session_date DATE DEFAULT CURRENT_DATE,
    last_session_time TIME DEFAULT CURRENT_TIME,
    phone_number_change_date DATE,
    deletion_date DATE,
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr)
);

-- Tabla logs_client
CREATE TABLE logs_client (
    id_log BIGSERIAL PRIMARY KEY,
    action_log VARCHAR(100),
    user_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (user_affected) REFERENCES usr(id_usr)
);

-- Tabla logs_message
CREATE TABLE logs_message (
    id_log BIGSERIAL PRIMARY KEY,
    action VARCHAR(100),
    message_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (message_affected) REFERENCES message_chat(id_message)
);

-- Para hacer la encriptación
CREATE EXTENSION IF NOT EXISTS pgcrypto;
