<?php
// get_dms.php - Fetch conversation between two users
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['user1_id']) || !isset($_GET['user2_id'])) {
    echo json_encode(["error" => "User IDs are required"]);
    exit();
}

$user1_id = intval($_GET['user1_id']);
$user2_id = intval($_GET['user2_id']);
$after_id = isset($_GET['after_id']) ? intval($_GET['after_id']) : 0;

$sql = "SELECT id, sender_id, receiver_id, content, created_at 
        FROM direct_messages 
        WHERE ((sender_id = $user1_id AND receiver_id = $user2_id) 
           OR (sender_id = $user2_id AND receiver_id = $user1_id))
        AND id > $after_id
        ORDER BY created_at ASC 
        LIMIT 50";

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
