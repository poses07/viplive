<?php
// get_rooms.php - Fetch active rooms
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json");

// Direct DB Connection
$host = "localhost";
$username = "d045d473";
$password = "jHJRCDftddPi4h6Yxqqw";
$database = "d045d473";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

// Set charset
$conn->set_charset("utf8mb4");

// Fetch active rooms (is_live = 1) with host details
$sql = "SELECT r.id, r.title, r.tags, r.image_url, r.viewer_count, r.is_live, 
               u.username as host_name, u.avatar_url as host_avatar
        FROM rooms r
        JOIN users u ON r.host_id = u.id
        WHERE r.is_live = 1
        ORDER BY r.created_at DESC";

$result = $conn->query($sql);

$rooms = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $rooms[] = $row;
    }
    echo json_encode($rooms);
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error]);
}

$conn->close();
?>
