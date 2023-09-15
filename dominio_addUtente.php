<?php
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
global $pdo;
// Include your database connection script
include "db/connect.php";

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["domainId"])) {
    $domainId = $_POST["domainId"];

    // Assuming you have the selected user's ID in a session variable
    $selected_IdUtente = $_SESSION['user']['idUtente'];

    try {
        // Prepare the call to the stored procedure
        $stmt = $pdo->prepare("CALL addDominioUtente(?, ?)");
        $stmt->bindParam(1, $selected_IdUtente, PDO::PARAM_INT);
        $stmt->bindParam(2, $domainId, PDO::PARAM_INT);

        // Execute the stored procedure
        $stmt->execute();

        // Fetch the result message from the stored procedure
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        // Close the cursor
        $stmt->closeCursor();

        echo $result['Message']; // Send the result message back to the client

    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
} else {
    echo "Invalid request";
}
