<?php
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Cambia "login.php" con la pagina di login desiderata
    exit(); // Assicura che l'esecuzione dello script si interrompa qui
}
global $pdo;
include "db/connect.php"; // Includi lo script di connessione al database

try {
    $userId = $_SESSION['user']['idUtente'];

    // Fetch the list of active surveys
    $currentDate = date("Y-m-d H:i:s"); // Get the current date and time
    $sqlSurveys = "SELECT id, titolo FROM sondaggio WHERE dataChiusura > ?";
    $stmtSurveys = $pdo->prepare($sqlSurveys);
    $stmtSurveys->bindParam(1, $currentDate, PDO::PARAM_STR);
    $stmtSurveys->execute();
    $surveys = $stmtSurveys->fetchAll(PDO::FETCH_ASSOC);

    $stmtSurveys->closeCursor();

    // Retrieve only users from the current user's domain
    $sqlGetUsers = "SELECT u.idUtente
                    FROM utentexdominio AS ud
                    INNER JOIN utente AS u ON ud.idUtente = u.idUtente
                    WHERE ud.idUtente = ?";
    $stmtGetUsers = $pdo->prepare($sqlGetUsers);
    $stmtGetUsers->bindParam(1, $userId, PDO::PARAM_INT);
    $stmtGetUsers->execute();
    $users = $stmtGetUsers->fetchAll(PDO::FETCH_ASSOC);

    $stmtGetUsers->closeCursor();

    if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["sondaggioId"]) && isset($_POST["selectedUsers"])) {
        $sondaggioId = $_POST["sondaggioId"];
        $selectedUsers = $_POST["selectedUsers"];

        // Call the stored procedure to create invitations
        $sqlCreateInvitations = "CALL creazioneInvito(?, ?, ?)";
        $stmtCreateInvitations = $pdo->prepare($sqlCreateInvitations);

        foreach ($selectedUsers as $userId) {
            $stmtCreateInvitations->execute([$userId, $sondaggioId, $userId]);
        }

        $stmtCreateInvitations->closeCursor();

        echo "Invitations sent successfully.";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Invia Inviti</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
</head>
<body>
<div class="container">
    <h2>Invia Inviti</h2>
    <form method="POST">
        <div class="form-group">
            <label for="sondaggioId">Seleziona il Sondaggio</label>
            <select class="form-control" id="sondaggioId" name="sondaggioId" required>
                <?php foreach ($surveys as $survey) { ?>
                    <option value="<?php echo $survey['id']; ?>"><?php echo $survey['titolo']; ?></option>
                <?php } ?>
            </select>
        </div>
        <div class="form-group">
            <label for="selectedUsers">Seleziona gli Utenti da Invitare</label>
            <select class="form-control" id="selectedUsers" name="selectedUsers[]" multiple required>
                <?php foreach ($users as $user) { ?>
                    <option value="<?php echo $user['idUtente']; ?>"><?php echo $user['nome'] . " (" . $user['email'] . ")"; ?></option>
                <?php } ?>
            </select>
        </div>
        <button type="submit" class="btn btn-primary">Invia Inviti</button>
    </form>
</div>
</body>
</html>
