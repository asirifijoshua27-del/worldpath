<?php

session_start();

if(!isset($_SESSION['user_id'])){
    header("Location: ../login.php");
    exit();
}

require '../config/database.php';

$stmt = $pdo->prepare("
SELECT *
FROM applications
WHERE email=:email
LIMIT 1
");

$stmt->execute([
    'email'=>$_SESSION['email']
]);

$app = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$app){
    die("No Application Found");
}

if($_SERVER['REQUEST_METHOD']=="POST"){

    $uploadDir="../uploads/";

    $documents=[

        "wassce"=>"wassce_result",
        "transcript"=>"transcript",
        "passport"=>"passport_document",
        "cv"=>"cv_resume"

    ];

    foreach($documents as $input=>$column){

        if(isset($_FILES[$input]) && $_FILES[$input]['error']==0){

            $filename=time()."_".$_FILES[$input]['name'];

            $allowed = [

                'pdf',
                'jpg',
                'jpeg',
                'png',
                'docx'

            ];

            $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

            if(!in_array($extension,$allowed)){
                die("Only PDF, JPG, DOCX, JPEG and PNG files are allowed.");
            }

            if($_FILES[$input]['size'] > 5 * 1024 * 1024){
                die("Maximum file size is 5MB.");
            }

            if(move_uploaded_file(

                $_FILES[$input]['tmp_name'], 
                $uploadDir.$filename

            )){

                // Update database only if upload succeeded
                $statusColumn = "";

                switch($column){

                    case "wassce_result":
                        $statusColumn = "wassce_status";
                        break;

                    case "transcript":
                        $statusColumn = "transcript_status";
                        break;

                    case "passport_document":
                        $statusColumn = "passport_status";
                        break;

                    case "cv_resume":
                        $statusColumn = "cv_status";
                        break;

                }

                $update = $pdo->prepare("
    UPDATE applications
    SET
        $column = :file,
        $statusColumn = 'Pending'
    WHERE id = :id
    ");

                $update->execute([

                    'file' => $filename,
                    'id' => $app['id']

                ]);

                // Student notification
                $notify = $pdo->prepare("
    INSERT INTO notifications
    (
        application_id,
        title,
        message
    )
    VALUES
    (
        :id,
        :title,
        :message
    )
    ");

                $notify->execute([

                    'id' => $app['id'],
                    'title' => "Document Uploaded",
                    'message' => "Your ".$input." document has been uploaded successfully and is awaiting verification."

                ]);

            } else {
                die("Failed to upload the file.");
            }

        }

    }

    header("Location: upload_documents.php?success=1");
    exit();

}

?>

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>

Manage Documents

</title>

<link
href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
rel="stylesheet">

<link
href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
rel="stylesheet">

</head>

<body class="bg-light">

<div class="container py-5">

<h2 class="mb-4">

<i class="fas fa-folder-open"></i>

My Documents

</h2>

<?php if(isset($_GET['success'])): ?>

<div class="alert alert-success">

Documents updated successfully.

Your application has been returned for review.

</div>

<?php endif; ?>

<form
method="POST"
enctype="multipart/form-data">

<table class="table table-bordered bg-white">

<tr class="table-primary">

<th>Document</th>

<th>Current File</th>

<th>Status</th>

<th>Replace File</th>

</tr>

<tr>

<td>WASSCE Result</td>

<td>

<?php

if($app['wassce_result']){

?>

<a
target="_blank"
href="../uploads/<?php echo $app['wassce_result']; ?>">

View File

</a>

<?php

}else{

echo "Not Uploaded";

}

?>

</td>

<td>

<?php echo $app['wassce_status']; ?>

</td>

<td>

<input
type="file"
name="wassce"
class="form-control">

</td>

</tr>

<tr>

<td>Transcript</td>

<td>

<?php

if($app['transcript']){

?>

<a
target="_blank"
href="../uploads/<?php echo $app['transcript']; ?>">

View File

</a>

<?php

}else{

echo "Not Uploaded";

}

?>

</td>

<td>

<?php echo $app['transcript_status']; ?>

</td>

<td>

<input
type="file"
name="transcript"
class="form-control">

</td>

</tr>

<tr>

<td>Passport</td>

<td>

<?php

if($app['passport_document']){

?>

<a
target="_blank"
href="../uploads/<?php echo $app['passport_document']; ?>">

View File

</a>

<?php

}else{

echo "Not Uploaded";

}

?>

</td>

<td>

<?php echo $app['passport_status']; ?>

</td>

<td>

<input
type="file"
name="passport"
class="form-control">

</td>

</tr>

<tr>

<td>CV / Resume</td>

<td>

<?php

if($app['cv_resume']){

?>

<a
target="_blank"
href="../uploads/<?php echo $app['cv_resume']; ?>">

View File

</a>

<?php

}else{

echo "Not Uploaded";

}

?>

</td>

<td>

<?php echo $app['cv_status']; ?>

</td>

<td>

<input
type="file"
name="cv"
class="form-control">

</td>

</tr>

</table>

<button
class="btn btn-primary">

Save Changes

</button>

<a
href="dashboard.php"
class="btn btn-secondary">

Back

</a>

</form>

</div>

</body>

</html>