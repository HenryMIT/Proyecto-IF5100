USE CR_Chat;

-- Tabla usr
DROP TABLE IF EXISTS usr;
CREATE TABLE usr (
    id_usr INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    username VARCHAR(255) NOT NULL,
    email VARBINARY(50) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pass VARBINARY(20) NOT NULL,
    profile_picture VARCHAR(255) DEFAULT 'default',
    profile_description VARCHAR(255) DEFAULT 'Hey there, I am using CR_Chat',
    deleted BOOLEAN DEFAULT FALSE,
    tkR varchar(255)
);

-- Tabla contact
DROP TABLE IF EXISTS contact;
CREATE TABLE contact (
    id_usr INT NOT NULL,
    id_contact INT NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100),
    PRIMARY KEY (id_usr, id_contact),
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr),
    FOREIGN KEY (id_contact) REFERENCES usr(id_usr)
);

-- Tabla message
DROP TABLE IF EXISTS message_chat;
CREATE TABLE message_chat (
    id_message INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
    id_usr_sender int NOT NULL,
    id_usr_receiver int NOT NULL,
    shipping_date DATE ,
    shipping_time TIMESTAMP,
    delivery_date DATE,
    delivery_time TIMESTAMP,
    media_content VARCHAR(255),
    text_message BLOB not null, -- encrypted 
    deleted BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN,
    seen BOOLEAN,
    FOREIGN KEY (id_usr_sender) REFERENCES usr(id_usr),
    FOREIGN KEY (id_usr_receiver) REFERENCES usr(id_usr)
);

-- Tabla logs_register_client
DROP TABLE IF EXISTS logs_register_client;
CREATE TABLE logs_register_client (
    id_record INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_usr INT NOT NULL,
    user_db varchar(100), 
    creation_date DATE,
    creation_time TIME,
    last_session_date DATE,
    last_session_time TIME,
    phone_number_change_date DATE,
    deletion_date DATE,
    FOREIGN KEY (id_usr) REFERENCES usr(id_usr)
);

-- Tabla logs_client
DROP TABLE IF EXISTS logs_client;
CREATE TABLE logs_client (
    id_log BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    action_log VARCHAR(100),
    user_affected INT,
    date_log DATE,
    details TEXT,
    FOREIGN KEY (user_affected) REFERENCES usr(id_usr)
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






