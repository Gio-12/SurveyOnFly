<?php
global $pdo;
session_start();
include "db/connect.php"; // Assicurati che questo include sia corretto e includa la connessione al database.

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST["email"];
    $password = $_POST["password"];

    $sql = "CALL loginUtente(?, ?, @utentebase_id, @utentebase_email, @utentebase_tipologiaUtente, @utente_tipologia)";
    $stmt = $pdo->prepare($sql);

    $stmt->bindParam(1, $email, PDO::PARAM_STR);
    $stmt->bindParam(2, $password, PDO::PARAM_STR);

    if ($stmt->execute()) {
        // Optionally fetch the output variables using a separate query
        $outputStmt = $pdo->query("SELECT @utentebase_id, @utentebase_email, @utentebase_tipologiaUtente, @utente_tipologia");
        $output = $outputStmt->fetch(PDO::FETCH_ASSOC);

        if ($output) {
            // Handle the output variables here
            $utentebase_id = (int)$output['@utentebase_id']; // Cast to integer
            $utentebase_email = $output['@utentebase_email'];
            $utentebase_tipologiaUtente = $output['@utentebase_tipologiaUtente'];
            $utente_tipologiaUtenteFisico = $output['@utente_tipologia'];

            // Check if login was successful and handle session storage
            if ($utentebase_id !== null && $utentebase_id !== 0) {
                // Store relevant user information in the session
                $_SESSION['user'] = [
                        'logged' => true,
                    'idUtente' => $utentebase_id,
                    'email' => $utentebase_email,
                    'tipologiaUtente' => $utentebase_tipologiaUtente,
                    'tipologia' => $utente_tipologiaUtenteFisico,
                ];
                echo '<script>
                  alert("Registrazione Completata! \n' .
                    'ID Utente: ' . $_SESSION['user']['idUtente'] . '\n' .
                    'Email: ' . $_SESSION['user']['email'] . '\n' .
                    'Tipologia Utente: ' . $_SESSION['user']['tipologiaUtente'] . '\n' .
                    'Tipologia: ' . $_SESSION['user']['tipologia'] . '");
                setTimeout(function() {
                    window.location.href = "dashboard.php";
                }, 3000); // 3 seconds delay
              </script>';
                exit(); // Make sure to exit after the JavaScript code
            } else {
                $loginError = "Credenziali non valide.";
            }
        } else {
            $loginError = "Errore DATABASE.";
        }
    } else {
        $loginError = "Errore DATABASE.";
    }
}
?>
<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="utf-8">
    <title>LOGIN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-GLhlTQ8iRABdZLl6O3oVMWSktQOp6b7In1Zl3/Jr59b6EGGoI1aFkw7cmDA6j6gD" crossorigin="anonymous">
    <style>
        /* Add custom styles for the login container */
        .login-container {
            max-width: 400px;
            margin: 50px auto;
            padding: 20px;
            border: 1px solid #ccc;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            background-color: #fff;
        }

        /* Add custom styles for the form within the container */
        .login-form {
            text-align: center;
        }
    </style>
</head>

<body>
<div class="login-container">
    <h1 class="text-center">User Login</h1>
    <?php if (isset($loginError)) : ?>
        <div class="alert alert-danger" role="alert">
            <?php echo $loginError; ?>
        </div>
    <?php endif; ?>
    <form action="login.php" method="POST" class="login-form">
        <div class="mb-3">
            <label for="email" class="form-label">Email:</label>
            <input type="email" name="email" class="form-control" required>
        </div>

        <div class="mb-3">
            <label for="password" class="form-label">Password:</label>
            <input type="password" name="password" class="form-control" required>
        </div>

        <div class="mb-3">
            <input type="submit" value="Login" class="btn btn-primary">
        </div>
    </form>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js" integrity="sha384-w76AqPfDkMBDXo30jS1Sgez6pr3x5MlQ1ZAGC+nuZB+EYdgRZgiwxhTBTkF7CXvN" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js" integrity="sha384-oBqDVmMz9ATKxIep9tiCxS/Z9fNfEXiDAYTujMAeBAsjFuCZSmKbSSUnQlmh/jp3" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.min.js" integrity="sha384-mQ93GR66B00ZXjt0YO5KlohRA5SY2XofN4zfuZxLkoj1gXtW8ANNCe9d5Y3eG5eD" crossorigin="anonymous"></script>
