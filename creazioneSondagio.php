<?php
global $pdo;
session_start();

// Includi il file di connessione al database
include "db/connect.php";

// Variabili per i messaggi di successo o errore
$successMessage = $errorMessage = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Ottieni i dati dal modulo
    $titoloSondaggio = $_POST["titolo"];
    $dominioSondaggio = $_POST["dominio"];
    $dataCreazione = date("Y-m-d H:i:s"); // Data e ora correnti
    $dataChiusura = $_POST["data_chiusura"];

    // Esegui la procedura di creazione del sondaggio nel database
    $sql = "INSERT INTO sondaggi (titolo, dominio, data_creazione, data_chiusura) VALUES (:titolo, :dominio, :data_creazione, :data_chiusura)";
    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(":titolo", $titoloSondaggio, PDO::PARAM_STR);
    $stmt->bindParam(":dominio", $dominioSondaggio, PDO::PARAM_STR);
    $stmt->bindParam(":data_creazione", $dataCreazione, PDO::PARAM_STR);
    $stmt->bindParam(":data_chiusura", $dataChiusura, PDO::PARAM_STR);

    if ($stmt->execute()) {
        $successMessage = "Sondaggio creato con successo!";
    } else {
        $errorMessage = "Errore durante la creazione del sondaggio.";
    }

    // Aggiungi le domande al sondaggio
    $sondaggioId = $pdo->lastInsertId(); // Ottieni l'ID del sondaggio appena creato

    if (isset($_POST["domande"])) {
        foreach ($_POST["domande"] as $index => $domanda) {
            // Verifica il tipo di domanda (aperta o chiusa)
            $tipoDomanda = $_POST["tipo_domanda"][$index];

            $sqlDomanda = "INSERT INTO domande (testo, sondaggio_id, tipo_domanda) VALUES (:testo, :sondaggio_id, :tipo_domanda)";
            $stmtDomanda = $pdo->prepare($sqlDomanda);
            $stmtDomanda->bindParam(":testo", $domanda, PDO::PARAM_STR);
            $stmtDomanda->bindParam(":sondaggio_id", $sondaggioId, PDO::PARAM_INT);
            $stmtDomanda->bindParam(":tipo_domanda", $tipoDomanda, PDO::PARAM_STR);

            $stmtDomanda->execute();
        }
    }
}
?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="utf-8">
    <title>Creazione Sondaggio</title>
    <!-- Includi le librerie Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>
<body>
<div class="container mt-5">
    <h1>Creazione di un Nuovo Sondaggio</h1>

    <?php if (!empty($successMessage)): ?>
        <div class="alert alert-success" role="alert">
            <?php echo $successMessage; ?>
        </div>
    <?php endif; ?>

    <?php if (!empty($errorMessage)): ?>
        <div class="alert alert-danger" role="alert">
            <?php echo $errorMessage; ?>
        </div>
    <?php endif; ?>

    <form method="POST">
        <div class="mb-3">
            <label for="titolo" class="form-label">Titolo del Sondaggio</label>
            <input type="text" class="form-control" name="titolo" required>
        </div>

        <div class="mb-3">
            <label for="dominio" class="form-label">Dominio del Sondaggio</label>
            <input type="text" class="form-control" name="dominio" required>
        </div>

        <div class="mb-3">
            <label for="data_chiusura" class="form-label">Data di Chiusura</label>
            <input type="datetime-local" class="form-control" name="data_chiusura" required>
        </div>

        <!-- Aggiungi un campo per le domande -->
        <div class="mb-3" id="domandeContainer">
            <label class="form-label">Domande del Sondaggio</label>
            <div class="input-group mb-3">
                <input type="text" class="form-control" name="domande[]" required>
                <select class="form-select" name="tipo_domanda[]" required>
                    <option value="aperta">Domanda Aperta</option>
                    <option value="chiusa">Domanda Chiusa</option>
                </select>
                <button class="btn btn-outline-secondary" type="button" onclick="aggiungiDomanda()">Aggiungi Domanda</button>
            </div>
        </div>

        <button type="submit" class="btn btn-primary">Crea Sondaggio</button>
    </form>
</div>

<script>
    // Funzione per aggiungere un campo per le domande
    function aggiungiDomanda() {
        const domandeContainer = document.getElementById('domandeContainer');
        const inputGroup = document.createElement('div');
        inputGroup.className = 'input-group mb-3';

        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'form-control';
        input.name = 'domande[]';
        input.required = true;

        const select = document.createElement('select');
        select.className = 'form-select';
        select.name = 'tipo_domanda[]';
        select.required = true;
        const option1 = document.createElement('option');
        option1.value = 'aperta';
        option1.textContent = 'Domanda Aperta';
        const option2 = document.createElement('option');
        option2.value = 'chiusa';
        option2.textContent = 'Domanda Chiusa';
        select.appendChild(option1);
        select.appendChild(option2);

        const button = document.createElement('button');
        button.className = 'btn btn-outline-secondary';
        button.type = 'button';
        button.textContent = 'Rimuovi Domanda';
        button.addEventListener('click', () => rimuoviDomanda(inputGroup));

        inputGroup.appendChild(input);
        inputGroup.appendChild(select);
        inputGroup.appendChild(button);
        domandeContainer.appendChild(inputGroup);
    }

    // Funzione per rimuovere un campo per le domande
    function rimuoviDomanda(inputGroup) {
        const domandeContainer = document.getElementById('domandeContainer');
        domandeContainer.removeChild(inputGroup);
    }

    // Inizializza la pagina con un campo per le domande
    window.onload = function () {
        aggiungiDomanda();
    };
</script>

<!-- Includi le librerie Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>
</html>
