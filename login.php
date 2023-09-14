<?php
global $pdo;
session_start();
include "db/connect.php"; // Assicurati che questo include sia corretto e includa la connessione al database.

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST["email"];
    $password = $_POST["password"];

    $sql = "CALL loginUtente(?, ?, @utentebase_id, @utentebase_email, @utentebase_tipologiaUtente, @utente_tipologia)";
    $stmt = $pdo->prepare($sql);

    $stmt->bindParam(1, $email, PDO::PARAM_STR);
    $stmt->bindParam(2, $password, PDO::PARAM_STR);

    if ($stmt->execute()) {
        // Optionally fetch the output variables using a separate query
        $outputStmt = $pdo->query("SELECT @utentebase_id, @utentebase_email, @utentebase_tipologiaUtente, @utente_tipologia");
        $output = $outputStmt->fetch(PDO::FETCH_ASSOC);

        if ($output) {
            // Handle the output variables here
            $utentebase_id = (int)$output['@utentebase_id']; // Cast to integer
            $utentebase_email = $output['@utentebase_email'];
            $utentebase_tipologiaUtente = $output['@utentebase_tipologiaUtente'];
            $utente_tipologiaUtenteFisico = $output['@utente_tipologia'];

            // Check if login was successful and handle session storage
            if ($utentebase_id !== null) {
                // Store relevant user information in the session
                $_SESSION['user'] = [
                    'idUtente' => $utentebase_id,
                    'email' => $utentebase_email,
                    'tipologiaUtente' => $utentebase_tipologiaUtente,
                    'tipologia' => $utente_tipologiaUtenteFisico,
                ];
                echo '<script>
                  alert("Registrazione Completata! \n' .
                    'ID Utente: ' . $_SESSION['user']['idUtente'] . '\n' .
                    'Email: ' . $_SESSION['user']['email'] . '\n' .
                    'Tipologia Utente: ' . $_SESSION['user']['tipologiaUtente'] . '\n' .
                    'Tipologia: ' . $_SESSION['user']['tipologia'] . '");
                setTimeout(function() {
                    window.location.href = "dashboard.php";
                }, 3000); // 3 seconds delay
              </script>';
                exit(); // Make sure to exit after the JavaScript code
            } else {
                $loginError = "Credenziali non valide.";
            }
        } else {
            $loginError = "Errore durante la query di output.";
        }
    } else {
        $loginError = "Errore durante l'esecuzione della query.";
    }
}
?>
<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="utf-8">
    <title>LOGIN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</head>

<body>
    <h1>User Login</h1>
    <?php if (isset($loginError)) : ?>
        <div class="alert alert-danger" role="alert">
            <?php echo $loginError; ?>
        </div>
    <?php endif; ?>
    <form action="login.php" method="POST" id="loginForm">
        <label for="email">Email:</label>
        <input type="email" name="email" required><br>

        <label for="password">Password:</label>
        <input type="password" name="password" required><br>

        <input type="submit" value="Login">
    </form>
</body>

</html>