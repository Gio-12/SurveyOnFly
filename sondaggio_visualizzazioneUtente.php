<?php
session_start();
include "db/connect.php"; // Include your database connection script
global $pdo;
global $surveyId; // Make sure to set the $surveyId based on your requirements

if (isset($_GET['SondaggioId'])) {
    $surveyId = ($_GET['SondaggioId']);
    // Query the database to retrieve the survey with $surveyId
    // If the survey exists, display its details
    // Otherwise, show an error message like "Sondaggio not found"
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
    <!-- Include Bootstrap libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>
<?php include 'includes/header.php'; ?>
<div class="container mt-5">
    <h1>Sondaggio Visualizzazione</h1>
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
                    <td><?php echo $domanda['domanda_foto']; ?></td>
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

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>

</html>
