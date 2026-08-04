<?php include 'includes/header.php'; ?>

<section class="py-5 text-white"
style="background:linear-gradient(135deg,#0056D2,#00A8CC);">

<div class="container text-center">

<h1 class="display-4 fw-bold">
Contact Us
</h1>

<p class="lead">
We would love to hear from you.
</p>

</div>

</section>

<div class="container py-5">

<div class="row">

<div class="col-lg-7">

<h2>Send Us A Message</h2>
<?php if(isset($_GET['success'])): ?>

<div class="alert alert-success">

Message sent successfully.

</div>

<?php endif; ?>

<form action="process_contact.php"
method="POST">

<div class="mb-3">

<label class="form-label">
Full Name
</label>

<input type="text"
name="fullname"
class="form-control"
required>

</div>

<div class="mb-3">

<label class="form-label">
Email
</label>

<input type="email"
name="email"
class="form-control"
required>

</div>

<div class="mb-3">

<label class="form-label">
Subject
</label>

<input type="text"
name="subject"
class="form-control"
required>

</div>

<div class="mb-3">

<label class="form-label">
Message
</label>

<textarea
name="message"
rows="5"
class="form-control"
required></textarea>

</div>

<button
type="submit"
class="btn btn-primary">

Send Message

</button>

</form>

</div>

<div class="col-lg-5">

<div class="card shadow">

<div class="card-body">

<h3>Contact Information</h3>

<hr>

<p>

<strong>Phone:</strong><br>

0530901898<br>

0509878889

</p>

<p>

<strong>Email:</strong><br>

asirifijoshua27@gmail.com

</p>

<p>

<strong>Organization:</strong><br>

WorldPath Group

</p>

</div>

</div>

</div>

</div>

</div>

<?php include 'includes/footer.php'; ?>