</body>
</html>
<style>
    body {
        font-family: Arial, sans-serif;
        background-color: #f2f2f2;
    }

    h1 {
        text-align: center;
        color: #4285f4; /* Google Blue */
    }

    form {
        max-width: 400px;
        margin: 0 auto;
        padding: 20px;
        background-color: #fff;
        border-radius: 5px;
        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
    }

    label {
        display: block;
        margin-bottom: 8px;
        font-weight: bold;
        color: #555;
    }

    input[type="text"],
    input[type="email"],
    input[type="password"],
    input[type="date"],
    select {
        width: 100%;
        padding: 10px;
        margin-bottom: 15px;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-sizing: border-box;
        font-size: 16px;
    }

    select {
        appearance: auto; /* Remove default select arrow on some browsers */
        -webkit-appearance: none;
        -moz-appearance: none;
        background-image: url('data:image/svg+xml;utf8,<svg fill="#000000" height="24" width="24" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64"><path d="M62,11c0-4.8-3.2-9-8-9H10C4.4,2,0,6.4,0,12v40c0,5.6,4.4,10,10,10h44c5.6,0,10-4.4,10-10V11z M11,4h42c3.3,0,6,2.7,6,6v38 c0,3.3-2.7,6-6,6H11c-3.3,0-6-2.7-6-6V10C5,6.7,7.7,4,11,4z M53,54c0,2.2-1.8,4-4,4H11c-2.2,0-4-1.8-4-4V12c0-2.2,1.8-4,4-4h42 c2.2,0,4,1.8,4,4V54z"/><path d="M33.8,46.8c-0.2,0.2-0.5,0.2-0.7,0L27,41.4c-0.2-0.2-0.2-0.5,0-0.7s0.5-0.2,0.7,0l4.3,4.3l4.3-4.3c0.2-0.2,0.5-0.2,0.7,0 s0.2,0.5,0,0.7L36,46.1L40.3,50.4c0.2,0.2,0.2,0.5,0,0.7c-0.2,0.2-0.5,0.2-0.7,0L36,47.9l-4.3,4.3c-0.2,0.2-0.5,0.2-0.7,0 c-0.2-0.2-0.2-0.5,0-0.7L35,46.1L30.7,41.8C30.5,41.6,30.5,41.3,30.7,41c0.2-0.2,0.5-0.2,0.7,0l4.3,4.3l4.3-4.3c0.2-0.2,0.5-0.2,0.7,0 c0.2,0.2,0.2,0.5,0,0.7L38,46.1L42.3,50.4c0.2,0.2,0.2,0.5,0,0.7c-0.2,0.2-0.5,0.2-0.7,0L38,47.9L33.8,46.8z"/></svg>');
        background-repeat: no-repeat;
        background-position: right 8px center;
        background-size: 24px;
    }

    input[type="submit"] {
        background-color: #4285f4; /* Google Blue */
        color: #fff;
        font-size: 18px;
        border: none;
        border-radius: 4px;
        padding: 12px 20px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    input[type="submit"]:hover {
        background-color: #357ae8; /* Hover color */
    }

    /* Adjust the styles of select boxes based on Google's style */
    select::-ms-expand {
        display: none; /* Remove default arrow in IE/Edge */
    }

    /* Media query for small screens */
    @media (max-width: 600px) {
        form {
            width: 80%;
            margin: 0 auto;
        }
    }
</style>
