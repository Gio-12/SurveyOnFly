<?php
global $pdo;
session_start();
include "db/connect.php";
if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $email = $_POST["email"];
    $password = $_POST["password"];
    $tipologiaUtente = $_POST["tipologiaUtente"];

    if ($tipologiaUtente === "Azienda") {
        $codiceFiscale = $_POST["codiceFiscale"];
        $nomeAzienda = $_POST["nomeAzienda"];
        $sede = $_POST["sede"];
        $indirizzo = $_POST["indirizzo"];

        $sql = "CALL registrazioneAzienda(?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);

        // Bind parameters using PDO-style binding
        $stmt->bindParam(1, $email, PDO::PARAM_STR);
        $stmt->bindParam(2, $password, PDO::PARAM_STR);
        $stmt->bindParam(3, $tipologiaUtente, PDO::PARAM_STR);
        $stmt->bindParam(4, $codiceFiscale, PDO::PARAM_STR);
        $stmt->bindParam(5, $nomeAzienda, PDO::PARAM_STR);
        $stmt->bindParam(6, $sede, PDO::PARAM_STR);
        $stmt->bindParam(7, $indirizzo, PDO::PARAM_STR);

        if ($stmt->execute()) {
            echo '<script>
            alert("Registrazione Completata!");
            setTimeout(function() {
                window.location.href = "index.php";
            }, 3000); 
          </script>';
            exit();
        } else {
            echo "Error: " . $stmt->errorInfo()[2];
        }

        $stmt->closeCursor();
    }

    if ($tipologiaUtente === "Utente") {
        $nome = $_POST["nome"];
        $cognome = $_POST["cognome"];
        $luogoNascita = $_POST["luogoNascita"];
        $annoNascita = $_POST["annoNascita"];
        $tipoAbbonamento = $_POST["tipoAbbonamento"];

        if ($tipoAbbonamento == 0) {
            $tipologia = "Semplice";
        } else {
            $tipologia = "Premium";
        }

        $sql2 = "CALL registrazioneUtente(?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql2);

        // Bind parameters using PDO-style binding
        $stmt->bindParam(1, $email, PDO::PARAM_STR);
        $stmt->bindParam(2, $password, PDO::PARAM_STR);
        $stmt->bindParam(3, $tipologiaUtente, PDO::PARAM_STR);
        $stmt->bindParam(4, $nome, PDO::PARAM_STR);
        $stmt->bindParam(5, $cognome, PDO::PARAM_STR);
        $stmt->bindParam(6, $luogoNascita, PDO::PARAM_STR);
        $stmt->bindParam(7, $annoNascita, PDO::PARAM_STR);
        $stmt->bindParam(8, $tipologia, PDO::PARAM_STR);
        $stmt->bindParam(9, $tipoAbbonamento, PDO::PARAM_STR);

        if ($stmt->execute()) {
            echo '<script>
            alert("Registrazione Completata!");
            setTimeout(function() {
                window.location.href = "index.php";
            }, 3000); // 3 seconds delay
          </script>';
            exit(); // Make sure to exit after the JavaScript code
        } else {
            echo "Error: " . $stmt->errorInfo()[2]; // Use errorInfo to get the error message
        }

        $stmt->closeCursor(); // Close the cursor to release resources
    }
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <title>REGISTRAZIONE</title>
    <meta charset="utf-8" name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container">
    <h1><b>REGISTRAZIONE UTENTE</b></h1>
    <form action="registrazione.php" method="POST" id="registrationForm">

        <label for="email">Email:</label>
        <input type="email" name="email" class="form-control" required>

        <label for="password">Password:</label>
        <input type="password" name="password" class="form-control" required>

        <label for="tipologiaUtente">Tipologia:</label>
        <select name="tipologiaUtente" required id="userTypeSelect" class="form-control">
            <option value="Utente">Utente</option>
            <option value="Azienda">Azienda</option>
        </select>

        <div id="utenteFields" class="form-group" style="display: none;">
            <label for="nome">Nome:</label>
            <input type="text" name="nome" class="form-control" required>

            <label for="cognome">Cognome:</label>
            <input type="text" name="cognome" class="form-control" required>

            <label for="luogoNascita">Luogo di Nascita:</label>
            <input type="text" name="luogoNascita" class="form-control" required>

            <label for="annoNascita">Anno di Nascita:</label>
            <input type="date" name="annoNascita" class="form-control" required>

            <label for="tipoAbbonamento">Sottoscrizione:</label>
            <select name="tipoAbbonamento" required class="form-control">
                <option value="0">0</option>
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
            </select>
        </div>

        <div id="aziendaFields" class="form-group" style="display: none;">
            <label for="codiceFiscale">Codice Fiscale:</label>
            <input type="text" name="codiceFiscale" id="codiceFiscale" class="form-control" pattern="[0-9]{8}" title="Inserici 8 cifre" required>

            <label for="nomeAzienda">Nome:</label>
            <input type="text" name="nomeAzienda" class="form-control" required>

            <label for="sede">Sede:</label>
            <input type="text" name="sede" class="form-control" required>

            <label for="indirizzo">Indirizzo:</label>
            <input type="text" name="indirizzo" class="form-control" required>
        </div>

        <input type="submit" class="btn btn-primary" value="Register">
    </form>
