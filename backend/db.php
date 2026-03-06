<?php
// db.php - Database Connection Script
// Disable error reporting for cleaner JSON output
error_reporting(0);
ini_set('display_errors', 0);

$host = "localhost";
$username = "d045d473";
$password = "jHJRCDftddPi4h6Yxqqw";
$database = "d045d473";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

// Set charset to utf8mb4 for emoji support
$conn->set_charset("utf8mb4");
?>