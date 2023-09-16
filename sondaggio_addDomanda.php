<?php
session_start();
//if (!isset($_SESSION['user'])) {
//    // Redirect the user to the login page or any other desired page
//    header("Location: login.php"); // Change "login.php" to the desired page
//    exit(); // Ensure script execution stops here
//}
//if (isset($_GET['insertedSondaggioId'])) {
//    // Retrieve the 'insertedSondaggioId' from the URL
//    $insertedSondaggioId = $_GET['insertedSondaggioId'];
//
//    // Now, you can use $insertedSondaggioId in your code as needed
//} else {
//    // Handle the case where 'insertedSondaggioId' is not set in the URL
//    echo "No 'insertedSondaggioId' parameter found in the URL.";
//}

global $pdo;
$sondaggio_id = 5;
include "db/connect.php"; // Include your database connection script

$options = array();

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $idUtenteCreatore = $_SESSION['user']['idUtente']; // User's ID
    $testo = $_POST['testo']; // Domanda Text from the form
    $punteggio = $_POST['punteggio']; // Punteggio from the form
    $lunghezzaMax = $_POST['lunghezzaMax']; // Lunghezza Massima from the form
    $tipologia = $_POST['tipologia']; // Tipologia from the form

    // Check if a file was uploaded for "foto"
    if (isset($_FILES['foto']) && !empty($_FILES['foto']['name'])) {
        $foto = file_get_contents($_FILES['foto']['tmp_name']); // Get the file content
    } else {
        $foto = null; // Set to null if no file was uploaded
    }

    // Check if options are provided for "Chiusa" type question
    if ($tipologia === 'Chiusa') {
        // Collect options in the $options array
        for ($i = 1; $i <= 5; $i++) { // Assuming a maximum of 5 options, adjust as needed
            if (isset($_POST['opzione' . $i]) && !empty($_POST['opzione' . $i])) {
                $options[] = $_POST['opzione' . $i];
            }
        }
    }

    // Call your SQL procedure here to add the question to the database
    $sql = "CALL DONEinserimentoDomanda(?, ?, ?, ?, ?, ?, ?, @p_idDomanda)";
    $stmt = $pdo->prepare($sql);

    // Bind parameters
    $stmt->bindParam(1, $idUtenteCreatore, PDO::PARAM_INT);
    $stmt->bindParam(2, $sondaggio_id, PDO::PARAM_INT);
    $stmt->bindParam(3, $testo, PDO::PARAM_STR);
    $stmt->bindParam(4, $foto, PDO::PARAM_LOB);
    $stmt->bindParam(5, $punteggio, PDO::PARAM_INT);
    $stmt->bindParam(6, $lunghezzaMax, PDO::PARAM_INT);
    $stmt->bindParam(7, $tipologia, PDO::PARAM_STR);

    // You may need to set $idUtenteCreatore to the appropriate user ID

    if ($stmt->execute()) {
        // Domanda added successfully, you can display a success message if needed
        $stmt->closeCursor();

        $outputStmt = $pdo->query("SELECT @p_idDomanda");
        $output = $outputStmt->fetch(PDO::FETCH_ASSOC);
        $domandaId = (int)$output['@p_idDomanda'];

        // Check if the question type is "Chiusa" and options are provided
        if ($tipologia === 'Chiusa' && !empty($options)) {
            // Insert the options for the added question

            // Call the procedure to insert options for "Chiusa" type question
            foreach ($options as $option) {
                $sql2 = "CALL DONEinserimentoOpzione(?, ?)";
                $stmt = $pdo->prepare($sql2);
                $stmt->bindParam(1, $domandaId, PDO::PARAM_INT);
                $stmt->bindParam(2, $option, PDO::PARAM_STR);

                if ($stmt->execute()) {
                } else {
                    // Handle error if option insertion fails
                    echo '<script>alert("Error fetching output variables.");</script>';
                }
                $stmt->closeCursor();
            }
        }
        echo '<script>alert("Domanda Inserita");</script>';
    } else {
        // Handle database error, you can display an error message if needed
        echo '<script>alert("Error fetching output variables.");</script>';
    }
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Aggiungi Domanda</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container mt-5">
    <h1>Aggiungi Domanda al sondaggio</h1>

    <!-- Form for adding questions -->
    <form id="addDomandaForm" method="POST" enctype="multipart/form-data">
        <div class="mb-3">
            <label for="testo" class="form-label">Domanda Text</label>
            <input type="text" class="form-control" name="testo" required>
        </div>
        <div class="mb-3">
            <label for="foto" class="form-label">Domanda Photo</label>
            <input type="file" class="form-control" name="foto">
        </div>
        <div class="mb-3">
            <label for="punteggio" class="form-label">Punteggio</label>
            <input type="number" class="form-control" name="punteggio" required>
        </div>
        <div class="mb-3">
            <label for="lunghezzaMax" class="form-label">Lunghezza Massima</label>
            <input type="number" class="form-control" name="lunghezzaMax">
        </div>
        <div class="mb-3">
            <label for="tipologia" class="form-label">Tipologia</label>
            <select class="form-select" name="tipologia" id="tipologia" required>
                <option value="Aperta">Aperta</option>
                <option value="Chiusa">Chiusa</option>
            </select>
        </div>

        <!-- Options for "Chiusa" type question -->
        <div id="optionsContainer">
            <!-- Input fields for options will be added here using JavaScript -->
        </div>

        <button type="submit" class="btn btn-success">Inserisci Domanda</button>
    </form>
</div>

<script>
    // Function to add input fields for options if the question type is "Chiusa"
    function addOptionField() {
        const optionsContainer = document.getElementById('optionsContainer');
        const optionIndex = optionsContainer.children.length + 1;

        const optionField = document.createElement('div');
        optionField.classList.add('mb-3');
        optionField.innerHTML = `
        <label for="opzione${optionIndex}" class="form-label">Opzione ${optionIndex}</label>
        <input type="text" class="form-control" name="opzione${optionIndex}">
    `;

        optionsContainer.appendChild(optionField);
    }

    // Function to remove input fields for options
    function removeOptionField() {
        const optionsContainer = document.getElementById('optionsContainer');
        if (optionsContainer.children.length > 0) {
            optionsContainer.removeChild(optionsContainer.lastChild);
        }
    }

    // Add an event listener to add/remove option fields when the question type changes
    document.getElementById('tipologia').addEventListener('change', function () {
        const tipologia = this.value;
        const optionsContainer = document.getElementById('optionsContainer');

        // Remove existing option fields
        while (optionsContainer.firstChild) {
            optionsContainer.removeChild(optionsContainer.firstChild);
        }

        // Add option fields if the question type is "Chiusa"
        if (tipologia === 'Chiusa') {
            for (let i = 1; i <= 5; i++) { // Maximum 5 options, adjust as needed
                addOptionField();
            }
        }
    });

    // Add an event listener to remove an option field when the user clicks a button (optional)
    document.getElementById('removeOptionBtn').addEventListener('click', function (e) {
        e.preventDefault();
        removeOptionField();
    });
</script>
</body>
</html>