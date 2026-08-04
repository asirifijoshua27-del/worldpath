<?php

require 'config/database.php';

if(!isset($_GET['id'])){
    die("Blog Not Found");
}

$id = $_GET['id'];

$stmt = $pdo->prepare("
SELECT *
FROM blogs
WHERE id=:id
");

$stmt->execute([
    'id'=>$id
]);

$blog = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$blog){
    die("Blog Not Found");
}

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
<?php echo $blog['title']; ?>
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<a
href="blogs.php"
class="btn btn-secondary mb-4">

Back To Blog

</a>

<h1>

<?php echo htmlspecialchars($blog['title']); ?>

</h1>

<p class="text-muted">

By

<?php echo htmlspecialchars($blog['author']); ?>

|

<?php echo $blog['created_at']; ?>

</p>

<?php if(!empty($blog['featured_image'])): ?>

<img
src="uploads/<?php echo $blog['featured_image']; ?>"
class="img-fluid rounded mb-4">

<?php endif; ?>

<div>

<?php echo nl2br(
htmlspecialchars($blog['content'])
); ?>

</div>

</div>

</body>

</html>