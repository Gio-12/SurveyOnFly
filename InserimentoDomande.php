<?php
global $pdo;
session_start();

// Verifica se l'utente è autenticato
/*if (!isset($_SESSION["user"])) {
    header("Location: login.php"); // Reindirizza l'utente alla pagina di login se non è autenticato
    exit();
}

// Simulazione dei dati dell'utente (sostituiscili con i tuoi dati reali)
$user = [
    "tipo" => "premium" // Tipo utente: "premium", "amministratore" o altro
];

// Verifica se l'utente è premium o amministratore
if ($user["tipo"] !== "premium" && $user["tipo"] !== "amministratore") {
    header("Location: dashboard.php"); // Reindirizza gli utenti non autorizzati alla dashboard
    exit();
}*/

// Elabora il modulo di inserimento della domanda
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Esegui la logica per l'inserimento della domanda nel database
    // Sostituisci con la tua logica per l'inserimento della domanda
    $testoDomanda = $_POST["testoDomanda"];
    $tipoDomanda = $_POST["tipoDomanda"];

    // Esegui la procedura di inserimento della domanda nel database
    include "db/connect.php"; // Includi il file di connessione al database
    $sql = "INSERT INTO domande (testo, tipo) VALUES (:testo, :tipo)";
    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(":testo", $testoDomanda, PDO::PARAM_STR);
    $stmt->bindParam(":tipo", $tipoDomanda, PDO::PARAM_STR);

    if ($stmt->execute()) {
        $successMessage = "Domanda inserita con successo!";
    } else {
        $errorMessage = "Errore durante l'inserimento della domanda.";
    }
}

?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="utf-8">
    <title>Inserimento Domanda</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>
<body>
<div class="container mt-5">
    <h1>Inserisci una Nuova Domanda</h1>

    <?php if (isset($successMessage)): ?>
        <div class="alert alert-success" role="alert">
            <?php echo $successMessage; ?>
        </div>
    <?php endif; ?>

    <?php if (isset($errorMessage)): ?>
        <div class="alert alert-danger" role="alert">
            <?php echo $errorMessage; ?>
        </div>
    <?php endif; ?>

    <form method="POST">
        <div class="mb-3">
            <label for="testoDomanda" class="form-label">Testo Domanda</label>
            <textarea class="form-control" id="testoDomanda" name="testoDomanda" rows="3" required></textarea>
        </div>
        <div class="mb-3">
            <label for="tipoDomanda" class="form-label">Tipo Domanda</label>
            <select class="form-select" id="tipoDomanda" name="tipoDomanda" required>
                <option value="aperta">Domanda Aperta</option>
                <option value="chiusa">Domanda Chiusa</option>
            </select>
        </div>

        <!-- Opzioni per domande chiuse -->
        <div class="mb-3" id="opzioniDomandaChiusa" style="display: none;">
            <label for="opzioni" class="form-label">Opzioni (una per riga)</label>
            <textarea class="form-control" id="opzioni" name="opzioni" rows="3"></textarea>
        </div>

        <!-- Risposta per domande aperte -->
        <div class="mb-3" id="rispostaDomandaAperta" style="display: none;">
            <label for="risposta" class="form-label">Risposta (massimo 255 caratteri)</label>
            <input type="text" class="form-control" id="risposta" name="risposta" maxlength="255">
        </div>

        <button type="submit" class="btn btn-primary">Inserisci Domanda</button>
    </form>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
<script>
    // Mostra/nascondi campi in base al tipo di domanda selezionato
    document.getElementById("tipoDomanda").addEventListener("change", function() {
        var tipoDomanda = this.value;
        var opzioniDomandaChiusa = document.getElementById("opzioniDomandaChiusa");
        var rispostaDomandaAperta = document.getElementById("rispostaDomandaAperta");

        if (tipoDomanda === "chiusa") {
            opzioniDomandaChiusa.style.display = "block";
            rispostaDomandaAperta.style.display = "none";
        } else {
            opzioniDomandaChiusa.style.display = "none";
            rispostaDomandaAperta.style.display = "block";
        }
    });
</script>
</body>
</html>
