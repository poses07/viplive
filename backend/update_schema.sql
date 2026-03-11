-- Update Users Table
ALTER TABLE users ADD COLUMN IF NOT EXISTS beans INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(10) DEFAULT 'unknown';
ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(50) DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS dob DATE DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(255) NOT NULL DEFAULT ''; -- Should be there but just in case

-- Create Chat Messages Table (Replaces 'messages' if it existed)
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    type VARCHAR(20) DEFAULT 'text', -- 'text', 'gift', 'system'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Update Rooms Table
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS type ENUM('live', 'party') DEFAULT 'live';
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Create Transactions Table if not exists
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    room_id INT,
    gift_id INT NOT NULL,
    amount INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (gift_id) REFERENCES gifts(id)
);

-- Ensure Gifts Table exists and has data
CREATE TABLE IF NOT EXISTS gifts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price INT NOT NULL,
    icon_url TEXT,
    category VARCHAR(20) DEFAULT 'popular'
);

-- Insert default gifts if table is empty (Optional check logic omitted for pure SQL, assume user runs this once)
-- INSERT IGNORE INTO gifts (id, name, price, category) VALUES 
-- (1, 'Rose', 1, 'popular'),
-- (2, 'Heart', 5, 'popular'),
-- (3, 'Car', 500, 'luxury'),
-- (4, 'Castle', 1000, 'luxury');
