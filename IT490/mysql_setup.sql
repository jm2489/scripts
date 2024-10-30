-- Create rabbit user with access rights to logindb database
CREATE USER IF NOT EXISTS 'rabbit'@'%' IDENTIFIED BY 'rabbitIT490!';
GRANT ALL PRIVILEGES ON logindb.* TO 'rabbit'@'%' WITH GRANT OPTION;

-- Create the logindb database if it doesn't exist
CREATE DATABASE IF NOT EXISTS logindb;

USE logindb;

-- Drop Table users if it exists
-- This is needed if rerunning the it490 script to start from baseline again
DROP TABLE IF EXISTS users;

-- Create the users table
CREATE TABLE IF NOT EXISTS users (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    last_login BIGINT NULL,
    PRIMARY KEY (id)
);

-- Drop Table sessions if it exists
-- Same thing from earlier
DROP TABLE IF EXISTS sessions;

-- Create the sessions table
CREATE TABLE IF NOT EXISTS sessions (
    username VARCHAR(255) NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    created_at BIGINT DEFAULT (unix_timestamp()),
    expire_date BIGINT NOT NULL,
    PRIMARY KEY (username),
    UNIQUE(session_token)
);


-- Insert a default user and hashed password into the users table.. Will remove once in prod.
INSERT INTO users (username,password)
VALUES ('steve', '$2y$10$iPNDJKXKUiT8OSYyXIACw.lTGJzD1CekSMfzW3o8k6yKWbyKHmLUq');

FLUSH PRIVILEGES;
