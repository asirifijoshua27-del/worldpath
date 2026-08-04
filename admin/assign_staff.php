<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

$id = $_POST['id'];

$assigned_to =
$_POST['assigned_to'];

$stmt = $pdo->prepare("
UPDATE applications
SET
assigned_to = :assigned_to,
assigned_date = NOW()
WHERE id = :id
");

$stmt->execute([
    'assigned_to' => $assigned_to,
    'id' => $id
]);

header(
"Location: application_details.php?id=$id"
);

exit;
?>
