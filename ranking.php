<?php
global $pdo;
session_start();
include "db/connect.php"; // Include your database connection script
try {
    // Prepare the call to the stored procedure to get the list of all prizes
    $sqlRankingList = "CALL getRanking()";
    $stmtRankingList  = $pdo->prepare($sqlRankingList);

    // Execute the stored procedure to get all prizes
    $stmtRankingList ->execute();

    // Fetch the results of all prizes into an associative array
    $RankingList = $stmtRankingList ->fetchAll(PDO::FETCH_ASSOC);

    $stmtRankingList->closeCursor();

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}

?>

<!DOCTYPE html>
<html lang="it">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Ranking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="list-container">
    <h1 class="text-center">Medals List</h1>
    <ul class="list-group">
        <?php
        // Iterate through the $RankingList
        foreach ($RankingList as $index => $Ranking) {
            $position = $index + 1;
            $medalClass = "";

            // Assign medals to the first, second, and third users
            if ($position == 1) {
                $medalClass = "gold-medal";
            } elseif ($position == 2) {
                $medalClass = "silver-medal";
            } elseif ($position == 3) {
                $medalClass = "bronze-medal";
            }

            // Check if the current user is the logged-in user and add a star
            $star = "";
            if ($_SESSION['user']['idUtente'] == $Ranking['idUtente']) {
                $star = " &#9733;"; // Unicode star character
                // You can customize the star icon or use an image
            }

            echo '<li class="list-group-item list-item ' . ($_SESSION['user']['idUtente'] == $Ranking['idUtente'] ? "user-row" : "") . '">';
            echo '<span class="position ' . $medalClass . '">Position: ' . $position . '</span>';
            echo '<span class="name">' . $Ranking['nome'] . $star . '</span>';
            echo '<span class="campo-totale">CampoTotale: ' . $Ranking['campoTotale'] . '</span>';
            echo '</li>';
        }
        ?>
    </ul>
</div>
<div class="container-flex">
    <div class="table-responsive">
        <div class="table-wrapper">
            <div class="table-title">
                <div class="row">
                    <div class="col-sm-8"><h2><b>Ranking</b></h2></div>
                </div>
            </div>
            <table class="table table-bordered">
                <thead>
                <tr>
                    <th>Nome</th>
                    <th>Punteggio</th>
                    <th></th> <!-- Icon column -->
                </tr>
                </thead>
                <tbody>
                <?php
                // Initialize variables for tracking the top 3 users
                $topUsers = array();

                // Iterate through the $RankingList
                foreach ($RankingList as $index => $Ranking) {
                    // Display the user's name and campoTotale
                    echo '<td>' . $Ranking['nome'] . '</td>';
                    echo '<td>' . $Ranking['campoTotale'] . '</td>';
                    if ($_SESSION['user']['idUtente'] == $Ranking['idUtente']) {
                        echo '<td>' . '<i class="fa fa-star"></i> ' . '</td>';
                    } else {
                        echo '</tr>';
                    }
                }
                ?>
                </tbody>
            </table>
        </div>
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

    /* Add custom styles for the list container */
    .list-container {
        max-width: 800px;
        margin: 0 auto;
    }

    /* Add custom styles for list items */
    .list-item {
        padding: 10px;
        border-bottom: 1px solid #ccc;
        display: flex;
        justify-content: space-between;
    }

    /* Add custom styles for medals */
    .gold-medal {
        color: gold;
    }

    .silver-medal {
        color: silver;
    }

    .bronze-medal {
        color: #cd7f32;
    }

    /* Add custom styles for the user's row */
    .user-row {
        background-color: #f0f0f0;
    }
</style>
