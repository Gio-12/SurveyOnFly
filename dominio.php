<?php
global $pdo;
session_start();
if (!isset($_SESSION['user'])) {
    // Redirect the user to the login page or any other desired page
    header("Location: login.php"); // Change "login.php" to the desired page
    exit(); // Ensure script execution stops here
}
include "db/connect.php"; // Include your database connection script
$userDomainsList = [];
try {
    // Prepare the call to the stored procedure to get the list of all domains
    $sqlAllDomains = "CALL getListaDominio()";
    $stmtAllDomains = $pdo->prepare($sqlAllDomains);

    // Execute the stored procedure to get all domains
    $stmtAllDomains->execute();

    // Fetch the results of all domains into an associative array
    $domainsList = $stmtAllDomains->fetchAll(PDO::FETCH_ASSOC);

    $stmtAllDomains->closeCursor();

    $sqlAllUserDomains = "CALL getListaDominioUtente(?)";
    $stmtAllUserDomains = $pdo->prepare($sqlAllUserDomains);

    $userId = $_SESSION['user']['idUtente'];

    $stmtAllUserDomains->bindParam(1, $userId, PDO::PARAM_INT);
    // Execute the stored procedure to get all user domains
    $stmtAllUserDomains->execute();

    // Fetch the results of all user domains into an associative array
    $userDomainsList = $stmtAllUserDomains->fetchAll(PDO::FETCH_ASSOC);

    $stmtAllUserDomains->closeCursor();
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

<?php include 'includes/header.php'; ?>

<div class="container-flex">
    <div class="table-responsive">
        <div class="table-wrapper">
            <div class="table-title">
                <div class="row">
                    <div class="col-sm-8"><h2>Lista <b>Domini</b></h2></div>
                    <div class="col-sm-4">
                        <?php if ($_SESSION['user']['tipologia'] === 'Amministratore') { ?>
                            <a href="dominio_add.php" type="button" class="btn btn-info add-new"><i
                                        class="fa fa-plus"></i> Aggiungi Nuovo Dominio</a>
                        <?php } ?>
                    </div>
                </div>
            </div>
            <table class="table table-bordered">
                <thead>
                <tr>
                    <th>Nome</th>
                    <th>Descrizione</th>
                    <th>Azioni</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($domainsList as $dominio) {
                    $domainId = $dominio['id'];
                    $isUserDomain = false;

                    if ($userDomainsList !== null) {
                        // Check if the domain is in the user's domain list
                        foreach ($userDomainsList as $userDomain) {
                            if ($userDomain['idDominio'] === $domainId) {
                                $isUserDomain = true;
                                break;
                            }
                        }
                    }
                    ?>
                    <tr data-domain-id="<?php echo $domainId; ?>" data-is-user-domain="<?php echo $isUserDomain ? 'true' : 'false'; ?>">
                    <td><?php echo $dominio['nome']; ?></td>
                    <td><?php echo $dominio['descrizione']; ?></td>
                    <td>
                        <?php if ($isUserDomain) { ?>
                            <!-- Show Remove button -->
                            <a href="#" class="action-link remove" title="Remove" data-toggle="tooltip"
                               data-action="remove"><i class="material-icons">&#xE872;</i></a>
                        <?php } else { ?>
                            <!-- Show Add button -->
                            <a href="#" class="action-link add" title="Add" data-toggle="tooltip"
                               data-action="add"><i class="material-icons">&#xE03B;</i></a>
                        <?php } ?>
                    </td>
                    </tr>
                <?php } ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
</body>
</html>
<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>

<script>
    $(document).ready(function () {
        // Handle click on "Add" or "Remove" links
        $(".action-link").click(function (e) {
            e.preventDefault();

            const domainRow = $(this).closest("tr");
            const domainId = domainRow.data("domain-id");
            const isUserDomain = domainRow.data("is-user-domain") === true;

            // Define the PHP script URLs for adding and removing domains
            const addDomainUrl = "dominio_addUtente.php"; // Replace with the actual URL
            const removeDomainUrl = "dominio_remove.php"; // Replace with the actual URL

            if ($(this).hasClass("add")) {
                // User clicked "Add" button
                $.ajax({
                    type: "POST",
                    url: addDomainUrl,
                    data: {
                        domainId: domainId,
                    },
                    success: function (response) {
                        alert(response); // Show success message
                        // Update the DOM or perform other actions as needed
                        location.reload();
                    },
                    error: function (xhr, status, error) {
                        alert("Error: " + error); // Handle the error
                    },
                });
            } else if ($(this).hasClass("remove")) {
                // User clicked "Remove" button
                $.ajax({
                    type: "POST",
                    url: removeDomainUrl,
                    data: {
                        domainId: domainId,
                    },
                    success: function (response) {
                        alert(response); // Show success message
                        // Update the DOM or perform other actions as needed
                        location.reload();
                    },
                    error: function (xhr, status, error) {
                        alert("Error: " + error); // Handle the error
                    },
                });
            }
        });
    });
</script>
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
