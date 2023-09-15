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
    <link rel="stylesheet" href="path-to-your-custom.css"> <!-- Include your custom CSS file here -->
    <?php
    include "includes/header.php";
    ?>
</head>
<body>
<div class="container">
    <h1>User Registration</h1>
    <form action="registrazione.php" method="POST" id="registrationForm">
        <!-- Common fields -->
        <label for="email">Email:</label>
        <input type="email" name="email" class="form-control" required>

        <label for="password">Password:</label>
        <input type="password" name="password" class="form-control" required>

        <label for="tipologiaUtente">User Type:</label>
        <select name="tipologiaUtente" required id="userTypeSelect" class="form-control">
            <option value="Utente">Utente</option>
            <option value="Azienda">Azienda</option>
        </select>

        <!-- Utente Registration Fields -->
        <div id="utenteFields" class="form-group" style="display: none;">
            <label for="nome">Name:</label>
            <input type="text" name="nome" class="form-control" required>

            <label for="cognome">Last Name:</label>
            <input type="text" name="cognome" class="form-control" required>

            <label for="luogoNascita">Place of Birth:</label>
            <input type="text" name="luogoNascita" class="form-control" required>

            <label for="annoNascita">Date of Birth:</label>
            <input type="date" name="annoNascita" class="form-control" required>

            <label for="tipologia">User Role:</label>
            <select name="tipologia" required class="form-control">
                <option value="Semplice">Semplice</option>
                <option value="Premium">Premium</option>
                <option value="Amministratore">Amministratore</option>
            </select>

            <label for="tipoAbbonamento">Subscription Type:</label>
            <select name="tipoAbbonamento" required class="form-control">
                <option value="0">0</option>
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
            </select>
        </div>

        <!-- Azienda Registration Fields -->
        <div id="aziendaFields" class="form-group" style="display: none;">
            <label for="codiceFiscale">Tax Code:</label>
            <input type="text" name="codiceFiscale" class="form-control" required>

            <label for="nome">Name:</label>
            <input type="text" name="nome" class="form-control" required>

            <label for="sede">Location:</label>
            <input type="text" name="sede" class="form-control" required>

            <label for="indirizzo">Address:</label>
            <input type="text" name="indirizzo" class="form-control" required>
        </div>

        <input type="submit" class="btn btn-primary" value="Register">
    </form>
</div>
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
<style>
    /* Custom CSS for the registration form */
    .container {
        max-width: 400px;
        margin: 0 auto;
        padding: 20px;
        background-color: #fff;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        border-radius: 4px;
    }

    h1 {
        text-align: center;
        margin-bottom: 20px;
    }

    form {
        display: flex;
        flex-direction: column;
        gap: 10px;
    }

    label {
        font-weight: bold;
    }

    input[type="email"],
    input[type="password"],
    select {
        width: 100%;
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 4px;
    }

    select {
        appearance: none;
        background-color: #fff;
    }

    .btn-primary {
        background-color: #4285f4;
        border-color: #4285f4;
        color: #fff;
        width: 100%;
        padding: 10px;
    }

    .btn-primary:hover {
        background-color: #357ae8;
        border-color: #357ae8;
    }
</style>