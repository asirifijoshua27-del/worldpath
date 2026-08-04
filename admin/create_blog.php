<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

$message = '';

if($_SERVER['REQUEST_METHOD'] == 'POST'){

    $title = trim($_POST['title']);
    $summary = trim($_POST['summary']);
    $content = trim($_POST['content']);
    $author = $_SESSION['fullname'];

    $slug = strtolower(
        preg_replace(
            '/[^A-Za-z0-9-]+/',
            '-',
            $title
        )
    );

    $imageName = '';

    if(!empty($_FILES['featured_image']['name'])){

        $imageName =
        time().'_'.$_FILES['featured_image']['name'];

        move_uploaded_file(
            $_FILES['featured_image']['tmp_name'],
            '../uploads/'.$imageName
        );
    }

    $stmt = $pdo->prepare("
        INSERT INTO blogs
        (
            title,
            slug,
            summary,
            content,
            featured_image,
            author
        )
        VALUES
        (
            :title,
            :slug,
            :summary,
            :content,
            :featured_image,
            :author
        )
    ");

    $stmt->execute([

        'title'=>$title,
        'slug'=>$slug,
        'summary'=>$summary,
        'content'=>$content,
        'featured_image'=>$imageName,
        'author'=>$author

    ]);

    $message = "Blog Published Successfully";
}

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>Create Blog</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>Create Blog Post</h2>

<hr>

<?php if($message): ?>

<div class="alert alert-success">
<?php echo $message; ?>
</div>

<?php endif; ?>

<form
method="POST"
enctype="multipart/form-data">

<div class="mb-3">

<label>Title</label>

<input
type="text"
name="title"
class="form-control"
required>

</div>

<div class="mb-3">

<label>Summary</label>

<textarea
name="summary"
class="form-control"
rows="3"></textarea>

</div>

<div class="mb-3">

<label>Featured Image</label>

<input
type="file"
name="featured_image"
class="form-control">

</div>

<div class="mb-3">

<label>Content</label>

<textarea
name="content"
class="form-control"
rows="12"
required></textarea>

</div>

<button
class="btn btn-primary">

Publish Blog

</button>

</form>

</div>

</body>

</html>