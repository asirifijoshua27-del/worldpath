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
    die("Staff Member Not Found");
}

$id = $_GET['id'];

$stmt = $pdo->prepare("
SELECT *
FROM staff
WHERE id = :id
");

$stmt->execute([
    'id' => $id
]);

$staff = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$staff){
    die("Staff Member Not Found");
}

if($_SERVER['REQUEST_METHOD'] == 'POST'){

    $fullname = trim($_POST['fullname']);
    $position = trim($_POST['position']);
    $bio = trim($_POST['bio']);

    $photo = $staff['photo'];

    if(
        isset($_FILES['photo']) &&
        $_FILES['photo']['error'] == 0
    ){

        $filename =
        time() . "_" .
        basename($_FILES['photo']['name']);

        move_uploaded_file(
            $_FILES['photo']['tmp_name'],
            "../uploads/" . $filename
        );

        $photo = $filename;
    }

    $update = $pdo->prepare("
    UPDATE staff
    SET
        fullname = :fullname,
        position = :position,
        bio = :bio,
        photo = :photo
    WHERE id = :id
    ");

    $update->execute([
        'fullname' => $fullname,
        'position' => $position,
        'bio' => $bio,
        'photo' => $photo,
        'id' => $id
    ]);

    header("Location: staff.php");
    exit();
}

?>

<!DOCTYPE html>
<html>

<head>

<meta charset="UTF-8">

<title>Edit Staff Member</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2>Edit Staff Member</h2>

<hr>

<form
method="POST"
enctype="multipart/form-data">

<div class="mb-3">

<label class="form-label">
Full Name
</label>

<input
type="text"
name="fullname"
class="form-control"
value="<?php echo htmlspecialchars($staff['fullname']); ?>"
required>

</div>

<div class="mb-3">

<label class="form-label">
Position
</label>

<input
type="text"
name="position"
class="form-control"
value="<?php echo htmlspecialchars($staff['position']); ?>"
required>

</div>

<div class="mb-3">

<label class="form-label">
Bio
</label>

<textarea
name="bio"
class="form-control"
rows="6"><?php echo htmlspecialchars($staff['bio']); ?></textarea>

</div>

<div class="mb-3">

<label class="form-label">
Change Photo
</label>

<input
type="file"
name="photo"
class="form-control">

</div>

<?php if(!empty($staff['photo'])): ?>

<div class="mb-3">

<p>Current Photo</p>

<img
src="../uploads/<?php echo htmlspecialchars($staff['photo']); ?>"
width="150"
class="img-thumbnail">

</div>

<?php endif; ?>

<button
type="submit"
class="btn btn-primary">

Update Staff

</button>

<a
href="staff.php"
class="btn btn-secondary">

Back

</a>

</form>

</div>

</body>

</html>