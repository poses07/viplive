<?php
// get_messages.php - Fetch chat messages for a room
header("Content-Type: application/json");
require 'db.php';

$room_id = isset($_GET['room_id']) ? intval($_GET['room_id']) : 0;
// To get only new messages (polling)
$after_id = isset($_GET['after_id']) ? intval($_GET['after_id']) : 0;

if ($room_id <= 0) {
    echo json_encode(["error" => "Invalid room ID"]);
    exit;
}

$sql = "SELECT cm.id, cm.content, cm.type, cm.created_at, u.id as user_id, u.username, u.avatar_url 
        FROM chat_messages cm
        JOIN users u ON cm.user_id = u.id
        WHERE cm.room_id = $room_id";

if ($after_id > 0) {
    $sql .= " AND cm.id > $after_id";
}

$sql .= " ORDER BY cm.created_at ASC LIMIT 50"; // Limit to 50 latest messages

$result = $conn->query($sql);

$messages = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $messages[] = $row;
    }
}

echo json_encode($messages);

$conn->close();
?>
