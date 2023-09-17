<?php
session_start();
include "db/connect.php";
global $pdo;

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $idMittente = $_POST['idMittente'];
    $idRicevente = $_POST['idRicevente'];
    $idSondaggio = $_POST['idSondaggio'];

    $sqlCreateInvito = "CALL creazioneInvito(:idMittente, :idRicevente, :idSondaggio)";

    try {
        $stmtCreateInvito = $pdo->prepare($sqlCreateInvito);
        $stmtCreateInvito->bindParam(":idMittente", $idMittente, PDO::PARAM_INT);
        $stmtCreateInvito->bindParam(":idRicevente", $idRicevente, PDO::PARAM_INT);
        $stmtCreateInvito->bindParam(":idSondaggio", $idSondaggio, PDO::PARAM_INT);

        $stmtCreateInvito->execute();

        $result = $stmtCreateInvito->fetch(PDO::FETCH_ASSOC);
        if (isset($result['Message'])) {

            echo "<script>alert('Error: " . $result['Message'] . "');</script>";
        } else {

            echo "<script>alert('Invio inviato!'); window.location.href = 'invito_creazione.php';</script>";
        }
        $stmtCreateInvito->closeCursor();
    } catch (PDOException $e) {

        echo "<script>alert('Database Error: " . $e->getMessage() . "');</script>";
        echo "<script>window.location.href = 'invito_creazione.php';</script>";
    }
    $stmtCreateInvito -> closeCursor();
} else {

    header("Location: invito_creazione.php");
    exit();
}
