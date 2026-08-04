<?php

session_start();

require '../config/database.php';

$stmt = $pdo->prepare("

INSERT INTO notifications(

application_id,
title,
message

)

VALUES(

:application_id,
:title,
:message

)

");

$stmt->execute([

'application_id' => $_POST['application_id'],
'title' => $_POST['title'],
'message' => $_POST['message']

]);

header(
"Location: application_details.php?id=".$_POST['application_id']
);
exit();