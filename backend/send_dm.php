<?php
// send_dm.php - Send a direct message
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['sender_id']) || !isset($data['receiver_id']) || !isset($data['content'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$sender_id = intval($data['sender_id']);
$receiver_id = intval($data['receiver_id']);
$content = $conn->real_escape_string($data['content']);

$sql = "INSERT INTO direct_messages (sender_id, receiver_id, content, created_at) 
        VALUES ($sender_id, $receiver_id, '$content', NOW())";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["error" => "Error sending message: " . $conn->error]);
}

$conn->close();
?>
