<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

if(!isset($_GET['id'])){
    die("Blog Not Found");
}

$id = $_GET['id'];

$stmt = $pdo->prepare("
SELECT *
FROM blogs
WHERE id = :id
");

$stmt->execute([
    'id' => $id
]);

$blog = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$blog){
    die("Blog Not Found");
}

if($_SERVER['REQUEST_METHOD'] == 'POST'){

    $title = trim($_POST['title']);
    $content = trim($_POST['content']);
    $status = $_POST['status'];

    $slug = strtolower(
        preg_replace(
            '/[^A-Za-z0-9-]+/',
            '-',
            $title
        )
    );

    $update = $pdo->prepare("
    UPDATE blogs
    SET
        title = :title,
        slug = :slug,
        content = :content,
        status = :status
    WHERE id = :id
    ");

    $update->execute([
        'title' => $title,
        'slug' => $slug,
        'content' => $content,
        'status' => $status,
        'id' => $id
    ]);

    header("Location: blogs.php");
    exit();
}

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>
Edit Blog
</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>
Edit Blog
</h2>

<hr>

<form method="POST">

<div class="mb-3">

<label class="form-label">
Title
</label>

<input
type="text"
name="title"
class="form-control"
value="<?php echo htmlspecialchars($blog['title']); ?>"
required>

</div>

<div class="mb-3">

<label class="form-label">
Content
</label>

<textarea
name="content"
class="form-control"
rows="12"
required><?php echo htmlspecialchars($blog['content']); ?></textarea>

</div>

<div class="mb-3">

<label class="form-label">
Status
</label>

<select
name="status"
class="form-select">

<option
value="Draft"
<?php if($blog['status']=="Draft") echo "selected"; ?>>
Draft
</option>

<option
value="Published"
<?php if($blog['status']=="Published") echo "selected"; ?>>
Published
</option>

</select>

</div>

<button
class="btn btn-primary">

Update Blog

</button>

<a
href="blogs.php"
class="btn btn-secondary">

Back

</a>

</form>

</div>

</body>

</html>