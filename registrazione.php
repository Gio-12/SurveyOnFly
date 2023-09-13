<?php
global $pdo;
session_start();
$ip_add = getenv("REMOTE_ADDR");
include "db/connect.php";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $userType = $_POST["tipologiaUtente"];

// Common fields
    $email = $_POST["email"];
    $password = $_POST["password"];
    $tipologiaUtente = $_POST["tipologiaUtente"];
    $nome = $_POST["nome"];
    $cognome = $_POST["cognome"];
    $luogoNascita = $_POST["luogoNascita"];
    $annoNascita = $_POST["annoNascita"];
    $tipologia = $_POST["tipologia"];
    $tipoAbbonamento = $_POST["tipoAbbonamento"];

// Specific fields for Azienda
    if ($userType === "Azienda") {
        $codiceFiscale = $_POST["codiceFiscale"];
        $sede = $_POST["sede"];
        $indirizzo = $_POST["indirizzo"];
    }

// Now, based on $userType, you can process the form accordingly
    if ($userType === "Utente") {
        $sql = "CALL DONEregistrazioneUtente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->bind_param("ssssssss", $email, $password, $tipologiaUtente, $nome, $cognome, $luogoNascita, $annoNascita, $tipologia, $tipoAbbonamento);

        if ($stmt->execute()) {
            echo "Registration successful!";
        } else {
            echo "Error: " . $stmt->error;
        }

        $stmt->close();
        $pdo->close();
        // Process the form for Utente
    } elseif ($userType === "Azienda") {
        // Process the form for Azienda
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<?php
include "includes/header.php";
?>
<body>
<h1>User Registration</h1>
<form action="registrazione.php" method="POST">
    <label for="email">Email:</label>
    <input type="email" name="email" required><br>

    <label for="password">Password:</label>
    <input type="password" name="password" required><br>

    <label for="tipologiaUtente">User Type:</label>
    <select name="tipologiaUtente" required>
        <option value="Utente">Utente</option>
        <option value="Azienda">Azienda</option>
    </select><br>

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

<!--    <label for="codiceFiscale">Tax Code:</label>-->
<!--    <input type="text" name="codiceFiscale" required><br>-->
<!---->
<!--    <label for="sede">Location:</label>-->
<!--    <input type="text" name="sede" required><br>-->
<!---->
<!--    <label for="indirizzo">Address:</label>-->
<!--    <input type="text" name="indirizzo" required><br>-->

    <input type="submit" value="Register">
</form>
</body>
<?php
include "includes/footer.php";
?>
</html>