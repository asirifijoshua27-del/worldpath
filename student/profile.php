<?php

session_start();

if(!isset($_SESSION['user_id'])){
    header("Location: ../login.php");
    exit();
}

require '../config/database.php';

$stmt = $pdo->prepare("
SELECT *
FROM users
WHERE id = :id
");

$stmt->execute([
    'id' => $_SESSION['user_id']
]);

$user = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$user){
    die("User Not Found");
}

if($_SERVER['REQUEST_METHOD'] == 'POST'){

    $fullname = trim($_POST['fullname']);
    $phone = trim($_POST['phone']);

    $update = $pdo->prepare("
    UPDATE users
    SET
        fullname = :fullname,
        phone = :phone
    WHERE id = :id
    ");

    $update->execute([
        'fullname' => $fullname,
        'phone' => $phone,
        'id' => $_SESSION['user_id']
    ]);

    header("Location: profile.php");
    exit();
}

?>

<!DOCTYPE html>
<html>
<head>

<title>My Profile</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>My Profile</h2>

<hr>

<form method="POST">

<div class="mb-3">

<label class="form-label">
Full Name
</label>

<input
type="text"
name="fullname"
class="form-control"
value="<?php echo htmlspecialchars($user['fullname']); ?>"
required>

</div>

<div class="mb-3">

<label class="form-label">
Email
</label>

<input
type="email"
class="form-control"
value="<?php echo htmlspecialchars($user['email']); ?>"
readonly>

</div>

<div class="mb-3">

<label class="form-label">
Phone
</label>

<input
type="text"
name="phone"
class="form-control"
value="<?php echo htmlspecialchars($user['phone'] ?? ''); ?>">

</div>

<button class="btn btn-primary">
Update Profile
</button>

</form>

</div>

</body>
</html>