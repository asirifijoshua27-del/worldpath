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
$document = $_POST['document'];
$status = $_POST['status'];

$allowedColumns = [
    'wassce_status',
    'transcript_status',
    'cv_status',
    'passport_status'
];

if(!in_array($document, $allowedColumns)){
    die("Invalid Document");
}

$sql = "
UPDATE applications
SET $document = :status
WHERE id = :id
";

$stmt = $pdo->prepare($sql);

$stmt->execute([
    'status' => $status,
    'id' => $id
]);

header(
    "Location: application_details.php?id=$id&document=1"
);

exit;
?>
