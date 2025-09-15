-- insert-demo-data.sql
-- Script to insert demo data into users table

USE demo_db;

-- Clear existing data (optional)
-- TRUNCATE TABLE users;

-- Insert demo users
INSERT INTO users (nom, email) VALUES
('Mouad FIFEL', 'mouad.fifel@email.ma'),
('Khalid FIFEL', 'khalid.fifel@email.ma'),
('Brahim FIFEL', 'brahim.fifel@email.ma'),
('Bilal FIFEL', 'bilal.fifel@email.ma')
ON DUPLICATE KEY UPDATE 
    nom = VALUES(nom),
    date_creation = CURRENT_TIMESTAMP;

-- Verify data insertion
SELECT COUNT(*) as total_users FROM users;
SELECT * FROM users ORDER BY date_creation DESC;