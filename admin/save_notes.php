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
$notes = $_POST['admin_notes'];

$stmt = $pdo->prepare("
UPDATE applications
SET admin_notes = :notes
WHERE id = :id
");

$stmt->execute([
    'notes' => $notes,
    'id' => $id
]);

header(
    "Location: application_details.php?id=$id&notes=1"
);

exit;
?>
