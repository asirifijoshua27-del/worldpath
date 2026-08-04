<?php

session_start();

if (
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
) {
    die("Access Denied");
}

include '../config/database.php';

$stmt = $pdo->query("
    SELECT *
    FROM contact_messages
    ORDER BY created_at DESC
");

$messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<title>Messages</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>Contact Messages</h2>

<a href="dashboard.php"
class="btn btn-secondary mb-3">
Back to Dashboard
</a>

<table class="table table-bordered">

<thead>

<tr>

<th>ID</th>
<th>Name</th>
<th>Email</th>
<th>Subject</th>
<th>Message</th>

</tr>

</thead>

<tbody>

<?php foreach($messages as $message): ?>

<tr>

<td><?php echo $message['id']; ?></td>

<td><?php echo htmlspecialchars($message['fullname']); ?></td>

<td><?php echo htmlspecialchars($message['email']); ?></td>

<td><?php echo htmlspecialchars($message['subject']); ?></td>

<td><?php echo htmlspecialchars($message['message']); ?></td>

</tr>

<?php endforeach; ?>

</tbody>

</table>

</div>

</body>

</html>