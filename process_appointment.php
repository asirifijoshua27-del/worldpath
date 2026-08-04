<?php

include 'config/database.php';

$stmt = $pdo->prepare("
INSERT INTO appointments
(
fullname,
email,
phone,
service,
appointment_date,
appointment_time
)
VALUES
(
:fullname,
:email,
:phone,
:service,
:appointment_date,
:appointment_time
)
");

$stmt->execute([

'fullname'=>$_POST['fullname'],
'email'=>$_POST['email'],
'phone'=>$_POST['phone'],
'service'=>$_POST['service'],
'appointment_date'=>$_POST['appointment_date'],
'appointment_time'=>$_POST['appointment_time']

]);

header(
"Location: appointments.php?success=1"
);

exit;