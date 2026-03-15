<?php
// update_seat.php - Lock/Unlock or Sit/Leave a seat
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['room_id']) || !isset($data['seat_index']) || !isset($data['action'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$room_id = intval($data['room_id']);
$seat_index = intval($data['seat_index']);
$action = $data['action']; // 'sit', 'leave', 'lock', 'unlock'
$user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;

// Fetch current seats JSON
$fetch_sql = "SELECT seats FROM rooms WHERE id = $room_id";
$result = $conn->query($fetch_sql);

if (!$result || $result->num_rows == 0) {
    echo json_encode(["error" => "Room not found"]);
    exit();
}

$row = $result->fetch_assoc();
$seats_json = $row['seats'];
$seats = ($seats_json) ? json_decode($seats_json, true) : [];

// If seats array is empty/null, initialize it (migration fallback)
if (empty($seats)) {
    for ($i = 0; $i < 10; $i++) {
        $seats[] = ["index" => $i, "user_id" => null, "is_locked" => false];
    }
}

// Find target seat
$target_seat = &$seats[$seat_index]; // Reference for direct modification

// Validate index
if (!isset($target_seat)) {
    echo json_encode(["error" => "Invalid seat index"]);
    exit();
}

switch ($action) {
    case 'sit':
        if ($user_id == 0) {
            echo json_encode(["error" => "User ID required for sitting"]);
            exit();
        }
        
        // Check if user is already sitting anywhere in this room
        foreach ($seats as $s) {
            if ($s['user_id'] == $user_id) {
                echo json_encode(["error" => "User already in a seat (Index: " . $s['index'] . ")"]);
                exit();
            }
        }
        
        // Check if seat is empty and unlocked
        if ($target_seat['is_locked']) {
            echo json_encode(["error" => "Seat is locked"]);
            exit();
        }
        if ($target_seat['user_id'] != null) {
            echo json_encode(["error" => "Seat is occupied"]);
            exit();
        }

        // Sit
        $target_seat['user_id'] = $user_id;
        break;

    case 'leave':
        // Only allow leaving if it's the user or maybe host (logic for host not added here yet)
        // For now, assume validation is done by frontend or user_id match
        // Ideally we should check if requesting user is the one sitting
        
        $target_seat['user_id'] = null;
        break;

    case 'lock':
        $target_seat['is_locked'] = true;
        break;

    case 'unlock':
        $target_seat['is_locked'] = false;
        break;

    default:
        echo json_encode(["error" => "Invalid action"]);
        exit();
}

// Save back to DB
$new_seats_json = json_encode($seats);
$update_sql = "UPDATE rooms SET seats = '$new_seats_json' WHERE id = $room_id";

if ($conn->query($update_sql) === TRUE) {
    echo json_encode(["success" => true, "message" => "Seat updated successfully"]);
} else {
    echo json_encode(["error" => "Error updating seat: " . $conn->error]);
}

$conn->close();
?>