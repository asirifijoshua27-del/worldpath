<?php include 'includes/header.php'; ?>
<?php

session_start();

<?php

if(isset($_GET['registered'])){

?>

<div class="alert alert-success">

Registration successful.

Please login to continue.

</div>

<?php

}

?>

if(isset($_SESSION['success_message'])){

    echo '
    <div class="container mt-3">
        <div class="alert alert-success">
            '.$_SESSION['success_message'].'
        </div>
    </div>
    ';

    unset($_SESSION['success_message']);
}

if(isset($_SESSION['error_message'])){

    echo '
    <div class="container mt-3">
        <div class="alert alert-danger">
            '.$_SESSION['error_message'].'
        </div>
    </div>
    ';

    unset($_SESSION['error_message']);
}

?>

<div class="container py-5">

<div class="row justify-content-center">

<div class="col-lg-5">

<div class="card shadow-lg border-0 rounded-4">

<div class="card-body p-5">

<div class="text-center mb-4">

<h2 class="fw-bold text-primary">
Welcome Back
</h2>

<p class="text-muted">
Login to your WorldPath account
</p>

</div>

<form action="process_login.php" method="POST">

<div class="mb-3">

<label class="form-label">
Email Address
</label>

<input
type="email"
name="email"
class="form-control form-control-lg"
required>

</div>

<div class="mb-3">

<label class="form-label">
Password
</label>

<input
type="password"
name="password"
class="form-control form-control-lg"
required>

</div>

<div class="d-grid">

<button
type="submit"
class="btn btn-primary btn-lg">

Login

</button>

</div>

</form>

<hr>

<p class="text-center">

Don't have an account?

<a href="register.php">
Register Here
</a>

</p>

</div>

</div>

</div>

</div>

</div>

<style>

body{
background:#f4f7fc;
}

.card{
border-radius:20px;
}

.form-control{
border-radius:12px;
}

.btn-primary{
background:#0056D2;
border:none;
border-radius:12px;
}

</style>

<?php include 'includes/footer.php'; ?>