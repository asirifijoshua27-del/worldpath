<?php

session_start();

require '../config/database.php';

$students = $pdo->query("
SELECT *
FROM students
ORDER BY id DESC
");

?>

<!DOCTYPE html>
<html>
<head>

<title>Students</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2 class="mb-4">
Students Database
</h2>

<table class="table table-bordered table-striped">

<thead>

<tr>

<th>ID</th>
<th>Name</th>
<th>Email</th>
<th>Country</th>
<th>Program</th>
<th>University</th>

</tr>

</thead>

<tbody>

<?php while($row = $students->fetch()): ?>

<tr>

<td><?= $row['id']; ?></td>
<td><?= $row['fullname']; ?></td>
<td><?= $row['email']; ?></td>
<td><?= $row['country']; ?></td>
<td><?= $row['program']; ?></td>
<td><?= $row['university']; ?></td>

</tr>

<?php endwhile; ?>

</tbody>

</table>

</div>

</body>
</html>