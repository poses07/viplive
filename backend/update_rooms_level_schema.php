<?php
require 'db.php';

// Add level and points columns to rooms table
$sql = "ALTER TABLE rooms 
        ADD COLUMN IF NOT EXISTS level INT DEFAULT 1,
        ADD COLUMN IF NOT EXISTS points INT DEFAULT 0";

if ($conn->query($sql) === TRUE) {
    echo "Rooms table updated successfully";
} else {
    echo "Error updating table: " . $conn->error;
}

$conn->close();
?>
