<!DOCTYPE html>
<html lang="it">

<head>
    <title>Header</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
</head>

<body>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark border-bottom border-body">
    <a class="navbar-brand" href="dashboard.php">Your Logo</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav"
            aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarNav">
        <ul class="navbar-nav">
            <li class="nav-item active">
                <a class="nav-link" href="profilo.php">Profilo</a>
            </li>
            <?php
            if (isset($_SESSION['user']) && $_SESSION['user']['tipologiaUtente'] !== 'Azienda') {
                echo '<li class="nav-item">';
                echo '<a class="nav-link" href="dominio.php">Domini</a>';
                echo '</li>';
                echo '<li class="nav-item">';
                echo '<a class="nav-link" href="invito.php">Inviti</a>';
                echo '</li>';
                echo '<li class="nav-item">';
                echo '<a class="nav-link" href="premio.php">Premi</a>';
                echo '</li>';
                echo '<li class="nav-item">';
                echo '<a class="nav-link" href="ranking.php">Ranking</a>';
                echo '</li>';
            }
            ?>
            <li class="nav-item">
                <a class="nav-link" href="sondaggio.php">Sondaggi</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="statistiche.php">Statistiche</a>
            </li>
        </ul>
    </div>
    <ul class="navbar-nav ml-auto">
        <?php
        if (isset($_SESSION['user'])) {
            echo '<li class="nav-item">';
            echo '<span class="nav-link text-white">Benvenuto ' . $_SESSION['user']['email'] . '</span>';
            echo '</li>';
            echo '<li class="nav-item">';
            echo '<a class="nav-link btn" href="logout.php">Logout</a>';
            echo '</li>';
        }
        ?>
    </ul>
</nav>
</body>

</html>
