<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

if(!isset($_GET['id'])){
    die("Blog Not Found");
}

$stmt = $pdo->prepare("
DELETE FROM blogs
WHERE id=:id
");

$stmt->execute([
    'id'=>$_GET['id']
]);

header("Location: blogs.php");
exit();