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

$sql = "";

switch ($action) {
    case 'sit':
        if ($user_id == 0) {
            echo json_encode(["error" => "User ID required for sitting"]);
            exit();
        }
        // Check if user is already sitting in this room
        $check_sql = "SELECT id FROM room_seats WHERE room_id = $room_id AND user_id = $user_id";
        $check_result = $conn->query($check_sql);
        if ($check_result->num_rows > 0) {
            echo json_encode(["error" => "User already in a seat"]);
            exit();
        }
        
        // Check if seat is empty and unlocked
        $seat_check = "SELECT is_locked, user_id FROM room_seats WHERE room_id = $room_id AND seat_index = $seat_index";
        $seat_result = $conn->query($seat_check);
        if ($seat_result->num_rows > 0) {
            $seat = $seat_result->fetch_assoc();
            if ($seat['is_locked']) {
                echo json_encode(["error" => "Seat is locked"]);
                exit();
            }
            if ($seat['user_id'] != null) {
                echo json_encode(["error" => "Seat is occupied"]);
                exit();
            }
        }

        $sql = "UPDATE room_seats SET user_id = $user_id WHERE room_id = $room_id AND seat_index = $seat_index";
        break;

    case 'leave':
        $sql = "UPDATE room_seats SET user_id = NULL WHERE room_id = $room_id AND seat_index = $seat_index";
        break;

    case 'lock':
        $sql = "UPDATE room_seats SET is_locked = TRUE WHERE room_id = $room_id AND seat_index = $seat_index";
        break;

    case 'unlock':
        $sql = "UPDATE room_seats SET is_locked = FALSE WHERE room_id = $room_id AND seat_index = $seat_index";
        break;

    default:
        echo json_encode(["error" => "Invalid action"]);
        exit();
}

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "message" => "Seat updated successfully"]);
} else {
    echo json_encode(["error" => "Error updating seat: " . $conn->error]);
}

$conn->close();
?>