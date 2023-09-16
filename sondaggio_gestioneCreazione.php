<?php
session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;
global $surveyId;

if (isset($_GET['survey_id'])) {
    $surveyId = ($_GET['survey_id']);
    // Query the database to retrieve the survey with $surveyId
    // If the survey exists, display its details
    // Otherwise, show an error message like "Sondaggio not found"
} else {
    echo "Invalid request: Missing 'id' parameter";
}
// Call the stored procedure to retrieve survey details
$sqlGetSondaggio = "CALL getSondaggioSingolo(?)";
$selected_idSondaggio = (int)$surveyId;

try {
    $stmtGetSondaggio = $pdo->prepare($sqlGetSondaggio);
    $stmtGetSondaggio->bindParam(1, $selected_idSondaggio, PDO::PARAM_INT);
    $stmtGetSondaggio->execute();

    $surveyDetails = $stmtGetSondaggio->fetch(PDO::FETCH_ASSOC);

    // Check if a valid survey is found
    if (!$surveyDetails) {
        // Handle error, e.g., survey not found
        echo "Sondaggio not found";
        exit;
    }

    $titolo = $surveyDetails['titolo'];
    $dataCreazione = $surveyDetails['dataCreazione'];
    $dataAttuale = $surveyDetails['dataAttuale'];
    $dataChiusura = $surveyDetails['dataChiusura'];
    $stato = $surveyDetails['stato'];
    $numMaxPartecipanti = $surveyDetails['numMaxPartecipanti'];
    $numeroIscritti = $surveyDetails['numeroIscritti'];
    $stmtGetSondaggio ->closeCursor();
} catch (PDOException $e) {
    echo "Error fetching survey data: " . $e->getMessage();
    exit;
}

// Call the stored procedure to retrieve questions for the survey
$sqlGetDomande = "CALL getDomandeSondaggio(?)";

try {
    $stmtGetDomande = $pdo->prepare($sqlGetDomande);
    $stmtGetDomande->bindParam(1, $selected_idSondaggio, PDO::PARAM_INT);
    $stmtGetDomande->execute();

    $domande = $stmtGetDomande->fetchAll(PDO::FETCH_ASSOC);

    $stmtGetDomande -> closeCursor();
} catch (PDOException $e) {
    echo "Error fetching questions: " . $e->getMessage();
    exit;
}
?>

<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="utf-8">
    <title>Gestione Creazione Sondaggio</title>
    <!-- Include Bootstrap libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>
<div class="container mt-5">
    <h1>Gestione Creazione Sondaggio</h1>

    <div class="mb-3">
        <h2>Dettagli Sondaggio</h2>
        <p><strong>Titolo:</strong> <?php echo $titolo; ?></p>
        <p><strong>Data Creazione:</strong> <?php echo $dataCreazione; ?></p>
        <p><strong>Data Attuale:</strong> <?php echo $dataAttuale; ?></p>
        <p><strong>Data Chiusura:</strong> <?php echo $dataChiusura; ?></p>
        <p><strong>Stato:</strong> <?php echo $stato; ?></p>
        <p><strong>Numero Massimo di Partecipanti:</strong> <?php echo $numMaxPartecipanti; ?></p>
        <p><strong>Numero di Iscritti:</strong> <?php echo $numeroIscritti; ?></p>
    </div>

    <div class="mb-3">
        <h2>Domande del Sondaggio</h2>
        <table class="table">
            <thead>
            <tr>
<!--                <th>ID Domanda</th>-->
                <th>Testo Domanda</th>
                <th>Foto</th>
                <th>Punteggio</th>
                <th>Lunghezza Massima</th>
                <th>Tipologia</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($domande as $domanda) { ?>
                <tr>
<!--                    <td>--><?php //echo $domanda['domanda_id']; ?><!--</td>-->
                    <td><?php echo $domanda['domanda_testo']; ?></td>
                    <td><?php echo $domanda['domanda_foto']; ?></td>
                    <td><?php echo $domanda['domanda_punteggio']; ?></td>
                    <td><?php echo $domanda['domanda_lunghezzaMax']; ?></td>
                    <td><?php echo $domanda['domanda_tipologia']; ?></td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>

    <a href="sondaggio_addDomanda.php?idSondaggio=<?php echo $surveyId; ?>" class="btn btn-primary">Aggiungi Domanda</a>

    <form method="POST" action="activate_survey.php">
        <input type="hidden" name="survey_id" value="<?php echo $surveyId; ?>">
        <button type="submit" class="btn btn-success">Attiva Sondaggio</button>
    </form>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>

</html>
