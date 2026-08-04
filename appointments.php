<?php include 'includes/header.php'; ?>

<section class="py-5">

<div class="container">

<h2 class="text-center mb-5">

Book Appointment

</h2>

<form
action="process_appointment.php"
method="POST">

<div class="row">

<div class="col-md-6 mb-3">

<input
type="text"
name="fullname"
class="form-control"
placeholder="Full Name"
required>

</div>

<div class="col-md-6 mb-3">

<input
type="email"
name="email"
class="form-control"
placeholder="Email"
required>

</div>

<div class="col-md-6 mb-3">

<input
type="text"
name="phone"
class="form-control"
placeholder="Phone Number">

</div>

<div class="col-md-6 mb-3">

<select
name="service"
class="form-control">

<option>
Study Abroad
</option>

<option>
STEM Education
</option>

<option>
Career Development
</option>

</select>

</div>

<div class="col-md-6 mb-3">

<input
type="date"
name="appointment_date"
class="form-control"
required>

</div>

<div class="col-md-6 mb-3">

<input
type="time"
name="appointment_time"
class="form-control"
required>

</div>

</div>

<button
class="btn btn-primary">

Book Appointment

</button>

</form>

</div>

</section>

<?php include 'includes/footer.php'; ?>