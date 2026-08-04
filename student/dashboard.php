<?php

session_start();

if(!isset($_SESSION['user_id'])){
    header("Location: ../login.php");
    exit();
}

require '../config/database.php';

/*
|--------------------------------------------------------------------------
| STUDENT APPLICATION
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
SELECT *
FROM applications
WHERE email = :email
ORDER BY id DESC
LIMIT 1
");

$stmt->execute([
    'email' => $_SESSION['email']
]);

$application = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$application){
?>
<!DOCTYPE html>
<html>
<head>
<title>No Application</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<div class="container py-5">

<div class="alert alert-info">

<h3>No Application Found</h3>

<p>
You have not submitted an application yet.
</p>

<a href="../application.php" class="btn btn-primary">
Apply Now
</a>

<a href="../index.php" class="btn btn-secondary">
Back Home
</a>

</div>

</div>

</body>
</html>
<?php
exit();
}

/*
|--------------------------------------------------------------------------
| NOTIFICATIONS COUNT
|--------------------------------------------------------------------------
*/

$notificationCount = $pdo->prepare("
SELECT COUNT(*)
FROM notifications
WHERE application_id = :id
");

$notificationCount->execute([
    'id' => $application['id']
]);

$totalNotifications = $notificationCount->fetchColumn();

?>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>
Student Dashboard
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

.status-box{
    font-size:18px;
    font-weight:bold;
}

</style>

</head>

<body>

<div class="d-flex">

<div class="sidebar p-3 text-white">

<h3 class="mb-4">
WorldPath
</h3>

<a href="dashboard.php">
<i class="fas fa-home"></i>
Dashboard
</a>

<a href="notifications.php">
    <i class="fas fa-bell"></i>
    Notifications
    <span class="badge bg-warning text-dark">
        <?php echo $totalNotifications; ?>
    </span>
</a>

<a href="upload_documents.php">
    <i class="fas fa-folder-open"></i>
    My Documents
</a>

<a href="profile.php">
    <i class="fas fa-user-circle"></i>
    My Profile
</a>

<a href="../logout.php">
    <i class="fas fa-sign-out-alt"></i>
    Logout
</a>

</div>

<div class="flex-grow-1 p-4">

<div class="d-flex justify-content-between align-items-center">

<div>

<h2>
Welcome,
<?php echo htmlspecialchars($_SESSION['fullname']); ?>
</h2>

<p class="text-muted">
Student Portal
</p>

</div>

</div>

<div class="row g-4">

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<i class="fas fa-file-alt fa-3x text-primary mb-3"></i>

<h5>
Application Status
</h5>

<div class="status-box text-success">

<?php echo htmlspecialchars($application['status']); ?>

</div>

</div>

</div>

</div>

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<i class="fas fa-user-tie fa-3x text-info mb-3"></i>

<h5>
Assigned Officer
</h5>

<p>

<?php

echo !empty($application['assigned_to'])
? htmlspecialchars($application['assigned_to'])
: 'Not Assigned';

?>

</p>

</div>

</div>

</div>

<div class="col-md-4">

<div class="card shadow">

<div class="card-body text-center">

<i class="fas fa-bell fa-3x text-warning mb-3"></i>

<h5>
Notifications
</h5>

<h3>

<?php echo $totalNotifications; ?>

</h3>

</div>

</div>

</div>

</div>

<div class="card shadow mt-4">

<div class="card-header bg-primary text-white">

Document Verification Status

</div>

<div class="card-body">

<table class="table table-bordered">

<tr>

<th>Document</th>
<th>Status</th>

</tr>

<tr>

<td>WASSCE Result</td>

<td>

<?php echo $application['wassce_status']; ?>

</td>

</tr>

<tr>

<td>Transcript</td>

<td>

<?php echo $application['transcript_status']; ?>

</td>

</tr>

<tr>

<td>CV / Resume</td>

<td>

<?php echo $application['cv_status']; ?>

</td>

</tr>

<tr>

<td>Passport</td>

<td>

<?php echo $application['passport_status']; ?>

</td>

</tr>

</table>

</div>

</div>

<div class="card shadow mt-4">

<div class="card-header bg-success text-white">

Application Timeline

</div>

<div class="card-body">

<ul class="list-group">

<li class="list-group-item">
Application Submitted
</li>

<li class="list-group-item">
Current Stage:
<strong>

<?php echo htmlspecialchars($application['status']); ?>

</strong>

</li>

<?php if(!empty($application['assigned_date'])): ?>

<li class="list-group-item">

Assigned To Officer On:

<?php

echo date(
'd M Y h:i A',
strtotime($application['assigned_date'])
);

?>

</li>

<?php endif; ?>

</ul>

</div>

</div>

<div class="card shadow mt-4">

<div class="card-header bg-dark text-white">

Admin Notes

</div>

<div class="card-body">

<?php

echo !empty($application['admin_notes'])
? nl2br(htmlspecialchars($application['admin_notes']))
: 'No notes available yet.';

?>

</div>

</div>

</div>

</div>

</body>

</html>