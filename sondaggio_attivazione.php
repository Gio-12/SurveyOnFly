<?php
global $pdo;
session_start();
include "db/connect.php"; // Include your database connection script

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['survey_id']) && isset($_SESSION['user']['idUtente'])) {
        $surveyId = intval($_POST['survey_id']);
        $userId = intval($_SESSION['user']['idUtente']);

        // Call the stored procedure to activate the survey
        $sqlActivateSurvey = "CALL attivaSondaggio(?, ?)";

        try {
            $stmtActivateSurvey = $pdo->prepare($sqlActivateSurvey);
            $stmtActivateSurvey->bindParam(1, $surveyId, PDO::PARAM_INT);
            $stmtActivateSurvey->bindParam(2, $userId, PDO::PARAM_INT);
            $stmtActivateSurvey->execute();

            // Check if the activation was successful
            $activationResult = $stmtActivateSurvey->fetch(PDO::FETCH_ASSOC);

            if ($activationResult && isset($activationResult['Message'])) {
                echo '<script>
                        alert("Sondaggio Attivato");
                        setTimeout(function() {
                            window.location.href = "sondaggio.php";
                        }, 3000);
                      </script>';
                exit();
            } else {
                // Handle activation failure, display an error message
                echo "Failed to activate survey.";
            }
        } catch (PDOException $e) {
            echo "Error activating survey: " . $e->getMessage();
        }
    } else {
        echo "Invalid request: Missing parameters.";
    }
} else {
    echo "Invalid request method.";
}
