<?php
session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;

// Check if the user is logged in and retrieve their user ID
if (!isset($_SESSION['user'])) {
    // Redirect to the login page if the user is not logged in
    header("Location: login.php");
    exit();
}

// Check if the form is submitted
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        foreach ($_POST as $key => $value) {
            // Check if the key corresponds to an Aperta question response
            if (strpos($key, 'risposta_aperta_') === 0) {
                $domandaId = substr($key, strlen('risposta_aperta_'));
                $risposta = $value; // The user's response
                $userId = $_SESSION['user']['idUtente']; // Get the user's ID

                // Call the stored procedure to insert the Aperta response
                $stmt = $pdo->prepare("CALL insertRispostaAperta(?, ?, ?)");
                $stmt->bindParam(1, $domandaId, PDO::PARAM_INT);
                $stmt->bindParam(2, $userId, PDO::PARAM_INT);
                $stmt->bindParam(3, $risposta, PDO::PARAM_STR);
                $stmt->execute();

                // Check the result and handle any errors
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
                if (isset($result['Message'])) {
                    // Handle the message, e.g., show an error message
                    echo "Error: " . $result['Message'];
                }
                $stmt->closeCursor();
            } elseif (strpos($key, 'risposta_chiusa_') === 0) {
                $domandaId = substr($key, strlen('risposta_chiusa_'));
                $opzioneId = $value; // The selected option ID
                $userId = $_SESSION['user']['idUtente']; // Get the user's ID

                // Call the stored procedure to insert the Chiusa response
                $stmt = $pdo->prepare("CALL insertRispostaChiusa(?, ?, ?)");
                $stmt->bindParam(1, $domandaId, PDO::PARAM_INT);
                $stmt->bindParam(2, $userId, PDO::PARAM_INT);
                $stmt->bindParam(3, $opzioneId, PDO::PARAM_INT);
                $stmt->execute();

                // Check the result and handle any errors
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
                if (isset($result['Message'])) {
                    // Handle the message, e.g., show an error message
                    echo "Error: " . $result['Message'];
                }
                $stmt->closeCursor();
            }
        }

        // Redirect the user to a confirmation page after successful submission
        header("Location: sondaggio.php");
        exit();

    } catch (PDOException $e) {
        echo "Error processing form data: " . $e->getMessage();
        exit();
    }
} else {
    // Redirect the user back to the survey page if accessed directly without form submission
    header("Location: sondaggio.php");
    exit();
}
