<?php
session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;
global $surveyId;

// Check if the user is logged in and retrieve their user ID
if (!isset($_SESSION['user'])) {
    // Redirect to the login page if the user is not logged in
    header("Location: login.php");
    exit();
}

if (isset($_GET['SondaggioId'])) {
    $surveyId = ($_GET['SondaggioId']);
} else {
    echo "Invalid request: Missing 'SondaggioId' parameter";
}

// Call the stored procedure to retrieve survey details
$selected_idSondaggio = (int)$surveyId;
$sqlGetSondaggio = "CALL getSondaggioSingolo(?)";

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
    <title>Completa Sondaggio</title>
    <!-- Include Bootstrap libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>
<body>
<?php include 'includes/header.php'; ?>
<div class="container mt-5">
    <h1>Completa il Sondaggio</h1>
    <button onclick="goBack()">Torna Indietro</button>

    <script>
        function goBack() {
            window.history.back();
        }
    </script>
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
        <form method="post" action="sondaggio_invio.php">
            <?php foreach ($domande as $domanda) { ?>
                <div class="mb-3">
                    <label for="domanda_<?php echo $domanda['domanda_id']; ?>"><?php echo $domanda['domanda_testo']; ?></label>
                    <?php if ($domanda['domanda_tipologia'] === 'Aperta') { ?>
                        <?php
                        $maxCharacters = $domanda['domanda_lunghezzaMax']; // Maximum character limit for this question
                        ?>
                        <textarea class="form-control" id="domanda_<?php echo $domanda['domanda_id']; ?>"
                                  name="risposta_aperta_<?php echo $domanda['domanda_id']; ?>"
                                  maxlength="<?php echo $maxCharacters; ?>"></textarea>
                        <small class="text-muted">Massimo <?php echo $maxCharacters; ?> caratteri</small>
                    <?php } elseif ($domanda['domanda_tipologia'] === 'Chiusa') { ?>
                        <?php
                        // Retrieve multiple-choice options for Chiusa questions
                        $domandaId = $domanda['domanda_id'];
                        $sqlGetOpzioni = "CALL getOpzioniDomanda(?)";

                        try {
                            $stmtGetOpzioni = $pdo->prepare($sqlGetOpzioni);
                            $stmtGetOpzioni->bindParam(1, $domandaId, PDO::PARAM_INT);
                            $stmtGetOpzioni->execute();

                            $opzioni = $stmtGetOpzioni->fetchAll(PDO::FETCH_ASSOC);

                            // Display radio buttons for multiple-choice options
                            foreach ($opzioni as $opzione) { ?>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio"
                                           name="risposta_chiusa_<?php echo $domanda['domanda_id']; ?>"
                                           id="opzione_<?php echo $opzione['idOpzione']; ?>"
                                           value="<?php echo $opzione['idOpzione']; ?>">
                                    <label class="form-check-label"
                                           for="opzione_<?php echo $opzione['idOpzione']; ?>"><?php echo $opzione['domanda_testo']; ?></label>
                                </div>
                            <?php }

                            $stmtGetOpzioni->closeCursor();
                        } catch (PDOException $e) {
                            echo "Error fetching options: " . $e->getMessage();
                        }
                        ?>
                    <?php } ?>
                </div>
            <?php } ?>
            <button type="submit" class="btn btn-primary">Invia Sondaggio</button>
        </form>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>

</html>
