<?php
// get_my_room.php - Fetch the room owned by the user
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

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id == 0) {
    die(json_encode(["error" => "Missing user_id"]));
}

$sql = "SELECT * FROM rooms WHERE host_id = $user_id LIMIT 1";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $room = $result->fetch_assoc();
    echo json_encode(["success" => true, "room" => $room]);
} else {
    echo json_encode(["success" => false, "message" => "No room found"]);
}

$conn->close();
?>
