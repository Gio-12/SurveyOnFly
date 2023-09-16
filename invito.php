<?php
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
global $pdo;
include "db/connect.php"; // Include your database connection script

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
<div class="container">
    <h2>Inviti ricevuti</h2>
    <table class="table table-bordered">
        <thead>
        <tr>
            <th>Sondaggio</th>
            <th>Mittente</th>
            <th>Actions</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($invitations as $invitation) { ?>
            <tr>
                <td><?php echo $invitation['sondaggio_nome']; ?></td>
                <td><?php echo $invitation['destinatario_email']; ?></td>
                <td>
                    <?php if ($invitation['hasValue'] == 0) { ?>
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
    $(document).ready(function () {
        // Handle click on "Accetta" button
        $(".accept-invitation").click(function () {
            var invitationId = $(this).data("invitation-id");
            respondToInvitation(invitationId, "Accettato");
        });

        // Handle click on "Rifiuta" button
        $(".reject-invitation").click(function () {
            var invitationId = $(this).data("invitation-id");
            respondToInvitation(invitationId, "Rifiutato");
        });

        function respondToInvitation(invitationId, response) {
            // Make an AJAX call to invito_risposta.php
            $.ajax({
                type: "POST",
                url: "invito_risposta.php",
                data: {
                    invitationId: invitationId,
                    response: response
                },
                success: function (data) {
                    // Handle the success response, e.g., update the UI
                    alert(data); // Show a success message (you can replace this with your own handling)
                    location.reload();
                },
                error: function (xhr, status, error) {
                    // Handle errors here
                    console.error(error);
                    alert("Error: " + error);
                    location.reload();
                }
            });
        }
    });
</script>