<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {

    header("Location: login.php");
    exit();
}
include "db/connect.php";

if ($_SESSION['user']['tipologia'] !== 'Amministratore') {
    echo "Access denied. You must be an administrator to access this page.";
    exit();
}


if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {

        $adminUserId = $_SESSION['user']['idUtente'];
        $newNome = $_POST["new_Nome"];
        $newDescrizione = $_POST["new_Descrizione"];

        $sqlAddDominio = "CALL addDominioAmministrazione(?, ?, ?)";
        $stmtAddDominio = $pdo->prepare($sqlAddDominio);

        $stmtAddDominio->bindParam(1, $adminUserId, PDO::PARAM_INT);
        $stmtAddDominio->bindParam(2, $newNome, PDO::PARAM_STR);
        $stmtAddDominio->bindParam(3, $newDescrizione, PDO::PARAM_STR);

        if ($stmtAddDominio->execute()) {
            echo '<script>
                alert("Dominio aggiunto correttamente");
                setTimeout(function() {
                    window.location.href = "dominio.php";
                }, 3000); 
            </script>';
            exit();
        } else {
            echo "Error: " . $stmtAddDominio->errorInfo()[2];
        }

        $stmtAddDominio->closeCursor();
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Crea nuovo dominio</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
</head>
<body>

<?php include 'includes/header.php'; ?>

<div class="container">
    <h2>Crea nuovo dominio</h2>
    <form action="dominio_add.php" method="POST">
        <div class="form-group">
            <label for="new_Nome">Nome:</label>
            <input type="text" class="form-control" id="new_Nome" name="new_Nome" required>
        </div>
        <div class="form-group">
            <label for="new_Descrizione">Descrizione:</label>
            <textarea class="form-control" id="new_Descrizione" name="new_Descrizione" rows="4" required></textarea>
        </div>
        <button type="submit" class="btn btn-primary">Crea Dominio</button>
    </form>
</div>
</body>
</html>
<style>

    body {
        background-color: #f0f0f0;
    }

    .container {
        max-width: 400px;
        margin: 50px auto;
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
        background-color: #222;
        border-color: #222;
        width: 100%;
        padding: 10px;
    }

    .btn-primary:hover {
        background-color: #357ae8;
        border-color: #357ae8;
    }
</style>
