<!DOCTYPE html>
<html lang="it">

<head>
    <meta charset="utf-8">
    <title>Creazione Sondaggio</title>
    <!-- Includi le librerie Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>
    <div class="container mt-5">
        <h1>Creazione di un Nuovo Sondaggio</h1>

        <button type="button" class="btn btn-primary" id="espandiCampiBtn">Crea Nuovo Sondaggio</button>

        <form method="POST" id="campiSondaggio" style="display: none;">
            <div class="mb-3">
                <label for="titolo" class="form-label">Titolo del Sondaggio</label>
                <input type="text" class="form-control" name="titolo" required>
            </div>

            <div class="mb-3">
                <label for="dominio" class="form-label">Dominio del Sondaggio</label>
                <input type="text" class="form-control" name="dominio" required>
            </div>

            <div class="mb-3">
                <label for="data_chiusura" class="form-label">Data di Chiusura</label>
                <input type="datetime-local" class="form-control" name="data_chiusura" required>
            </div>

            <div class="mb-3">
                <label for="max_partecipanti" class="form-label">Numero Massimo di Partecipanti</label>
                <input type="number" class="form-control" name="max_partecipanti" required>
            </div>
            <button type="submit" class="btn btn-success">Crea Sondaggio</button>
        </form>

        <!-- Lista dei sondaggi creati -->
        <div class="mt-5">
            <h2>I tuoi sondaggi</h2>
            <div id="accordion">
                <!-- Esempio di un pannello per un sondaggio -->
                <div class="card">
                    <div class="card-header" id="heading1">
                        <h5 class="mb-0">
                            <button class="btn btn-link" data-toggle="collapse" data-target="#collapse1" aria-expanded="true" aria-controls="collapse1">
                                Titolo del Sondaggio 1
                            </button>
                        </h5>
                    </div>

                    <div id="collapse1" class="collapse show" aria-labelledby="heading1" data-parent="#accordion">
                        <div class="card-body">
                            <!-- Lista delle domande del sondaggio -->
                            <ul id="domandeSondaggio1">
                                <li>Domanda 1</li>
                                <li>Domanda 2</li>
                                <!-- Aggiungi altre domande qui -->
                            </ul>
                            <div class="mb-3">
                                <label for="tipo_domanda" class="form-label">Tipo di Domanda</label>
                                <select class="form-select" id="tipo_domanda">
                                    <option value="aperta">Domanda Aperta</option>
                                    <option value="chiusa">Domanda Chiusa</option>
                                </select>
                            </div>

                            <!-- Campo per la domanda aperta -->
                            <div class="mb-3" id="campo_domanda_aperta">
                                <label for="domanda_aperta" class="form-label">Domanda Aperta</label>
                                <input type="text" class="form-control" name="domanda_aperta">
                            </div>

                            <!-- Campo per la domanda chiusa -->
                            <div class="mb-3" id="campo_domanda_chiusa" style="display: none;">
                                <label for="domanda_chiusa" class="form-label">Domanda Chiusa</label>
                                <input type="text" class="form-control" name="domanda_chiusa">
                                <button type="button" class="btn btn-secondary mt-2" id="aggiungi_opzione">Aggiungi Opzione</button>
                            </div>

                            <!-- Container per le opzioni -->
                            <div id="container_opzioni" style="display: none;">
                                <!-- Opzioni saranno aggiunte qui -->
                            </div>
                        </div>
                    </div>
                </div>
                <!-- Fine esempio -->

                <!-- Aggiungi altri pannelli per i tuoi sondaggi creati -->
            </div>
        </div>
    </div>

    <script>
        // Funzione per mostrare/nascondere i campi per la creazione di un nuovo sondaggio
        function toggleCampiSondaggio() {
            const campiSondaggio = document.getElementById('campiSondaggio');
            const espandiCampiBtn = document.getElementById('espandiCampiBtn');

            if (campiSondaggio.style.display === 'none') {
                campiSondaggio.style.display = 'block';
                espandiCampiBtn.textContent = 'Nascondi Campi';
            } else {
                campiSondaggio.style.display = 'none';
                espandiCampiBtn.textContent = 'Crea Nuovo Sondaggio';
            }
        }

        // Gestisci il click sul pulsante "Crea Nuovo Sondaggio"
        const espandiCampiBtn = document.getElementById('espandiCampiBtn');
        espandiCampiBtn.addEventListener('click', toggleCampiSondaggio);

        // Funzione per aggiungere una domanda a un sondaggio esistente
        function aggiungiDomandaSondaggio(sondaggioId) {
            const domandeContainer = document.getElementById(`domandeSondaggio${sondaggioId}`);

            // Creazione di un elemento per la nuova domanda
            const nuovaDomanda = document.createElement('li');
            nuovaDomanda.textContent = 'Nuova Domanda';
            domandeContainer.appendChild(nuovaDomanda);
        }

        // Aggiungi un evento di click per il pulsante "Aggiungi Domanda" di ogni sondaggio
        function aggiungiDomandaButtonEventListener(sondaggioId) {
            const aggiungiDomandaButton = document.getElementById(`aggiungiDomandaBtn${sondaggioId}`);
            aggiungiDomandaButton.addEventListener('click', () => aggiungiDomandaSondaggio(sondaggioId));
        }

        // Funzione per gestire la visibilità dei campi in base alla selezione del tipo di domanda
        function gestisciTipoDomanda() {
            const tipoDomanda = document.getElementById('tipo_domanda').value;
            const campoDomandaAperta = document.getElementById('campo_domanda_aperta');
            const campoDomandaChiusa = document.getElementById('campo_domanda_chiusa');
            const containerOpzioni = document.getElementById('container_opzioni');
            const aggiungiOpzioneButton = document.getElementById('aggiungi_opzione');

            if (tipoDomanda === 'aperta') {
                campoDomandaAperta.style.display = 'block';
                campoDomandaChiusa.style.display = 'none';
                containerOpzioni.style.display = 'none';
            } else if (tipoDomanda === 'chiusa') {
                campoDomandaAperta.style.display = 'none';
                campoDomandaChiusa.style.display = 'block';
                containerOpzioni.style.display = 'block';
            }
        }

        // Funzione per aggiungere un campo per le opzioni
        function aggiungiOpzione() {
            const containerOpzioni = document.getElementById('container_opzioni');
            const nuovaOpzione = document.createElement('div');
            nuovaOpzione.className = 'mb-3';

            const inputOpzione = document.createElement('input');
            inputOpzione.type = 'text';
            inputOpzione.className = 'form-control';
            inputOpzione.name = 'opzioni_domanda[]';
            inputOpzione.placeholder = 'Opzione';
            nuovaOpzione.appendChild(inputOpzione);

            containerOpzioni.appendChild(nuovaOpzione);
        }

        // Aggiungi evento di cambio per il tipo di domanda
        document.getElementById('tipo_domanda').addEventListener('change', gestisciTipoDomanda);

        // Aggiungi evento per l'aggiunta delle opzioni (solo per domanda chiusa)
        document.getElementById('aggiungi_opzione').addEventListener('click', aggiungiOpzione);

        // Inizializza la pagina
        gestisciTipoDomanda();

        // Inizializza la pagina con il pannello delle domande nascosto
        window.onload = function() {
            const campiSondaggio = document.getElementById('campiSondaggio');
            campiSondaggio.style.display = 'none';
            aggiungiDomandaButtonEventListener(1); // Aggiungi il gestore dell'evento al primo sondaggio
        };
    </script>

    <!-- Includi le librerie Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
</body>

</html>