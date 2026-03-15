<?php
// get_room_details.php - Fetch single room details
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['room_id'])) {
    echo json_encode(["error" => "Missing room_id"]);
    exit();
}

$room_id = intval($_GET['room_id']);

$sql = "SELECT r.id, r.title, r.tags, r.image_url, r.viewer_count, r.is_live, r.level, r.points,
               u.username as host_name, u.avatar_url as host_avatar, u.id as host_id
        FROM rooms r
        JOIN users u ON r.host_id = u.id
        WHERE r.id = $room_id";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    echo json_encode($result->fetch_assoc());
} else {
    echo json_encode(["error" => "Room not found"]);
}

$conn->close();
?>
