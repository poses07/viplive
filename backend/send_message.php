<?php
// send_message.php - Send a chat message to a room
header("Content-Type: application/json");
require 'db.php';

// Get POST data
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['room_id']) || !isset($data['user_id']) || !isset($data['content'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit;
}

$room_id = intval($data['room_id']);
$user_id = intval($data['user_id']);
$content = $conn->real_escape_string($data['content']);
$type = isset($data['type']) ? $conn->real_escape_string($data['type']) : 'text'; // text, gift, system

// Insert message
$sql = "INSERT INTO chat_messages (room_id, user_id, content, type) VALUES ($room_id, $user_id, '$content', '$type')";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "message_id" => $conn->insert_id]);
} else {
    echo json_encode(["error" => "Error sending message: " . $conn->error]);
}

$conn->close();
?>
