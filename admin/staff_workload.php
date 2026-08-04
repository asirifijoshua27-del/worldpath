<?php

session_start();

require '../config/database.php';

$staff = $pdo->query("

SELECT
assigned_to,
COUNT(*) as total

FROM applications

WHERE assigned_to IS NOT NULL

GROUP BY assigned_to

ORDER BY total DESC

")->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>

<html>

<head>

<title>
Staff Workload
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2 class="mb-4">
Counselor Workload
</h2>

<table class="table table-bordered">

<tr>

<th>
Counselor
</th>

<th>
Applications
</th>

</tr>

<?php foreach($staff as $row): ?>

<tr>

<td>
<?php echo $row['assigned_to']; ?>
</td>

<td>
<?php echo $row['total']; ?>
</td>

</tr>

<?php endforeach; ?>

</table>

</div>

</body>

</html>