<?php
// send_gift.php - Process gift transaction
header("Content-Type: application/json");
require 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['sender_id']) || !isset($data['receiver_id']) || !isset($data['gift_id']) || !isset($data['room_id'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit();
}

$sender_id = intval($data['sender_id']);
$receiver_id = intval($data['receiver_id']);
$gift_id = intval($data['gift_id']);
$room_id = intval($data['room_id']);
$quantity = isset($data['quantity']) ? intval($data['quantity']) : 1;
if ($quantity < 1) $quantity = 1;

// Start Transaction
$conn->begin_transaction();

try {
    // 1. Get Gift Details
    $gift_sql = "SELECT name, price FROM gifts WHERE id = $gift_id";
    $gift_result = $conn->query($gift_sql);
    if ($gift_result->num_rows == 0) throw new Exception("Gift not found");
    $gift_row = $gift_result->fetch_assoc();
    $gift_price = $gift_row['price'];
    $gift_name = $gift_row['name'];
    
    // Calculate Total Price
    $total_price = $gift_price * $quantity;

    // 2. Check Sender Balance
    $sender_sql = "SELECT username, diamonds FROM users WHERE id = $sender_id FOR UPDATE";
    $sender_result = $conn->query($sender_sql);
    
    if (!$sender_result || $sender_result->num_rows == 0) {
        throw new Exception("Sender not found (ID: $sender_id)");
    }
    
    $sender_row = $sender_result->fetch_assoc();
    $sender_balance = $sender_row['diamonds'];
    $sender_name = $sender_row['username'];

    if ($sender_balance < $total_price) {
        throw new Exception("Insufficient balance. Needed: $total_price, Has: $sender_balance");
    }

    // 3. Deduct from Sender
    $deduct_sql = "UPDATE users SET diamonds = diamonds - $total_price WHERE id = $sender_id";
    if (!$conn->query($deduct_sql)) {
        throw new Exception("Failed to deduct balance");
    }

    // 4. Add 'Beans' to Receiver (NOT Diamonds)
    // Streamers earn Beans, Viewers spend Diamonds
    $add_sql = "UPDATE users SET beans = beans + $total_price WHERE id = $receiver_id";
    if (!$conn->query($add_sql) || $conn->affected_rows === 0) {
        throw new Exception("Failed to add beans or receiver not found");
    }

    // 5. Record Transaction
    // Assuming 'amount' column stores total value. If you have a 'quantity' column, add it.
    $log_sql = "INSERT INTO transactions (sender_id, receiver_id, room_id, gift_id, amount) VALUES ($sender_id, $receiver_id, $room_id, $gift_id, $total_price)";
    $conn->query($log_sql);

    // 6. Insert Chat Message
    // Use a special type 'gift' so the frontend can render it differently
    $msg_content = "sent $gift_name" . ($quantity > 1 ? " x$quantity" : "");
    $msg_sql = "INSERT INTO chat_messages (room_id, user_id, content, type) VALUES ($room_id, $sender_id, '$msg_content', 'gift')";
    $conn->query($msg_sql);

    // 7. Update Room Points and Level
    // Example: 1 point per 1 diamond value. Level up every 1000 points.
    $update_room_sql = "UPDATE rooms 
                        SET points = points + $total_price, 
                            level = 1 + FLOOR((points + $total_price) / 1000) 
                        WHERE id = $room_id";
    $conn->query($update_room_sql);
    
    // Fetch updated room stats
    $room_stats_sql = "SELECT points, level FROM rooms WHERE id = $room_id";
    $room_stats_result = $conn->query($room_stats_sql);
    $room_stats = $room_stats_result->fetch_assoc();

    // Commit
    $conn->commit();

    echo json_encode([
        "success" => true,
        "message" => "Gift sent successfully",
        "new_balance" => $sender_balance - $total_price,
        "gift_name" => $gift_name,
        "quantity" => $quantity,
        "room_points" => $room_stats['points'],
        "room_level" => $room_stats['level']
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["error" => $e->getMessage()]);
}

$conn->close();
?>
