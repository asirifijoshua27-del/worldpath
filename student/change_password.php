<?php

session_start();

if(!isset($_SESSION['user_id'])){
    header("Location: ../login.php");
    exit();
}

require '../config/database.php';

if($_SERVER['REQUEST_METHOD']=='POST'){

    $password = password_hash(
        $_POST['password'],
        PASSWORD_DEFAULT
    );

    $stmt = $pdo->prepare("
    UPDATE users
    SET password = :password
    WHERE id = :id
    ");

    $stmt->execute([
        'password'=>$password,
        'id'=>$_SESSION['user_id']
    ]);

    $success = true;
}

?>

<!DOCTYPE html>
<html>
<head>

<title>Change Password</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>Change Password</h2>

<?php if(isset($success)): ?>

<div class="alert alert-success">
Password Updated Successfully
</div>

<?php endif; ?>

<form method="POST">

<div class="mb-3">

<label>New Password</label>

<input
type="password"
name="password"
class="form-control"
required>

</div>

<button class="btn btn-success">

Update Password

</button>

</form>

</div>

</body>
</html>