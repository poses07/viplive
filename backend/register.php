<?php
// register.php - Direct Connection Version
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json");

// Direct DB Connection (Bypassing db.php for debug)
$host = "localhost";
$username = "d045d473";
$password = "jHJRCDftddPi4h6Yxqqw";
$database = "d045d473";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    die(json_encode(["error" => "Invalid JSON input", "raw_input" => $input]));
}

if (!isset($data['username']) || !isset($data['password'])) {
    die(json_encode(["error" => "Missing username or password"]));
}

$username = $conn->real_escape_string($data['username']);
$password = password_hash($data['password'], PASSWORD_DEFAULT);
$gender = isset($data['gender']) ? $conn->real_escape_string($data['gender']) : 'unknown';
$country = isset($data['country']) ? $conn->real_escape_string($data['country']) : '';
$dob = isset($data['dob']) ? $conn->real_escape_string($data['dob']) : NULL;

if ($dob === '' || $dob === 'NULL') {
    $dob = "NULL";
} else {
    $dob = "'$dob'";
}

// SQL Check
$sql = "INSERT INTO users (username, password, gender, country, dob, level, diamonds, beans, created_at) 
        VALUES ('$username', '$password', '$gender', '$country', $dob, 1, 0, 0, NOW())";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "id" => $conn->insert_id]);
} else {
    echo json_encode(["error" => "SQL Error: " . $conn->error, "sql" => $sql]);
}

$conn->close();
?>
