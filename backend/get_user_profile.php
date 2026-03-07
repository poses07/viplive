<?php
// get_user_profile.php - Fetch user profile data
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
$viewer_id = isset($_GET['viewer_id']) ? intval($_GET['viewer_id']) : 0;

if ($user_id == 0) {
    echo json_encode(["error" => "User ID is required"]);
    exit();
}

// Fetch user data
$sql = "SELECT id, username, avatar_url, level, diamonds, beans, bio, created_at,
        (SELECT COUNT(*) FROM follows WHERE following_id = users.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = users.id) as following_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $viewer_id AND following_id = users.id) as is_following
        FROM users WHERE id = $user_id";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    $user['is_following'] = (bool)$user['is_following'];
    echo json_encode($user);
} else {
    echo json_encode(["error" => "User not found"]);
}

$conn->close();
?>
