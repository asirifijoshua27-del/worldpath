<?php

session_start();

if(
!isset($_SESSION['role']) ||
$_SESSION['role']!='admin'
){
die("Access Denied");
}

require '../config/database.php';

$staff = $pdo->query("
SELECT *
FROM staff
ORDER BY id DESC
")->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<title>Staff Management</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2 class="mb-4">
Staff Management
</h2>

<a href="dashboard.php"
class="btn btn-secondary mb-3">

Dashboard

</a>

<a href="add_staff.php"
class="btn btn-primary mb-3">

Add Staff

</a>

<table class="table table-bordered bg-white">

<tr>

<th>ID</th>
<th>Name</th>
<th>Position</th>
<th>Actions</th>

</tr>

<?php foreach($staff as $member): ?>

<tr>

<td>
<?php echo $member['id']; ?>
</td>

<td>
<?php echo $member['fullname']; ?>
</td>

<td>
<?php echo $member['position']; ?>
</td>

<td>

<a
href="edit_staff.php?id=<?php echo $member['id']; ?>"
class="btn btn-success btn-sm">

Edit

</a>

<a
href="delete_staff.php?id=<?php echo $member['id']; ?>"
class="btn btn-danger btn-sm">

Delete

</a>

</td>

</tr>

<?php endforeach; ?>

</table>

</div>

</body>

</html>