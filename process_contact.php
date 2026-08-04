<?php

require 'config/database.php';

try {

$stmt = $pdo->prepare("

INSERT INTO contact_messages

(
fullname,
email,
subject,
message
)

VALUES

(
:fullname,
:email,
:subject,
:message
)

");

$stmt->execute([

'fullname' => $_POST['fullname'],
'email' => $_POST['email'],
'subject' => $_POST['subject'],
'message' => $_POST['message']

]);

header("Location: contact.php?success=1");

exit;

} catch(PDOException $e){

echo $e->getMessage();

}