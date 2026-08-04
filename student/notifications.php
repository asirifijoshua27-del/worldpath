<?php

session_start();

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

require '../config/database.php';

/*
|--------------------------------------------------------------------------
| FIND STUDENT APPLICATION
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
SELECT *
FROM applications
WHERE email = :email
LIMIT 1
");

$stmt->execute([
    'email' => trim($_SESSION['email'])
]);

$application = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$application) {

    die("
    <h2>No Application Found</h2>

    <p><strong>Logged in Email:</strong> "
    . htmlspecialchars($_SESSION['email']) .
    "</p>

    <p>Please submit an application first.</p>
    ");

}

/*
|--------------------------------------------------------------------------
| LOAD NOTIFICATIONS
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
SELECT *
FROM notifications
WHERE application_id = :id
ORDER BY created_at DESC
");

$stmt->execute([
    'id' => $application['id']
]);

$notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<title>My Notifications</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

<link
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
rel="stylesheet">

<style>

body{
    background:#f5f7fb;
}

.card{
    border:none;
    border-radius:15px;
}

</style>

</head>

<body>

<div class="container py-5">

<a href="dashboard.php"
class="btn btn-secondary mb-4">

<i class="fas fa-arrow-left"></i>

Back to Dashboard

</a>

<h2 class="mb-4">

My Notifications

</h2>

<?php if(count($notifications) == 0): ?>

<div class="alert alert-info">

You don't have any notifications yet.

</div>

<?php else: ?>

<?php foreach($notifications as $note): ?>

<div class="card shadow mb-3">

<div class="card-body">

<h5 class="text-primary">

<?php echo htmlspecialchars($note['title']); ?>

</h5>

<p>

<?php echo nl2br(htmlspecialchars($note['message'])); ?>

</p>

<small class="text-muted">

<?php echo $note['created_at']; ?>

</small>

</div>

</div>

<?php endforeach; ?>

<?php endif; ?>

</div>

</body>

</html>