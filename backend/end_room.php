<?php
// end_room.php - End a live room (Host only)
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

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!isset($data['room_id'])) {
    die(json_encode(["error" => "Missing room_id"]));
}

$room_id = (int)$data['room_id'];

// Update room status to offline
$sql = "UPDATE rooms SET is_active = 0 WHERE id = $room_id";

if ($conn->query($sql) === TRUE) {
    // Also clear seats if it's a party room
    $clear_seats = "UPDATE room_seats SET user_id = NULL, is_locked = 0 WHERE room_id = $room_id";
    $conn->query($clear_seats);
    
    echo json_encode(["success" => true, "message" => "Room ended successfully"]);
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error]);
}

$conn->close();
?>