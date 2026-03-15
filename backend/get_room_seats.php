<?php
// get_room_seats.php - Fetch seats for a room
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

// Check for room_id in GET or POST
$room_id = 0;

if (isset($_GET['room_id'])) {
    $room_id = (int)$_GET['room_id'];
} else {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    if (isset($data['room_id'])) {
        $room_id = (int)$data['room_id'];
    }
}

if ($room_id == 0) {
    die(json_encode(["error" => "Missing room_id"]));
}

// Check if room is live
$check_sql = "SELECT is_active FROM rooms WHERE id = $room_id";
$check_result = $conn->query($check_sql);

if ($check_result && $check_result->num_rows > 0) {
    $room = $check_result->fetch_assoc();
    if ($room['is_active'] == 0) {
        http_response_code(410); // Gone
        echo json_encode(["error" => "Room ended"]);
        exit();
    }
} else {
    http_response_code(404);
    echo json_encode(["error" => "Room not found"]);
    exit();
}

// Fetch seats from JSON
$sql = "SELECT seats FROM rooms WHERE id = $room_id";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $seats_json = $row['seats'];
    
    // If seats is null (migration), return empty or default
    if ($seats_json === null) {
        $default_seats = [];
        for ($i = 0; $i < 10; $i++) {
            $default_seats[] = ["index" => $i, "user_id" => null, "is_locked" => false];
        }
        echo json_encode($default_seats);
    } else {
        $seats = json_decode($seats_json, true);
        
        // Enrich with user data
        $enriched_seats = [];
        $user_ids = [];
        
        // Collect all user IDs
        foreach ($seats as $seat) {
            if (!empty($seat['user_id'])) {
                $user_ids[] = $seat['user_id'];
            }
        }
        
        // Fetch user details in bulk if any
        $users_map = [];
        if (!empty($user_ids)) {
            $ids_str = implode(",", $user_ids);
            $user_sql = "SELECT id, username, avatar_url, level, gender FROM users WHERE id IN ($ids_str)";
            $user_result = $conn->query($user_sql);
            if ($user_result) {
                while($u = $user_result->fetch_assoc()) {
                    $users_map[$u['id']] = $u;
                }
            }
        }
        
        // Build final response
        foreach ($seats as $seat) {
            $seat_data = [
                "seat_index" => $seat['index'],
                "is_locked" => $seat['is_locked'],
                "user_id" => $seat['user_id'],
                "username" => null,
                "avatar_url" => null,
                "level" => 0,
                "gender" => "unknown"
            ];
            
            if (!empty($seat['user_id']) && isset($users_map[$seat['user_id']])) {
                $u = $users_map[$seat['user_id']];
                $seat_data['username'] = $u['username'];
                $seat_data['avatar_url'] = $u['avatar_url'];
                $seat_data['level'] = (int)$u['level'];
                $seat_data['gender'] = $u['gender'];
            }
            
            $enriched_seats[] = $seat_data;
        }
        
        echo json_encode($enriched_seats);
    }
} else {
    echo json_encode(["error" => "Room not found"]);
}

$conn->close();
?>