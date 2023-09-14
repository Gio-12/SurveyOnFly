<<<<<<< Updated upstream
=======
<?php
session_start();
include "db/connect.php"; // Assicurati che questo include sia corretto e includa la connessione al database.

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST["email"];
    $password = $_POST["password"];
    $tipologiaUtente = $_POST["tipologiaUtente"];

    $sql = "CALL login(?, ?)";
    $stmt = $pdo->prepare($sql);
    
    $stmt->bindParam(1, $email, PDO::PARAM_STR);
    $stmt->bindParam(2, $password, PDO::PARAM_STR);

    if ($stmt->execute()) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($user) {
            // L'utente è stato autenticato con successo, puoi gestire la sessione e reindirizzare a una pagina successiva.
            $_SESSION["user"] = $user;
            header("Location: dashboard.php"); // Cambia "dashboard.php" con la pagina a cui desideri reindirizzare l'utente dopo il login.
            exit();
        } else {
            $loginError = "Credenziali non valide.";
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

        <label for="tipologiaUtente">User Type:</label>
        <select name="tipologiaUtente" required id="userTypeSelect">
            <option value="Utente">Utente</option>
            <option value="Azienda">Azienda</option>
        </select><br>

        <input type="submit" value="Login">
    </form>
</body>

</html>
>>>>>>> Stashed changes
