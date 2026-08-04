<?php



require 'config/database.php';



if($_SERVER['REQUEST_METHOD'] == 'POST'){



    try{



        $fullname =

        trim($_POST['fullname']);



        $email =

        trim($_POST['email']);



        $phone =

        trim($_POST['phone']);



        $country =

        trim($_POST['country']);



        $program =

        trim($_POST['program']);



        $university =

        trim($_POST['university']);



        if($university == "Other"){



            $university =

            trim($_POST['other_university']);



        }



        $statement =

        trim($_POST['statement']);



        $education_level =

        trim($_POST['education_level']);



        $scholarship_needed =

        trim($_POST['scholarship_needed']);



        $intake =

        trim($_POST['intake']);



        $passport_available =

        trim($_POST['passport_available']);



        // Upload folder



        $uploadDir =

        "uploads/";



        // WASSCE Result



        $wassce_result = "";



        if(!empty($_FILES['wassce_result']['name'])){



            $wassce_result =

            time() . "_" .

            basename($_FILES['wassce_result']['name']);



            move_uploaded_file(



                $_FILES['wassce_result']['tmp_name'],



                $uploadDir .

                $wassce_result



            );



        }



        // Transcript



        $transcript = "";



        if(!empty($_FILES['transcript']['name'])){



            $transcript =

            time() . "_" .

            basename($_FILES['transcript']['name']);



            move_uploaded_file(



                $_FILES['transcript']['tmp_name'],



                $uploadDir .

                $transcript



            );



        }



        // CV



        $cv_resume = "";



        if(!empty($_FILES['cv_resume']['name'])){



            $cv_resume =

            time() . "_" .

            basename($_FILES['cv_resume']['name']);



            move_uploaded_file(



                $_FILES['cv_resume']['tmp_name'],



                $uploadDir .

                $cv_resume



            );



        }



        // Passport



        $passport_document = "";



        if(!empty($_FILES['passport_document']['name'])){



            $passport_document =

            time() . "_" .

            basename($_FILES['passport_document']['name']);



            move_uploaded_file(



                $_FILES['passport_document']['tmp_name'],



                $uploadDir .

                $passport_document



            );



        }



        $stmt = $pdo->prepare("



            INSERT INTO applications(



                fullname,

                email,

                phone,

                country,

                program,

                university,

                statement,

                education_level,

                scholarship_needed,

                intake,

                passport_available,

                wassce_result,

                transcript,

                cv_resume,

                passport_document



            )



            VALUES(



                :fullname,

                :email,

                :phone,

                :country,

                :program,

                :university,

                :statement,

                :education_level,

                :scholarship_needed,

                :intake,

                :passport_available,

                :wassce_result,

                :transcript,

                :cv_resume,

                :passport_document



            )



        ");



        $stmt->execute([



            'fullname' => $fullname,

            'email' => $email,

            'phone' => $phone,

            'country' => $country,

            'program' => $program,

            'university' => $university,

            'statement' => $statement,

            'education_level' => $education_level,

            'scholarship_needed' => $scholarship_needed,

            'intake' => $intake,

            'passport_available' => $passport_available,

            'wassce_result' => $wassce_result,

            'transcript' => $transcript,

            'cv_resume' => $cv_resume,

            'passport_document' => $passport_document



        ]);



        header(

            "Location: application.php?success=1"

        );



        exit();



    }catch(PDOException $e){



        die(

            "Database Error: " .

            $e->getMessage()

        );



    }



}

?>
