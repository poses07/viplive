<?php
// get_rooms.php - Fetch active live rooms
header("Content-Type: application/json");
require 'db.php';

// Optional: Filter by type (live, party, etc.)
$type = isset($_GET['type']) ? $_GET['type'] : null;

$sql = "SELECT r.id, r.title, r.room_type, r.tag, r.cover_image, r.created_at, 
               u.username as host_name, u.avatar_url as host_avatar
        FROM rooms r
        JOIN users u ON r.host_id = u.id
        WHERE r.is_active = 1";

if ($type) {
    $sql .= " AND r.room_type = '" . $conn->real_escape_string($type) . "'";
}

$sql .= " ORDER BY r.created_at DESC";

$result = $conn->query($sql);

$rooms = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $rooms[] = $row;
    }
}

echo json_encode($rooms);

$conn->close();
?>
