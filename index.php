<?php

require 'config/database.php';

include 'includes/header.php';

/*
|--------------------------------------------------------------------------
| LATEST BLOGS
|--------------------------------------------------------------------------
*/

$blogs = $pdo->query("
SELECT *
FROM blogs
ORDER BY id DESC
LIMIT 3
")->fetchAll(PDO::FETCH_ASSOC);

?>

<!-- HERO SECTION -->

<section class="hero">

<div class="container">

<div class="row align-items-center">

<div class="col-lg-6">

<h1>
Study Abroad With Confidence
</h1>

<p>
WorldPath helps students secure university admissions,
visa guidance, document reviews, scholarship opportunities,
and career development support worldwide.
</p>

<a href="application.php" class="btn btn-primary btn-lg me-2">
Apply Now
</a>

<a href="appointment.php" class="btn btn-outline-light btn-lg">
Book Consultation
</a>

</div>

<div class="col-lg-6 text-center">

<img
src="assets/images/students.png"
class="img-fluid"
alt="Students">

</div>

</div>

</div>

</section>

<!-- STATISTICS -->

<section class="section-padding bg-white">

<div class="container">

<div class="row text-center">

<div class="col-md-3 mb-4">

<div class="counter-box">

<h2>500+</h2>

<p>Residents Trained</p>

</div>

</div>

<div class="col-md-3 mb-4">

<div class="counter-box">

<h2>30+</h2>

<p>Students Mentored</p>

</div>

</div>

<div class="col-md-3 mb-4">

<div class="counter-box">

<h2>3+</h2>

<p>Countries Served</p>

</div>

</div>

<div class="col-md-3 mb-4">

<div class="counter-box">

<h2>4+</h2>

<p>University Placements</p>

</div>

</div>

</div>

</div>

</section>

<!-- SERVICES -->

<section class="section-padding bg-light">

<div class="container">

<div class="text-center mb-5">

<h2>
Our Services
</h2>

<p>
Professional education and career support services.
</p>

</div>

<div class="row">

<div class="col-md-4 mb-4">

<div class="card service-card shadow h-100">

<div class="card-body text-center">

<div class="service-icon">
🎓
</div>

<h4>
Study Abroad Consultancy
</h4>

<p>
University admissions,
scholarship assistance,
visa guidance and student support.
</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card service-card shadow h-100">

<div class="card-body text-center">

<div class="service-icon">
💻
</div>

<h4>
STEM Education
</h4>

<p>
Coding,
Artificial Intelligence,
Robotics and Digital Skills.
</p>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card service-card shadow h-100">

<div class="card-body text-center">

<div class="service-icon">
🚀
</div>

<h4>
Career Development
</h4>

<p>
CV Reviews,
Mentorship,
Leadership and Professional Growth.
</p>

</div>

</div>

</div>

</div>

</div>

</section>

<!-- WHY CHOOSE US -->

<section class="section-padding">

<div class="container">

<div class="text-center mb-5">

<h2>
Why Choose WorldPath
</h2>

</div>

<div class="row text-center">

<div class="col-md-4">

<h1 class="text-primary">
30+
</h1>

<p>
Students Mentored
</p>

</div>

<div class="col-md-4">

<h1 class="text-success">
3+
</h1>

<p>
Countries Served
</p>

</div>

<div class="col-md-4">

<h1 class="text-warning">
95%
</h1>

<p>
Student Satisfaction
</p>

</div>

</div>

</div>

</section>

<!-- BLOG SECTION -->

<section class="section-padding bg-light">

<div class="container">

<div class="text-center mb-5">

<h2>
Latest Articles
</h2>

</div>

<div class="row">

<?php foreach($blogs as $blog): ?>

<div class="col-md-4 mb-4">

<div class="card blog-card shadow h-100">

<?php if(!empty($blog['image'])): ?>

<img
src="uploads/<?php echo $blog['image']; ?>"
alt="<?php echo htmlspecialchars($blog['title']); ?>">

<?php endif; ?>

<div class="card-body">

<h5>

<?php echo htmlspecialchars($blog['title']); ?>

</h5>

<p>

<?php echo substr(strip_tags($blog['content']),0,120); ?>

...

</p>

<a
href="blog_details.php?id=<?php echo $blog['id']; ?>"
class="btn btn-primary">

Read More

</a>

</div>

</div>

</div>

<?php endforeach; ?>

</div>

</div>

</section>

<!-- FOUNDER -->

<section class="section-padding">

<div class="container">

<div class="row align-items-center">

<div class="col-lg-5">

<img
src="assets/images/founder.jpg"
class="img-fluid rounded shadow"
alt="Founder">

</div>

<div class="col-lg-7">

<h2>
Meet Our Founder
</h2>

<h4>
Joshua Kwame Asirifi (Cyril)
</h4>

<p>
Founder of WorldPath Group,
Education Consultant,
Entrepreneur and Youth Mentor.
</p>

<p>
Successfully assisted students from Ghana,
Nigeria and Cameroon to secure university
admissions and scholarship opportunities.
</p>

<p>
Student placements include:
</p>

<ul>

<li>Hampton University</li>

<li>Wingate University</li>

<li>University of Wisconsin</li>

<li>St. John's University</li>

</ul>

<p>
Mentored more than 30 students for WASSCE
success and actively supports orphanages
and care homes.
</p>

</div>

</div>

</div>

</section>

<!-- LEADERSHIP TEAM -->

<section class="section-padding bg-light">

<div class="container">

<div class="text-center mb-5">

<h2>
Our Leadership Team
</h2>

<p>
Meet the professionals driving the vision of WorldPath.
</p>

</div>

<div class="row">

<div class="col-lg-3 col-md-6 mb-4">

<div class="card shadow h-100">

<img src="assets/images/founder.jpg" class="card-img-top">

<div class="card-body text-center">

<h5>
Joshua Kwame Asirifi
</h5>

<p class="text-primary fw-bold">
Founder & CEO
</p>

</div>

</div>

</div>

<div class="col-lg-3 col-md-6 mb-4">

<div class="card shadow h-100">

<img src="assets/images/gideon.jpg" class="card-img-top">

<div class="card-body text-center">

<h5>
Gideon Agyei Tuffour
</h5>

<p class="text-primary fw-bold">
Head of Counselling
</p>

</div>

</div>

</div>

<div class="col-lg-3 col-md-6 mb-4">

<div class="card shadow h-100">

<img src="assets/images/nana.jpg" class="card-img-top">

<div class="card-body text-center">

<h5>
Nana Addo Kwadwo
</h5>

<p class="text-primary fw-bold">
Program Coordinator
</p>

</div>

</div>

</div>

<div class="col-lg-3 col-md-6 mb-4">

<div class="card shadow h-100">

<img src="assets/images/priscilla.jpg" class="card-img-top">

<div class="card-body text-center">

<h5>
Priscilla Obiri Yeboah
</h5>

<p class="text-primary fw-bold">
Program Coordinator
</p>

</div>

</div>

</div>

</div>

</div>

</section>

<!-- TESTIMONIALS -->

<section class="section-padding">

<div class="container">

<div class="text-center mb-5">

<h2>
Student Success Stories
</h2>

</div>

<div class="row">

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body">

<p>
"WorldPath guided me through the admission process and helped me secure opportunities abroad."
</p>

<h6>
Student - Ghana
</h6>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body">

<p>
"The mentorship and counselling gave me confidence to pursue my studies internationally."
</p>

<h6>
Student - Nigeria
</h6>

</div>

</div>

</div>

<div class="col-md-4 mb-4">

<div class="card shadow">

<div class="card-body">

<p>
"The support from application preparation to visa guidance was exceptional."
</p>

<h6>
Student - Cameroon
</h6>

</div>

</div>

</div>

</div>

</div>

</section>

<!-- CTA -->

<section class="cta-section py-5">

<div class="container text-center">

<h2>
Ready To Start Your Journey?
</h2>

<p>
Book a consultation today and discover your study abroad opportunities.
</p>

<a
href="appointment.php"
class="btn btn-light btn-lg">

Book Appointment

</a>

</div>

</section>

<?php include 'includes/footer.php'; ?>
