<?php
// get_gifts.php - Fetch all gifts
header("Content-Type: application/json");
require 'db.php';

$sql = "SELECT * FROM gifts";
$result = $conn->query($sql);

$gifts = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $gifts[] = $row;
    }
}

echo json_encode($gifts);
$conn->close();
?>