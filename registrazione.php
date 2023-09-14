<?php
global $pdo;
session_start();
//$ip_add = getenv("REMOTE_ADDR");
include "db/connect.php";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $userType = $_POST["tipologiaUtente"];

// Common fields

    $email = $_POST["email"];
    $password = $_POST["password"];
    $tipologiaUtente = $_POST["tipologiaUtente"];

// Specific fields for Azienda
    if ($userType === "Azienda") {
        $codiceFiscale = $_POST["codiceFiscale"];
        $nome = $_POST["nome"];
        $sede = $_POST["sede"];
        $indirizzo = $_POST["indirizzo"];

        $sql = "CALL registrazioneAzienda(?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);

        // Bind parameters using PDO-style binding
        $stmt->bindParam(1, $email, PDO::PARAM_STR);
        $stmt->bindParam(2, $password, PDO::PARAM_STR);
        $stmt->bindParam(3, $tipologiaUtente, PDO::PARAM_STR);
        $stmt->bindParam(4, $codiceFiscale, PDO::PARAM_STR);
        $stmt->bindParam(5, $nome, PDO::PARAM_STR);
        $stmt->bindParam(6, $sede, PDO::PARAM_STR);
        $stmt->bindParam(7, $indirizzo, PDO::PARAM_STR);

        if ($stmt->execute()) {
            echo "Registration successful!";
        } else {
            echo "Error: " . $stmt->errorInfo()[2]; // Use errorInfo to get the error message
        }

        $stmt->closeCursor(); // Close the cursor to release resources
        $pdo->close();
    }

// Now, based on $userType, you can process the form accordingly
    if ($userType === "Utente") {

        $nome = $_POST["nome"];
        $cognome = $_POST["cognome"];
        $luogoNascita = $_POST["luogoNascita"];
        $annoNascita = $_POST["annoNascita"];
        $tipologia = $_POST["tipologia"];
        $tipoAbbonamento = $_POST["tipoAbbonamento"];

        $sql = "CALL registrazioneUtente(?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->bind_param("sssssssss", $email, $password, $tipologiaUtente, $nome, $cognome, $luogoNascita, $annoNascita, $tipologia, $tipoAbbonamento);

        if ($stmt->execute()) {
            echo "Registration successful!";
        } else {
            echo "Error: " . $stmt->error;
        }

        $stmt->closeCursor(); // Close the cursor to release resources
        $pdo->close();
    }
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="utf-8">
    <title>REGISTRAZIONE</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</head>
<?php
include "includes/header.php";
?>
<body>
<h1>User Registration</h1>
<form action="registrazione.php" method="POST" id="registrationForm">
    <label for="email">Email:</label>
    <input type="email" name="email" required><br>

    <label for="password">Password:</label>
    <input type="password" name="password" required><br>

    <label for="tipologiaUtente">User Type:</label>
    <select name="tipologiaUtente" required id="userTypeSelect">
        <option value="Utente">Utente</option>
        <option value="Azienda">Azienda</option>
    </select><br>

    <!-- Utente Registration Fields -->
    <div id="utenteFields">
        <!-- Add fields specific to Utente registration here -->
        <label for="nome">Name:</label>
        <input type="text" name="nome" required><br>

        <label for="cognome">Last Name:</label>
        <input type="text" name="cognome" required><br>

        <label for="luogoNascita">Place of Birth:</label>
        <input type="text" name="luogoNascita" required><br>

        <label for="annoNascita">Date of Birth:</label>
        <input type="date" name="annoNascita" required><br>

        <label for="tipologia">User Role:</label>
        <select name="tipologia" required>
            <option value="Semplice">Semplice</option>
            <option value="Premium">Premium</option>
            <option value="Amministratore">Amministratore</option>
        </select><br>

        <label for="tipoAbbonamento">Subscription Type:</label>
        <select name="tipoAbbonamento" required>
            <option value="0">0</option>
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
        </select><br>
        <!-- Add other Utente-specific fields here -->
    </div>

    <!-- Azienda Registration Fields -->
    <div id="aziendaFields" style="display: none;">

        <label for="codiceFiscale">Tax Code:</label>
        <input type="text" name="codiceFiscale" required><br>

        <label for="nome">Name:</label>
        <input type="text" name="nome" required><br>

        <label for="sede">Location:</label>
        <input type="text" name="sede" required><br>

        <label for="indirizzo">Address:</label>
        <input type="text" name="indirizzo" required><br>
    </div>
    <input type="submit" value="Register">
</form>
</body>
<?php
include "includes/footer.php";
?>
</html>
<script>
    const userTypeSelect = document.getElementById('userTypeSelect');
    const utenteFields = document.getElementById('utenteFields');
    const aziendaFields = document.getElementById('aziendaFields');

    // Function to remove the 'required' attribute from all fields within a container
    function removeRequired(container) {
        const fields = container.querySelectorAll('input, select');
        fields.forEach((field) => {
            field.removeAttribute('required');
        });
    }

    // Function to add the 'required' attribute to all fields within a container
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
            // Remove 'required' from Azienda fields
            removeRequired(aziendaFields);
            // Add 'required' to Utente fields
            addRequired(utenteFields);
        } else if (userTypeSelect.value === 'Azienda') {
            utenteFields.style.display = 'none';
            aziendaFields.style.display = 'block';
            // Remove 'required' from Utente fields
            removeRequired(utenteFields);
            // Add 'required' to Azienda fields
            addRequired(aziendaFields);
        }
    });
</script>
