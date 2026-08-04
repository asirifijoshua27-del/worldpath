<?php

$host = "localhost";
$port = "5432";
$dbname = "worldpath_db";
$user = "postgres";
$password = "WorldPath2026!";

try {

    $pdo = new PDO(
        "pgsql:host=$host;port=$port;dbname=$dbname",
        $user,
        $password
    );

    $pdo->setAttribute(
        PDO::ATTR_ERRMODE,
        PDO::ERRMODE_EXCEPTION
    );

} catch(PDOException $e) {

    die(
        "Connection Failed: " .
        $e->getMessage()
    );

}