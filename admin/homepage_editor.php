<?php

session_start();

if(!isset($_SESSION['role']) || $_SESSION['role'] != 'admin'){
    die('Access Denied');
}

require '../config/database.php';
require '../includes/site_setup.php';

$homepage = get_homepage_settings($pdo);

if($_SERVER['REQUEST_METHOD'] === 'POST'){
    $allowed = array_keys($homepage);
    $updates = [];

    foreach($allowed as $key){
        $updates[$key] = $_POST[$key] ?? '';
    }

    save_homepage_settings($pdo, $updates);

    header('Location: homepage_editor.php?saved=1');
    exit();
}

$groups = [
    'Hero Section' => ['hero_title','hero_subtitle','hero_primary_button','hero_secondary_button'],
    'Homepage Numbers' => ['stat_one_number','stat_one_label','stat_two_number','stat_two_label','stat_three_number','stat_three_label','stat_four_number','stat_four_label'],
    'Call To Action' => ['cta_title','cta_text','cta_button']
];

$labels = [
    'hero_title' => 'Hero Title',
    'hero_subtitle' => 'Hero Subtitle',
    'hero_primary_button' => 'Primary Button Text',
    'hero_secondary_button' => 'Secondary Button Text',
    'stat_one_number' => 'First Number',
    'stat_one_label' => 'First Label',
    'stat_two_number' => 'Second Number',
    'stat_two_label' => 'Second Label',
    'stat_three_number' => 'Third Number',
    'stat_three_label' => 'Third Label',
    'stat_four_number' => 'Fourth Number',
    'stat_four_label' => 'Fourth Label',
    'cta_title' => 'CTA Title',
    'cta_text' => 'CTA Text',
    'cta_button' => 'CTA Button Text'
];

?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Homepage Editor</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
<style>
body{background:#f4f6f9;}
.sidebar{width:260px;min-height:100vh;background:#0056D2;}
.sidebar a{color:white;text-decoration:none;display:block;padding:12px;border-radius:8px;margin-bottom:8px;}
.sidebar a:hover,.sidebar a.active{background:#00A8CC;}
.card{border:none;border-radius:8px;}
textarea{min-height:120px;}
</style>
</head>
<body>
<div class="d-flex">
<div class="sidebar p-3 text-white">
<h3 class="mb-4">WorldPath CRM</h3>
<a href="dashboard.php"><i class="fas fa-chart-line"></i> Dashboard</a>
<a href="homepage_editor.php" class="active"><i class="fas fa-pen-to-square"></i> Homepage Editor</a>
<a href="notifications.php"><i class="fas fa-bell"></i> Notifications</a>
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
<h2>Homepage Editor</h2>
<p class="text-muted mb-0">Edit the homepage text from here. No code needed.</p>
</div>
<a href="../index.php" target="_blank" class="btn btn-outline-primary"><i class="fas fa-eye"></i> Preview Homepage</a>
</div>

<?php if(isset($_GET['saved'])): ?>
<div class="alert alert-success">Homepage updated successfully.</div>
<?php endif; ?>

<form method="POST">
<?php foreach($groups as $groupTitle => $fields): ?>
<div class="card shadow mb-4">
<div class="card-header bg-primary text-white"><?php echo htmlspecialchars($groupTitle); ?></div>
<div class="card-body">
<div class="row g-3">
<?php foreach($fields as $field): ?>
<div class="col-md-<?php echo strpos($field, 'subtitle') !== false || strpos($field, 'text') !== false ? '12' : '6'; ?>">
<label class="form-label"><?php echo htmlspecialchars($labels[$field]); ?></label>
<?php if(strpos($field, 'subtitle') !== false || strpos($field, 'text') !== false): ?>
<textarea name="<?php echo htmlspecialchars($field); ?>" class="form-control"><?php echo htmlspecialchars($homepage[$field]); ?></textarea>
<?php else: ?>
<input type="text" name="<?php echo htmlspecialchars($field); ?>" class="form-control" value="<?php echo htmlspecialchars($homepage[$field]); ?>">
<?php endif; ?>
</div>
<?php endforeach; ?>
</div>
</div>
</div>
<?php endforeach; ?>

<button class="btn btn-success btn-lg"><i class="fas fa-save"></i> Save Homepage</button>
</form>
</div>
</div>
</body>
</html>
