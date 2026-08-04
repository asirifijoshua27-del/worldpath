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

$stmt = $pdo->prepare("
SELECT *
FROM users
WHERE fullname ILIKE :search
OR email ILIKE :search
ORDER BY id DESC
");

$stmt->execute([
'search' => "%$search%"
]);

$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html>

<head>

<title>Users Management</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2 class="mb-4">
Users Management
</h2>

<a href="dashboard.php"
class="btn btn-secondary mb-3">
Back To Dashboard
</a>

<div class="card shadow">

<div class="card-body">
<form method="GET" class="mb-3">

<input
type="text"
name="search"
placeholder="Search User"
class="form-control">

</form>
<table class="table table-bordered">

<thead>

<tr>

<th>ID</th>
<th>Full Name</th>
<th>Email</th>
<th>Role</th>
<th>Created</th>
<th>Actions</th>

</tr>

</thead>

<tbody>

<?php foreach($users as $user): ?>

<tr>

<td>
<?php echo $user['id']; ?>
</td>

<td>
<?php echo htmlspecialchars($user['fullname']); ?>
</td>

<td>
<?php echo htmlspecialchars($user['email']); ?>
</td>

<td>

<?php if($user['role']=="admin"): ?>

<span class="badge bg-danger">
Admin
</span>

<?php else: ?>

<span class="badge bg-primary">
Student
</span>

<?php endif; ?>

</td>

<td>
<?php echo $user['created_at']; ?>
</td>

<td>

<a
href="promote_user.php?id=<?php echo $user['id']; ?>"
class="btn btn-success btn-sm">

Make Admin

</a>

<a
href="delete_user.php?id=<?php echo $user['id']; ?>"
class="btn btn-danger btn-sm"
onclick="return confirm('Delete this user?')">

Delete

</a>

</td>

</tr>

<?php endforeach; ?>

</tbody>

</table>

</div>

</div>

</div>

</body>

</html>