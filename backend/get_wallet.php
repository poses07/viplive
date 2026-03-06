<?php
// get_wallet.php - Fetch user wallet balance (diamonds and beans)
header("Content-Type: application/json");
require 'db.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    echo json_encode(["error" => "Invalid user ID"]);
    exit;
}

$sql = "SELECT wallet_balance as diamonds, beans FROM users WHERE id = $user_id";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode($result->fetch_assoc());
} else {
    echo json_encode(["error" => "User not found"]);
}

$conn->close();
?>
