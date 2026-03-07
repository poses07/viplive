<?php
// migrate.php - Add missing columns to users table
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = "localhost";
$username = "d045d473";
$password = "jHJRCDftddPi4h6Yxqqw";
$database = "d045d473";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully.<br>";

// SQL to add missing columns
$sql_commands = [
    // Users Table
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(255) NOT NULL DEFAULT ''",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(10)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(50)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS dob DATE",
    
    // Rooms Table
    "ALTER TABLE rooms ADD COLUMN IF NOT EXISTS tags VARCHAR(255)",
    "ALTER TABLE rooms ADD COLUMN IF NOT EXISTS image_url VARCHAR(255)",
    "ALTER TABLE rooms ADD COLUMN IF NOT EXISTS viewer_count INT DEFAULT 0",
    "ALTER TABLE rooms ADD COLUMN IF NOT EXISTS is_live BOOLEAN DEFAULT TRUE"
];

foreach ($sql_commands as $sql) {
    if ($conn->query($sql) === TRUE) {
        echo "Success: $sql <br>";
    } else {
        echo "Error: " . $conn->error . " (Query: $sql)<br>";
    }
}

echo "Migration completed.";
$conn->close();
?>