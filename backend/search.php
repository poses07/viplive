<?php
// search.php - Search for users and rooms
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['q'])) {
    echo json_encode(["error" => "Query is required"]);
    exit();
}

$query = $conn->real_escape_string($_GET['q']);
$type = isset($_GET['type']) ? $_GET['type'] : 'all'; // 'users', 'rooms', 'all'

$results = [
    'users' => [],
    'rooms' => []
];

// Search Users
if ($type === 'all' || $type === 'users') {
    $user_sql = "SELECT id, username, avatar_url, level FROM users 
                 WHERE username LIKE '%$query%' LIMIT 20";
    $user_result = $conn->query($user_sql);
    if ($user_result->num_rows > 0) {
        while($row = $user_result->fetch_assoc()) {
            $results['users'][] = $row;
        }
    }
}

// Search Rooms
if ($type === 'all' || $type === 'rooms') {
    $room_sql = "SELECT r.id, r.title, r.room_type, r.tag, r.cover_image, r.viewer_count,
                 u.username as host_name, u.avatar_url as host_avatar
                 FROM rooms r
                 JOIN users u ON r.host_id = u.id
                 WHERE r.is_active = 1 AND (r.title LIKE '%$query%' OR u.username LIKE '%$query%')
                 LIMIT 20";
    $room_result = $conn->query($room_sql);
    if ($room_result->num_rows > 0) {
        while($row = $room_result->fetch_assoc()) {
            $results['rooms'][] = $row;
        }
    }
}

echo json_encode($results);
$conn->close();
?>
