<?php
// get_room_seats.php - Fetch seats for a specific room
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['room_id'])) {
    echo json_encode(["error" => "Room ID is required"]);
    exit();
}

$room_id = intval($_GET['room_id']);

// Join with users table to get seat user details
$sql = "SELECT rs.seat_index, rs.is_locked, u.id as user_id, u.username, u.avatar_url 
        FROM room_seats rs 
        LEFT JOIN users u ON rs.user_id = u.id 
        WHERE rs.room_id = $room_id 
        ORDER BY rs.seat_index ASC";

$result = $conn->query($sql);

$seats = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $seats[] = $row;
    }
}

echo json_encode($seats);
$conn->close();
?>