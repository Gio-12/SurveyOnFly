<?php
session_start();
include "db/connect.php";
global $pdo;
global $surveyId;

if (isset($_GET['SondaggioId'])) {
    $surveyId = ($_GET['SondaggioId']);
} else {
    echo "Invalid request: Missing 'SondaggioId' parameter";
    exit;
}

$selected_idSondaggio = (int)$surveyId;
$sqlGetSondaggio = "CALL getSondaggioSingolo(?)";

try {
    $stmtGetSondaggio = $pdo->prepare($sqlGetSondaggio);
    $stmtGetSondaggio->bindParam(1, $selected_idSondaggio, PDO::PARAM_INT);
    $stmtGetSondaggio->execute();

    $surveyDetails = $stmtGetSondaggio->fetch(PDO::FETCH_ASSOC);

    if (!$surveyDetails) {
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
    $stmtGetSondaggio->closeCursor();
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

    $stmtGetDomande->closeCursor();
} catch (PDOException $e) {
    echo "Error fetching questions: " . $e->getMessage();
    exit;
}
?>

<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="utf-8">
    <title>Sondaggio Visualizzazione</title>
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
<div class="container">
    <div class="row">
        <div class="col-sm-8 text-left">
            <div class="page-title">
                <h1>SONDAGGIO </h1>
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

    <div class="question-list">
        <h2>Domande del Sondaggio</h2>
        <table class="table">
            <thead>
            <tr>
                <th>Testo Domanda</th>
                <th>Foto</th>
                <th>Punteggio</th>
                <th>Lunghezza Massima</th>
                <th>Tipologia</th>
                <th>Opzioni</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($domande as $domanda) { ?>
                <tr>
                    <td><?php echo $domanda['domanda_testo']; ?></td>
                    <td><?php echo $domanda['domanda_foto']; ?></td>
                    <td><?php echo $domanda['domanda_punteggio']; ?></td>
                    <td><?php echo $domanda['domanda_lunghezzaMax']; ?></td>
                    <td><?php echo $domanda['domanda_tipologia']; ?></td>
                    <td>
                        <?php
                        $domandaId = $domanda['domanda_id'];
                        $sqlGetOpzioni = "CALL getOpzioniDomanda(?)";

                        try {
                            $stmtGetOpzioni = $pdo->prepare($sqlGetOpzioni);
                            $stmtGetOpzioni->bindParam(1, $domandaId, PDO::PARAM_INT);
                            $stmtGetOpzioni->execute();

                            $opzioni = $stmtGetOpzioni->fetchAll(PDO::FETCH_ASSOC);

                            foreach ($opzioni as $opzione) {
                                echo $opzione['domanda_testo'] . "<br>";
                            }

                            $stmtGetOpzioni->closeCursor();
                        } catch (PDOException $e) {
                            echo "Error fetching options: " . $e->getMessage();
                        }
                        ?>
                    </td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
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
    .container {
        margin-top: 20px;
    }
    .survey-details {
        background-color: #f8f9fa;
        padding: 20px;
        border-radius: 5px;
    }

    .question-list {
        margin-top: 20px;
    }
</style>