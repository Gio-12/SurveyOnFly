<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
include "db/connect.php"; // Include your database connection script

// DA ATTIVARE ALLA FINE
//if ($_SESSION['user']['tipologia'] !== 'Amministratore') {
//    // Redirect to a restricted access page or display an error message
//    echo "Access denied. You must be an administrator to access this page.";
//    exit();
//}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        // Prepare the call to the stored procedure addPremioAmministrazione
        // Bind parameters using PDO-style binding
        $adminUserId = $_SESSION['user']['idUtente'];
        $newNome = $_POST["new_Nome"];
        $newDescrizione = $_POST["new_Descrizione"];
        $newNumMinimoPunti = $_POST["new_NumMinimoPunti"];
        if (isset($_FILES['new_Foto']) && $_FILES['new_Foto']['size'] > 0) {
            $newFoto = file_get_contents($_FILES['new_Foto']['tmp_name']);
        } else {
            $newFoto = null; // Set it to null if no file was uploaded
        }

        $sqlAddPremio = "CALL addPremioAmministrazione(?, ?, ?, ?, ?)";
        $stmtAddPremio = $pdo->prepare($sqlAddPremio);

        $stmtAddPremio->bindParam(1, $adminUserId, PDO::PARAM_INT);
        $stmtAddPremio->bindParam(2, $newNome, PDO::PARAM_STR);
        $stmtAddPremio->bindParam(3, $newDescrizione, PDO::PARAM_STR);
        $stmtAddPremio->bindParam(4, $newFoto, PDO::PARAM_LOB);
        $stmtAddPremio->bindParam(5, $newNumMinimoPunti, PDO::PARAM_STR);

        if ($stmtAddPremio->execute()) {
            echo '<script>
                alert("Premio added successfully!");
                setTimeout(function() {
                    window.location.href = "premio.php";
                }, 3000); // Redirect to the premio list page
            </script>';
            exit(); // Make sure to exit after the JavaScript code
        } else {
            echo "Error: " . $stmtAddPremio->errorInfo()[2]; // Use errorInfo to get the error message
        }

        $stmtAddPremio->closeCursor(); // Close the cursor to release resources
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Crea nuovo premio</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
</head>
<body>

<?php include 'includes/header.php'; ?>

<div class="container">
    <h2>Crea nuovo premio</h2>
    <form action="premio_add.php" method="POST" enctype="multipart/form-data">
        <div class="form-group">
            <label for="new_Nome">Nome:</label>
            <input type="text" class="form-control" id="new_Nome" name="new_Nome" required>
        </div>
        <div class="form-group">
            <label for="new_Descrizione">Descrizione:</label>
            <textarea class="form-control" id="new_Descrizione" name="new_Descrizione" rows="4" required></textarea>
        </div>
        <div class="form-group">
            <label for="new_Foto">Foto:</label>
            <input type="file" class="form-control-file" id="new_Foto" name="new_Foto" accept="image/*">
        </div>
        <div class="form-group">
            <label for="new_NumMinimoPunti">NumMinimoPunti:</label>
            <input type="number" class="form-control" id="new_NumMinimoPunti" name="new_NumMinimoPunti" required>
        </div>
        <button type="submit" class="btn btn-primary">Crea Premio</button>
    </form>
</div>
</body>
</html>
<style>
    /* Custom CSS for Google-like login form */
    body {
        background-color: #f0f0f0;
    }

    .container {
        max-width: 400px;
        margin: 0 auto;
        padding: 20px;
        background-color: #fff;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        border-radius: 4px;
    }

    h2 {
        text-align: center;
    }

    .form-group {
        margin-bottom: 20px;
    }

    label {
        font-weight: bold;
    }

    .btn-primary {
        background-color: #4285f4;
        border-color: #4285f4;
        width: 100%;
        padding: 10px;
    }

    .btn-primary:hover {
        background-color: #357ae8;
        border-color: #357ae8;
    }
</style>