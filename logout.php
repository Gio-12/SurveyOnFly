<?php
// Start the session
session_start();

// Check if the user is logged in
if (isset($_SESSION['user'])) {
    // Unset all session variables
    session_unset();

    // Destroy the session
    session_destroy();
}

// Redirect the user to a login page or any other desired page
header("Location: login.php"); // Change "login.php" to the desired page
exit();
