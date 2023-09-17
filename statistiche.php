<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Statistiche EFORM</title>
    <!-- Aggiungi qui le librerie o i file CSS per la visualizzazione delle statistiche, ad esempio chart.js o simili -->

    <style>
        .container {
            width: 80%; /* Imposta la larghezza desiderata */
            margin: 0 auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }

        th {
            background-color: #f2f2f2;
        }

        .expandable-content {
            display: none;
        }
    </style>
</head>
<body>
<?php include 'includes/header.php'; ?>
<div class="container">
<h2>Statistiche dei Sondaggi</h2>

<?php
global $pdo;
session_start();
// Include your database connection script
include "db/connect.php";

try {
    // Esempio: Ottieni tutti i sondaggi
    $sqlSondaggi = "SELECT * FROM Sondaggio";
    $stmtSondaggi = $pdo->prepare($sqlSondaggi);
    $stmtSondaggi->execute();
    $resultsSondaggi = $stmtSondaggi->fetchAll(PDO::FETCH_ASSOC);

    foreach ($resultsSondaggi as $sondaggio) {
        $sondaggioId = $sondaggio['id'];
        $sondaggioTitolo = $sondaggio['titolo'];

        // Esempio: Numero di risposte per ogni domanda in un sondaggio
        $sqlResponsesPerQuestion = "SELECT d.testo AS testo_domanda, COUNT(r.id) AS num_risposte
                                    FROM Domanda d
                                    LEFT JOIN RispostaAperta r ON d.id = r.idDomanda
                                    WHERE d.idSondaggio = :sondaggioId
                                    GROUP BY d.testo";
        $stmtResponsesPerQuestion = $pdo->prepare($sqlResponsesPerQuestion);
        $stmtResponsesPerQuestion->bindParam(':sondaggioId', $sondaggioId, PDO::PARAM_INT);
        $stmtResponsesPerQuestion->execute();
        $resultsResponsesPerQuestion = $stmtResponsesPerQuestion->fetchAll(PDO::FETCH_ASSOC);

        // Esempio: Distribuzione delle risposte per le domande chiuse in un sondaggio
        $sqlClosedQuestionDistribution = "SELECT d.testo AS testo_domanda, o.testo AS opzione, COUNT(rc.id) AS num_risposte
                                        FROM Domanda d
                                        LEFT JOIN Opzione o ON d.id = o.idDomanda
                                        LEFT JOIN RispostaChiusa rc ON o.idOpzione = rc.idOpzione
                                        WHERE d.idSondaggio = :sondaggioId AND d.tipologia = 'chiusa'
                                        GROUP BY d.testo, o.testo";
        $stmtClosedQuestionDistribution = $pdo->prepare($sqlClosedQuestionDistribution);
        $stmtClosedQuestionDistribution->bindParam(':sondaggioId', $sondaggioId, PDO::PARAM_INT);
        $stmtClosedQuestionDistribution->execute();
        $resultsClosedQuestionDistribution = $stmtClosedQuestionDistribution->fetchAll(PDO::FETCH_ASSOC);

        // Esempio: Valore medio, minimo e massimo del numero di caratteri per le domande aperte in un sondaggio
        $sqlOpenQuestionStats = "SELECT d.testo AS testo_domanda, 
                                        AVG(LENGTH(ra.testoRisposta)) AS valore_medio,
                                        MIN(LENGTH(ra.testoRisposta)) AS valore_minimo,
                                        MAX(LENGTH(ra.testoRisposta)) AS valore_massimo
                                FROM Domanda d
                                LEFT JOIN RispostaAperta ra ON d.id = ra.idDomanda
                                WHERE d.idSondaggio = :sondaggioId AND d.tipologia = 'aperta'
                                GROUP BY d.testo";
        $stmtOpenQuestionStats = $pdo->prepare($sqlOpenQuestionStats);
        $stmtOpenQuestionStats->bindParam(':sondaggioId', $sondaggioId, PDO::PARAM_INT);
        $stmtOpenQuestionStats->execute();
        $resultsOpenQuestionStats = $stmtOpenQuestionStats->fetchAll(PDO::FETCH_ASSOC);
        // Stampa il titolo del sondaggio come link espandibile
        echo "<h3><a href='javascript:void(0);' class='expandable-link'>$sondaggioTitolo</a></h3>";

        // Crea una sezione espandibile per le statistiche del sondaggio
        echo "<div class='expandable-content'>";
        echo "<h4>Numero di Risposte per Ogni Domanda</h4>";
        echo "<table>";
        echo "<thead>";
        echo "<tr>";
        echo "<th>Testo Domanda</th>";
        echo "<th>Numero di Risposte</th>";
        echo "</tr>";
        echo "</thead>";
        echo "<tbody>";
        foreach ($resultsResponsesPerQuestion as $row) {
            echo "<tr>";
            echo "<td>{$row['testo_domanda']}</td>";
            echo "<td>{$row['num_risposte']}</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";

        echo "<h4>Distribuzione delle Risposte per Domande Chiuse</h4>";
        echo "<table>";
        echo "<thead>";
        echo "<tr>";
        echo "<th>Testo Domanda</th>";
        echo "<th>Opzione</th>";
        echo "<th>Numero di Risposte</th>";
        echo "</tr>";
        echo "</thead>";
        echo "<tbody>";
        foreach ($resultsClosedQuestionDistribution as $row) {
            echo "<tr>";
            echo "<td>{$row['testo_domanda']}</td>";
            echo "<td>{$row['opzione']}</td>";
            echo "<td>{$row['num_risposte']}</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";

        echo "<h4>Statistiche delle Domande Aperte</h4>";
        echo "<table>";
        echo "<thead>";
        echo "<tr>";
        echo "<th>Testo Domanda</th>";
        echo "<th>Valore Medio</th>";
        echo "<th>Valore Minimo</th>";
        echo "<th>Valore Massimo</th>";
        echo "</tr>";
        echo "</thead>";
        echo "<tbody>";
        foreach ($resultsOpenQuestionStats as $row) {
            echo "<tr>";
            echo "<td>{$row['testo_domanda']}</td>";
            echo "<td>{$row['valore_medio']}</td>";
            echo "<td>{$row['valore_minimo']}</td>";
            echo "<td>{$row['valore_massimo']}</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";

        echo "</div>"; // Fine della sezione espandibile
    }
} catch (PDOException $e) {
    echo "Errore nella query: " . $e->getMessage();
}
?>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
    $(document).ready(function () {
        // Gestisci il clic sui link espandibili dei sondaggi
        $('.expandable-link').click(function () {
            $(this).parent().next('.expandable-content').slideToggle();
        });
    });
</script>
</body>
</html>
