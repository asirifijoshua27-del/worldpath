<?php

session_start();

if(
!isset($_SESSION['role']) ||
$_SESSION['role']!='admin'
){
die("Access Denied");
}

require '../config/database.php';

$id = $_GET['id'];

$stmt = $pdo->prepare("
DELETE FROM users
WHERE id=:id
");

$stmt->execute([
'id'=>$id
]);

header("Location: users.php");
exit;