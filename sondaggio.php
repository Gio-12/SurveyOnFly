<?php
global $pdo;
session_start();

if ($_SESSION['user']['tipologiaUtente'] === 'Azienda') {
    header("Location: error.php");
    exit();
}

include "db/connect.php";

try {
    $userId = $_SESSION['user']['idUtente'];
    $userType = $_SESSION['user']['tipologia'];

    $listaSondaggioCreatore = array();
    $listaSondaggioPartecipante = array();


    if ($userType === 'Premium' || $userType === 'Amministratore' || $userType === 'Azienda') {
        $sqlListaSondaggioCreatore = "CALL getListaSondaggioCreatore(?)";

        $stmtListaSondaggioCreatore = $pdo->prepare($sqlListaSondaggioCreatore);
        $stmtListaSondaggioCreatore->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtListaSondaggioCreatore->execute();
        $listaSondaggioCreatore = $stmtListaSondaggioCreatore->fetchAll(PDO::FETCH_ASSOC);

        $stmtListaSondaggioCreatore->closeCursor();
    }


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
<?php include 'includes/header.php'; ?>
<div class="container">
    <div class="row">
        <div class="col-sm-8 text-left"><h2>Sondaggi Partecipati</h2></div>
    </div>
    <table class="table table-bordered">
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
                    if ($survey['stato'] === 'Aperto' && $survey['completato'] !== 1) {
                        echo '<a href="sondaggio_partecipazione.php?SondaggioId=' . $survey['id'] . '" class="btn btn-primary">Avvia</a>';
                    } else {
                        echo '<a href="sondaggio_visualizzazioneUtente.php?SondaggioId=' . $survey['id'] . '" class="btn btn-primary">Visualizza</a>';
                    }
                    ?>
                </td>
            </tr>
        <?php } ?>
        </tbody>
    </table>
</div>

<?php

if ($userType === 'Premium' || $userType === 'Azienda') {
    ?>
    <div class="container">
        <div class="row">
            <div class="col-sm-8 text-left"><h2>Sondaggi Creati</h2></div>
            <div class="col-sm-4 text-right">
                <a href="sondaggio_creazione.php" type="button" class="btn btn-info add-new"><i class="fa fa-plus"></i> Aggiungi Nuovo Sondaggio</a>
            </div>
        </div>
        <table class="table table-bordered">
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
                            echo '<a href="sondaggio_gestioneCreazione.php?SondaggioId=' . $survey['id'] . '" class="btn btn-primary">Procedura Creazione</a>';
                        } elseif ($survey['stato'] === 'Aperto' || $survey['stato'] === 'Chiuso') {
                            echo '<a href="sondaggio_visualizzazione.php?SondaggioId=' . $survey['id'] . '" class="btn btn-success">Visualizza</a>';
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
<style>
    .container{
        margin: 50px auto;
    }
</style>
