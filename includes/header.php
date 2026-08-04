<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
?>

<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>WorldPath Group</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

<link
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
rel="stylesheet">

<link
href="assets/css/style.css"
rel="stylesheet">

</head>

<body>

<!-- NAVBAR -->

<nav class="navbar navbar-expand-lg navbar-dark bg-primary sticky-top shadow">

<div class="container">

<a class="navbar-brand fw-bold" href="index.php">

<i class="fas fa-globe-americas me-2"></i>

WorldPath Group

</a>

<button
class="navbar-toggler"
type="button"
data-bs-toggle="collapse"
data-bs-target="#navbarNav">

<span class="navbar-toggler-icon"></span>

</button>

<div
class="collapse navbar-collapse"
id="navbarNav">

<ul class="navbar-nav ms-auto align-items-lg-center">

<li class="nav-item">
<a class="nav-link" href="index.php">
Home
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="about.php">
About
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="services.php">
Services
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="application.php">
Apply
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="appointments.php">
Book Appointment
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="blogs.php">
Blog
</a>
</li>

<li class="nav-item">
<a class="nav-link" href="contact.php">
Contact
</a>
</li>

<?php if(isset($_SESSION['user_id'])): ?>

    <?php if(isset($_SESSION['role']) && $_SESSION['role'] == 'admin'): ?>

        <li class="nav-item ms-lg-3">

            <a
            href="admin/dashboard.php"
            class="btn btn-warning">

            <i class="fas fa-user-shield"></i>

            Admin Dashboard

            </a>

        </li>

    <?php else: ?>

        <li class="nav-item ms-lg-3">

            <a
            href="student/dashboard.php"
            class="btn btn-success">

            <i class="fas fa-user-graduate"></i>

            Dashboard

            </a>

        </li>

    <?php endif; ?>

    <li class="nav-item ms-lg-2">

        <a
        href="logout.php"
        class="btn btn-danger">

        <i class="fas fa-sign-out-alt"></i>

        Logout

        </a>

    </li>

<?php else: ?>

    <li class="nav-item ms-lg-3">

        <a
        href="login.php"
        class="btn btn-outline-light">

        <i class="fas fa-sign-in-alt"></i>

        Login

        </a>

    </li>

    <li class="nav-item ms-lg-2">

        <a
        href="register.php"
        class="btn btn-warning">

        <i class="fas fa-user-plus"></i>

        Register

        </a>

    </li>

<?php endif; ?>

</ul>

</div>

</div>

</nav>