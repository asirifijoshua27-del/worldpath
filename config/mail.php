<?php

use PHPMailer\PHPMailer\PHPMailer;

require __DIR__ . '/../vendor/autoload.php';

function sendMail(
$fullname,
$email,
$subject,
$message
){

$mail = new PHPMailer(true);

$mail->isSMTP();

$mail->Host = 'smtp.gmail.com';

$mail->SMTPAuth = true;

$mail->Username = 'YOUR_GMAIL@gmail.com';

$mail->Password = 'YOUR_APP_PASSWORD';

$mail->SMTPSecure = 'tls';

$mail->Port = 587;

$mail->setFrom(
'YOUR_GMAIL@gmail.com',
'WorldPath Group'
);

$mail->addAddress(
'asirifijoshua27@gmail.com'
);

$mail->Subject =
"New Contact Form Submission";

$mail->Body = "

Name: $fullname

Email: $email

Subject: $subject

Message:

$message

";

$mail->send();

}