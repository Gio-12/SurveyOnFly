<?php
session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;
global $surveyId;

if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}

if (isset($_GET['SondaggioId'])) {
    $surveyId = ($_GET['SondaggioId']);
} else {
    echo "Invalid request: Missing 'SondaggioId' parameter";
}

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
    <div class="row">
        <div class="col-sm-8 text-left">
            <div class="page-title">
                <h1>SONDAGGIO</h1>
            </div>
        </div>
        <div class="col-sm-4 text-right">
            <button class="btn btn-primary go-back-button" onclick="goBack()">Indietro</button>
        </div>
    </div>
    <div class="survey-details">
        <h2>Dettagli Sondaggio</h2>
        <p><strong>Titolo:</strong> <?php echo $titolo; ?></p>
        <p><strong>Data Creazione:</strong> <?php echo $dataCreazione; ?></p>
        <p><strong>Data Attuale:</strong> <?php echo $dataAttuale; ?></p>
        <p><strong>Data Chiusura:</strong> <?php echo $dataChiusura; ?></p>
        <p><strong>Stato:</strong> <?php echo $stato; ?></p>
        <p><strong>Numero Massimo di Partecipanti:</strong> <?php echo $numMaxPartecipanti; ?></p>
        <p><strong>Numero di Iscritti:</strong> <?php echo $numeroIscritti; ?></p>
    </div>

    <div class="questions-section">
        <h2>Domande del Sondaggio</h2>
        <form method="post" action="sondaggio_invio.php">
            <input type="hidden" name="sondaggio_id" value="<?php echo $selected_idSondaggio; ?>">
            <?php foreach ($domande as $domanda) { ?>
                <div class="question">
                    <h3><?php echo $domanda['domanda_testo']; ?></h3>
                    <?php if ($domanda['domanda_tipologia'] === 'Aperta') { ?>
                        <?php
                        $maxCharacters = $domanda['domanda_lunghezzaMax'];
                        ?>
                        <label for="domanda_<?php echo $domanda['domanda_id']; ?>">Risposta (Massimo <?php echo $maxCharacters; ?> caratteri):</label>
                        <textarea class="form-control" id="domanda_<?php echo $domanda['domanda_id']; ?>"
                                  name="risposta_aperta_<?php echo $domanda['domanda_id']; ?>"
                                  maxlength="<?php echo $maxCharacters; ?>"></textarea>
                    <?php } elseif ($domanda['domanda_tipologia'] === 'Chiusa') { ?>
                        <?php
                        $domandaId = $domanda['domanda_id'];
                        $sqlGetOpzioni = "CALL getOpzioniDomanda(?)";

                        try {
                            $stmtGetOpzioni = $pdo->prepare($sqlGetOpzioni);
                            $stmtGetOpzioni->bindParam(1, $domandaId, PDO::PARAM_INT);
                            $stmtGetOpzioni->execute();

                            $opzioni = $stmtGetOpzioni->fetchAll(PDO::FETCH_ASSOC);

                            foreach ($opzioni as $opzione) { ?>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio"
                                           name="risposta_chiusa_<?php echo $domanda['domanda_id']; ?>"
                                           id="opzione_<?php echo $opzione['opzione_Id']; ?>"
                                           value="<?php echo $opzione['opzione_Id']; ?>">
                                    <label class="form-check-label"
                                           for="opzione_<?php echo $opzione['opzione_Id']; ?>"><?php echo $opzione['domanda_testo']; ?></label>
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
            <div class="submit-button">
                <button type="submit" class="btn btn-primary">Invia Sondaggio</button>
            </div>
        </form>
    </div>
</div>
</body>
</html>
<script>
    function goBack() {
        window.history.back();
    }
</script>
<style>
    body {
        background-color: #f5f5f5;
    }

    .container {
        background-color: #fff;
        padding: 20px;
        border-radius: 5px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        margin-top: 20px;
    }

    .page-title {
        text-align: center;
    }

    .go-back-button {
        float: right;
    }

    .survey-details {
        margin-top: 20px;
        background-color: #f9f9f9;
        padding: 15px;
        border: 1px solid #ddd;
        border-radius: 5px;
        margin-bottom: 20px;
    }

    .survey-details h2 {
        color: #333;
        margin-bottom: 10px;
    }

    .survey-details p {
        font-size: 16px;
        margin: 5px 0;
    }

    .questions-section {
        background-color: #f9f9f9;
        padding: 15px;
        border: 1px solid #ddd;
        border-radius: 5px;
    }

    .question {
        margin-bottom: 20px;
        padding: 15px;
        border: 1px solid #ddd;
        border-radius: 5px;
        background-color: #fff;
    }

    .question h3 {
        color: #333;
        margin-bottom: 10px;
    }

    .question textarea {
        width: 100%;
        padding: 10px;
        border: 1px solid #ddd;
        border-radius: 5px;
    }

    .question label {
        font-weight: bold;
    }

    .question .form-check {
        margin-top: 10px;
    }

    .question .form-check label {
        font-weight: normal;
    }

    .submit-button {
        margin-top: 20px;
        text-align: center;
    }
</style>