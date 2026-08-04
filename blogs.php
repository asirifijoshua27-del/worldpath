<?php

require 'config/database.php';

$stmt = $pdo->query("
SELECT *
FROM blogs
ORDER BY created_at DESC
");

$blogs = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>
<head>

<meta charset="UTF-8">

<title>
WorldPath Blog
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2 class="mb-4">
Latest Articles
</h2>

<div class="row">

<?php foreach($blogs as $blog): ?>

<div class="col-md-4 mb-4">

<div class="card shadow h-100">

<?php if(!empty($blog['image'])): ?>

<img
src="uploads/<?php echo $blog['image']; ?>"
class="card-img-top">

<?php endif; ?>

<div class="card-body">

<h5>

<?php echo htmlspecialchars($blog['title']); ?>

</h5>

<p>

<?php echo substr(
strip_tags($blog['content']),
0,
120
); ?>

...

</p>

<a
href="blog_details.php?id=<?php echo $blog['id']; ?>"
class="btn btn-primary">

Read More

</a>

</div>

</div>

</div>

<?php endforeach; ?>

</div>

</div>

</body>

</html>