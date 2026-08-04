<?php

session_start();

if (
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
) {
    die("Access Denied");
}

require '../config/database.php';

if (!isset($_GET['id'])) {
    die("Application Not Found");
}

$id = $_GET['id'];

$stmt = $pdo->prepare("
    SELECT *
    FROM applications
    WHERE id = :id
");

$stmt->execute([
    'id' => $id
]);

$application = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$application) {
    die("Application Not Found");
}

?>

<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Application Details</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

<link
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
rel="stylesheet">

<style>

body{
    background:#f5f7fb;
}

.card{
    border:none;
    border-radius:15px;
}

.section-title{
    color:#0056D2;
    font-weight:bold;
    margin-bottom:15px;
}

.document-card{
    border:1px solid #ddd;
    border-radius:10px;
    padding:15px;
    background:#fff;
}

</style>

</head>

<body>

<div class="container py-5">

<a href="applications.php"
class="btn btn-secondary mb-4">

<i class="fas fa-arrow-left"></i>
Back To Applications

</a>

<div class="card shadow">

<div class="card-body p-4">

<h2 class="text-primary mb-4">
Application #<?php echo $application['id']; ?>
</h2>

<hr>

<!-- PERSONAL INFORMATION -->

<h4 class="section-title">
Personal Information
</h4>

<p>
<strong>Full Name:</strong>
<?php echo htmlspecialchars($application['fullname']); ?>
</p>

<p>
<strong>Email:</strong>
<?php echo htmlspecialchars($application['email']); ?>
</p>

<p>
<strong>Phone:</strong>
<?php echo htmlspecialchars($application['phone']); ?>
</p>

<hr>

<!-- ACADEMIC INFORMATION -->

<h4 class="section-title">
Academic Information
</h4>

<p>
<strong>Education Level:</strong>
<?php echo htmlspecialchars($application['education_level']); ?>
</p>

<p>
<strong>Country:</strong>
<?php echo htmlspecialchars($application['country']); ?>
</p>

<p>
<strong>Program:</strong>
<?php echo htmlspecialchars($application['program']); ?>
</p>

<p>
<strong>University:</strong>
<?php echo htmlspecialchars($application['university']); ?>
</p>

<hr>

<!-- STUDY PREFERENCES -->

<h4 class="section-title">
Study Preferences
</h4>

<p>
<strong>Scholarship Assistance Needed:</strong>
<?php echo htmlspecialchars($application['scholarship_needed']); ?>
</p>

<p>
<strong>Preferred Intake:</strong>
<?php echo htmlspecialchars($application['intake']); ?>
</p>

<p>
<strong>Passport Available:</strong>
<?php echo htmlspecialchars($application['passport_available']); ?>
</p>

<hr>

<!-- PERSONAL STATEMENT -->

<h4 class="section-title">
Personal Statement
</h4>

<div class="border rounded p-3 bg-light">

<?php
echo nl2br(
htmlspecialchars($application['statement'])
);
?>

</div>

<hr>

<!-- VERIFICATION SUMMARY -->

<h4 class="section-title">
Verification Summary
</h4>

<div class="row">

<div class="col-md-3 mb-3">
<div class="card border-success">
<div class="card-body text-center">
<h5><?php echo $application['wassce_status']; ?></h5>
<p>WASSCE</p>
</div>
</div>
</div>

<div class="col-md-3 mb-3">
<div class="card border-primary">
<div class="card-body text-center">
<h5><?php echo $application['transcript_status']; ?></h5>
<p>Transcript</p>
</div>
</div>
</div>

<div class="col-md-3 mb-3">
<div class="card border-warning">
<div class="card-body text-center">
<h5><?php echo $application['cv_status']; ?></h5>
<p>CV / Resume</p>
</div>
</div>
</div>

<div class="col-md-3 mb-3">
<div class="card border-info">
<div class="card-body text-center">
<h5><?php echo $application['passport_status']; ?></h5>
<p>Passport</p>
</div>
</div>
</div>

</div>

<hr>

<!-- DOCUMENTS -->

<h4 class="section-title">
Uploaded Documents
</h4>

<div class="row">

<?php

$documents = [

[
'name'=>'WASSCE Result',
'file'=>'wassce_result',
'status'=>'wassce_status'
],

[
'name'=>'Transcript',
'file'=>'transcript',
'status'=>'transcript_status'
],

[
'name'=>'CV / Resume',
'file'=>'cv_resume',
'status'=>'cv_status'
],

[
'name'=>'Passport Document',
'file'=>'passport_document',
'status'=>'passport_status'
]

];

foreach($documents as $doc):

?>

<div class="col-md-6 mb-4">

<div class="document-card">

<h5><?php echo $doc['name']; ?></h5>

<?php if(!empty($application[$doc['file']])): ?>

<a
href="../uploads/<?php echo $application[$doc['file']]; ?>"
target="_blank"
class="btn btn-primary btn-sm">

View Document

</a>

<?php else: ?>

<span class="text-danger">
Not Uploaded
</span>

