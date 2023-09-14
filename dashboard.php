<?php
session_start();

// Verifica se l'utente è autenticato
/*if (!isset($_SESSION["user"])) {
    header("Location: login.php"); // Reindirizza l'utente alla pagina di login se non è autenticato
    exit();
}*/

// Includi il file di connessione al database e le procedure
include "db/connect.php";

// Simulazione dei dati dell'utente (sostituiscili con i tuoi dati reali)
$user = [
    "id" => 1,
    "nome" => "Nome Utente",
    // Aggiungi altri dati dell'utente qui
];

// Esegui le procedure per ottenere i dati necessari

// Esempio di chiamata a una procedura per ottenere la lista dei domini di interesse
$stmt = $pdo->prepare("CALL getListDominioUtente(:userId)");
$stmt->bindParam(":userId", $user["id"], PDO::PARAM_INT);
$stmt->execute();
$dominiInteresse = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Chiudi la connessione al database
$pdo = null;
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="utf-8">
    <title>Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-light bg-light">
    <div class="container-fluid">
        <a class="navbar-brand" href="#">Dashboard</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="#">Home</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Profilo</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Sondaggi</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Risposte</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Premi</a>
                </li>
                <!-- Aggiungi altri collegamenti per le tue operazioni utente qui -->
            </ul>
            <ul class="navbar-nav ml-auto">
                <li class="nav-item">
                    <a class="nav-link" href="#">Benvenuto, <?php echo $user["nome"]; ?></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="logout.php">Logout</a>
                </li>
            </ul>
        </div>
    </div>
</nav>

<div class="container mt-5">
    <h1>Benvenuto nella tua dashboard, <?php echo $user["nome"]; ?>!</h1>
    <!-- Qui puoi inserire il contenuto della tua dashboard -->
</div>

</body>
</html>
