<?php

require 'config/database.php';

$stmt = $pdo->query("
SELECT *
FROM staff
ORDER BY fullname
");

$staff = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>
<head>

<title>Our Team</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2 class="mb-5 text-center">

Meet Our Team

</h2>

<div class="row">

<?php foreach($staff as $member): ?>

<div class="col-md-4 mb-4">

<div class="card shadow h-100">

<?php if(!empty($member['photo'])): ?>

<img
src="uploads/<?php echo $member['photo']; ?>"
class="card-img-top">

<?php endif; ?>

<div class="card-body">

<h5>

<?php echo htmlspecialchars($member['fullname']); ?>

</h5>

<p class="text-primary">

<?php echo htmlspecialchars($member['position']); ?>

</p>

<p>

<?php echo nl2br(
htmlspecialchars($member['bio'])
); ?>

</p>

</div>

</div>

</div>

<?php endforeach; ?>

</div>

</div>

</body>
</html>