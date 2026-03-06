<?php
// get_conversations.php - Get list of users with active conversations
header("Content-Type: application/json");
require 'db.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(["error" => "User ID is required"]);
    exit();
}

$user_id = intval($_GET['user_id']);

// Complex query to get latest message for each unique conversation partner
// This gets the latest message ID for each pair involving user_id
$sql = "SELECT 
            CASE 
                WHEN sender_id = $user_id THEN receiver_id 
                ELSE sender_id 
            END as other_user_id,
            MAX(id) as last_msg_id
        FROM direct_messages
        WHERE sender_id = $user_id OR receiver_id = $user_id
        GROUP BY other_user_id
        ORDER BY last_msg_id DESC";

$result = $conn->query($sql);
$conversations = [];

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $other_id = $row['other_user_id'];
        $msg_id = $row['last_msg_id'];
        
        // Fetch user details and message content
        $detail_sql = "SELECT dm.content, dm.created_at, u.username, u.avatar_url 
                       FROM direct_messages dm
                       JOIN users u ON u.id = $other_id
                       WHERE dm.id = $msg_id";
        
        $detail_res = $conn->query($detail_sql);
        if ($detail_res->num_rows > 0) {
            $detail = $detail_res->fetch_assoc();
            $conversations[] = [
                'user_id' => $other_id,
                'username' => $detail['username'],
                'avatar_url' => $detail['avatar_url'],
                'last_message' => $detail['content'],
                'time' => $detail['created_at']
            ];
        }
    }
}

echo json_encode($conversations);
$conn->close();
?>
