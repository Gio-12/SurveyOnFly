<?php
global $pdo;
session_start();
include "db/connect.php"; // Include your database connection script

try {
    // Prepare the call to the stored procedure to get the list of all prizes
    $sqlAllPrizes = "CALL DONEgetListPremio()";
    $stmtAllPrizes = $pdo->prepare($sqlAllPrizes);

    // Execute the stored procedure to get all prizes
    $stmtAllPrizes->execute();

    // Fetch the results of all prizes into an associative array
    $premiList = $stmtAllPrizes->fetchAll(PDO::FETCH_ASSOC);

    $stmtAllPrizes->closeCursor();

    // Prepare the call to the stored procedure to get prizes of the logged-in user
    $sqlUserPrizes = "CALL 	getListUtentePremi(?)";
    $stmtUserPrizes = $pdo->prepare($sqlUserPrizes);

    // Bind the user's ID as input
    $userId = $_SESSION['user']['idUtente'];
    $stmtUserPrizes->bindParam(1, $userId, PDO::PARAM_INT);

    // Execute the stored procedure to get user-specific prizes
    $stmtUserPrizes->execute();

    // Fetch the results of user-specific prizes into an associative array
    $userPrizes = $stmtUserPrizes->fetchAll(PDO::FETCH_ASSOC);

    $stmtUserPrizes->closeCursor();

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}

// Close the database connection
$pdo = null;
?>

<!DOCTYPE html>
<html>
<head>
    <title>List of Premi</title>
</head>
<body>
<h1>List of Premi</h1>

<!-- Table for displaying all prizes -->
<h2>All Prizes</h2>
<table border="1">
    <tr>
        <th>ID</th>
        <th>Nome</th>
        <th>Descrizione</th>
        <th>Foto</th>
        <th>NumMinimoPunti</th>
    </tr>
    <?php foreach ($premiList as $premio) { ?>
        <tr>
            <td><?php echo $premio['id']; ?></td>
            <td><?php echo $premio['nome']; ?></td>
            <td><?php echo $premio['descrizione']; ?></td>
            <td><?php echo $premio['foto']; ?></td>
            <td><?php echo $premio['numMinimoPunti']; ?></td>
        </tr>
    <?php } ?>
</table>

<!-- Table for displaying user-specific prizes -->
<h2>User's Prizes</h2>
<table border="1">
    <tr>
        <th>ID</th>
        <th>Nome</th>
        <th>Descrizione</th>
        <th>Foto</th>
        <th>NumMinimoPunti</th>
    </tr>
    <?php foreach ($userPrizes as $prize) { ?>
        <tr>
            <td><?php echo $prize['id']; ?></td>
            <td><?php echo $prize['nome']; ?></td>
            <td><?php echo $prize['descrizione']; ?></td>
            <td><?php echo $prize['foto']; ?></td>
            <td><?php echo $prize['numMinimoPunti']; ?></td>
        </tr>
    <?php } ?>
</table>
</body>
</html>