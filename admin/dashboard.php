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

$totalStaff = $pdo->query("
SELECT COUNT(*)
FROM staff
")->fetchColumn();

$totalBlogs = $pdo->query("
SELECT COUNT(*)
FROM blogs
")->fetchColumn();

$totalMessages = $pdo->query("
SELECT COUNT(*)
FROM contact_messages
")->fetchColumn();

$totalAppointments = $pdo->query("
SELECT COUNT(*)
FROM appointments
")->fetchColumn();

$approvedApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Approved'
")->fetchColumn();

$pendingApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Pending'
")->fetchColumn();

$rejectedApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Rejected'
")->fetchColumn();

/*
|--------------------------------------------------------------------------
| COUNTS
|--------------------------------------------------------------------------
*/

$totalUsers = $pdo->query("
SELECT COUNT(*)
FROM users
")->fetchColumn();

$totalApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
")->fetchColumn();

$totalAppointments = $pdo->query("
SELECT COUNT(*)
FROM appointments
")->fetchColumn();

$totalMessages = $pdo->query("
SELECT COUNT(*)
FROM contact_messages
")->fetchColumn();

$pendingApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Pending'
")->fetchColumn();

$approvedApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Approved'
")->fetchColumn();

$rejectedApplications = $pdo->query("
SELECT COUNT(*)
FROM applications
WHERE status='Rejected'
")->fetchColumn();

$totalBlogs = $pdo->query("
SELECT COUNT(*)
FROM blogs
")->fetchColumn();
/*
|--------------------------------------------------------------------------
| RECENT APPLICATIONS
|--------------------------------------------------------------------------
*/

$recentApplications = $pdo->query("
SELECT *
FROM applications
ORDER BY id DESC
LIMIT 5
")->fetchAll(PDO::FETCH_ASSOC);

/*
|--------------------------------------------------------------------------
| RECENT APPOINTMENTS
|--------------------------------------------------------------------------
*/

$recentAppointments = $pdo->query("
SELECT *
FROM appointments
ORDER BY id DESC
LIMIT 5
")->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>
WorldPath CRM Dashboard
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

<link
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
rel="stylesheet">

<style>

body{
    background:#f4f6f9;
}

.sidebar{
    width:260px;
    min-height:100vh;
    background:#0056D2;
}

.sidebar a{
    color:white;
    text-decoration:none;
    display:block;
    padding:12px;
    border-radius:8px;
    margin-bottom:8px;
}

.sidebar a:hover{
    background:#00A8CC;
}

.card{
    border:none;
    border-radius:15px;
}

.stat-card:hover{
    transform:translateY(-5px);
    transition:.3s;
}

</style>

</head>

<body>

<div class="d-flex">

<!-- SIDEBAR -->

<div class="sidebar p-3 text-white">

<h3 class="mb-4">
WorldPath CRM
</h3>

<a href="dashboard.php">
<i class="fas fa-chart-line"></i>
 Dashboard
</a>

<a href="applications.php">
<i class="fas fa-user-graduate"></i>
 Applications
</a>

<a href="appointments.php">
<i class="fas fa-calendar"></i>
 Appointments
</a>

<a href="messages.php">
<i class="fas fa-envelope"></i>
 Messages
</a>

<a href="users.php">
<i class="fas fa-users"></i>
 Users
</a>

<a href="reports.php">
<i class="fas fa-chart-pie"></i>
 Reports
</a>

<a href="staff.php">
<i class="fas fa-user-tie"></i>
 Staff
</a>

<a href="../logout.php">
<i class="fas fa-sign-out-alt"></i>
 Logout
</a>
<a href="staff.php">
<i class="fas fa-user-tie"></i>
 Staff
</a>
</div>

<!-- MAIN CONTENT -->

<div class="flex-grow-1 p-4">

<h2>
Welcome,
<?php echo $_SESSION['fullname']; ?>
</h2>

<p class="text-muted">
WorldPath Admissions CRM Dashboard
</p>

<div class="row g-4">

<div class="col-md-3">

<div class="card shadow stat-card">

<div class="card-body text-center">

<i class="fas fa-users fa-2x text-primary mb-3"></i>

<h2>
<?php echo $totalUsers; ?>
</h2>

<p>
Users
</p>

</div>

</div>

</div>

<div class="col-md-3">

<div class="card shadow stat-card">

<div class="card-body text-center">

<i class="fas fa-user-graduate fa-2x text-success mb-3"></i>

<h2>
<?php echo $totalApplications; ?>
</h2>

<p>
Applications
</p>

</div>

</div>

</div>

<div class="col-md-3">

<div class="card shadow stat-card">

<div class="card-body text-center">

<i class="fas fa-calendar fa-2x text-warning mb-3"></i>

<h2>
<?php echo $totalAppointments; ?>
</h2>

<p>
Appointments
</p>

</div>

</div>

</div>

<div class="col-md-3">

<div class="card shadow stat-card">

<div class="card-body text-center">

<i class="fas fa-envelope fa-2x text-danger mb-3"></i>

<h2>
<?php echo $totalMessages; ?>
</h2>

<p>
Messages
</p>

</div>

</div>

</div>

</div>

<!-- APPLICATION STATUS -->

<div class="row mt-4">

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-warning">
<?php echo $pendingApplications; ?>
</h2>

<p>
Pending Applications
</p>

</div>

</div>

</div>

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-success">
<?php echo $approvedApplications; ?>
</h2>

<p>
Approved Applications
</p>

</div>

</div>

</div>

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<h2 class="text-danger">
<?php echo $rejectedApplications; ?>
</h2>

<p>
Rejected Applications
</p>

</div>

</div>

</div>

</div>

<!-- RECENT APPLICATIONS -->

<div class="card shadow mt-5">

<div class="card-header bg-primary text-white">

Recent Applications

</div>

<div class="card-body">

<table class="table table-bordered">

<tr>

<th>Name</th>
<th>Country</th>
<th>Program</th>
<th>Status</th>

</tr>

<?php foreach($recentApplications as $app): ?>

<tr>

<td><?php echo $app['fullname']; ?></td>

<td><?php echo $app['country']; ?></td>

<td><?php echo $app['program']; ?></td>

<td><?php echo $app['status']; ?></td>

</tr>

<?php endforeach; ?>

</table>

</div>

</div>

<!-- RECENT APPOINTMENTS -->

<div class="card shadow mt-4">

<div class="card-header bg-success text-white">

Recent Appointments

</div>

<div class="card-body">

<table class="table table-bordered">

<tr>

<th>Name</th>
<th>Service</th>
<th>Date</th>
<th>Status</th>

</tr>

<div class="row g-4">

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2><?php echo $totalApplications; ?></h2>
<p>Total Applications</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2 class="text-success">
<?php echo $approvedApplications; ?>
</h2>
<p>Approved</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2 class="text-warning">
<?php echo $pendingApplications; ?>
</h2>
<p>Pending</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2 class="text-danger">
<?php echo $rejectedApplications; ?>
</h2>
<p>Rejected</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2><?php echo $totalStaff; ?></h2>
<p>Staff Members</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2><?php echo $totalBlogs; ?></h2>
<p>Blog Posts</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2><?php echo $totalMessages; ?></h2>
<p>Messages</p>
</div>
</div>
</div>

<div class="col-md-3">
<div class="card shadow">
<div class="card-body text-center">
<h2><?php echo $totalAppointments; ?></h2>
<p>Appointments</p>
</div>
</div>
</div>

</div>

<?php foreach($recentAppointments as $appointment): ?>

<tr>

<td><?php echo $appointment['fullname']; ?></td>

<td><?php echo $appointment['service']; ?></td>

<td><?php echo $appointment['appointment_date']; ?></td>

<td><?php echo $appointment['status']; ?></td>

</tr>

<?php endforeach; ?>

</table>

</div>

</div>

</div>
<div class="col-md-3">

<div class="card shadow">

<div class="card-body text-center">

<h2>

<?php echo $totalBlogs; ?>

</h2>

<p>
Blog Articles
</p>

</div>

</div>

</div>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>

</html>