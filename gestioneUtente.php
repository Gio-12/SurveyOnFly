<?php
global $pdo;
session_start();
include "db/connect.php"; // Includi lo script di connessione al database

// Funzione per ottenere i dati dell'utente
function getUtenteInfo($userId) {
    global $pdo;
    try {
        $sqlGetUser = "CALL DONEgetInformazioniUtente(?)";
        $stmtGetUser = $pdo->prepare($sqlGetUser);
        $stmtGetUser->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtGetUser->execute();
        $userInfo = $stmtGetUser->fetch(PDO::FETCH_ASSOC);
        $stmtGetUser->closeCursor();
        return $userInfo;
    } catch (PDOException $e) {
        echo "Errore: " . $e->getMessage();
    }
    return null;
}

// Funzione per aggiornare i dati dell'utente
function updateUtenteInfo($userId, $newEmail, $newPassword, $newNome, $newCognome, $newLuogoNascita, $newAnnoNascita) {
    global $pdo;
    try {
        $sqlUpdateUser = "CALL updateUtente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmtUpdateUser = $pdo->prepare($sqlUpdateUser);
        $stmtUpdateUser->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtUpdateUser->bindParam(2, $newEmail, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(3, $newPassword, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(4, $newNome, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(5, $newCognome, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(6, $newLuogoNascita, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(7, $newAnnoNascita, PDO::PARAM_STR);
        $stmtUpdateUser->bindParam(8, $message, PDO::PARAM_STR | PDO::PARAM_INPUT_OUTPUT, 1000);
        $stmtUpdateUser->bindParam(9, $errorCode, PDO::PARAM_INT | PDO::PARAM_INPUT_OUTPUT);
        $stmtUpdateUser->bindParam(10, $errorDescription, PDO::PARAM_STR | PDO::PARAM_INPUT_OUTPUT, 1000);

        $stmtUpdateUser->execute();

        $stmtUpdateUser->closeCursor();

        $errorCode = $stmtUpdateUser->errorCode();
        $errorDescription = $stmtUpdateUser->errorInfo();

        if ($errorCode === '00000') {
            return true; // Successo
        } else {
            return false; // Errore
        }

    } catch (PDOException $e) {
        echo "Errore: " . $e->getMessage();
    }
    return false;
}

$userId = $_SESSION['user']['idUtente'];
$userInfo = getUtenteInfo($userId);

// Verifica se il form è stato inviato per l'aggiornamento dei dati
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $newEmail = $_POST["newEmail"];
    $newPassword = $_POST["newPassword"];
    $newNome = $_POST["newNome"];
    $newCognome = $_POST["newCognome"];
    $newLuogoNascita = $_POST["newLuogoNascita"];
    $newAnnoNascita = $_POST["newAnnoNascita"];

    if (updateUtenteInfo($userId, $newEmail, $newPassword, $newNome, $newCognome, $newLuogoNascita, $newAnnoNascita)) {
        echo "Dati aggiornati con successo!";
        // Aggiorna la visualizzazione dei dati utente
        $userInfo = getUtenteInfo($userId);
    } else {
        echo "Errore nell'aggiornamento dei dati. Consulta il log degli errori.";
    }
}

// Chiudi la connessione al database
$pdo = null;
?>

<!DOCTYPE html>
<html>

<head>
    <title>Gestione Utente</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>

<body>
<div class="container mt-5">
    <h1 style="color: #4285f4;">Gestione Utente</h1>
    <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
        <div class="mb-3 row">
            <label for="inputEmail" class="col-sm-2 col-form-label">Email</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputEmail" name="newEmail"
                       value="<?php echo $userInfo['userEmail']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputPassword" class="col-sm-2 col-form-label">Password</label>
            <div class="col-sm-10">
                <input class="form-control" type="password" id="inputPassword" name="newPassword" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputNome" class="col-sm-2 col-form-label">Nome</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputNome" name="newNome"
                       value="<?php echo $userInfo['userNome']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputCognome" class="col-sm-2 col-form-label">Cognome</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputCognome" name="newCognome"
                       value="<?php echo $userInfo['userCognome']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputLuogoNascita" class="col-sm-2 col-form-label">Luogo di Nascita</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputLuogoNascita" name="newLuogoNascita"
                       value="<?php echo $userInfo['userLuogoNascita']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputAnnoNascita" class="col-sm-2 col-form-label">Anno di Nascita</label>
            <div class="col-sm-10">
                <input class="form-control" type="date" id="inputAnnoNascita" name="newAnnoNascita"
                       value="<?php echo $userInfo['userAnnoNascita']; ?>" readonly>
            </div>
        </div>
        <?php if (!isset($_POST['modifica'])) { ?>
            <button type="submit" name="modifica" class="btn btn-primary">Modifica</button>
        <?php } else { ?>
            <button type="submit" name="aggiorna" class="btn btn-success">Aggiorna</button>
        <?php } ?>
    </form>
</div>
</body>

</html>
