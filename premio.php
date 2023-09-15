<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
include "db/connect.php"; // Include your database connection script
try {
    // Prepare the call to the stored procedure to get the list of all prizes
    $sqlAllPrizes = "CALL getListaPremio()";
    $stmtAllPrizes = $pdo->prepare($sqlAllPrizes);

    // Execute the stored procedure to get all prizes
    $stmtAllPrizes->execute();

    // Fetch the results of all prizes into an associative array
    $premiList = $stmtAllPrizes->fetchAll(PDO::FETCH_ASSOC);

    $stmtAllPrizes->closeCursor();

    // Prepare the call to the stored procedure to get prizes of the logged-in user
    $sqlUserPrizes = "CALL 	getListaPremioUtente(?)";
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

?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>List of Premi</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container-flex">
    <div class="table-responsive">
        <div class="table-wrapper">
            <div class="table-title">
                <div class="row">
                    <div class="col-sm-8"><h2>Lista <b>Premi</b></h2></div>
                    <div class="col-sm-4">
<!--                        --><?php //if ($_SESSION['user']['tipologia'] === 'Amministratore') { ?>
                            <a href="premio_add.php" type="button" class="btn btn-info add-new"><i class="fa fa-plus"></i> Aggiungi Nuovo Premio</a>
<!--                        --><?php //} else {
//                            echo '<td></td>';
//                        }?>
                    </div>
                </div>
            </div>
            <table class="table table-bordered">
                <thead>
                <tr>
                    <th>Nome</th>
                    <th>Descrizione</th>
                    <th>Foto</th>
                    <th>NumMinimoPunti</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($premiList as $premio) { ?>
                    <tr>
                        <td><?php echo $premio['nome']; ?></td>
                        <td><?php echo $premio['descrizione']; ?></td>
                        <td><?php echo $premio['foto']; ?></td>
                        <td><?php echo $premio['numMinimoPunti']; ?></td>
                    </tr>
                <?php } ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<div class="container">
    <h2>User's Prizes Carousel</h2>
    <div id="userPrizesCarousel" class="carousel slide" data-ride="carousel">
        <!-- Slides -->
        <div class="carousel-inner">
            <?php foreach ($userPrizes as $index => $prize) { ?>
                <div class="carousel-item<?php echo ($index === 0) ? ' active' : ''; ?>">
<!--                    <img src="--><?php //echo $prize['foto']; ?><!--" alt="Prize Image">-->
                    <h1><?php echo $prize['nome']; ?></h1>
<!--                    <div class="carousel-caption">-->
<!--                        <h3>--><?php //echo $prize['nome']; ?><!--</h3>-->
<!--                    </div>-->
                </div>
            <?php } ?>
        </div>

        <!-- Controls -->
        <a class="carousel-control-prev" href="#userPrizesCarousel" role="button" data-slide="prev">
            <span class="carousel-control-prev-icon" aria-hidden="true"></span>
            <span class="sr-only">Previous</span>
        </a>
        <a class="carousel-control-next" href="#userPrizesCarousel" role="button" data-slide="next">
            <span class="carousel-control-next-icon" aria-hidden="true"></span>
            <span class="sr-only">Next</span>
        </a>
    </div>
</div>
</body>
</html>
<style>
    body {
        text-align: center;
        color: #404E67;
        background: #F5F7FA;
        font-family: 'Open Sans', sans-serif;
    }

    .table-wrapper {
        width: 100%;
        margin: 30px auto;
        background: #fff;
        padding: 20px;
        box-shadow: 0 1px 1px rgba(0, 0, 0, .05);
    }

    .table-title {
        padding-bottom: 10px;
        margin: 0 0 10px;
    }

    .table-title h2 {
        margin: 6px 0 0;
        font-size: 22px;
    }

    .table-title .add-new {
        float: right;
        height: 30px;
        font-weight: bold;
        font-size: 12px;
        text-shadow: none;
        min-width: 100px;
        border-radius: 50px;
        line-height: 13px;
    }

    .table-title .add-new i {
        margin-right: 4px;
    }

    table.table {
        table-layout: fixed;
    }

    table.table tr th, table.table tr td {
        border-color: #e9e9e9;
    }

    table.table th i {
        font-size: 13px;
        margin: 0 5px;
        cursor: pointer;
    }

    table.table th:last-child {
        width: 100px;
    }

    table.table td a {
        cursor: pointer;
        display: inline-block;
        margin: 0 5px;
        min-width: 24px;
    }

    table.table td a.edit {
        color: #FFC107;
    }

    table.table td a.delete {
        color: #E34724;
    }

    table.table td i {
        font-size: 19px;
    }


    table.table .form-control {
        height: 32px;
        line-height: 32px;
        box-shadow: none;
        border-radius: 2px;
    }

    table.table .form-control.error {
        border-color: #f50000;
    }
</style>
