<?php

session_start();

if(
!isset($_SESSION['role']) ||
$_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

include '../config/database.php';

$id = $_GET['id'];

$stmt = $pdo->prepare(
"DELETE FROM contact_messages WHERE id=:id"
);

$stmt->execute([
'id'=>$id
]);

header("Location: messages.php");

exit;