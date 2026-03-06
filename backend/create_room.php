<?php
// create_room.php - Create a new Live or Chat Party room
header("Content-Type: application/json");
require 'db.php';

// Get POST data
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['host_id']) || !isset($data['title']) || !isset($data['type'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$host_id = intval($data['host_id']);
$title = $conn->real_escape_string($data['title']);
$type = $conn->real_escape_string($data['type']); // 'live' or 'party'
$tag = isset($data['tag']) ? $conn->real_escape_string($data['tag']) : 'Chat';
$cover_image = isset($data['cover_image']) ? $conn->real_escape_string($data['cover_image']) : '';

// 1. Deactivate any existing active rooms for this host
$update_sql = "UPDATE rooms SET is_active = FALSE WHERE host_id = $host_id AND is_active = TRUE";
$conn->query($update_sql);

// 2. Create new room
$sql = "INSERT INTO rooms (host_id, title, type, tag, cover_image, is_active) VALUES ($host_id, '$title', '$type', '$tag', '$cover_image', TRUE)";

if ($conn->query($sql) === TRUE) {
    $room_id = $conn->insert_id;
    
    // 3. If it's a Chat Party, initialize 10 seats
    if ($type === 'party') {
        // Seat 0 is for Host (locked by default until they take it)
        $seat_values = [];
        for ($i = 0; $i < 10; $i++) {
            // Index 0 is host seat, others empty
            $user_id = ($i == 0) ? $host_id : "NULL"; 
            $seat_values[] = "($room_id, $i, $user_id)";
        }
        $seat_sql = "INSERT INTO room_seats (room_id, seat_index, user_id) VALUES " . implode(", ", $seat_values);
        $conn->query($seat_sql);
    }

    echo json_encode([
        "success" => true,
        "message" => "Room created successfully",
        "room_id" => $room_id,
        "type" => $type
    ]);
} else {
    echo json_encode(["error" => "Error creating room: " . $conn->error]);
}

$conn->close();
?>