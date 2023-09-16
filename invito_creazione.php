<?php
global $pdo;
session_start();
// Include your database connection script
include "db/connect.php";
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <!-- Add your meta tags, stylesheets, and scripts here -->
    <title>Crea Invito</title>
</head>
<body>
<?php include 'includes/header.php'; ?>
<div class="container">
    <h2>Crea Invito</h2>
    <form action="invito_invio.php" method="POST">
        <div class="form-group">
            <label for="recipient">Seleziona il destinatario:</label>
            <select class="form-control" id="recipient" name="idRicevente">
                <!-- Populate this dropdown with users from the database -->
                <?php
                // Fetch the list of users (excluding Azienda)
                $sqlGetUtentiFisici = "CALL getListaUtentiFisici()";
                $stmtGetUtentiFisici = $pdo->prepare($sqlGetUtentiFisici);
                $stmtGetUtentiFisici->execute();
                $users = $stmtGetUtentiFisici->fetchAll(PDO::FETCH_ASSOC);

                foreach ($users as $user) {
                    // Check if the user's ID is not the same as the session user's ID
                    if ($user['id'] != $_SESSION['user']['idUtente']) {
                        echo "<option value=\"{$user['id']}\">{$user['email']}</option>";
                    }
                }
                $stmtGetUtentiFisici ->closeCursor();
                ?>
            </select>
        </div>
        <div class="form-group">
            <label for="survey">Seleziona il sondaggio:</label>
            <select class="form-control" id="survey" name="idSondaggio">
                <!-- Populate this dropdown with surveys from the database -->
                <?php
                $userId = $_SESSION['user']['idUtente'];
                $userId = (int)$userId;
                // Fetch the list of open surveys created by the user
                $sqlGetSondaggiCreatore = "CALL getListaSondaggioCreatore(?)";
                $stmtGetSondaggiCreatore = $pdo->prepare($sqlGetSondaggiCreatore);
                $stmtGetSondaggiCreatore->bindParam(1, $userId, PDO::PARAM_INT);
                $stmtGetSondaggiCreatore->execute();
                $surveys = $stmtGetSondaggiCreatore->fetchAll(PDO::FETCH_ASSOC);

                foreach ($surveys as $survey) {
                    if ($survey['stato'] === 'Aperto' && $survey['numeroIscritti'] < $survey['numMaxPartecipanti']) {
                        echo "<option value=\"{$survey['id']}\">{$survey['titolo']}</option>";
                    }
                }
                $stmtGetSondaggiCreatore -> closeCursor();
                ?>
            </select>
        </div>
        <input type="hidden" name="idMittente" value="<?php echo $_SESSION['user']['idUtente']; ?>">
        <button type="submit" class="btn btn-primary">Invia Invito</button>
    </form>
</div>
</body>
</html>
