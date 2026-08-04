<?php

session_start();

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}

require 'config/database.php';

/*
|--------------------------------------------------------------------------
| Get Current User
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
SELECT *
FROM users
WHERE id = :id
LIMIT 1
");

$stmt->execute([
    'id' => $_SESSION['user_id']
]);

$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {

    session_destroy();

    header("Location: login.php");

    exit();
}

/*
|--------------------------------------------------------------------------
| Refresh Session
|--------------------------------------------------------------------------
*/

$_SESSION['fullname'] = $user['fullname'];
$_SESSION['email']    = $user['email'];
$_SESSION['role']     = $user['role'];

/*
|--------------------------------------------------------------------------
| Redirect According To Role
|--------------------------------------------------------------------------
*/

switch ($user['role']) {

    case 'admin':

        header("Location: admin/dashboard.php");
        exit();

    case 'user':

        header("Location: student/dashboard.php");
        exit();

    default:

        session_destroy();

        header("Location: login.php");

        exit();
}

?>