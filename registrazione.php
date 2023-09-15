<?php
global $pdo;
session_start();
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
    <meta charset="utf-8">
    <title>REGISTRAZIONE</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Ranking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
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
