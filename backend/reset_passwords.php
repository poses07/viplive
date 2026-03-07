<?php
// reset_passwords.php - Reset passwords for test users
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = "localhost";
$username = "d045d473";
$password = "jHJRCDftddPi4h6Yxqqw";
$database = "d045d473";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// New password: "123456"
$new_password_hash = password_hash("123456", PASSWORD_DEFAULT);

$sql = "UPDATE users SET password = '$new_password_hash' WHERE username IN ('User1', 'User2', 'User3')";

if ($conn->query($sql) === TRUE) {
    echo "Passwords updated successfully. New password is: 123456";
} else {
    echo "Error updating passwords: " . $conn->error;
}

$conn->close();
?>