<?php

include 'includes/header.php';

if(!isset($_SESSION['user_id'])){

    header("Location: login.php");
    exit();

}

require 'config/database.php';

/*
|--------------------------------------------------------------------------
| Prevent duplicate applications
|--------------------------------------------------------------------------
*/

$check = $pdo->prepare("
SELECT id
FROM applications
WHERE email = :email
LIMIT 1
");

$check->execute([
    'email' => $_SESSION['email']
]);

if($check->fetch()){

    header("Location: student/dashboard.php");
    exit();

}

?>

<style>

.hero-section{
    background:
    linear-gradient(
        rgba(0,0,0,0.55),
        rgba(0,0,0,0.55)
    ),
    url('assets/images/application-hero.jpg');

    background-size:cover;
    background-position:center;
    min-height:450px;

    display:flex;
    align-items:center;
    justify-content:center;
}

.stats-card{
    border:none;
    border-radius:15px;
    transition:0.3s;
}

.stats-card:hover{
    transform:translateY(-5px);
}

.application-card{
    border:none;
    border-radius:20px;
}

.section-title{
    color:#0056D2;
    font-weight:700;
    margin-bottom:20px;
}

.form-control,
.form-select{
    padding:12px;
    border-radius:10px;
}

.upload-box{
    background:#f8f9fa;
    border:2px dashed #ced4da;
    padding:20px;
    border-radius:12px;
}

</style>

<!-- HERO -->

<section class="hero-section text-white">

<div class="container text-center">

<h1 class="display-3 fw-bold">

WorldPath Study Abroad Application Portal

</h1>

<p class="lead mt-3">

Take the first step toward studying abroad with
scholarships, admissions guidance and visa support.

</p>

<a href="#applicationForm"
class="btn btn-info btn-lg mt-3">

Start Application

</a>

</div>

</section>

<!-- STATISTICS -->

<section class="py-5 bg-light">

<div class="container">

<div class="row text-center">

<div class="col-md-3 mb-3">

<div class="card stats-card shadow">

<div class="card-body">

<h2 class="text-primary">500+</h2>

<p>Residents Trained</p>

</div>

</div>

</div>

<div class="col-md-3 mb-3">

<div class="card stats-card shadow">

<div class="card-body">

<h2 class="text-primary">30+</h2>

<p>Students Mentored</p>

</div>

</div>

</div>

<div class="col-md-3 mb-3">

<div class="card stats-card shadow">

<div class="card-body">

<h2 class="text-primary">3</h2>

<p>Countries Served</p>

</div>

</div>

</div>

<div class="col-md-3 mb-3">

<div class="card stats-card shadow">

<div class="card-body">

<h2 class="text-primary">4+</h2>

<p>US University Placements</p>

</div>

</div>

</div>

</div>

</div>

</section>

<!-- APPLICATION FORM -->

<section class="py-5" id="applicationForm">

<div class="container">

<div class="card shadow-lg application-card">

<div class="card-body p-5">

<h2 class="text-center text-primary mb-5">

Study Abroad Application Form

</h2>

<?php if(isset($_GET['success'])): ?>

<div class="alert alert-success">

Application Submitted Successfully.

</div>

<?php endif; ?>

<form
action="process_application.php"
method="POST"
enctype="multipart/form-data">

<!-- PERSONAL INFORMATION -->

<h4 class="section-title">

Personal Information

</h4>

<div class="row">

<div class="col-md-6 mb-3">

<label>Full Name</label>

<input
type="text"
name="fullname"
class="form-control"
required>

</div>

<div class="col-md-6 mb-3">

<label>Email Address</label>

<input
type="email"
name="email"
class="form-control"
required>

</div>

<div class="col-md-6 mb-3">

<label>Phone Number</label>

<input
type="text"
name="phone"
class="form-control"
required>

</div>

<div class="col-md-6 mb-3">

<label>Current Education Level</label>

<select
name="education_level"
class="form-select"
required>

<option value="">Select Level</option>

<option>SHS Graduate</option>
<option>Diploma Holder</option>
<option>Bachelor's Degree</option>
<option>Master's Degree</option>

</select>

</div>

</div>

<hr>

<!-- STUDY PREFERENCES -->

<h4 class="section-title">

Study Preferences

</h4>

<div class="row">

<div class="col-md-6 mb-3">

<label>Country of Interest</label>

<select
name="country"
class="form-select"
required>

<option value="">Select Country</option>

<option>United States</option>
<option>Canada</option>
<option>United Kingdom</option>
<option>Australia</option>
<option>Germany</option>
<option>France</option>
<option>Italy</option>
<option>Netherlands</option>
<option>Ireland</option>
<option>Sweden</option>
<option>Finland</option>
<option>Japan</option>
<option>South Korea</option>
<option>Malaysia</option>

</select>

</div>

<div class="col-md-6 mb-3">

<label>Program of Interest</label>

<select
name="program"
class="form-select"
required>

<option value="">Select Program</option>

<option>Computer Science</option>
<option>Software Engineering</option>
<option>Artificial Intelligence</option>
<option>Cyber Security</option>
<option>Medicine</option>
<option>Nursing</option>
<option>Business Administration</option>
<option>Accounting</option>
<option>Finance</option>
<option>Law</option>
<option>Mechanical Engineering</option>
<option>Civil Engineering</option>
<option>Data Science</option>
<option>Architecture</option>
<option>Education</option>
<option>Other</option>

</select>

</div>

<div class="col-md-6 mb-3">

<label>Preferred University</label>

<select
name="university"
id="university"
class="form-select"
onchange="toggleUniversity()">

<option value="">Select University</option>

<option>Hampton University</option>
<option>Wingate University</option>
<option>University of Wisconsin</option>
<option>St. John's University</option>
<option>Harvard University</option>
<option>MIT</option>
<option>Stanford University</option>
<option value="Other">Other</option>

</select>

</div>

<div
class="col-md-6 mb-3"
id="otherUniversityDiv"
style="display:none;">

<label>Enter University Name</label>

<input
type="text"
name="other_university"
class="form-control">

</div>

<div class="col-md-6 mb-3">

<label>Need Scholarship?</label>

<select
name="scholarship_needed"
class="form-select"
required>

<option value="">Select</option>

<option>Yes</option>
<option>No</option>

</select>

</div>

<div class="col-md-6 mb-3">

<label>Preferred Intake</label>

<select
name="intake"
class="form-select"
required>

<option value="">Select Intake</option>

<option>Spring</option>
<option>Summer</option>
<option>Fall</option>

</select>

</div>

<div class="col-md-6 mb-3">

<label>Do You Have A Passport?</label>

<select
name="passport_available"
class="form-select"
required>

<option value="">Select</option>

<option>Yes</option>
<option>No</option>

</select>

</div>

</div>

<hr>

<!-- PERSONAL STATEMENT -->

<h4 class="section-title">

Personal Statement

</h4>

<div class="mb-4">

<textarea
name="statement"
rows="6"
class="form-control"
placeholder="Tell us about your academic goals, achievements and why you want to study abroad."></textarea>

</div>

<hr>

<!-- DOCUMENTS -->

<h4 class="section-title">

Upload Documents

</h4>

<div class="row">

<div class="col-md-6 mb-4">

<div class="upload-box">

<label>WASSCE Results</label>

<input
type="file"
name="wassce_result"
class="form-control">

</div>

</div>

<div class="col-md-6 mb-4">

<div class="upload-box">

<label>Transcript</label>

<input
type="file"
name="transcript"
class="form-control">

</div>

</div>

<div class="col-md-6 mb-4">

<div class="upload-box">

<label>CV / Resume</label>

<input
type="file"
name="cv_resume"
class="form-control">

</div>

</div>

<div class="col-md-6 mb-4">

<div class="upload-box">

<label>Passport Bio Page</label>

<input
type="file"
name="passport_document"
class="form-control">

</div>

</div>

</div>

<div class="text-center">

<button
type="submit"
class="btn btn-primary btn-lg px-5">

Submit Application

</button>

</div>

</form>

</div>

</div>

</div>

</section>

<script>

function toggleUniversity(){

let university =
document.getElementById("university");

let otherUniversity =
document.getElementById("otherUniversityDiv");

if(university.value === "Other"){

otherUniversity.style.display = "block";

}else{

otherUniversity.style.display = "none";

}

}

</script>

<?php include 'includes/footer.php'; ?>
