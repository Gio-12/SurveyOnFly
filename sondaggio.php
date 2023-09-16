<?php
global $pdo;
session_start();
// Include your database connection script
include "db/connect.php";

try {
    $userId = $_SESSION['user']['idUtente'];
    $userType = $_SESSION['user']['tipologia'];

    $listaSondaggioCreatore = array();
    $listaSondaggioPartecipante = array();

    // Check if the user type allows access to ListaSondaggioCreatore
    if ($userType === 'Premium' || $userType === 'Amministratore' || $userType === 'Azienda') {
        $sqlListaSondaggioCreatore = "CALL getListaSondaggioCreatore(?)";

        $stmtListaSondaggioCreatore = $pdo->prepare($sqlListaSondaggioCreatore);
        $stmtListaSondaggioCreatore->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtListaSondaggioCreatore->execute();
        $listaSondaggioCreatore = $stmtListaSondaggioCreatore->fetchAll(PDO::FETCH_ASSOC);

        $stmtListaSondaggioCreatore->closeCursor();
    }

    // Check if the user type allows access to ListaSondaggioPartecipante
    if ($userType === 'Premium' || $userType === 'Amministratore' || $userType === 'Semplice' ) {
        $sqlListaSondaggioPartecipante = "CALL getListaSondaggioPartecipante(?)";

        $stmtListaSondaggioPartecipante = $pdo->prepare($sqlListaSondaggioPartecipante);
        $stmtListaSondaggioPartecipante->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtListaSondaggioPartecipante->execute();
        $listaSondaggioPartecipante = $stmtListaSondaggioPartecipante->fetchAll(PDO::FETCH_ASSOC);

        $stmtListaSondaggioPartecipante->closeCursor();
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Sondaggi</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container">
    <h2>Sondaggi Partecipati</h2>
    <table class="table table-bordered">
        <!-- Table header -->
        <thead>
        <tr>
            <th>titolo</th>
            <th>dataCreazione</th>
            <th>dataAttuale</th>
            <th>dataChiusura</th>
            <th>stato</th>
            <th>numMaxPartecipanti</th>
            <th>numeroIscritti</th>
            <th>completato</th>
            <th>Azioni</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($listaSondaggioPartecipante as $survey) { ?>
            <tr>
                <!-- Display data for each sondaggio -->
                <td><?php echo $survey['titolo']; ?></td>
                <td><?php echo $survey['dataCreazione']; ?></td>
                <td><?php echo $survey['dataAttuale']; ?></td>
                <td><?php echo $survey['dataChiusura']; ?></td>
                <td><?php echo $survey['stato']; ?></td>
                <td><?php echo $survey['numMaxPartecipanti']; ?></td>
                <td><?php echo $survey['numeroIscritti']; ?></td>
                <td><?php echo $survey['completato']; ?></td>
                <td>
                    <?php
                    if ($survey['stato'] !== 'Chiuso' && $survey['stato'] !== '1') {
                        // Display a button linked to the survey_partecipazione page
                        echo '<a href="sondaggio_partecipazione.php?survey_id=' . $survey['id'] . '" class="btn btn-primary">Avvia</a>';
                    }
                    ?>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
</div>

<?php
// Check if the user has permission to view "Sondaggi Creati" table
if ($userType === 'Premium' || $userType === 'Azienda' || $userType === 'Amministratore') {
    ?>
    <div class="container">
        <h2>Sondaggi Creati
                <a href="sondaggio_creazione.php" type="button" class="btn btn-info add-new"><i class="fa fa-plus"></i> Aggiungi Nuovo Sondaggio</a>
        </h2>
        <table class="table table-bordered">
            <!-- Table header -->
            <thead>
            <tr>
                <th>titolo</th>
                <th>dataCreazione</th>
                <th>dataAttuale</th>
                <th>dataChiusura</th>
                <th>stato</th>
                <th>numMaxPartecipanti</th>
                <th>numeroIscritti</th>
                <th>Azioni</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($listaSondaggioCreatore as $survey) { ?>
                <tr>
                    <!-- Display data for each sondaggio -->
                    <td><?php echo $survey['titolo']; ?></td>
                    <td><?php echo $survey['dataCreazione']; ?></td>
                    <td><?php echo $survey['dataAttuale']; ?></td>
                    <td><?php echo $survey['dataChiusura']; ?></td>
                    <td><?php echo $survey['stato']; ?></td>
                    <td><?php echo $survey['numMaxPartecipanti']; ?></td>
                    <td><?php echo $survey['numeroIscritti']; ?></td>
                    <td>
                        <?php
                        if ($survey['stato'] === 'Creazione') {
                            // Display a button linked to sondaggio_creazione.php
                            echo '<a href="sondaggio_gestioneCreazione.php?survey_id=' . $survey['id'] . '" class="btn btn-primary">Procedura Creazione</a>';
                        } elseif ($survey['stato'] === 'Attivo' || $survey['stato'] === 'Chiuso') {
                            // Display a button linked to sondaggio_visualizzazione.php
                            echo '<a href="sondaggio_visualizzazione.php?survey_id=' . $survey['id'] . '" class="btn btn-success">Visualizza</a>';
                        }
                        ?>
                    </td>
                </tr>
            <?php } ?>
            </tbody>
        </table>
    </div>
<?php } ?>
</body>
</html>

