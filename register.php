```php
<?php include 'includes/header.php'; ?>
<?php

session_start();

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

<div class="col-lg-6">

<div class="card shadow-lg border-0 rounded-4">

<div class="card-body p-5">

<div class="text-center mb-4">

<h2 class="fw-bold text-primary">
Create Account
</h2>

<p class="text-muted">
Join WorldPath and start your study abroad journey.
</p>

</div>

<form action="process_register.php" method="POST">

<div class="mb-3">

<label class="form-label fw-semibold">
Full Name
</label>

<input
type="text"
name="fullname"
class="form-control form-control-lg"
placeholder="Enter your full name"
required>

</div>

<div class="mb-3">

<label class="form-label fw-semibold">
Email Address
</label>

<input
type="email"
name="email"
class="form-control form-control-lg"
placeholder="Enter your email"
required>

</div>

<div class="mb-3">

<label class="form-label fw-semibold">
Password
</label>

<input
type="password"
name="password"
class="form-control form-control-lg"
placeholder="Create a password"
required>

</div>

<div class="d-grid">

<button
type="submit"
class="btn btn-primary btn-lg">

Register

</button>

</div>

</form>

<hr class="my-4">

<p class="text-center mb-0">

Already have an account?

<a href="login.php"
class="text-decoration-none fw-bold">

Login Here

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

.btn-primary:hover{
    background:#0042a8;
}

</style>

<?php include 'includes/footer.php'; ?>
```