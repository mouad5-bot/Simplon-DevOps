-- create-table.sql
-- Script to create the users table

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS demo_db;

-- Use the database
USE demo_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_date_creation (date_creation)
);

-- Verify table creation
DESCRIBE users;