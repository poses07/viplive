<?php
// get_transactions.php - Fetch user transactions
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(["error" => "User ID is required"]);
    exit();
}

$user_id = intval($_GET['user_id']);
$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;

// Fetch sent and received transactions
// We join with users (sender/receiver) and gifts to get names
$sql = "SELECT t.id, t.amount, t.created_at, 
               t.sender_id, s.username as sender_name,
               t.receiver_id, r.username as receiver_name,
               t.gift_id, g.name as gift_name, g.icon_url
        FROM transactions t
        LEFT JOIN users s ON t.sender_id = s.id
        LEFT JOIN users r ON t.receiver_id = r.id
        LEFT JOIN gifts g ON t.gift_id = g.id
        WHERE t.sender_id = $user_id OR t.receiver_id = $user_id
        ORDER BY t.created_at DESC
        LIMIT $limit";

$result = $conn->query($sql);

$transactions = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $transactions[] = $row;
    }
}

echo json_encode($transactions);
$conn->close();
?>
