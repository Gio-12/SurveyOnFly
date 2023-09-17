<?php
global $pdo;
session_start();

if (!$_SESSION['user']['tipologiaUtente'] === 'Premium') {
    header("Location: error.php");
    exit();
}

include "db/connect.php";
?>

<!DOCTYPE html>
<html lang="it">
<head>
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

                <?php
                $sqlGetUtentiFisici = "CALL getListaUtentiFisici()";
                $stmtGetUtentiFisici = $pdo->prepare($sqlGetUtentiFisici);
                $stmtGetUtentiFisici->execute();
                $users = $stmtGetUtentiFisici->fetchAll(PDO::FETCH_ASSOC);

                foreach ($users as $user) {

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

                <?php
                $userId = $_SESSION['user']['idUtente'];
                $userId = (int)$userId;

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
<style>
    body {
        background-color: #f5f5f5;
        font-family: Arial, sans-serif;
    }

    .container {
        background-color: #fff;
        border-radius: 5px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        padding: 20px;
        margin-top: 20px;
    }

    h2 {
        margin-bottom: 20px;
    }

    label {
        font-weight: bold;
    }

    select.form-control,
    input.form-control {
        width: 100%;
        padding: 10px;
        margin-bottom: 20px;
        border: 1px solid #ccc;
        border-radius: 4px;
    }

    button.btn-primary {
        background-color: #222222;
        color: #fff;
        border: none;
    }

    button.btn-primary:hover {
        background-color: #0056b3;
    }
</style>