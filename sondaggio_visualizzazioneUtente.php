<?php
session_start();
include "db/connect.php";
global $pdo;
global $surveyId;

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
    <div class="card mb-4">
        <div class="card-body">
            <h2 class="card-title">Dettagli Sondaggio</h2>
            <p><strong>Titolo:</strong> <?php echo $titolo; ?></p>
            <p><strong>Data Creazione:</strong> <?php echo $dataCreazione; ?></p>
            <p><strong>Data Attuale:</strong> <?php echo $dataAttuale; ?></p>
            <p><strong>Data Chiusura:</strong> <?php echo $dataChiusura; ?></p>
            <p><strong>Stato:</strong> <?php echo $stato; ?></p>
            <p><strong>Numero Massimo di Partecipanti:</strong> <?php echo $numMaxPartecipanti; ?></p>
            <p><strong>Numero di Iscritti:</strong> <?php echo $numeroIscritti; ?></p>
        </div>
    </div>
    <div class="card">
    <div class="card-body">
        <h2>Domande del Sondaggio</h2>
        <table class="table">
            <thead>
            <tr>
                <th>Testo Domanda</th>
                <th>Foto</th>
                <th>Punteggio</th>
                <th>Lunghezza Massima</th>
                <th>Tipologia</th>
                <th>Risposta Utente</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($domande as $domanda) { ?>
                <tr>
                    <td><?php echo $domanda['domanda_testo']; ?></td>
                    <td>
                        <?php
                        // Check if there is blob data
                        if (!empty($domanda['domanda_foto'])) {
                            // Generate a data URI for the image
                            $imageData = base64_encode($domanda['domanda_foto']);
                            $imageType = 'image/jpeg'; // Set the appropriate image type
                            $dataUri = "data:$imageType;base64,$imageData";
                            ?>
                            <img src="<?php echo $dataUri; ?>" alt="Image">
                        <?php } else {
                            echo "No image available";
                        }
                        ?>
                    </td>
                    <td><?php echo $domanda['domanda_punteggio']; ?></td>
                    <td><?php echo $domanda['domanda_lunghezzaMax']; ?></td>
                    <td><?php echo $domanda['domanda_tipologia']; ?></td>
                    <td>
                        <?php
                        // Call the stored procedures to get user answers
                        $domandaId = $domanda['domanda_id'];
                        $userId = $_SESSION['user']['idUtente'];
                        $sqlGetRispostaChiusa = "CALL getRipostaChiusaUtente(?, ?)";
                        $sqlGetRispostaAperta = "CALL getRipostaApertaUtente(?, ?)";

                        try {
                            // Check the question type
                            if ($domanda['domanda_tipologia'] === 'Chiusa') {
                                $stmtGetRisposta = $pdo->prepare($sqlGetRispostaChiusa);
                            } else {
                                $stmtGetRisposta = $pdo->prepare($sqlGetRispostaAperta);
                            }

                            $stmtGetRisposta->bindParam(1, $userId, PDO::PARAM_INT);
                            $stmtGetRisposta->bindParam(2, $domandaId, PDO::PARAM_INT);
                            $stmtGetRisposta->execute();

                            $risposta = $stmtGetRisposta->fetch(PDO::FETCH_ASSOC);

                            if ($risposta) {
                                // Display user answer
                                if ($domanda['domanda_tipologia'] === 'Chiusa') {
                                    // Display idOpzione for "Chiusa" questions
                                    echo "ID Opzione: " . $risposta['idOpzione'];
                                } else {
                                    // Display user answer for "Aperta" questions
                                    echo $risposta['testoRisposta'];
                                }
                            } else {
                                // Display a message indicating no answer
                                echo "Nessuna risposta data.";
                            }

                            $stmtGetRisposta -> closeCursor();
                        } catch (PDOException $e) {
                            echo "Error fetching user answers: " . $e->getMessage();
                        }
                        ?>
                    </td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
    </div>
</div>
</body>

</html>
<script>
    function goBack() {
        window.history.back();
    }
</script>