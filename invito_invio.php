<?php

session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $idMittente = $_POST['idMittente'];
    $idRicevente = $_POST['idRicevente'];
    $idSondaggio = $_POST['idSondaggio'];

    // Call the stored procedure to create the invitation
    $sqlCreateInvito = "CALL creazioneInvito(:idMittente, :idRicevente, :idSondaggio)";

    try {
        $stmtCreateInvito = $pdo->prepare($sqlCreateInvito);
        $stmtCreateInvito->bindParam(":idMittente", $idMittente, PDO::PARAM_INT);
        $stmtCreateInvito->bindParam(":idRicevente", $idRicevente, PDO::PARAM_INT);
        $stmtCreateInvito->bindParam(":idSondaggio", $idSondaggio, PDO::PARAM_INT);

        $stmtCreateInvito->execute();

        // Check if the stored procedure returns a message
        $result = $stmtCreateInvito->fetch(PDO::FETCH_ASSOC);
        if (isset($result['Message'])) {
            // Handle the message, e.g., show an error message using JavaScript alert
            echo "<script>alert('Error: " . $result['Message'] . "');</script>";
        } else {
            // Invitation created successfully, redirect using JavaScript
            echo "<script>alert('Invitation created successfully.'); window.location.href = 'invito_creazione.php';</script>";
        }
        $stmtCreateInvito->closeCursor();
    } catch (PDOException $e) {
        // Handle database errors by displaying an alert and redirecting
        echo "<script>alert('Database Error: " . $e->getMessage() . "');</script>";
        echo "<script>window.location.href = 'invito_creazione.php';</script>";
    }
    $stmtCreateInvito -> closeCursor();
} else {
    // Redirect the user to the create invitation page if accessed directly
    header("Location: invito_creazione.php");
    exit();
}
