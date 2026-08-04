<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

$totalApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
")->fetchColumn();

$approved = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Approved'
")->fetchColumn();

$pending = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Pending'
")->fetchColumn();

$rejected = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Rejected'
")->fetchColumn();

$totalUsers = $pdo->query("
SELECT COUNT(*)
FROM users
")->fetchColumn();

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
Reports
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2 class="mb-4">
WorldPath Reports
</h2>

<div class="row">

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-primary">
<?php echo $totalApplications; ?>
</h2>

<p>Total Applications</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-success">
<?php echo $approved; ?>
</h2>

<p>Approved Applications</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-warning">
<?php echo $pending; ?>
</h2>

<p>Pending Applications</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-danger">
<?php echo $rejected; ?>
</h2>

<p>Rejected Applications</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-info">
<?php echo $totalUsers; ?>
</h2>

<p>Total Users</p>

</div>

</div>

</div>

</div>

<a href="dashboard.php"
class="btn btn-primary">

Back Dashboard

</a>

</div>

</body>

</html>