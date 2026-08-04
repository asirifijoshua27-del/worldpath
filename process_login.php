<?php

session_start();

require 'config/database.php';

$email = trim($_POST['email']);
$password = $_POST['password'];

$stmt = $pdo->prepare("
SELECT *
FROM users
WHERE email=:email
");

$stmt->execute([
    'email'=>$email
]);

$user = $stmt->fetch(PDO::FETCH_ASSOC);

if($user && password_verify($password,$user['password'])){

    $_SESSION['user_id']=$user['id'];
    $_SESSION['fullname']=$user['fullname'];
    $_SESSION['email']=$user['email'];
    $_SESSION['role']=$user['role'];

    /*
    ===============================
    ADMIN LOGIN
    ===============================
    */

    if($user['role']=="admin"){

        header("Location: admin/dashboard.php");
        exit();

    }

    /*
    ===============================
    STUDENT LOGIN
    ===============================
    */

    $check = $pdo->prepare("
    SELECT id
    FROM applications
    WHERE email=:email
    LIMIT 1
    ");

    $check->execute([
        'email'=>$user['email']
    ]);

    if($check->fetch()){

        header("Location: student/dashboard.php");

    }else{

        header("Location: application.php");

    }

    exit();

}

echo "Invalid Login";