<?php endif; ?>

<p class="mt-3">

<strong>Current Status:</strong>

<?php echo $application[$doc['status']]; ?>

</p>

<form
action="update_document_status.php"
method="POST">

<input
type="hidden"
name="id"
value="<?php echo $application['id']; ?>">

<input
type="hidden"
name="document"
value="<?php echo $doc['status']; ?>">

<select
name="status"
class="form-select mb-2">

<option value="Pending"
<?php if($application[$doc['status']] == 'Pending') echo 'selected'; ?>>
Pending
</option>

<option value="Verified"
<?php if($application[$doc['status']] == 'Verified') echo 'selected'; ?>>
Verified
</option>

<option value="Rejected"
<?php if($application[$doc['status']] == 'Rejected') echo 'selected'; ?>>
Rejected
</option>

</select>

<button
type="submit"
class="btn btn-success btn-sm">

Update Status

</button>

</form>

</div>

</div>

<?php endforeach; ?>

</div>

<hr>

<!-- APPLICATION STATUS -->

<h4 class="section-title">
Application Status
</h4>

<p>

<strong>Current Status:</strong>

<?php echo htmlspecialchars($application['status']); ?>

</p>

<form
action="update_application.php"
method="POST">

<input
type="hidden"
name="id"
value="<?php echo $application['id']; ?>">

<select
name="status"
class="form-select mb-3">

<option value="Submitted"
<?php if($application['status']=='Submitted') echo 'selected'; ?>>
Submitted
</option>

<option value="Documents Review"
<?php if($application['status']=='Documents Review') echo 'selected'; ?>>
Documents Review
</option>

<option value="Admission Processing"
<?php if($application['status']=='Admission Processing') echo 'selected'; ?>>
Admission Processing
</option>

<option value="Visa Guidance"
<?php if($application['status']=='Visa Guidance') echo 'selected'; ?>>
Visa Guidance
</option>

<option value="Approved"
<?php if($application['status']=='Approved') echo 'selected'; ?>>
Approved
</option>

<option value="Rejected"
<?php if($application['status']=='Rejected') echo 'selected'; ?>>
Rejected
</option>

</select>

<button
type="submit"
class="btn btn-primary">

Update Status

</button>

</form>

<hr>

<!-- STAFF ASSIGNMENT -->

<h4 class="section-title">
Assign Application
</h4>

<div class="alert alert-light">

<p>

<strong>Current Officer:</strong>

<?php

echo !empty($application['assigned_to'])
? htmlspecialchars($application['assigned_to'])
: 'Unassigned';

?>

</p>

<p>

<strong>Assigned Date:</strong>

<?php

echo !empty($application['assigned_date'])
? date(
'd M Y h:i A',
strtotime($application['assigned_date'])
)
: 'Not Assigned Yet';

?>

</p>

</div>

<form
action="assign_application.php"
method="POST">

<input
type="hidden"
name="id"
value="<?php echo $application['id']; ?>">

<label class="form-label">
Assign To Staff Member
</label>

<select
name="assigned_to"
class="form-select mb-3"
required>

<option value="">
Select Staff
</option>

<?php

$staffQuery = $pdo->query("
SELECT *
FROM staff
ORDER BY fullname ASC
");

while($staff = $staffQuery->fetch(PDO::FETCH_ASSOC)):

?>

<option
value="<?php echo htmlspecialchars($staff['fullname']); ?>"

<?php
if(
$application['assigned_to']
==
$staff['fullname']
){
echo "selected";
}
?>

>

<?php echo htmlspecialchars($staff['fullname']); ?>

(<?php echo htmlspecialchars($staff['position']); ?>)

</option>

<?php endwhile; ?>

</select>

<button
type="submit"
class="btn btn-dark">

Assign Application

</button>

</form>

<hr>

<!-- ADMIN NOTES -->

<h4 class="section-title">
Admin Notes
</h4>

<form
action="save_notes.php"
method="POST">

<input
type="hidden"
name="id"
value="<?php echo $application['id']; ?>">

<textarea
name="admin_notes"
class="form-control mb-3"
rows="5"><?php echo htmlspecialchars($application['admin_notes'] ?? ''); ?></textarea>

<button
type="submit"
class="btn btn-success">

Save Notes

</button>

</form>

<hr>

<!-- SEND NOTIFICATION -->

<h4 class="section-title">
Send Notification To Student
</h4>

<form
action="send_notification.php"
method="POST">

<input
type="hidden"
name="application_id"
value="<?php echo $application['id']; ?>">

<input
type="hidden"
name="student_email"
value="<?php echo htmlspecialchars($application['email']); ?>">

<input
type="text"
name="title"
class="form-control mb-3"
placeholder="Notification Title"
required>

<textarea
name="message"
class="form-control mb-3"
rows="4"
placeholder="Write notification..."
required></textarea>

<button
type="submit"
class="btn btn-warning">

Send Notification

</button>

</form>

</div>

</div>

</div>

</body>
</html>