</div>
</body>
</html>
<script>
    const userTypeSelect = document.getElementById('userTypeSelect');
    const utenteFields = document.getElementById('utenteFields');
    const aziendaFields = document.getElementById('aziendaFields');

    function removeRequired(container) {
        const fields = container.querySelectorAll('input, select');
        fields.forEach((field) => {
            field.removeAttribute('required');
        });
    }

    function addRequired(container) {
        const fields = container.querySelectorAll('input, select');
        fields.forEach((field) => {
            field.setAttribute('required', 'required');
        });
    }

    userTypeSelect.addEventListener('change', () => {
        if (userTypeSelect.value === 'Utente') {
            utenteFields.style.display = 'block';
            aziendaFields.style.display = 'none';
            removeRequired(aziendaFields);
            addRequired(utenteFields);
        } else if (userTypeSelect.value === 'Azienda') {
            utenteFields.style.display = 'none';
            aziendaFields.style.display = 'block';
            removeRequired(utenteFields);
            addRequired(aziendaFields);
        }
    });
</script>
<style>
    body{
        background-color: #222;
    }
    .container {
        max-width: 600px;
        margin: 50px auto;
        padding: 40px;
        background-color: #fff;
        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
        border-radius: 5px;
        text-align: center;
    }

    h1 {
        text-align: center;
        font-size: 24px;
        color: #222;
        margin-bottom: 20px;
    }

    form {
        max-width: 600px;
        margin: 0 auto;
        padding: 20px;
        background-color: #fff;
        border-radius: 5px;
        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
    }

    label {
        display: block;
        margin-bottom: 16px;
        font-weight: bold;
        color: #555;
        font-size: 18px;
    }

    input[type="email"],
    input[type="password"],
    select {
        width: 100%;
        padding: 12px;
        margin-bottom: 20px;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-sizing: border-box;
        font-size: 18px;
    }

    select {
        appearance: auto;
        -webkit-appearance: none;
        -moz-appearance: none;
        background-image: url('data:image/svg+xml;utf8,<svg fill="#000000" height="24" width="24" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64"><path d="M62,11c0-4.8-3.2-9-8-9H10C4.4,2,0,6.4,0,12v40c0,5.6,4.4,10,10,10h44c5.6,0,10-4.4,10-10V11z M11,4h42c3.3,0,6,2.7,6,6v38 c0,3.3-2.7,6-6,6H11c-3.3,0-6-2.7-6-6V10C5,6.7,7.7,4,11,4z M53,54c0,2.2-1.8,4-4,4H11c-2.2,0-4-1.8-4-4V12c0-2.2,1.8-4,4-4h42 c2.2,0,4,1.8,4,4V54z"/><path d="M33.8,46.8c-0.2,0.2-0.5,0.2-0.7,0L27,41.4c-0.2-0.2-0.2-0.5,0-0.7s0.5-0.2,0.7,0l4.3,4.3l4.3-4.3c0.2-0.2,0.5-0.2,0.7,0 s0.2,0.5,0,0.7L36,46.1L40.3,50.4c0.2,0.2,0.2,0.5,0,0.7c-0.2,0.2-0.5,0.2-0.7,0L36,47.9l-4.3,4.3c-0.2,0.2-0.5,0.2-0.7,0 c-0.2-0.2-0.2-0.5,0-0.7L35,46.1L30.7,41.8C30.5,41.6,30.5,41.3,30.7,41c0.2-0.2,0.5-0.2,0.7,0l4.3,4.3l4.3-4.3c0.2-0.2,0.5-0.2,0.7,0 c0.2,0.2,0.2,0.5,0,0.7L38,46.1L42.3,50.4c0.2,0.2,0.2,0.5,0,0.7c-0.2,0.2-0.5,0.2-0.7,0L38,47.9L33.8,46.8z"/></svg>');
        background-repeat: no-repeat;
        background-position: right 8px center;
        background-size: 24px;
    }

    input[type="submit"] {
        background-color: #222;
        color: #fff;
        font-size: 18px;
        border: none;
        border-radius: 4px;
        padding: 16px 24px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    input[type="submit"]:hover {
        background-color: #357ae8;
    }

    select::-ms-expand {
        display: none;
    }

    @media (max-width: 600px) {
        form {
            width: 80%;
            margin: 0 auto;
        }
    }
</style>
