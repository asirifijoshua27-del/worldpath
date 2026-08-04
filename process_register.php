<?php

session_start();

require 'config/database.php';

try {

    $fullname = trim($_POST['fullname']);
    $email = trim($_POST['email']);

    $password = password_hash(
        $_POST['password'],
        PASSWORD_DEFAULT
    );

    /*
    |--------------------------------------------------------------------------
    | CHECK IF EMAIL EXISTS
    |--------------------------------------------------------------------------
    */

    $check = $pdo->prepare("
    SELECT id
    FROM users
    WHERE email = :email
    ");

    $check->execute([
        'email' => $email
    ]);

    if($check->fetch()){

        $_SESSION['error_message'] =
        "Email already registered.";

        header("Location: register.php");
        exit();
    }

    /*
    |--------------------------------------------------------------------------
    | CREATE ACCOUNT
    |--------------------------------------------------------------------------
    */

    $stmt = $pdo->prepare("
    INSERT INTO users
    (
        fullname,
        email,
        password
    )
    VALUES
    (
        :fullname,
        :email,
        :password
    )
    ");

    $stmt->execute([

        'fullname' => $fullname,
        'email' => $email,
        'password' => $password

    ]);

    /*
    |--------------------------------------------------------------------------
    | SUCCESS REDIRECT
    |--------------------------------------------------------------------------
    */

    $_SESSION['success_message'] =
    "Registration successful. Please login.";

    header("Location: login.php?registered=1");
exit();

} catch(PDOException $e){

    $_SESSION['error_message'] =
    "Registration failed. Please try again.";

    header("Location: register.php");
    exit();

}