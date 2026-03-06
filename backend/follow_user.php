<?php
// follow_user.php - Toggle follow status
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['follower_id']) || !isset($data['following_id'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$follower_id = intval($data['follower_id']);
$following_id = intval($data['following_id']);

if ($follower_id == $following_id) {
    echo json_encode(["error" => "Cannot follow yourself"]);
    exit();
}

// Check if already following
$check_sql = "SELECT id FROM follows WHERE follower_id = $follower_id AND following_id = $following_id";
$result = $conn->query($check_sql);

if ($result->num_rows > 0) {
    // Unfollow
    $sql = "DELETE FROM follows WHERE follower_id = $follower_id AND following_id = $following_id";
    $is_following = false;
    $action = "unfollowed";
} else {
    // Follow
    $sql = "INSERT INTO follows (follower_id, following_id) VALUES ($follower_id, $following_id)";
    $is_following = true;
    $action = "followed";
}

if ($conn->query($sql) === TRUE) {
    echo json_encode([
        "success" => true,
        "is_following" => $is_following,
        "message" => "Successfully $action user"
    ]);
} else {
    echo json_encode(["error" => "Database error: " . $conn->error]);
}

$conn->close();
?>
