<?php
session_start();
if (!isset($_SESSION['user'])) {

    header("Location: login.php");
    exit();
}
global $pdo;
include "db/connect.php";

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["invitationId"]) && isset($_POST["response"])) {
    $invitationId = $_POST["invitationId"];
    $response = $_POST["response"];


    $userId = $_SESSION['user']['idUtente'];

    try {

        $sqlUpdateInvitation = "CALL rispostaInvito(?, ?, ?)";
        $stmtUpdateInvitation = $pdo->prepare($sqlUpdateInvitation);
        $stmtUpdateInvitation->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtUpdateInvitation->bindParam(2, $invitationId, PDO::PARAM_STR);
        $stmtUpdateInvitation->bindParam(3, $response, PDO::PARAM_STR);


        $stmtUpdateInvitation->execute();
        $stmtUpdateInvitation->closeCursor();

        echo "Risposta inviata.";
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
} else {
    echo "Invalid request.";
}

