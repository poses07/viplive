<?php
// get_room_seats.php - Fetch seats for a room
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

// Check for room_id in GET or POST
$room_id = 0;

if (isset($_GET['room_id'])) {
    $room_id = (int)$_GET['room_id'];
} else {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    if (isset($data['room_id'])) {
        $room_id = (int)$data['room_id'];
    }
}

if ($room_id == 0) {
    die(json_encode(["error" => "Missing room_id"]));
}

// Check if room is live
$check_sql = "SELECT is_active FROM rooms WHERE id = $room_id";
$check_result = $conn->query($check_sql);

if ($check_result && $check_result->num_rows > 0) {
    $room = $check_result->fetch_assoc();
    if ($room['is_active'] == 0) {
        http_response_code(410); // Gone
        echo json_encode(["error" => "Room ended"]);
        exit();
    }
} else {
    http_response_code(404);
    echo json_encode(["error" => "Room not found"]);
    exit();
}

// Fetch seats with user details
$sql = "SELECT rs.seat_index, rs.is_locked, u.id as user_id, u.username, u.avatar_url 
        FROM room_seats rs
        LEFT JOIN users u ON rs.user_id = u.id
        WHERE rs.room_id = $room_id
        ORDER BY rs.seat_index ASC";

$result = $conn->query($sql);

$seats = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $seats[] = $row;
    }
    echo json_encode($seats);
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error]);
}

$conn->close();
?>