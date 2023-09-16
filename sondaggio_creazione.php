<?php
session_start();
//if (!isset($_SESSION['user'])) {
//    // Redirect the user to the login page or any other desired page
//    header("Location: login.php"); // Change "login.php" to the desired page
//    exit(); // Ensure script execution stops here
//}

global $pdo;

include "db/connect.php"; // Include your database connection script

$query = "CALL getListaDominio()";

try {
    $stmt = $pdo->prepare($query);
    $stmt->execute();

    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}


if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $idUtenteCreatore = $_SESSION['user']['idUtente']; // User's ID
    $idDominio = $_POST['dominio']; // Dominio ID from the form
    $titolo = $_POST['titolo']; // Titolo from the form
    $dataChiusura = $_POST['data_chiusura']; // Data Chiusura from the form
    $numMaxPartecipanti = $_POST['max_partecipanti']; // Max Partecipanti from the form

    $sql = "CALL creazioneSondaggio(?, ?, ?, ?, ?, @insertedSondaggioId, @message)";
    $stmt = $pdo->prepare($sql);

    $stmt->bindParam(1, $idUtenteCreatore, PDO::PARAM_INT);
    $stmt->bindParam(2, $idDominio, PDO::PARAM_INT);
    $stmt->bindParam(3, $titolo, PDO::PARAM_STR);
    $stmt->bindParam(4, $dataChiusura, PDO::PARAM_STR);
    $stmt->bindParam(5, $numMaxPartecipanti, PDO::PARAM_INT);

    if ($stmt->execute()) {
        // Optionally fetch the output variables using a separate query
        $outputStmt = $pdo->query("SELECT @insertedSondaggioId, @message");
        $output = $outputStmt->fetch(PDO::FETCH_ASSOC);

        if ($output) {
            $insertedSondaggioId = (int)$output['@insertedSondaggioId']; // Cast to integer
            $message = $output['@message'];

            if ($insertedSondaggioId > 0) {
                echo '<script>alert("Sondaggio created successfully. ID: ' . $insertedSondaggioId . '");                
    setTimeout(function() {
                    window.location.href = "sondaggio.php";
                }, 3000)</script>';

            } else {
                // Handle errors here, e.g., display an error message
                echo '<script>alert("Failed to create sondaggio. Message: ' . $message . '");</script>';
            }
        } else {
            // Handle database error
            echo '<script>alert("Error fetching output variables.");</script>';
        }
        $outputStmt -> closeCursor();
        $stmt -> closeCursor();
    } else {
        // Handle database error
        echo '<script>alert("Error executing stored procedure.");</script>';
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
<?php include 'includes/header.php'; ?>
<div class="container mt-5">
    <h1>Creazione di un Nuovo Sondaggio</h1>
    <form method="POST" id="campiSondaggio">
        <div class="mb-3">
            <label for="titolo" class="form-label">Titolo del Sondaggio</label>
            <input type="text" class="form-control" name="titolo" required>
        </div>

        <div class="mb-3">
            <label for="dominio" class="form-label">Dominio del Sondaggio</label>
            <select class="form-select" name="dominio" required>
                <?php
                // Include your database connection code
                include "db/connect.php";

                // Call the stored procedure to get the list of Domini
                $query = "CALL getListaDominio()";

                try {
                    $stmt = $pdo->prepare($query);
                    $stmt->execute();

                    // Fetch the results as an associative array
                    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

                    // Check if there are any results
                    if (count($results) > 0) {
                        // Loop through the results and create an option for each Dominio
                        foreach ($results as $row) {
                            $dominioId = $row['id']; // Assuming 'id' is the primary key
                            $nomeDominio = $row['nome'];
                            $descrizioneDominio = $row['descrizione'];

                            // Output each Dominio as an option
                            echo '<option value="' . $dominioId . '">' . $nomeDominio . '</option>';
                        }
                    } else {
                        echo '<option value="" disabled>No Domini found</option>';
                    }
                } catch (PDOException $e) {
                    echo '<option value="" disabled>Error: ' . $e->getMessage() . '</option>';
                }
                ?>
            </select>
        </div>

        <div class="mb-3">
            <label for="data_chiusura" class="form-label">Data di Chiusura</label>
            <input type="date" class="form-control" name="data_chiusura" required>
        </div>

        <div class="mb-3">
            <label for="max_partecipanti" class="form-label">Numero Massimo di Partecipanti</label>
            <input type="number" class="form-control" name="max_partecipanti" required>
        </div>
        <button type="submit" class="btn btn-success">Crea Sondaggio</button>
    </form>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>

</html>