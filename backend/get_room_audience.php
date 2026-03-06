<?php
// get_room_audience.php - Fetch active audience in a room
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['room_id'])) {
    echo json_encode(["error" => "Missing room_id"]);
    exit();
}

$room_id = intval($_GET['room_id']);
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;

$sql = "SELECT u.id, u.username, u.avatar_url, u.level 
        FROM room_audience ra 
        JOIN users u ON ra.user_id = u.id 
        WHERE ra.room_id = $room_id 
        ORDER BY ra.joined_at DESC 
        LIMIT $limit";

$result = $conn->query($sql);

$audience = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $audience[] = $row;
    }
}

echo json_encode($audience);
$conn->close();
?>
