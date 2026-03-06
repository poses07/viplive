-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS viplive_db;
USE viplive_db;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    avatar_url TEXT,
    level INT DEFAULT 1,
    diamonds INT DEFAULT 0, -- Virtual currency
    is_host BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rooms Table (Live & Chat Party)
CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL,
    title VARCHAR(100),
    cover_image TEXT,
    tag ENUM('Chat', 'Music', 'Friends', 'CP') DEFAULT 'Chat',
    type ENUM('live', 'party') DEFAULT 'live',
    viewer_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Room Seats Table (For Chat Party - 10 Seats)
CREATE TABLE IF NOT EXISTS room_seats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    seat_index INT NOT NULL CHECK (seat_index BETWEEN 0 AND 9),
    user_id INT DEFAULT NULL, -- NULL means empty seat
    is_locked BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(room_id, seat_index) -- Each seat is unique per room
);

-- Gifts Table
CREATE TABLE IF NOT EXISTS gifts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price INT NOT NULL,
    icon_url TEXT,
    category VARCHAR(20) DEFAULT 'popular'
);

-- Transactions/Gift History
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL, -- Can be a host or user
    room_id INT,
    gift_id INT NOT NULL,
    amount INT NOT NULL, -- Price at time of sending
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (gift_id) REFERENCES gifts(id)
);

-- Insert Mock Data
INSERT INTO users (username, avatar_url, level, diamonds, is_host) VALUES 
('Alexander', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', 5, 1000, TRUE),
('GuestUser1', 'https://i.pravatar.cc/150?img=1', 1, 50, FALSE),
('GuestUser2', 'https://i.pravatar.cc/150?img=2', 2, 120, FALSE);

INSERT INTO gifts (name, price, category) VALUES 
('Rose', 1, 'popular'),
('Heart', 5, 'popular'),
('Car', 500, 'luxury'),
('Castle', 1000, 'luxury');
