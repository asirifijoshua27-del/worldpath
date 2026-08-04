<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

$stmt = $pdo->query("
SELECT *
FROM blogs
WHERE status='Published'
");

$blogs = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
Blog Management
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
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

<div class="d-flex justify-content-between mb-4">

<h2>
Blog Management
</h2>

<a
href="create_blog.php"
class="btn btn-primary">

Create New Blog

</a>

</div>

<div class="card shadow">

<div class="card-body">

<table class="table table-bordered">

<thead>

<tr>

<th>ID</th>
<th>Title</th>
<th>Status</th>
<th>Created By</th>
<th>Date</th>
<th>Action</th>

</tr>

</thead>

<tbody>

<?php foreach($blogs as $blog): ?>

<tr>

<td>
<?php echo $blog['id']; ?>
</td>

<td>
<?php echo htmlspecialchars($blog['title']); ?>
</td>

<td>

<?php

if($blog['status']=='Published'){
echo "<span class='badge bg-success'>Published</span>";
}
else{
echo "<span class='badge bg-warning'>Draft</span>";
}

?>

</td>

<td>
<?php echo htmlspecialchars($blog['created_by']); ?>
</td>

<td>
<?php echo $blog['created_at']; ?>
</td>

<td>

<a
href="edit_blog.php?id=<?php echo $blog['id']; ?>"
class="btn btn-sm btn-primary">

Edit

</a>

<a
href="delete_blog.php?id=<?php echo $blog['id']; ?>"
class="btn btn-sm btn-danger"
onclick="return confirm('Delete blog?')">

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