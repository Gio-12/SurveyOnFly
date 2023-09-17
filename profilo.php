<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit();
}
include "db/connect.php";

function getUtenteInfo($userId) {
    global $pdo;
    try {
        $sqlGetUtenteInfo = "CALL getInfoUtente(?)";
        $stmtGetUtenteInfo = $pdo->prepare($sqlGetUtenteInfo);
        $stmtGetUtenteInfo->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtGetUtenteInfo->execute();
        $utenteInfo = $stmtGetUtenteInfo->fetch(PDO::FETCH_ASSOC);
        $stmtGetUtenteInfo->closeCursor();
        return $utenteInfo;
    } catch (PDOException $e) {
        echo "Errore: " . $e->getMessage();
    }
    return null;
}

function getAziendaInfo($userId) {
    global $pdo;
    try {
        $sqlGetAziendaInfo = "CALL getInfoAzienda(?)";
        $stmtGetAziendaInfo = $pdo->prepare($sqlGetAziendaInfo);
        $stmtGetAziendaInfo->bindParam(1, $userId, PDO::PARAM_INT);
        $stmtGetAziendaInfo->execute();
        $aziendaInfo = $stmtGetAziendaInfo->fetch(PDO::FETCH_ASSOC);
        $stmtGetAziendaInfo->closeCursor();
        return $aziendaInfo;
    } catch (PDOException $e) {
        echo "Errore: " . $e->getMessage();
    }
    return null;
}

$userId = $_SESSION['user']['idUtente'];
$userType = $_SESSION['user']['tipologiaUtente'];

if ($userType === 'Utente') {
    $userInfo = getUtenteInfo($userId);
} elseif ($userType === 'Azienda') {
    $userInfo = getAziendaInfo($userId);
} else {
    echo "Invalid user type";
    exit();
}
?>
<!DOCTYPE html>
<html lang="it">

<head>
    <title>Gestione Utente</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>

<body>
<?php include 'includes/header.php'; ?>
<div class="container mt-5">
    <h1>Gestione Utente</h1>
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
                <input class="form-control" type="password" id="inputPassword" name="newPassword"
                       value="<?php echo $userInfo['userPassword']; ?>" readonly>
            </div>
        </div>

        <?php if ($userType === 'Utente') { ?>
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
        <?php } ?>

        <!-- Azienda-Specific Fields -->
        <?php if ($userType === 'Azienda') { ?>
            <div class="mb-3 row">
                <label for="inputAziendaNome" class="col-sm-2 col-form-label">Nome Azienda</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputAziendaNome" name="newAziendaNome"
                           value="<?php echo $userInfo['azienda_nome']; ?>" readonly>
                </div>
            </div>
            <div class="mb-3 row">
                <label for="inputAziendaSede" class="col-sm-2 col-form-label">Sede Azienda</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputAziendaSede" name="newAziendaSede"
                           value="<?php echo $userInfo['azienda_sede']; ?>" readonly>
                </div>
            </div>
            <div class="mb-3 row">
                <label for="inputAziendaIndirizzo" class="col-sm-2 col-form-label">Indirizzo Azienda</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputAziendaIndirizzo" name="newAziendaIndirizzo"
                           value="<?php echo $userInfo['azienda_indirizzo']; ?>" readonly>
                </div>
            </div>

        <?php } ?>

        <div class="mb-3 row">
            <label for="inputTipologia" class="col-sm-2 col-form-label">Tipologia</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputTipologia" name="newTipologia"
                       value="<?php echo $userInfo['userTipologia']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputTipoAbbonamento" class="col-sm-2 col-form-label">Tipo Abbonamento</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputTipoAbbonamento" name="newTipoAbbonamento"
                       value="<?php echo $userInfo['userTipoAbbonamento']; ?>" readonly>
            </div>
        </div>
        <div class="mb-3 row">
            <label for="inputCampoTotale" class="col-sm-2 col-form-label">Campo Totale</label>
            <div class="col-sm-10">
                <input class="form-control" type="text" id="inputCampoTotale" name="newCampoTotale"
                       value="<?php echo $userInfo['userCampoTotale']; ?>" readonly>
            </div>
        </div>

        <?php if ($userType === 'Utente' && $userInfo['userTipologia'] === 'Premium') { ?>
            <div class="mb-3 row">
                <label for="inputInizioAbbonamento" class="col-sm-2 col-form-label">Inizio Abbonamento</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputInizioAbbonamento" name="newInizioAbbonamento"
                           value="<?php echo $userInfo['userInizioAbbonamento']; ?>" readonly>
                </div>
            </div>
            <div class="mb-3 row">
                <label for="inputFineAbbonamento" class="col-sm-2 col-form-label">Fine Abbonamento</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputFineAbbonamento" name="newFineAbbonamento"
                           value="<?php echo $userInfo['userFineAbbonamento']; ?>" readonly>
                </div>
            </div>
            <div class="mb-3 row">
                <label for="inputCostoAbbonamento" class="col-sm-2 col-form-label">Costo Abbonamento</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputCostoAbbonamento" name="newCostoAbbonamento"
                           value="<?php echo $userInfo['userCostoAbbonamento']; ?>" readonly>
                </div>
            </div>
            <div class="mb-3 row">
                <label for="inputNumSondaggi" class="col-sm-2 col-form-label">Numero di Sondaggi</label>
                <div class="col-sm-10">
                    <input class="form-control" type="text" id="inputNumSondaggi" name="newNumSondaggi"
                           value="<?php echo $userInfo['userNumSondaggi']; ?>" readonly>
                </div>
            </div>
        <?php } ?>
    </form>
</div>
</body>
</html>
<style>
    body {
        background-color: #F5F7FA;
        color: #fff;
    }

    .container {
        background-color: #fff;
        padding: 20px;
        border-radius: 4px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        max-width: 800px; /* Set a maximum width for the container */
        margin: 0 auto; /* Center the container horizontally */
    }

    h1 {
        color: #222;
        text-align: center;
        padding: 10px;
        border-radius: 4px;
    }

    label {
        color: #777;
    }

    input[type="text"],
    input[type="password"],
    input[type="date"],
    select {
        width: 100%;
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 4px;
        margin-bottom: 10px; /* Add some space between fields */
    }

    /* Style for readonly input fields */
    .form-control[readonly] {
        background-color: #f8f9fa;
        color: #333;
    }
</style>