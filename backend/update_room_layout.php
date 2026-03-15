<?php
// update_room_layout.php - Update the number of seats in a room
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['room_id']) || !isset($data['seat_count'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$room_id = intval($data['room_id']);
$new_count = intval($data['seat_count']);

// Validate seat count
$allowed_counts = [5, 10, 20];
if (!in_array($new_count, $allowed_counts)) {
    echo json_encode(["error" => "Invalid seat count. Allowed: 5, 10, 20"]);
    exit();
}

// Fetch current seats
$sql = "SELECT seats FROM rooms WHERE id = $room_id";
$result = $conn->query($sql);

if (!$result || $result->num_rows == 0) {
    echo json_encode(["error" => "Room not found"]);
    exit();
}

$row = $result->fetch_assoc();
$seats_json = $row['seats'];
$seats = ($seats_json) ? json_decode($seats_json, true) : [];

// Initialize if empty
if (empty($seats)) {
    for ($i = 0; $i < 10; $i++) { // Default was 10
        $seats[] = ["index" => $i, "user_id" => null, "is_locked" => false];
    }
}

$current_count = count($seats);

if ($new_count == $current_count) {
    echo json_encode(["success" => true, "message" => "Seat count unchanged"]);
    exit();
}

if ($new_count > $current_count) {
    // Add new seats
    for ($i = $current_count; $i < $new_count; $i++) {
        $seats[] = ["index" => $i, "user_id" => null, "is_locked" => false];
    }
} else {
    // Reduce seats
    // Check if any users are in the seats to be removed
    for ($i = $new_count; $i < $current_count; $i++) {
        if (isset($seats[$i]['user_id']) && $seats[$i]['user_id'] != null) {
            echo json_encode(["error" => "Cannot reduce seats. Seat index $i is occupied."]);
            exit();
        }
    }
    // Slice array
    $seats = array_slice($seats, 0, $new_count);
}

// Save back to DB
$new_seats_json = json_encode($seats);
$update_sql = "UPDATE rooms SET seats = '$new_seats_json' WHERE id = $room_id";

if ($conn->query($update_sql)) {
    echo json_encode(["success" => true, "seat_count" => $new_count]);
} else {
    echo json_encode(["error" => "Failed to update room layout"]);
}

$conn->close();
?>
