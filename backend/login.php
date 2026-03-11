<?php
// login.php - User login
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['username']) || !isset($data['password'])) {
    echo json_encode(["error" => "Missing username or password"]);
    exit();
}

$username = $conn->real_escape_string($data['username']);
$password = $data['password'];

$sql = "SELECT id, username, password, avatar_url, level, diamonds, beans FROM users WHERE username = '$username'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    if (password_verify($password, $user['password'])) {
        // Auto-fix balance for dev: If balance is low, top it up
        // Temporarily increased for testing
        if ($user['diamonds'] < 10000) {
            $new_balance = 50000;
            $uid = $user['id'];
            $conn->query("UPDATE users SET diamonds = $new_balance WHERE id = $uid");
            $user['diamonds'] = $new_balance; // Update local variable for response
        }

        // Remove password from response
        unset($user['password']);
        
        echo json_encode([
            "success" => true,
            "user" => $user
        ]);
    } else {
        echo json_encode(["error" => "Invalid password"]);
    }
} else {
    echo json_encode(["error" => "User not found"]);
}

$conn->close();
?>
