<?php
// get_gifts.php - Fetch available gifts
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

$sql = "SELECT id, name, icon_url, price, currency_type FROM gifts ORDER BY price ASC";
$result = $conn->query($sql);

$gifts = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $gifts[] = $row;
    }
    echo json_encode($gifts);
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error]);
}

$conn->close();
?>