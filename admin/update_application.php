<?php

session_start();

if(
    !isset($_SESSION['role']) ||
    $_SESSION['role'] != 'admin'
){
    die("Access Denied");
}

require '../config/database.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require '../vendor/autoload.php';

$id = $_POST['id'];
$status = $_POST['status'];

/*
|--------------------------------------------------------------------------
| UPDATE APPLICATION
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
UPDATE applications
SET status = :status
WHERE id = :id
");

$stmt->execute([
    'status' => $status,
    'id' => $id
]);

/*
|--------------------------------------------------------------------------
| GET STUDENT DETAILS
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare("
SELECT fullname,email
FROM applications
WHERE id=:id
");

$stmt->execute([
    'id'=>$id
]);

$student = $stmt->fetch(PDO::FETCH_ASSOC);

/*
|--------------------------------------------------------------------------
| SEND EMAIL
|--------------------------------------------------------------------------
*/

try{

$mail = new PHPMailer(true);

$mail->isSMTP();

$mail->Host = 'smtp.gmail.com';

$mail->SMTPAuth = true;

$mail->Username = 'asirifijoshua27@gmail.com';

$mail->Password = 'Phee443@Josh';

$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;

$mail->Port = 587;

$mail->setFrom(
'info@worldpathgroup.org',
'WorldPath Group'
);

$mail->addAddress(
$student['email'],
$student['fullname']
);

$mail->isHTML(true);

$mail->Subject =
'Application Status Update';

$mail->Body = "

<h2>Hello {$student['fullname']},</h2>

<p>

Your application status has been updated.

</p>

<p>

<b>New Status:</b>
{$status}

</p>

<p>

Please log in to your student portal
for more information.

</p>

<p>

Regards,<br>
WorldPath Group

</p>

";

$mail->send();

}catch(Exception $e){

// optional logging

}

header(
"Location: application_details.php?id=".$id
);

exit;