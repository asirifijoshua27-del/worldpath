<?php

function logActivity(
    $pdo,
    $applicationId,
    $action,
    $performedBy
){

$stmt = $pdo->prepare("

INSERT INTO application_logs (

application_id,
action,
performed_by

)

VALUES (

:application_id,
:action,
:performed_by

)

");

$stmt->execute([

'application_id'=>$applicationId,
'action'=>$action,
'performed_by'=>$performedBy

]);

}