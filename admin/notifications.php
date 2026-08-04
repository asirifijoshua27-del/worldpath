<?php

session_start();

if(!isset($_SESSION['role']) || $_SESSION['role'] != 'admin'){
    die('Access Denied');
}

require '../config/database.php';
require '../includes/site_setup.php';
ensure_notifications_table($pdo);

if(isset($_GET['read'])){
    $mark = $pdo->prepare("UPDATE notifications SET is_read = TRUE WHERE id = :id AND sender_role = 'student'");
    $mark->execute(['id' => $_GET['read']]);
    header('Location: notifications.php');
    exit();
}

$students = $pdo->query("
SELECT a.id AS application_id, a.fullname, a.email, u.id AS user_id
FROM applications a
LEFT JOIN users u ON u.email = a.email
ORDER BY a.fullname ASC
")->fetchAll(PDO::FETCH_ASSOC);

$stmt = $pdo->query("
SELECT n.*, a.fullname, a.email
FROM notifications n
LEFT JOIN applications a ON a.id = n.application_id
WHERE n.sender_role = 'student'
ORDER BY n.created_at DESC
");
$studentMessages = $stmt->fetchAll(PDO::FETCH_ASSOC);

$sent = $pdo->query("
SELECT n.*, a.fullname, a.email
FROM notifications n
LEFT JOIN applications a ON a.id = n.application_id
WHERE n.sender_role = 'admin'
ORDER BY n.created_at DESC
LIMIT 20
")->fetchAll(PDO::FETCH_ASSOC);

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Notifications</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
<style>
body{background:#f4f6f9;}
.sidebar{width:260px;min-height:100vh;background:#0056D2;}
.sidebar a{color:white;text-decoration:none;display:block;padding:12px;border-radius:8px;margin-bottom:8px;}
.sidebar a:hover,.sidebar a.active{background:#00A8CC;}
.card{border:none;border-radius:8px;}
.message-unread{border-left:5px solid #ffc107;}
</style>
</head>
<body>
<div class="d-flex">
<div class="sidebar p-3 text-white">
<h3 class="mb-4">WorldPath CRM</h3>
<a href="dashboard.php"><i class="fas fa-chart-line"></i> Dashboard</a>
<a href="homepage_editor.php"><i class="fas fa-pen-to-square"></i> Homepage Editor</a>
<a href="notifications.php" class="active"><i class="fas fa-bell"></i> Notifications</a>
<a href="applications.php"><i class="fas fa-user-graduate"></i> Applications</a>
<a href="appointments.php"><i class="fas fa-calendar"></i> Appointments</a>
<a href="messages.php"><i class="fas fa-envelope"></i> Messages</a>
<a href="users.php"><i class="fas fa-users"></i> Users</a>
<a href="staff.php"><i class="fas fa-user-tie"></i> Staff</a>
<a href="../logout.php"><i class="fas fa-sign-out-alt"></i> Logout</a>
</div>

<div class="flex-grow-1 p-4">
<div class="d-flex justify-content-between align-items-center mb-4">
<div>
<h2>Notification Center</h2>
<p class="text-muted mb-0">Send updates to students and read student replies.</p>
</div>
</div>

<?php if(isset($_GET['sent'])): ?>
<div class="alert alert-success">Notification sent successfully.</div>
<?php endif; ?>

<div class="row g-4">
<div class="col-lg-5">
<div class="card shadow h-100">
<div class="card-header bg-primary text-white">Send Notification To Student</div>
<div class="card-body">
<form action="send_notification.php" method="POST">
<label class="form-label">Student</label>
<select name="application_id" class="form-select mb-3" required>
<option value="">Select student</option>
<?php foreach($students as $student): ?>
<option value="<?php echo $student['application_id']; ?>">
<?php echo htmlspecialchars($student['fullname'] . ' - ' . $student['email']); ?>
</option>
<?php endforeach; ?>
</select>
<label class="form-label">Title</label>
<input type="text" name="title" class="form-control mb-3" required>
<label class="form-label">Message</label>
<textarea name="message" rows="6" class="form-control mb-3" required></textarea>
<button class="btn btn-warning w-100"><i class="fas fa-paper-plane"></i> Send Notification</button>
</form>
</div>
</div>
</div>

<div class="col-lg-7">
<div class="card shadow mb-4">
<div class="card-header bg-dark text-white">Student Messages</div>
<div class="card-body">
<?php if(empty($studentMessages)): ?>
<div class="alert alert-info mb-0">No student messages yet.</div>
<?php endif; ?>
<?php foreach($studentMessages as $message): ?>
<div class="card shadow-sm mb-3 <?php echo empty($message['is_read']) ? 'message-unread' : ''; ?>">
<div class="card-body">
<div class="d-flex justify-content-between gap-3">
<div>
<h5 class="mb-1"><?php echo htmlspecialchars($message['title']); ?></h5>
<p class="text-muted mb-2">
<?php echo htmlspecialchars(($message['fullname'] ?? 'Student') . ' - ' . ($message['email'] ?? '')); ?>
</p>
</div>
<?php if(empty($message['is_read'])): ?>
<a href="notifications.php?read=<?php echo $message['id']; ?>" class="btn btn-sm btn-outline-success align-self-start">Mark Read</a>
<?php endif; ?>
</div>
<p><?php echo nl2br(htmlspecialchars($message['message'])); ?></p>
<small class="text-muted"><?php echo htmlspecialchars($message['created_at']); ?></small>
</div>
</div>
<?php endforeach; ?>
</div>
</div>

<div class="card shadow">
<div class="card-header bg-success text-white">Recently Sent</div>
<div class="card-body">
<?php if(empty($sent)): ?>
<div class="alert alert-info mb-0">No sent notifications yet.</div>
<?php endif; ?>
<?php foreach($sent as $message): ?>
<div class="border-bottom pb-3 mb-3">
<h6 class="mb-1"><?php echo htmlspecialchars($message['title']); ?></h6>
<p class="small text-muted mb-1">To <?php echo htmlspecialchars($message['fullname'] ?? $message['email'] ?? 'Student'); ?></p>
<p class="mb-1"><?php echo nl2br(htmlspecialchars($message['message'])); ?></p>
<small class="text-muted"><?php echo htmlspecialchars($message['created_at']); ?></small>
</div>
<?php endforeach; ?>
</div>
</div>
</div>
</div>
</div>
</div>
</body>
</html>
