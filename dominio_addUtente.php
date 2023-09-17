<?php
session_start();
if (!isset($_SESSION['user'])) {

    header("Location: login.php");
    exit();
}
global $pdo;

include "db/connect.php";

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["domainId"])) {
    $domainId = $_POST["domainId"];


    $selected_IdUtente = $_SESSION['user']['idUtente'];

    try {

        $stmt = $pdo->prepare("CALL addDominioUtente(?, ?)");
        $stmt->bindParam(1, $selected_IdUtente, PDO::PARAM_INT);
        $stmt->bindParam(2, $domainId, PDO::PARAM_INT);


        $stmt->execute();


        $result = $stmt->fetch(PDO::FETCH_ASSOC);


        $stmt->closeCursor();

        echo $result['Message'];

    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
} else {
    echo "Invalid request";
}
