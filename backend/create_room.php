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

// Check if user already has a room
$check_sql = "SELECT id FROM rooms WHERE host_id = $host_id LIMIT 1";
$check_result = $conn->query($check_sql);

if ($check_result && $check_result->num_rows > 0) {
    // Update existing room
    $row = $check_result->fetch_assoc();
    $room_id = $row['id'];
    
    $update_sql = "UPDATE rooms SET title='$title', tags='$tags', image_url='$image_url', is_live=1 WHERE id=$room_id";
    
    if ($conn->query($update_sql) === TRUE) {
        // Ensure host is in seat 0 using JSON
        // First fetch current seats
        $get_seats_sql = "SELECT seats FROM rooms WHERE id = $room_id";
        $result = $conn->query($get_seats_sql);
        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $seats = json_decode($row['seats'], true);
            
            // If seats column is null (migration case), initialize it
            if ($seats === null) {
                $seats = [];
                for ($i = 0; $i < 10; $i++) {
                    $seats[] = ["index" => $i, "user_id" => null, "is_locked" => false];
                }
            }
            
            // Force host to seat 0
            $seats[0]['user_id'] = $host_id;
            
            $new_seats_json = json_encode($seats);
            $update_seats_sql = "UPDATE rooms SET seats = '$new_seats_json' WHERE id = $room_id";
            $conn->query($update_seats_sql);
        }
        
        echo json_encode(["success" => true, "room_id" => $room_id]);
    } else {
        echo json_encode(["error" => "Failed to update existing room: " . $conn->error]);
    }
} else {
    // Insert New Room
    $sql = "INSERT INTO rooms (host_id, title, tags, image_url, viewer_count, is_live, created_at) 
            VALUES ($host_id, '$title', '$tags', '$image_url', 0, 1, NOW())";

    if ($conn->query($sql) === TRUE) {
        $room_id = $conn->insert_id;
        
        // Initialize 10 seats as JSON
    $seats = [];
    for ($i = 0; $i < 10; $i++) {
        // Auto-assign Host to Seat 0
        $uid = ($i == 0) ? $host_id : null;
        $seats[] = [
            "index" => $i,
            "user_id" => $uid,
            "is_locked" => false
        ];
    }
    
    $seats_json = json_encode($seats);
    $update_json_sql = "UPDATE rooms SET seats = '$seats_json' WHERE id = $room_id";
    
    if ($conn->query($update_json_sql) === TRUE) {
        echo json_encode(["success" => true, "room_id" => $room_id]);
    } else {
        echo json_encode(["error" => "Room created but failed to save seats JSON: " . $conn->error]);
    }
    } else {
        echo json_encode(["error" => "SQL Error: " . $conn->error, "sql" => $sql]);
    }
}

$conn->close();
?>