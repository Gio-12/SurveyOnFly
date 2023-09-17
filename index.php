<!DOCTYPE html>
<html lang="it" dir="ltr">
<head>
    <title>SurveyToGo</title>
    <meta charset="utf-8" name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto|Varela+Round|Open+Sans">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
    <style>
        body {
            background-color: #222;
            color: #fff;
        }

        .navbar {
            background-color: #333;
        }

        #intro {
            height: 100vh;
            /*background-image: url('your-background-image.jpg'); !* Replace with your background image URL *!*/
            background-size: cover;
            background-position: center;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .display-3 {
            font-size: 3rem;
            font-weight: bold;
        }

        .hr-light {
            border-top: 2px solid #fff; /* White horizontal rule */
            width: 50px;
            margin: 20px auto;
        }
    </style>
</head>
<body>
<header>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ml-auto">
                <li class="nav-item">
                    <a class="nav-link" href="login.php">LOGIN</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="registrazione.php">REGISTRATI</a>
                </li>
            </ul>
        </div>
    </nav>
</header>
<div id="intro" class="view hm-black-strong">
    <div class="container-fluid full-bg-img d-flex align-items-center justify-content-center">
        <div class="row d-flex justify-content-center">
            <div class="col-md-12 text-center">
                <h2 class="display-3 font-bold text-center mb-2">Benvenuto su SurveyOnFly</h2>
                <hr class="hr-light">
                <h4 class="text-center">Piattaforma per fare Sondaggi</h4>
            </div>
        </div>
    </div>
</div>
</body>
</html>
