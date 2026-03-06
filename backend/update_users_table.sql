-- Add password, gender, country, dob columns to users table
ALTER TABLE users ADD COLUMN password VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN gender VARCHAR(20) DEFAULT 'unknown';
ALTER TABLE users ADD COLUMN country VARCHAR(100) DEFAULT '';
ALTER TABLE users ADD COLUMN dob DATE DEFAULT NULL;
