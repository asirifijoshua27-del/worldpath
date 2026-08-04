<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

$search = $_GET['search'] ?? '';

$sql = "
SELECT *
FROM applications
";

if(!empty($search)){

    $sql .= "
    WHERE
    fullname ILIKE :search
    OR email ILIKE :search
    OR country ILIKE :search
    OR program ILIKE :search
    ";
}

$sql .= " ORDER BY id DESC";

$stmt = $pdo->prepare($sql);

if(!empty($search)){

    $stmt->execute([
        'search' => "%$search%"
    ]);

}else{

    $stmt->execute();
}

$applications = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
Applications Management
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
    display:block;
    padding:12px;
    text-decoration:none;
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

</style>

</head>

<body>

<div class="d-flex">

<div class="sidebar p-3 text-white">

<h3>WorldPath CRM</h3>

<hr>

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
<i class="fas fa-chart-bar"></i>
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

</div>

<div class="flex-grow-1 p-4">

<div class="d-flex justify-content-between align-items-center mb-4">

<h2>
Applications Management
</h2>

</div>

<div class="card shadow mb-4">

<div class="card-body">

<form method="GET">

<div class="row">

<div class="col-md-10">

<input
type="text"
name="search"
class="form-control"
placeholder="Search by name, email, country or program..."
value="<?php echo htmlspecialchars($search); ?>">

</div>

<div class="col-md-2">

<button
class="btn btn-primary w-100">

Search

</button>

</div>

</div>

</form>

</div>

</div>

<div class="card shadow">

<div class="card-body">

<div class="table-responsive">

<table class="table table-bordered table-hover">

<thead class="table-primary">

<tr>

<th>ID</th>
<th>Name</th>
<th>Email</th>
<th>Country</th>
<th>Program</th>
<th>Status</th>
<th>Assigned Officer</th>
<th>Action</th>

</tr>

</thead>

<tbody>

<?php foreach($applications as $app): ?>

<tr>

<td>
<?php echo $app['id']; ?>
</td>

<td>
<?php echo htmlspecialchars($app['fullname']); ?>
</td>

<td>
<?php echo htmlspecialchars($app['email']); ?>
</td>

<td>
<?php echo htmlspecialchars($app['country']); ?>
</td>

<td>
<?php echo htmlspecialchars($app['program']); ?>
</td>

<td>

<?php

if($app['status']=="Approved"){

    echo "<span class='badge bg-success'>Approved</span>";

}
elseif($app['status']=="Rejected"){

    echo "<span class='badge bg-danger'>Rejected</span>";

}
else{

    echo "<span class='badge bg-warning text-dark'>".$app['status']."</span>";

}

?>

</td>

<td>

<?php

echo !empty($app['assigned_to'])
? htmlspecialchars($app['assigned_to'])
: 'Unassigned';

?>

</td>

<td>

<a
href="application_details.php?id=<?php echo $app['id']; ?>"
class="btn btn-sm btn-primary">

View

</a>

</td>

</tr>

<?php endforeach; ?>

</tbody>

</table>

</div>

</div>

</div>

</div>

</div>

</body>

</html>