<?php
global $pdo;
session_start();
if (!$_SESSION['user']['tipologiaUtente'] === 'Premium' || !$_SESSION['user']['tipologiaUtente'] === 'Azienda') {
    header("Location: error.php");
    exit();
}

include "db/connect.php";

// Initialize variables
$selectedSondaggioId = null;
$statistics = [];

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    if (isset($_POST['idSondaggio'])) {
        $selectedSondaggioId = $_POST['idSondaggio'];

        // Call the stored procedure to retrieve statistics
        $sqlCallProcedure = "CALL statisticheAggregate(?)";
        $stmtCallProcedure = $pdo->prepare($sqlCallProcedure);
        $stmtCallProcedure->bindParam(1, $selectedSondaggioId, PDO::PARAM_INT);
        $stmtCallProcedure->execute();

        // Fetch the statistics
        $statistics = $stmtCallProcedure->fetchAll(PDO::FETCH_ASSOC);
        $stmtCallProcedure->closeCursor();
    }
}

// Fetch the list of surveys for the logged-in user
$userId = $_SESSION['user']['idUtente'];
$userId = (int)$userId;

$sqlGetSondaggiCreatore = "CALL getListaSondaggioCreatore(?)";
$stmtGetSondaggiCreatore = $pdo->prepare($sqlGetSondaggiCreatore);
$stmtGetSondaggiCreatore->bindParam(1, $userId, PDO::PARAM_INT);
$stmtGetSondaggiCreatore->execute();
$surveys2 = $stmtGetSondaggiCreatore->fetchAll(PDO::FETCH_ASSOC);
$surveys = [];
foreach ($surveys2 as $survey) {
    if ($survey['stato'] === 'Aperto' && $survey['numeroIscritti'] < $survey['numMaxPartecipanti']) {
        $surveys[] = $survey;
    }
}
$stmtGetSondaggiCreatore->closeCursor();
?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualizza Statistiche</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<?php include 'includes/header.php'; ?>
<div class="container mt-5">
    <h2>Visualizza Statistiche del Sondaggio</h2>
    <form method="post" action="">
        <div class="form-group">
            <label for="survey">Seleziona il sondaggio:</label>
            <select class="form-control" id="survey" name="idSondaggio">
                <option value="">Seleziona un sondaggio</option>
                <?php foreach ($surveys as $survey) : ?>
                    <option value="<?= $survey['id'] ?>" <?= ($survey['id'] == $selectedSondaggioId) ? 'selected' : '' ?>>
                        <?= $survey['titolo'] ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </div>
        <button type="submit" class="btn btn-primary" name="visualizzaStatistiche">Visualizza Statistiche</button>
    </form>

    <?php if (!empty($statistics)) : ?>
        <h3 class="mt-4">Statistiche del Sondaggio Selezionato</h3>
        <table class="table">
            <thead>
            <tr>
                <th>Domanda</th>
                <th>Opzioni</th>
                <th>Tipo Domanda</th>
                <th>Numero di Risposte</th>
                <th>Valore Medio</th>
                <th>Valore Minimo</th>
                <th>Valore Massimo</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($statistics as $stat) : ?>
                <tr>
                    <td><?= $stat['testo_domanda'] ?></td>
                    <td><?= $stat['risposte_chiuse'] ?></td>
                    <td><?= $stat['domanda_tipo'] ?></td>
                    <td><?= $stat['num_risposte'] ?></td>
                    <td><?= $stat['valore_medio'] ?></td>
                    <td><?= $stat['valore_minimo'] ?></td>
                    <td><?= $stat['valore_massimo'] ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
</body>
</html>
