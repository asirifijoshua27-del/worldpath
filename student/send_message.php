<?php

session_start();

if(!isset($_SESSION['user_id'])){
    header('Location: ../login.php');
    exit();
}

require '../config/database.php';
require '../includes/site_setup.php';
ensure_notifications_table($pdo);

$title = trim($_POST['title'] ?? '');
$message = trim($_POST['message'] ?? '');

if($title === '' || $message === ''){
    die('Message title and body are required.');
}

$stmt = $pdo->prepare("
SELECT id
FROM applications
WHERE email = :email
ORDER BY id DESC
LIMIT 1
");
$stmt->execute(['email' => $_SESSION['email']]);
$applicationId = $stmt->fetchColumn();

$insert = $pdo->prepare("
INSERT INTO notifications(
    application_id,
    sender_user_id,
    recipient_user_id,
    sender_role,
    title,
    message,
    is_read
)
VALUES(
    :application_id,
    :sender_user_id,
    NULL,
    'student',
    :title,
    :message,
    FALSE
)
");

$insert->execute([
    'application_id' => $applicationId ?: null,
    'sender_user_id' => $_SESSION['user_id'],
    'title' => $title,
    'message' => $message
]);

header('Location: notifications.php?sent=1');
exit();
