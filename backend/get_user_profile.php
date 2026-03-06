<?php
// get_user_profile.php - Fetch detailed user profile
header("Content-Type: application/json");
require 'db.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
// Current logged in user (to check if following)
$current_user_id = isset($_GET['current_user_id']) ? intval($_GET['current_user_id']) : 0;

if ($user_id <= 0) {
    echo json_encode(["error" => "Invalid user ID"]);
    exit;
}

// Fetch basic user info
$sql = "SELECT id, username, email, avatar_url, created_at FROM users WHERE id = $user_id";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // Fetch stats (Mock data for now, or real counts if tables exist)
    // Assuming tables: followers, following, posts
    // For MVP, we'll return mock stats but structure it for real data later
    
    $user['followers_count'] = 1250; // Mock
    $user['following_count'] = 45;   // Mock
    $user['level'] = 12;             // Mock
    $user['bio'] = "Music lover 🎵 | Travel enthusiast ✈️ | Live streamer 📹"; // Mock
    
    // Check if current user is following this user
    $user['is_following'] = false; // Default
    if ($current_user_id > 0) {
        // Real check would be: SELECT * FROM followers WHERE follower_id = $current_user_id AND following_id = $user_id
        // For MVP, mock random boolean based on ID parity
        $user['is_following'] = ($user_id % 2 == 0); 
    }
    
    // Fetch recent posts (Mock)
    $user['posts'] = [
        ['id' => 1, 'image_url' => 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963', 'likes' => 120],
        ['id' => 2, 'image_url' => 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9', 'likes' => 85],
        ['id' => 3, 'image_url' => 'https://images.unsplash.com/photo-1511367461989-f85a21fda167', 'likes' => 210],
    ];

    echo json_encode($user);
} else {
    echo json_encode(["error" => "User not found"]);
}

$conn->close();
?>
