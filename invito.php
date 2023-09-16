<?php
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Cambia "login.php" con la pagina di login desiderata
    exit(); // Assicura che l'esecuzione dello script si interrompa qui
}
global $pdo;
include "db/connect.php"; // Includi lo script di connessione al database

try {
    $userId = $_SESSION['user']['idUtente'];
    $userType = $_SESSION['user']['tipologia'];

    if ($userType == 'Premium' || $userType == 'Amministratore') {

        $sqlSentInvitations = "CALL getListaInvitoMittente(?)";

        $stmtSentInvitations = $pdo->prepare($sqlSentInvitations);
        $stmtSentInvitations->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtSentInvitations->execute();
        $sentInvitations = $stmtSentInvitations->fetchAll(PDO::FETCH_ASSOC);

        $stmtSentInvitations->closeCursor();
    }

    // Call the stored procedure to fetch invitations
    $sqlInvitations = "CALL getListaInvitoRicevente(?)";

    $stmtInvitations = $pdo->prepare($sqlInvitations);
    $stmtInvitations->bindParam(1, $userId, PDO::PARAM_INT);
    $stmtInvitations->execute();
    $invitations = $stmtInvitations->fetchAll(PDO::FETCH_ASSOC);

    $stmtInvitations->closeCursor();

    // Verifica lo stato del sondaggio per ciascun invito
    foreach ($invitations as &$invitation) {
        $sondaggioId = $invitation['idSondaggio']; // Sostituisci con il nome corretto della colonna che contiene l'ID del sondaggio
        $sqlCheckSondaggio = "SELECT stato, dataChiusura FROM sondaggio WHERE id = ?";
        $stmtCheckSondaggio = $pdo->prepare($sqlCheckSondaggio);
        $stmtCheckSondaggio->bindParam(1, $sondaggioId, PDO::PARAM_INT);
        $stmtCheckSondaggio->execute();
        $sondaggioDataChiusura = $stmtCheckSondaggio->fetch(PDO::FETCH_ASSOC);
        $stmtCheckSondaggio->closeCursor();

        // Verifica se la data di chiusura è successiva alla data corrente
        $dataChiusura = new DateTime($sondaggioDataChiusura['dataChiusura']);
        $dataCorrente = new DateTime();

        if ($dataChiusura > $dataCorrente) {
            // Il sondaggio è ancora attivo
            $invitation['sondaggio_stato'] = "Attivo";
        } else {
            // Il sondaggio non è più attivo
            $invitation['sondaggio_stato'] = "Non attivo";
        }
    }

    // Verifica lo stato degli inviti mandati
    foreach ($sentInvitations as &$sentInvitation) {
        $sondaggioId = $sentInvitation['idSondaggio']; // Sostituisci con il nome corretto della colonna che contiene l'ID del sondaggio
        $sqlCheckSondaggio = "SELECT stato, dataChiusura FROM sondaggio WHERE id = ?";
        $stmtCheckSondaggio = $pdo->prepare($sqlCheckSondaggio);
        $stmtCheckSondaggio->bindParam(1, $sondaggioId, PDO::PARAM_INT);
        $stmtCheckSondaggio->execute();
        $sondaggioDataChiusura = $stmtCheckSondaggio->fetch(PDO::FETCH_ASSOC);
        $stmtCheckSondaggio->closeCursor();

        // Verifica se la data di chiusura è successiva alla data corrente
        $dataChiusura = new DateTime($sondaggioDataChiusura['dataChiusura']);
        $dataCorrente = new DateTime();

        if ($dataChiusura > $dataCorrente) {
            // Il sondaggio è ancora attivo
            $sentInvitation['sondaggio_stato'] = "Attivo";
        } else {
            // Il sondaggio non è più attivo
            $sentInvitation['sondaggio_stato'] = "Non attivo";
        }
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="it">

<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Inviti</title>
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
        <h2>Inviti ricevuti</h2>
        <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Sondaggio</th>
                    <th>Mittente</th>
                    <th>Stato</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($invitations as $invitation) { ?>
                    <tr>
                        <td><?php echo $invitation['sondaggio_nome']; ?></td>
                        <td><?php echo $invitation['mittente_email']; ?></td>
                        <td><?php echo $invitation['sondaggio_stato']; ?></td>
                        <td>
                            <?php if ($invitation['hasValue'] == 0 && $invitation['sondaggio_stato'] == 'Attivo') { ?>
                                <button class="btn btn-success accept-invitation" data-invitation-id="<?php echo $invitation['codice']; ?>">Accetta</button>
                                <button class="btn btn-danger reject-invitation" data-invitation-id="<?php echo $invitation['codice']; ?>">Rifiuta</button>
                            <?php } else { ?>
                                <?php echo $invitation['esito']; ?>
                            <?php } ?>
                        </td>
                    </tr>
                <?php } ?>
            </tbody>
        </table>
    </div>
    <div class="container">
        <h2>Inviti mandati</h2>
        <div class="col-sm-4">
            <!--                        --><?php //if ($_SESSION['user']['tipologia'] === 'Premium') { 
                                            ?>
            <a href="invito_creazione.php" type="button" class="btn btn-info add-new"><i class="fa fa-plus"></i> Crea Invito</a>
            <!--                        --><?php //} else {
                                            //                            echo '<td></td>';
                                            //                        }
                                            ?>
        </div>
        <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Sondaggio</th>
                    <th>Mittente</th>
                    <th>Stato</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($sentInvitations as $sentInvitation) { ?>
                    <tr>
                        <td><?php echo $sentInvitation['sondaggio_nome']; ?></td>
                        <td><?php echo $sentInvitation['destinatario_email']; ?></td>
                        <td>
                            <?php if ($sentInvitation['hasValue'] == 0) { ?>
                                sconosciuto;
                            <?php } else { ?>
                                <?php echo $sentInvitation['esito']; ?>
                            <?php } ?>
                        </td>
                    </tr>
                <?php } ?>
            </tbody>
        </table>
    </div>
</body>

</html>
<script>
    $(document).ready(function() {
        // Gestisci il clic sul pulsante "Accetta"
        $(".accept-invitation").click(function() {
            var invitationId = $(this).data("invitation-id");
            rispondiAInvito(invitationId, "Accettato");
        });

        // Gestisci il clic sul pulsante "Rifiuta"
        $(".reject-invitation").click(function() {
            var invitationId = $(this).data("invitation-id");
            rispondiAInvito(invitationId, "Rifiutato");
        });

        function rispondiAInvito(invitationId, response) {
            // Effettua una chiamata AJAX a invito_risposta.php
            $.ajax({
                type: "POST",
                url: "invito_risposta.php",
                data: {
                    invitationId: invitationId,
                    response: response
                },
                success: function(data) {
                    // Gestisci la risposta di successo, ad esempio, aggiorna l'interfaccia utente
                    alert(data); // Mostra un messaggio di successo (puoi sostituire questo con la tua gestione personalizzata)
                    location.reload();
                },
                error: function(xhr, status, error) {
                    // Gestisci gli errori qui
                    console.error(error);
                    alert("Errore: " + error);
                    location.reload();
                }
            });
        }
    });
</script>