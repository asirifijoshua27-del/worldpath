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
    FROM appointments
    ORDER BY created_at DESC
");

$appointments = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<title>Appointments</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>Appointment Requests</h2>

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
<th>Phone</th>
<th>Service</th>
<th>Date</th>
<th>Time</th>
<th>Status</th>

</tr>

</thead>

<tbody>

<?php foreach($appointments as $appointment): ?>

<tr>

<td><?php echo $appointment['id']; ?></td>

<td><?php echo htmlspecialchars($appointment['fullname']); ?></td>

<td><?php echo htmlspecialchars($appointment['email']); ?></td>

<td><?php echo htmlspecialchars($appointment['phone']); ?></td>

<td><?php echo htmlspecialchars($appointment['service']); ?></td>

<td><?php echo $appointment['appointment_date']; ?></td>

<td><?php echo $appointment['appointment_time']; ?></td>

<td><?php echo $appointment['status']; ?></td>

</tr>

<?php endforeach; ?>

</tbody>

</table>

</div>

</body>

</html>