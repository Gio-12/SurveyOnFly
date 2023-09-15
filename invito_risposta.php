<?php
session_start();
global $pdo;
include "db/connect.php"; // Include your database connection script

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["invitationId"]) && isset($_POST["response"])) {
    $invitationId = $_POST["invitationId"];
    $response = $_POST["response"];

    // Get the user ID from the session
    $userId = $_SESSION['user']['idUtente'];

    try {
        // Call the stored procedure to update the invitation's response
        $sqlUpdateInvitation = "CALL rispostaInvito(?, ?, ?)";
        $stmtUpdateInvitation = $pdo->prepare($sqlUpdateInvitation);
        $stmtUpdateInvitation->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtUpdateInvitation->bindParam(2, $invitationId, PDO::PARAM_STR);
        $stmtUpdateInvitation->bindParam(3, $response, PDO::PARAM_STR);


        $stmtUpdateInvitation->execute();
        $stmtUpdateInvitation->closeCursor();

        echo "Invitation response updated successfully.";
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
} else {
    echo "Invalid request.";
}

