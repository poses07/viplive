<?php
// register.php - Register a new user
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['username']) || !isset($data['password'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$username = $conn->real_escape_string($data['username']);
$password = password_hash($data['password'], PASSWORD_DEFAULT);
$gender = isset($data['gender']) ? $conn->real_escape_string($data['gender']) : 'unknown';
$country = isset($data['country']) ? $conn->real_escape_string($data['country']) : '';
$dob = isset($data['dob']) ? $conn->real_escape_string($data['dob']) : '';

// Check if username exists
$check_sql = "SELECT id FROM users WHERE username = '$username'";
$check_result = $conn->query($check_sql);

if ($check_result->num_rows > 0) {
    echo json_encode(["error" => "Username already exists"]);
    exit();
}

$sql = "INSERT INTO users (username, password, gender, country, dob, level, diamonds, beans, created_at) 
        VALUES ('$username', '$password', '$gender', '$country', '$dob', 1, 0, 0, NOW())";

if ($conn->query($sql) === TRUE) {
    $user_id = $conn->insert_id;
    echo json_encode([
        "success" => true,
        "user" => [
            "id" => $user_id,
            "username" => $username,
            "level" => 1,
            "diamonds" => 0,
            "beans" => 0,
            "avatar_url" => "" // Default avatar logic can be handled here or frontend
        ]
    ]);
} else {
    echo json_encode(["error" => "Error registering user: " . $conn->error]);
}

$conn->close();
?>
