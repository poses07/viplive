<?php
// join_room.php - Record user entering a room
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['room_id'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$user_id = intval($data['user_id']);
$room_id = intval($data['room_id']);

// Insert or update timestamp if already there
$sql = "INSERT INTO room_audience (room_id, user_id, joined_at) VALUES ($room_id, $user_id, NOW()) 
        ON DUPLICATE KEY UPDATE joined_at = NOW()";

if ($conn->query($sql) === TRUE) {
    // Update room active count
    $count_sql = "UPDATE rooms SET viewer_count = (SELECT COUNT(*) FROM room_audience WHERE room_id = $room_id) WHERE id = $room_id";
    $conn->query($count_sql);
    
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["error" => "Error joining room: " . $conn->error]);
}

$conn->close();
?>
