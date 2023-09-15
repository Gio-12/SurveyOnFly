<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
include "db/connect.php";
?>
<!DOCTYPE html>
<html lang="it">

<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Dashboard</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
</head>

<body>
    <!-- Include the shared navbar -->
    <?php include 'includes/header.php'; ?>
    <!-- Dashboard Content -->
    <div class="dashboard">
        <!-- Include your specific dashboard content here -->
        <!-- For example, content related to the "Profilo" page -->
    </div>
</body>

</html>