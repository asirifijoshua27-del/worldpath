<?php

session_start();

require '../config/database.php';

$title = $_POST['title'];
$content = $_POST['content'];

$slug = strtolower(
preg_replace(
'/[^A-Za-z0-9-]+/',
'-',
$title
)
);

$stmt = $pdo->prepare("
INSERT INTO blogs(

title,
slug,
content,
author

)

VALUES(

:title,
:slug,
:content,
:author

)
");

$stmt->execute([

'title' => $title,
'slug' => $slug,
'content' => $content,
'author' => $_SESSION['fullname']

]);

header("Location: blogs.php");
exit();