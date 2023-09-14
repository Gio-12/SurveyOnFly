<?php
// Mock data for testing
$premiList = [
    [
        'id' => 1,
        'nome' => 'Prize 1',
        'descrizione' => 'Description of Prize 1',
        'foto' => 'prize1.jpg',
        'numMinimoPunti' => 10
    ],
    [
        'id' => 2,
        'nome' => 'Prize 2',
        'descrizione' => 'Description of Prize 2',
        'foto' => 'prize2.jpg',
        'numMinimoPunti' => 20
    ],
    // Add more mock data as needed
];
?>

<!DOCTYPE html>
<html>
<head>
    <title>List of Premi</title>
</head>
<body>
<h1>List of Premi</h1>
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
</body>
</html>
