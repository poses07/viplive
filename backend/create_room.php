<?php
// create_room.php - Create a new room
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

// Set charset to handle special characters and emojis
$conn->set_charset("utf8mb4");

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    die(json_encode(["error" => "Invalid JSON input", "raw_input" => $input]));
}

if (!isset($data['host_id']) || !isset($data['title'])) {
    die(json_encode(["error" => "Missing host_id or title"]));
}

$host_id = (int)$data['host_id'];
$title = $conn->real_escape_string($data['title']);
$tags = isset($data['tags']) ? $conn->real_escape_string($data['tags']) : '';
$image_url = isset($data['image_url']) ? $conn->real_escape_string($data['image_url']) : '';

// Insert Room
$sql = "INSERT INTO rooms (host_id, title, tags, image_url, viewer_count, is_live, created_at) 
        VALUES ($host_id, '$title', '$tags', '$image_url', 0, 1, NOW())";

if ($conn->query($sql) === TRUE) {
    $room_id = $conn->insert_id;
    
    // Initialize 10 seats (0-9)
    $seat_values = [];
    for ($i = 0; $i < 10; $i++) {
        // Auto-assign Host to Seat 0
        $uid = ($i == 0) ? $host_id : "NULL";
        $seat_values[] = "($room_id, $i, $uid, 0)";
    }
    
    // Batch insert seats
    $seat_sql = "INSERT INTO room_seats (room_id, seat_index, user_id, is_locked) VALUES " . implode(", ", $seat_values);
    
    if ($conn->query($seat_sql) === TRUE) {
        echo json_encode(["success" => true, "room_id" => $room_id]);
    } else {
        // If seat creation fails, we should ideally rollback/delete the room, but for now just report error
        echo json_encode(["error" => "Room created but failed to create seats: " . $conn->error]);
    }
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error, "sql" => $sql]);
}

$conn->close();
?>