<?php

session_start();

require '../config/database.php';

if($_SERVER['REQUEST_METHOD']=="POST"){

$fullname=$_POST['fullname'];
$position=$_POST['position'];
$bio=$_POST['bio'];

$stmt=$pdo->prepare("
INSERT INTO staff
(fullname,position,bio)
VALUES
(:fullname,:position,:bio)
");

$stmt->execute([
'fullname'=>$fullname,
'position'=>$position,
'bio'=>$bio
]);

header("Location: staff.php");
exit;
}

?>

<!DOCTYPE html>
<html>

<head>

<title>Add Staff</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

</head>

<body>

<div class="container py-5">

<h2>
Add Staff Member
</h2>

<form method="POST">

<div class="mb-3">

<label>Name</label>

<input
type="text"
name="fullname"
class="form-control"
required>

</div>

<div class="mb-3">

<label>Position</label>

<input
type="text"
name="position"
class="form-control"
required>

</div>

<div class="mb-3">

<label>Biography</label>

<textarea
name="bio"
class="form-control"
rows="5"></textarea>

</div>

<button
class="btn btn-primary">

Save Staff

</button>

</form>

</div>

</body>

</html>