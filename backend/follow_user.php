<?php
// follow_user.php - Toggle follow status
header("Content-Type: application/json");
require 'db.php';

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['follower_id']) || !isset($input['following_id'])) {
    echo json_encode(["success" => false, "message" => "Missing parameters"]);
    exit();
}

$follower_id = intval($input['follower_id']);
$following_id = intval($input['following_id']);

if ($follower_id == $following_id) {
    echo json_encode(["success" => false, "message" => "Cannot follow yourself"]);
    exit();
}

// Check if already following
$check_sql = "SELECT id FROM follows WHERE follower_id = $follower_id AND following_id = $following_id";
$result = $conn->query($check_sql);

if ($result->num_rows > 0) {
    // Already following, so UNFOLLOW
    $delete_sql = "DELETE FROM follows WHERE follower_id = $follower_id AND following_id = $following_id";
    if ($conn->query($delete_sql)) {
        echo json_encode(["success" => true, "is_following" => false, "message" => "Unfollowed"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error unfollowing"]);
    }
} else {
    // Not following, so FOLLOW
    $insert_sql = "INSERT INTO follows (follower_id, following_id) VALUES ($follower_id, $following_id)";
    if ($conn->query($insert_sql)) {
        echo json_encode(["success" => true, "is_following" => true, "message" => "Followed"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error following"]);
    }
}

$conn->close();
?>
