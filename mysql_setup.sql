-- Create a new MySQL user with access from any IP
CREATE USER 'rabbit'@'%' IDENTIFIED BY 'rabbitIT490!';

-- Grant all privileges to the user on the logindb database
GRANT ALL PRIVILEGES ON logindb.* TO 'rabbit'@'%' WITH GRANT OPTION;

-- Create the logindb database if it doesn't exist
CREATE DATABASE IF NOT EXISTS logindb;

-- Use the logindb database
USE logindb;

-- Create the users table with the specified schema
CREATE TABLE IF NOT EXISTS users (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    last_login TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Apply the changes immediately
FLUSH PRIVILEGES;
