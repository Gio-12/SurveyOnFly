-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Creato il: Set 17, 2023 alle 15:51
-- Versione del server: 10.4.27-MariaDB
-- Versione PHP: 8.1.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `databaseprogetto2`
--

DELIMITER $$
--
-- Procedure
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addDominioAmministratore` (IN `admin_UserId` INT, IN `new_Nome` VARCHAR(100), IN `new_Descrizione` VARCHAR(200))   BEGIN
 DECLARE userRole ENUM('Semplice', 'Premium', 'Amministratore');

    SELECT tipologia INTO userRole FROM utentebase WHERE id = admin_UserId;
    
    IF userRole = 'Amministratore' THEN
    
        IF NOT EXISTS (SELECT 1 FROM dominio WHERE nome = new_Nome) THEN
        
            INSERT INTO dominio (nome, descrizione) VALUES (new_Nome, new_Descrizione);
            SELECT 'Dominio inserito correttamente' AS Message;
        ELSE
            SELECT 'E già presente un dominio con lo stesso nome' AS Message;
        END IF;
    ELSE
        SELECT 'Utente non è un Amministratore' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addDominioUtente` (IN `selected_IdUtente` INT, IN `selected_IdDominio` INT)   BEGIN
    DECLARE userType ENUM('Utente', 'Azienda');
    DECLARE dominioExists INT;
    
    -- Controlla se l'utente esiste e non è un'azienda
    SELECT 
        tipologiaUtente
    INTO 
        userType
    FROM 
        utentebase
    WHERE 
        id = selected_IdUtente;

    IF userType = 'Utente' THEN
    
        SELECT COUNT(*) INTO dominioExists FROM utentexdominio WHERE idUtente = selected_IdUtente AND idDominio = selected_IdDominio;

        IF dominioExists = 0 THEN
    
            INSERT INTO utentexdominio (idUtente, idDominio) VALUES (selected_IdUtente, selected_IdDominio);
            SELECT 'Dominio aggiunto correttamente' AS Message;
        ELSE
            SELECT 'Domio già presente nelle preferenze' AS Message;
        END IF;
    ELSE
        SELECT 'User non ha i permessi per accedere a questa sezione' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addPremioAmministrazione` (IN `admin_UserId` INT, IN `new_Nome` VARCHAR(100), IN `new_Descrizione` VARCHAR(200), IN `new_Foto` BLOB, IN `new_NumMinimoPunti` DOUBLE)   BEGIN
    DECLARE userRole ENUM('Amministratore');
    
    SELECT tipologia INTO userRole FROM utentebase WHERE id = admin_UserId;
    
    IF userRole = 'Amministratore' THEN

        INSERT INTO premio (idCreatore, nome, foto, descrizione, numMinimoPunti)
        VALUES (admin_UserId, new_Nome, new_Foto, new_Descrizione, new_NumMinimoPunti);
        SELECT 'Premio inserito correttamente' AS Message;
    ELSE
    
        SELECT 'Utente non è un amministratore' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `attivaSondaggio` (IN `p_sondaggioId` INT, IN `p_userId` INT)   BEGIN
    DECLARE v_idUtenteCreatore INT;
    DECLARE v_statoEnum ENUM('Aperto', 'Creazione', 'Chiuso');

    -- Ottieni l'idUtenteCreatore e lo stato attuale del sondaggio
    SELECT idUtenteCreatore, stato
    INTO v_idUtenteCreatore, v_statoEnum
    FROM sondaggio
    WHERE id = p_sondaggioId;

    -- Controlla se userId fornito corrisponde a idUtenteCreatore
    IF v_idUtenteCreatore = p_userId THEN
        -- Controlla se lo stato attuale è 'Creazione'
        IF v_statoEnum = 'Creazione' THEN
            -- Aggiorna lo stato a 'Aperto''
            UPDATE sondaggio
            SET stato = 'Aperto'
            WHERE id = p_sondaggioId;
            
            -- Restituisce un messaggio di successo
            SELECT 'Sondaggio stato aggiornato ad Aperto' AS Message;
        ELSE
            -- Restituisce un messaggio di errore se lo stato non è 'Creazione'
            SELECT 'Il Sondaggio non è nello stato di Creazione' AS Message;
        END IF;
    ELSE
        -- Restituisce un messaggio di errore se userId non corrisponde a idUtenteCreatore
        SELECT 'Utente non ha il permesso di aggiornare lo stato' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `creazioneInvito` (IN `idMittente` INT, IN `idRicevente` INT, IN `idSondaggio` INT)   BEGIN
    DECLARE sondaggio_stato ENUM('Aperto', 'Chiuso');
    DECLARE invito_exists INT;

    -- Ottieni lo stato del sondaggio
    SELECT stato INTO sondaggio_stato FROM sondaggio WHERE id = idSondaggio;

    -- Controlla se esiste già un invito con gli stessi campi
SELECT COUNT(*) INTO invito_exists
FROM invito AS i
WHERE i.idRicevente = idRicevente
AND i.idSondaggio = idSondaggio;

    IF sondaggio_stato = 'Aperto' THEN
        IF invito_exists = 0 THEN
            -- Procedi con l'invito
            START TRANSACTION;

            SET @codice = UUID();

            INSERT INTO invito (codice, idMittente, idRicevente, idSondaggio)
            VALUES (@codice, idMittente, idRicevente, idSondaggio);

            COMMIT;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un invito con gli stessi valori esiste già.';
            ROLLBACK;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il sondaggio non è aperto.';
        ROLLBACK;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `creazioneSondaggio` (IN `new_idUtenteCreatore` INT, IN `new_idDominio` INT, IN `new_titolo` VARCHAR(100), IN `new_dataChiusura` DATE, IN `new_numMaxPartecipanti` SMALLINT, OUT `insertedSondaggioId` INT, OUT `message` VARCHAR(255))   BEGIN
    DECLARE dominioExists INT;

    -- Controlla se il dominio esiste
    SELECT COUNT(*) INTO dominioExists FROM dominio WHERE id = new_idDominio;

    IF dominioExists > 0 THEN
        -- Calcola dataCreazione come data e ora correnti
        SET @dataCreazione = NOW();
        SET @dataMinInterval = DATE_ADD(@dataCreazione, INTERVAL 1 DAY);

        -- Controlla se dataChiusura è almeno 1 giorno avanti rispetto a dataCreazione
        IF new_dataChiusura >= @dataMinInterval THEN
            -- Inserisci il sondaggio con dataCreazione, dataChiusura e stato 'Aperto'
            INSERT INTO sondaggio (idUtenteCreatore, idDominio, titolo, dataCreazione, dataChiusura, numMaxPartecipanti)
            VALUES (new_idUtenteCreatore, new_idDominio, new_titolo, @dataCreazione, new_dataChiusura, new_numMaxPartecipanti);

            -- Ottieni l'ID del sondaggio inserito
            SET insertedSondaggioId = LAST_INSERT_ID();

            SET message = 'Sondaggio creato con successo';
        ELSE
            SET insertedSondaggioId = 0;
            SET message = 'dataChiusura deve avvenire almeno 1 giorno dopo dataCreazione';
        END IF;
    ELSE
        SET insertedSondaggioId = 0;
        SET message = 'Dominio non trovato';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generazioneAutomaticaInviti` (IN `p_idUtenteCreatore` INT, IN `p_numMaxPartecipanti` INT, IN `p_idSondaggio` INT)   BEGIN
    DECLARE numInviti INT;
    DECLARE i INT;
    
    -- Determina il numero di utenti disponibili con la preferenza di dominio specificata
    SELECT COUNT(*) INTO numInviti
    FROM utente u
    JOIN utentexdominio pd ON u.idUtente = pd.idUtente
    WHERE pd.idDominio = (SELECT idDominio FROM sondaggio WHERE id = p_idSondaggio);

    -- Imposta numInviti al minimo utenti disponibili oppure p_numMaxPartecipanti
    SET numInviti = LEAST(numInviti, p_numMaxPartecipanti);
    
    SET i = 1;

    WHILE i <= numInviti DO
        SET @randomUtenteID = (
            SELECT u.idUtente
            FROM utente u
            JOIN utentexdominio pd ON u.idUtente = pd.idUtente
            WHERE pd.idDominio = (SELECT idDominio FROM sondaggio WHERE id = p_idSondaggio)
            ORDER BY RAND()
            LIMIT 1
        );

        SELECT COUNT(*) INTO @invito_exists
        FROM invito AS i
        WHERE i.idRicevente = @randomUtenteID
        AND i.idSondaggio = p_idSondaggio;

        IF @invito_exists = 0 THEN
            INSERT INTO invito (codice, idMittente, idRicevente, idSondaggio, hasValue)
            VALUES (
                UUID(),
                p_idUtenteCreatore,
                @randomUtenteID,
                p_idSondaggio,
                0
            );
            SET i = i + 1;
        END IF;
    END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getDomandeSondaggio` (IN `selected_idSondaggio` INT)   BEGIN
    -- Dichiara una variabile per verificare se il sondaggio esiste
    DECLARE sondaggioExists INT;

    -- Controlla se il sondaggio esiste
    SELECT COUNT(*) INTO sondaggioExists FROM sondaggio WHERE id = selected_idSondaggio;

    -- Crea sempre un set di risultati, anche se il sondaggio non esiste
    IF sondaggioExists > 0 THEN
        -- Recupera le domande per l'id_selezionatoSondaggio
        SELECT
            id AS domanda_id,
            idSondaggio,
            testo AS domanda_testo,
            foto AS domanda_foto,
            punteggio AS domanda_punteggio,
            lunghezzaMax AS domanda_lunghezzaMax,
            tipologia AS domanda_tipologia
        FROM
            domanda
        WHERE
            idSondaggio = selected_idSondaggio;
    ELSE
        -- Se il sondaggio non esiste, restituisce un set di risultati vuoto
        SELECT
            NULL AS domanda_id,
            NULL AS idSondaggio,
            NULL AS domanda_testo,
            NULL AS domanda_foto,
            NULL AS domanda_punteggio,
            NULL AS domanda_lunghezzaMax,
            NULL AS domanda_tipologia
        FROM
            dual
        WHERE
            1 = 0; -- Condizione sempre falsa per restituire un risultato vuoto
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getInfoAzienda` (IN `userId` INT)   BEGIN
    DECLARE userExists INT;
    DECLARE userEmail VARCHAR(100);
    DECLARE userName VARCHAR(100);
    DECLARE userSede VARCHAR(100);
    DECLARE userIndirizzo VARCHAR(100);
    DECLARE userPassword VARCHAR(100); 
    
    SELECT COUNT(*) INTO userExists FROM utentebase WHERE id = userId;

    IF userExists > 0 THEN

        SELECT 
            ub.email, 
            ub.password, 
            a.nome AS azienda_nome, 
            a.sede AS azienda_sede, 
            a.indirizzo AS azienda_indirizzo
        INTO 
            userEmail, 
            userPassword, 
            userName, 
            userSede, 
            userIndirizzo
        FROM 
            utentebase AS ub
        JOIN 
            azienda AS a ON ub.id = a.idUtente
        WHERE 
            ub.id = userId;

        SELECT 
            userEmail, 
            userPassword, 
            userName, 
            userSede, 
            userIndirizzo;
    ELSE
       
        SELECT 'Utente non trovato' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getInfoUtente` (IN `userId` INT)   BEGIN
    DECLARE userExists INT;
    DECLARE userEmail VARCHAR(100);
    DECLARE userPassword VARCHAR(100); 
    DECLARE userNome VARCHAR(100);
    DECLARE userCognome VARCHAR(100);
    DECLARE userLuogoNascita VARCHAR(100);
    DECLARE userAnnoNascita DATE;
    DECLARE userTipologia ENUM('Semplice', 'Premium', 'Amministratore');
    DECLARE userTipoAbbonamento ENUM('0', '1', '2', '3');
    DECLARE userCampoTotale DOUBLE;
    DECLARE userInizioAbbonamento DATE;
    DECLARE userFineAbbonamento DATE;
    DECLARE userCostoAbbonamento SMALLINT;
    DECLARE userNumSondaggi SMALLINT;

    SELECT COUNT(*) INTO userExists FROM utentebase WHERE id = userId;

    IF userExists > 0 THEN
        -- Recupera le informazioni Utente
        SELECT 
            ub.email, 
            ub.password,
            u.nome AS userNome, 
            u.cognome AS userCognome, 
            u.luogoNascita AS userLuogoNascita, 
            u.annoNascita AS userAnnoNascita, 
            u.tipologia AS userTipologia,
            u.tipoAbbonamento AS userTipoAbbonamento,
            u.campoTotale
        INTO 
            userEmail, 
            userPassword,
            userNome, 
            userCognome, 
            userLuogoNascita, 
            userAnnoNascita, 
            userTipologia, 
            userTipoAbbonamento,
            userCampoTotale
        FROM 
            utentebase AS ub
        JOIN 
            utente AS u ON ub.id = u.idUtente
        WHERE 
            ub.id = userId;

        -- Controlla se l'utente è Premium e recupera le informazioni premium
        IF userTipologia = 'Premium' THEN
            SELECT 
                inizioAbbonamento, 
                fineAbbonamento, 
                costoAbbonamento, 
                numSondaggi
            INTO 
                userInizioAbbonamento, 
                userFineAbbonamento, 
                userCostoAbbonamento, 
                userNumSondaggi
            FROM 
                utentepremium
            WHERE 
                idUtente = userId;
        END IF;

        -- Restituisce le informazioni Utente
        SELECT 
            userEmail, 
            userPassword,
            userNome, 
            userCognome, 
            userLuogoNascita, 
            userAnnoNascita, 
            userTipologia, 
            userTipoAbbonamento,
            userCampoTotale,
            userInizioAbbonamento,
            userFineAbbonamento,
            userCostoAbbonamento,
            userNumSondaggi;
    ELSE
        -- L'utente non esiste, restituisce un risultato vuoto o un messaggio
        SELECT 'Utente non trovato' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaDominio` ()   BEGIN
    -- Recupera informazioni su tutti gli elementi del dominio
    SELECT *
    FROM dominio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaDominioUtente` (IN `userId` INT)   BEGIN
    SELECT *
    FROM utentexdominio 
    WHERE idUtente = userId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaInvitoMittente` (IN `userId` INT)   BEGIN
    DECLARE userType ENUM('Azienda','Semplice','Premium','Amministratore');
    
    -- Controlla la tipologia dell'Utente
    SELECT tipologia INTO userType FROM utentebase WHERE id = userId;
    
    IF userType = 'Premium' OR userType = 'Amministratore' THEN
        -- L'utente è Premium o Amministratore, procedere con la query
        SELECT
            invito.*,
            utenteDestinatario.email AS destinatario_email,
            sondaggio.titolo AS sondaggio_nome
        FROM
            invito
        JOIN
            utentebase AS utenteDestinatario ON invito.idRicevente = utenteDestinatario.id
        JOIN
            sondaggio ON invito.idSondaggio = sondaggio.id
        WHERE
            invito.idMittente = userId
        ORDER BY
            invito.id DESC;
    ELSE
        -- L'utente non è Premium o Amministratore, restituisce un risultato vuoto
        SELECT 'Utente non è Premium o Amministratore' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaInvitoRicevente` (IN `userId` INT)   BEGIN
    DECLARE userType ENUM('Utente', 'Azienda');
    
    -- Controllare la tipologiaUtente
    SELECT tipologiaUtente INTO userType FROM utentebase WHERE id = userId;
    
    IF userType = 'Utente' THEN
        -- Se l'utente è un "Utente", si procede con la query
        SELECT
            invito.*,
            mittente.email AS mittente_email,
            sondaggio.titolo AS sondaggio_nome
        FROM
            invito
        JOIN
            utentebase AS mittente ON invito.idMittente = mittente.id
        JOIN
            sondaggio ON invito.idSondaggio = sondaggio.id
        WHERE
            invito.idRicevente = userId
        ORDER BY
            CASE
                WHEN invito.hasValue = 0 THEN 0  -- Le righe con hasValue false vengono prima
                ELSE 1
            END,
            invito.id DESC; 
    ELSE
        -- Se Utente non è 'Utente' ritorna un risultato vuoto
        SELECT 'User non è un Utente' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaPremio` ()   BEGIN
    SELECT *
    FROM premio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaPremioUtente` (IN `userId` INT)   BEGIN
    DECLARE userExists INT;
    
    SELECT COUNT(*) INTO userExists FROM utentexpremio WHERE idUtenteVincitore = userId;
    
    IF userExists > 0 THEN
    
        SELECT p.id, p.nome, p.descrizione, p.foto, p.numMinimoPunti
        FROM premio AS p
        WHERE p.id IN (
            SELECT up.idPremio
            FROM utentexpremio AS up
            WHERE up.idUtenteVincitore = userId
        );
    ELSE
    
        SELECT 'Utente non ha vinto nessun premio attualmente' AS message;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaSondaggioCreatore` (IN `userId` INT)   BEGIN
    DECLARE userExists INT;
    DECLARE userTipologia ENUM('Semplice', 'Premium', 'Amministratore');

    -- Recupera la tipologia dell'utente
    SELECT tipologia INTO userTipologia FROM utente WHERE idUtente = userId;

    IF userTipologia IN ('Azienda', 'Premium') THEN
        -- Se l'utente è un Azienda o Premium, facciamo la query
        SELECT *
        FROM sondaggio
        WHERE idUtenteCreatore = userId;
    ELSE
        -- Se l'utente non è Azienda or Premium, ritorna un messaggio
        SELECT 'Utente non ha accesso a questa funzionalità' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaSondaggioPartecipante` (IN `userId` INT)   BEGIN
    DECLARE userExists INT;
    DECLARE userTipologia ENUM('Semplice', 'Premium', 'Amministratore');

    -- Recupera la tipologia dell'utente
    SELECT tipologia INTO userTipologia FROM utente WHERE idUtente = userId;

    IF userTipologia IN ('Semplice', 'Premium', 'Amministratore') THEN
        -- Recupera record di sondaggi univoci per l'utente in base alle voci utentexsondaggio
        SELECT DISTINCT s.*, us.completato
        FROM sondaggio s
        INNER JOIN utentexsondaggio us ON s.id = us.idSondaggio
        WHERE us.idUtente = userId;
    ELSE
        -- Ser l'utente non è Azienda o Premium, restituisce un messaggio
        SELECT 'Utente non ha accesso a questa funzionalità' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getListaUtentiFisici` ()   BEGIN
    SELECT email, id
    FROM utentebase
    WHERE tipologiaUtente != 'Azienda';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOpzioniDomanda` (IN `select_idDomanda` INT)   BEGIN
    -- Dichiariamo una variabile per verificare se il sondaggio esiste
    DECLARE domandaExists INT;

    -- Controlla se il sondaggio esiste
    SELECT COUNT(*) INTO domandaExists FROM domanda WHERE id = select_idDomanda;

    -- Se il sondaggio esiste, recupera le domande
    IF domandaExists > 0 THEN
        -- Recupera le domande per selected_idSondaggio
        SELECT
            idDomanda AS domanda_id,
            idOpzione AS opzione_Id,
            testo AS domanda_testo
        FROM
            opzione
        WHERE
            idDomanda = select_idDomanda;
    ELSE
        -- Se il sondaggio non esiste, restituisce un risultato vuoto
        SELECT 'Domanda non esiste' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPremio` (IN `premioId` INT)   BEGIN
  DECLARE rowCount INT;
  
  SELECT COUNT(*) INTO rowCount FROM premio WHERE id = premioId;
  
  IF rowCount = 0 THEN
    SELECT 'Il premio ' + CAST(premioId AS CHAR) + ' non esiste' AS message;
  ELSE
  
    SELECT * FROM premio WHERE id = premioId;
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRanking` ()   BEGIN
    -- Selezioniamo l'idUtente, i nomi e (i punti) campoTotale, ordinati per campoTotale in ordine decrescente
    SELECT u.idUtente, u.nome, u.campoTotale
    FROM utente AS u
    ORDER BY u.campoTotale DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRipostaApertaUtente` (IN `p_idUtente` INT, IN `p_idDomanda` INT)   BEGIN
    SELECT * FROM rispostaaperta
    WHERE idUtente = p_idUtente AND idDomanda = p_idDomanda;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRipostaChiusaUtente` (IN `p_idUtente` INT, IN `p_idDomanda` INT)   BEGIN
    SELECT * FROM rispostachiusa
    WHERE idUtente = p_idUtente AND idDomanda = p_idDomanda;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSondaggioSingolo` (IN `sondaggioId` INT)   BEGIN
 SELECT *
 FROM sondaggio
 WHERE id = sondaggioId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `inserimentoDomanda` (IN `p_idUtenteCreatore` INT, IN `p_idSondaggio` INT, IN `p_testo` VARCHAR(400), IN `p_foto` BLOB, IN `p_punteggio` SMALLINT, IN `p_lunghezzaMax` SMALLINT, IN `p_tipologia` ENUM('Aperta','Chiusa'), OUT `p_idDomanda` INT)   BEGIN
    DECLARE userType ENUM('Utente', 'Azienda');
    DECLARE sondaggioExists INT;
    DECLARE lunghezzaMaxValue SMALLINT;
    DECLARE insertedDomandaId INT; -- Variabile per memorizzare l'ID della domanda inserita
    
    -- Controlliamo se l'utente esiste e otteniamo il tipo di utente
    SELECT tipologiaUtente INTO userType FROM utentebase WHERE id = p_idUtenteCreatore;
    
    -- Controlliamo se il sondaggio esiste
    SELECT COUNT(*) INTO sondaggioExists FROM sondaggio WHERE id = p_idSondaggio;
    
    -- Impostiamo lunghezzaMaxValue in base alla tipologia
    IF p_tipologia = 'Aperta' THEN
        SET lunghezzaMaxValue = p_lunghezzaMax;
    ELSE
        SET lunghezzaMaxValue = NULL;
    END IF;
    
    IF sondaggioExists > 0 THEN
        -- Verifica se l'utente è il creatore del sondaggio
        IF EXISTS (SELECT 1 FROM sondaggio WHERE id = p_idSondaggio AND idUtenteCreatore = p_idUtenteCreatore) THEN
            -- Inseriamo la domanda
            INSERT INTO domanda (idSondaggio, testo, foto, punteggio, lunghezzaMax, tipologia)
            VALUES (p_idSondaggio, p_testo, p_foto, p_punteggio, lunghezzaMaxValue, p_tipologia);
            
            -- Otteniamo l'ID dell'ultima domanda inserita
            SET insertedDomandaId = LAST_INSERT_ID();
            
            -- Impostiamo p_idDomanda con insertedDomandaId
            SET p_idDomanda = insertedDomandaId;
            
            -- ritorniamo insertedDomandaId come risulato interessato
            SELECT insertedDomandaId AS idDomanda;
        ELSE
            SELECT 'Non sei tu il creatore di questo sondaggio' AS Message;
        END IF;
    ELSE
        SELECT 'Sondaggio non esiste' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `inserimentoOpzione` (IN `p_idDomanda` INT, IN `p_testo` VARCHAR(200))   BEGIN
    DECLARE maxOpzione INT;
    DECLARE domandaTipologia ENUM('Aperta', 'Chiusa');

    -- Otteniamo la tipologia della domanda
    SELECT tipologia INTO domandaTipologia
    FROM domanda
    WHERE id = p_idDomanda;

    -- Se la domanda è "Chiusa", procedere all'aggiunta dell'opzione
    IF domandaTipologia = 'Chiusa' THEN
        -- Trova l'idOpzione massimo per l'idDomanda dato
        SELECT MAX(idOpzione) INTO maxOpzione
        FROM opzione
        WHERE idDomanda = p_idDomanda;

        -- Se non esistono opzioni per l'idDomanda, impostiamo maxOpzione su 0
        IF maxOpzione IS NULL THEN
            SET maxOpzione = 0;
        END IF;

        -- Inserire la nuova opzione con un idOpzione incrementata
        INSERT INTO opzione (idDomanda, idOpzione, testo)
        VALUES (p_idDomanda, maxOpzione + 1, p_testo);

        SELECT 'Opzione inserita con successo' AS Message;
    ELSE
        SELECT 'Le opzioni possono essere aggiunte solo a domande di tipo "Chiusa"' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertRispostaAperta` (IN `p_idDomanda` INT, IN `p_idUtente` INT, IN `p_testoRisposta` VARCHAR(400))   BEGIN
    DECLARE domandaTipologia ENUM('Aperta', 'Chiusa');
    DECLARE maxLunghezzaMax SMALLINT;
    DECLARE sondaggioId INT;
    DECLARE userIsParticipant INT;

    -- Controlliamo se la domanda esiste
    SELECT tipologia, idSondaggio INTO domandaTipologia, sondaggioId
    FROM domanda
    WHERE id = p_idDomanda;

    -- Controlliamo se l'utente è un partecipante al sondaggio
    SELECT COUNT(*) INTO userIsParticipant
    FROM utentexsondaggio
    WHERE idSondaggio = sondaggioId AND idUtente = p_idUtente AND completato = 0;

    IF userIsParticipant > 0 THEN
        IF domandaTipologia = 'Aperta' THEN
            -- Controlliamo se la lunghezza del testo della risposta non supera la lunghezzaMax
            SELECT lunghezzaMax INTO maxLunghezzaMax
            FROM domanda
            WHERE id = p_idDomanda;

            IF CHAR_LENGTH(p_testoRisposta) <= maxLunghezzaMax THEN
                -- Inseriamo la risposta in rispostaaperta
                INSERT INTO rispostaaperta (idDomanda, idUtente, testoRisposta)
                VALUES (p_idDomanda, p_idUtente, p_testoRisposta);

                SELECT 'Risposta aperta inserita con successo' AS Message;
            ELSE
                SELECT 'Il testo della risposta supera la lunghezza massima' AS Message;
            END IF;
        ELSE
            SELECT 'Le risposte aperte possono essere aggiunte solo alle domande di tipo "Aperta"' AS Message;
        END IF;
    ELSE
        SELECT 'Utente non partecipa al sondaggio oppure il sondaggio è già stato completato' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertRispostaChiusa` (IN `p_idDomanda` INT, IN `p_idUtente` INT, IN `p_idOpzione` INT)   BEGIN
    DECLARE domandaTipologia ENUM('Aperta', 'Chiusa');
    DECLARE opzioneExists INT;
    DECLARE sondaggioId INT;
    DECLARE userIsParticipant INT;

    -- Controllo se la domanda esiste
    SELECT tipologia, idSondaggio INTO domandaTipologia, sondaggioId
    FROM domanda
    WHERE id = p_idDomanda;

    -- Controlliamo se l'utente partecipa al sondaggio
    SELECT COUNT(*) INTO userIsParticipant
    FROM utentexsondaggio
    WHERE idSondaggio = sondaggioId AND idUtente = p_idUtente AND completato = 0;

    IF userIsParticipant > 0 THEN
        IF domandaTipologia = 'Chiusa' THEN
            -- Controlliamo se esiste l'opzione con idDomanda e idOpzione specificati
            SELECT COUNT(*) INTO opzioneExists
            FROM opzione
            WHERE idDomanda = p_idDomanda AND idOpzione = p_idOpzione;

            IF opzioneExists > 0 THEN
                -- Inserisci la risposta in rispostachiusa
                INSERT INTO rispostachiusa (idDomanda, idUtente, idOpzione)
                VALUES (p_idDomanda, p_idUtente, p_idOpzione);

                SELECT 'Risposta chiusa inserita correttamente' AS Message;
            ELSE
                SELECT 'Opzione specificata non esiste' AS Message;
            END IF;
        ELSE
            SELECT 'Le risposte chiuse possono essere aggiunte solo alle domande di tipo "Chiusa"' AS Message;
        END IF;
    ELSE
        SELECT 'Utente non partecipa al sondaggio oppure il sondaggio è già stato completato' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `loginUtente` (IN `login_Email` VARCHAR(100), IN `login_Password` VARCHAR(100), OUT `utentebase_id` INT, OUT `utentebase_email` VARCHAR(100), OUT `utentebase_tipologiaUtente` VARCHAR(100), OUT `utente_tipologia` VARCHAR(100))   BEGIN
    DECLARE user_id INT;
    DECLARE user_tipologiaUtente VARCHAR(255);
    DECLARE user_tipologia VARCHAR(255);

    SELECT id, tipologiaUtente, tipologia
    INTO user_id, user_tipologiaUtente, user_tipologia
    FROM utentebase
    WHERE email = login_Email AND password = login_Password;

    IF user_id IS NOT NULL THEN
        SET utentebase_id = user_id;
        SET utentebase_email = login_Email;
        SET utentebase_tipologiaUtente = user_tipologiaUtente;
        
        IF user_tipologiaUtente = 'Utente' THEN     
            SET utente_tipologia = user_tipologia;
        ELSE
            SET utente_tipologia = NULL; 
        END IF;
    ELSE
        SET utentebase_id = NULL;
        SET utentebase_email = NULL;
        SET utentebase_tipologiaUtente = NULL;
        SET utente_tipologia = NULL;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrazioneAzienda` (IN `new_Email` VARCHAR(100), IN `new_Password` VARCHAR(100), IN `new_TipologiaUtente` ENUM('Utente','Azienda'), IN `new_CodiceFiscale` INT(11), IN `new_Nome` VARCHAR(100), IN `new_Sede` VARCHAR(100), IN `new_Indirizzo` VARCHAR(100))   BEGIN

    IF EXISTS (SELECT 1 FROM utentebase WHERE email = new_Email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La email è già stata registrata';
    ELSE

        IF new_TipologiaUtente = 'Azienda' THEN

            INSERT INTO utentebase (email, password, tipologiaUtente, tipologia)
            VALUES (new_Email, new_Password, new_TipologiaUtente, new_TipologiaUtente);
            
            SET @lastUserID = LAST_INSERT_ID();
            
            IF NOT EXISTS (SELECT 1 FROM Azienda WHERE codiceFiscale = new_CodiceFiscale OR nome = new_Nome) THEN
                INSERT INTO azienda (codiceFiscale, idUtente, nome, sede, indirizzo)
                VALUES (new_CodiceFiscale, @lastUserID, new_Nome, new_Sede, new_Indirizzo);
            ELSE
                DELETE FROM utentebase WHERE idUtente = @lastUserID; 
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Azienda già esistente';
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Questa procedura è riservata solo per le aziende';
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrazioneUtente` (IN `new_Email` VARCHAR(100), IN `new_Password` VARCHAR(100), IN `new_TipologiaUtente` ENUM('Utente','Azienda'), IN `new_Nome` VARCHAR(100), IN `new_Cognome` VARCHAR(100), IN `new_LuogoNascita` VARCHAR(100), IN `new_AnnoNascita` DATE, IN `new_Tipologia` ENUM('Semplice','Premium','Amministratore'), IN `new_TipoAbbonamento` ENUM('0','1','2','3'))   BEGIN
    IF EXISTS (SELECT 1 FROM utentebase WHERE email = new_Email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email già registrata';
    ELSE
        IF new_TipologiaUtente != 'Azienda' THEN
        
            INSERT INTO utentebase (email, password, tipologiaUtente)
            VALUES (new_Email, new_Password, new_TipologiaUtente);        
            
            SET @lastUserID = LAST_INSERT_ID();       
            
            INSERT INTO utente (idUtente, nome, cognome, luogoNascita, annoNascita, tipologia, tipoAbbonamento)
            VALUES (@lastUserID, new_Nome, new_Cognome, new_LuogoNascita, new_AnnoNascita, new_Tipologia, new_TipoAbbonamento);
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Questa procedura è riservata solo per gli utenti fisici';
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `removeDominioUtente` (IN `selected_UserId` INT, IN `selected_DominioId` INT)   BEGIN
    DECLARE userType ENUM('Utente', 'Azienda');

    SELECT tipologiaUtente INTO userType FROM utentebase WHERE id = selected_UserId;
    
    IF userType = 'Utente' THEN

        IF EXISTS (SELECT 1 FROM utentexdominio WHERE idUtente = selected_UserId AND idDominio = selected_DominioId ) THEN

            DELETE FROM utentexdominio WHERE idUtente = selected_UserId AND idDominio = selected_DominioId ;
            SELECT 'Dominio rimosso correttamente' AS Message;
        ELSE
            SELECT 'Utente non ha questo dominio tra i preferiti' AS Message;
        END IF;
    ELSE
        SELECT 'User non ha i permessi per accedere' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rispostaInvito` (IN `userId` INT, IN `invitationId` VARCHAR(250), IN `response` ENUM('Accettato','Rifiutato'))   BEGIN
    -- Aggiorno l'esito dell'invito con il codice Invito indicato
    UPDATE invito
    SET esito = response
    WHERE codice = invitationId AND idRicevente = userId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sondaggioCompletato` (IN `p_userId` INT, IN `p_sondaggioId` INT)   BEGIN
    UPDATE utentexsondaggio
    SET completato = 1
    WHERE idUtente = p_userId AND idSondaggio = p_sondaggioId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `statisticheAggregate` (IN `p_sondaggioId` INT)   BEGIN

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_statistics (
        testo_domanda VARCHAR(400),
        domanda_tipo ENUM('Aperta', 'Chiusa'),
        num_risposte INT,
        risposte_chiuse TEXT,
        valore_medio INT,
        valore_minimo INT,
        valore_massimo INT
    );


    INSERT INTO tmp_statistics (testo_domanda, domanda_tipo, num_risposte)
    SELECT
        d.testo AS testo_domanda,
        'Aperta' AS domanda_tipo,
        COUNT(ra.id) AS num_risposte
    FROM Domanda d
    LEFT JOIN RispostaAperta ra ON d.id = ra.idDomanda
    WHERE d.idSondaggio = p_sondaggioId AND d.tipologia = 'aperta'
    GROUP BY d.id;

 
    INSERT INTO tmp_statistics (testo_domanda, domanda_tipo, risposte_chiuse)
    SELECT
        d.testo AS testo_domanda,
        'Chiusa' AS domanda_tipo,
        GROUP_CONCAT(o.testo ORDER BY rc.idOpzione) AS risposte_chiuse
    FROM Domanda d
    JOIN Opzione o ON d.id = o.idDomanda
    LEFT JOIN RispostaChiusa rc ON o.idOpzione = rc.idOpzione
    WHERE d.idSondaggio = p_sondaggioId AND d.tipologia = 'chiusa'
    GROUP BY d.id;

    INSERT INTO tmp_statistics (testo_domanda, domanda_tipo, valore_medio, valore_minimo, valore_massimo)
    SELECT
        d.testo AS testo_domanda,
        'Aperta' AS domanda_tipo,
        AVG(LENGTH(ra.testoRisposta)) AS valore_medio,
        MIN(LENGTH(ra.testoRisposta)) AS valore_minimo,
        MAX(LENGTH(ra.testoRisposta)) AS valore_massimo
    FROM Domanda d
    LEFT JOIN RispostaAperta ra ON d.id = ra.idDomanda
    WHERE d.idSondaggio = p_sondaggioId AND d.tipologia = 'aperta'
    GROUP BY d.id;

    SELECT * FROM tmp_statistics;

    DROP TEMPORARY TABLE IF EXISTS tmp_statistics;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePremioAmministratore` (IN `admin_UserId` INT, IN `premioId` INT, IN `new_Nome` VARCHAR(100), IN `new_Foto` BLOB, IN `new_Descrizione` VARCHAR(200), IN `new_NumMinimoPunti` DOUBLE)   BEGIN
    DECLARE userRole ENUM('Amministratore');

    SELECT tipologia INTO userRole FROM utentebase WHERE id = admin_UserId;

    IF userRole = 'Amministratore' THEN
    
        IF EXISTS (SELECT 1 FROM premio WHERE id = premioId) THEN
        
            UPDATE premio
            SET
                nome = IF(new_Nome <> '', new_Nome, nome),
                foto = IF(new_Foto IS NOT NULL, new_Foto, foto),
                descrizione = IF(new_Descrizione <> '', new_Descrizione, descrizione),
                numMinimoPunti = IF(new_NumMinimoPunti IS NOT NULL, new_NumMinimoPunti, numMinimoPunti)
            WHERE id = premioId;
            SELECT 'Il premio è stato aggiornato correttamente' AS Message;
        ELSE

            SELECT 'Il premio non esiste' AS Message;
        END IF;
    ELSE

        SELECT 'Utente non è un amministratore' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUtente` (IN `userId` INT, IN `newEmail` VARCHAR(100), IN `newNome` VARCHAR(100), IN `newCognome` VARCHAR(100), IN `newLuogoNascita` VARCHAR(100), IN `newAnnoNascita` DATE, IN `newPassword` VARCHAR(100), IN `newIndirizzo` VARCHAR(100), IN `newSede` VARCHAR(100))   BEGIN
    DECLARE userExists INT;
    DECLARE userType ENUM('Utente', 'Azienda');
    DECLARE newEmailExists INT;
    
    -- Controllo se l'utente esiste
    SELECT COUNT(*) INTO userExists FROM utentebase WHERE id = userId;
   
    IF userExists > 0 THEN
        SELECT tipologiaUtente INTO userType FROM utentebase WHERE id = userId;
        
        -- Controlla se la nuova email esiste già nella tabella utentebase
        SELECT COUNT(*) INTO newEmailExists FROM utentebase WHERE email = newEmail;
        
        IF newEmailExists = 0 THEN
            -- Se l'email non esiste, procedo con l'aggiornamento
            
            -- Aggiorna i campi utentebase
            UPDATE utentebase
            SET 
                email = CASE WHEN newEmail IS NOT NULL AND newEmail != '' THEN newEmail ELSE email END,
                password = CASE WHEN newPassword IS NOT NULL AND newPassword != '' THEN newPassword ELSE password END
            WHERE id = userId;
            
            IF userType = 'Utente' THEN
                -- Aggiorna i campi utente
                UPDATE utente
                SET 
                    nome = CASE WHEN newNome IS NOT NULL AND newNome != '' THEN newNome ELSE nome END,
                    cognome = CASE WHEN newCognome IS NOT NULL AND newCognome != '' THEN newCognome ELSE cognome END,
                    luogoNascita = CASE WHEN newLuogoNascita IS NOT NULL AND newLuogoNascita != '' THEN newLuogoNascita ELSE luogoNascita END,
                     annoNascita = CASE WHEN newAnnoNascita IS NOT NULL AND newAnnoNascita != '' AND STR_TO_DATE(newAnnoNascita, '%Y-%m-%d') IS NOT NULL THEN newAnnoNascita ELSE annoNascita END
                WHERE idUtente = userId;
            ELSEIF userType = 'Azienda' THEN
                -- Aggiorna i campi dell'azienda
                UPDATE azienda
                SET 
                    email = CASE WHEN newEmail IS NOT NULL AND newEmail != '' THEN newEmail ELSE email END,
                    nome = CASE WHEN newNome IS NOT NULL AND newNome != '' THEN newNome ELSE nome END,
                    sede = CASE WHEN newSede IS NOT NULL AND newSede != '' THEN newSede ELSE sede END,
                    indirizzo = CASE WHEN newIndirizzo IS NOT NULL AND newIndirizzo != '' THEN newIndirizzo ELSE indirizzo END
                WHERE idUtente = userId;
            END IF;
        ELSE
            SELECT 'E-mail duplicata' AS Message;
        END IF;
    ELSE
        SELECT 'Utente non trovato' AS Message;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `azienda`
--

CREATE TABLE `azienda` (
  `codiceFiscale` int(11) NOT NULL,
  `idUtente` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `sede` varchar(100) NOT NULL,
  `indirizzo` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `azienda`
--

INSERT INTO `azienda` (`codiceFiscale`, `idUtente`, `nome`, `sede`, `indirizzo`) VALUES
(12345671, 6, 'Lidl', 'Bologna', 'Via chiassi'),
(12345673, 7, 'TheSpace', 'Bologna', 'Via bozza');

-- --------------------------------------------------------

--
-- Struttura della tabella `domanda`
--

CREATE TABLE `domanda` (
  `id` int(11) NOT NULL,
  `idSondaggio` int(11) NOT NULL,
  `testo` varchar(400) NOT NULL,
  `foto` blob DEFAULT NULL,
  `punteggio` smallint(6) NOT NULL,
  `lunghezzaMax` smallint(6) DEFAULT NULL,
  `tipologia` enum('Aperta','Chiusa') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `domanda`
--

INSERT INTO `domanda` (`id`, `idSondaggio`, `testo`, `foto`, `punteggio`, `lunghezzaMax`, `tipologia`) VALUES
(1, 1, 'Dove gioca lautaro?', NULL, 5, 20, 'Aperta'),
(2, 1, 'In che lega gioca il milan?', NULL, 5, 20, 'Aperta'),
(3, 1, 'Chi ha vinto lo scudetto l\'altro anno?', NULL, 10, NULL, 'Chiusa');

-- --------------------------------------------------------

--
-- Struttura della tabella `dominio`
--

CREATE TABLE `dominio` (
  `id` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `descrizione` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `dominio`
--

INSERT INTO `dominio` (`id`, `nome`, `descrizione`) VALUES
(1, 'Sport', 'Tutto sullo sport!'),
(2, 'Cinema', 'Film, Serie e altro ancora'),
(3, 'Cultura', 'Quello che sai'),
(4, 'Macchine', 'Il mondo delle auto');

-- --------------------------------------------------------

--
-- Struttura della tabella `invito`
--

CREATE TABLE `invito` (
  `id` int(11) NOT NULL,
  `codice` varchar(250) NOT NULL,
  `idMittente` int(11) NOT NULL,
  `idRicevente` int(11) NOT NULL,
  `idSondaggio` int(11) NOT NULL,
  `hasValue` tinyint(1) NOT NULL DEFAULT 0,
  `esito` enum('Accettato','Rifiutato') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `invito`
--

INSERT INTO `invito` (`id`, `codice`, `idMittente`, `idRicevente`, `idSondaggio`, `hasValue`, `esito`) VALUES
(1, '2e6d2f1f-555f-11ee-a4eb-a85e45520414', 2, 1, 1, 1, 'Accettato'),
(2, '2ff9ce2c-555f-11ee-a4eb-a85e45520414', 2, 5, 1, 1, 'Accettato');

--
-- Trigger `invito`
--
DELIMITER $$
CREATE TRIGGER `accettazioneInvito` BEFORE UPDATE ON `invito` FOR EACH ROW BEGIN
    -- Controllo se l'esito è 'Accettato' o 'Rifiutato'
    IF NEW.esito IN ('Accettato', 'Rifiutato') THEN
        -- Imposto hasValue su true (1)
        SET NEW.hasValue = 1;
        
        -- Controllo se non esiste già una relazione esistente
        IF NOT EXISTS (
            SELECT 1
            FROM utentexsondaggio
            WHERE idSondaggio = NEW.idSondaggio AND idUtente = NEW.idRicevente
        ) THEN
            -- Inserisci un record in utentexsondaggio
            INSERT INTO utentexsondaggio (idSondaggio, idUtente)
            VALUES (NEW.idSondaggio, NEW.idRicevente);
            
            -- Aggiorna numeroIscritti in sondaggio
            UPDATE sondaggio
            SET numeroIscritti = numeroIscritti + 1
            WHERE id = NEW.idSondaggio;
        END IF;
    -- Controllo se l'esito è NULL
    ELSEIF NEW.esito IS NULL THEN
        -- imposto hasValue a false (0)
        SET NEW.hasValue = 0;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `aseggnazionePuntoCampoTotale` AFTER UPDATE ON `invito` FOR EACH ROW BEGIN
    -- Controllo se l'esito è 'Accettato'
    IF NEW.esito = 'Accettato' THEN
        -- inserisco un recors in utentexsondaggio
        UPDATE utente
        SET campoTotale = campoTotale + 0.5
        WHERE idUtente = NEW.idRicevente;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `opzione`
--

CREATE TABLE `opzione` (
  `idDomanda` int(11) NOT NULL,
  `idOpzione` int(11) NOT NULL,
  `testo` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `opzione`
--

INSERT INTO `opzione` (`idDomanda`, `idOpzione`, `testo`) VALUES
(3, 1, 'Napoli'),
(3, 2, 'Inter'),
(3, 3, 'Juventus');

-- --------------------------------------------------------

--
-- Struttura della tabella `premio`
--

CREATE TABLE `premio` (
  `id` int(11) NOT NULL,
  `idCreatore` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `descrizione` varchar(200) DEFAULT NULL,
  `foto` blob DEFAULT NULL,
  `numMinimoPunti` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `premio`
--

INSERT INTO `premio` (`id`, `idCreatore`, `nome`, `descrizione`, `foto`, `numMinimoPunti`) VALUES
(1, 1, 'Primo Sondaggio', 'Primo sondaggio Completato!!!', 0x89504e470d0a1a0a0000000d4948445200000200000002000806000000f478d4fa00002000494441547801ecbdf7771b599626780982a0f714bd24ca7b93f2ca94524a29bdcfca2c5f5955dd55d5d33d737667cdd999fd27f6d79ded3d33b3dbb5d366b7bb6c5775555665a7abf4de28a54cb994a1288a22456f0002e07edf03a1644a64bc08102002c0bd3a5700112f5e447c01c4bdef5a112545401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014540115004140145401150041401454011500414014560b108142d7602dd5f115004b28e400067100257812bc041303fbbf575ee67c9f7182651707c96e77b9ffc8caf13e0317064763c5e9414014520171150052017ef9a9e73212040015d06ae0153b02785fbadef29f0f959e5ec2bf7a1329014f07c5de83d1504d25c01efa40850e84f81a9008ccfbe261582e42bb7cd7d3f82bfb90fe755520414011f21a00a808f6e869e4ac1203057b853c0dfca75b39fd5cebe2e24f493c29f423f29ccf17649884a435219480afc5b5fa90c5001189e7d1d9a7de567b7b22a0900454911584a045401584ab4f558858800857313b815dc3ce7b511ef6f15fcb7febdd4421da79411a2b270abc0bff5ef018ce903f7ce79edc77b2a064a8a80229001045401c800a83a654122c0553d053805fd5c61df32cf675408a818287d8900053d05fe5c0580efafcdf3199507752900042545603108a802b018f474df424680029c82be13bc62f6b563f6b3b92b7d9af3a91c28794780429e6e835b2d0357f05937f8d2ec2b15052a104a8a8022e0010155003c80a5430b16010a700af2f659a6d05f054e0a7ebe721b7df24a994780b1063de0a402c0d72fc0540af839998a0315082545401158000155001600463f2e680428f01bc0abc1c9153e053edf53d0f395ab7c46db2b651f016627d04a905400f84a8520a9209cc7fb1b6055080082922290444015802412fa5ae808509853a853e8af056f03af072757f76aca0718394214f4b400d0124025e034f813f0593095012a0b541a941481824640158082befd057ff134d973454fa1bf114ca14fe1cfbfe9dfd7153e40c803a2b0679c00853f95002a039fcdfe4d25812e052545a0e0105005a0e06e79c15f3023f5b9aaa790df0ca6d0e77b32a3f303e0dca2a28004022552541cc26ba914058252c4cbc0e745e0db5eb12df9b9b9d099b8cc80692137afc9bfe7be725b3c2af17858666211bc4e0b3ec82d9c1267cb9366b6c1f959a6327072f6fd25bc32c340491128080454012888db5cf01749a1df05e6ea7e07782b7835b80b4cd3beefa8a8282881920a099654497149b50482151280802f0a40c82705bd79c56773ffe618ec9b14f089d7e205150273e173053d853affa6bb7c26f615856066060a00847f4201482a025ffe6db6c5a11c5041884e486c7a54a2d363129f9ec03c51df613c7b4274155c0053213801fe084c2bc105b02a030041297f115005207fef6da15fd97c429f0a401798dbb24e4558b517072ba538540d219f10f44108fbdbfe360a40794201282ec52a3fa104249401acf821f0f1dfd25ecfcc8c11eaf1181481a4d0c7eb0cfe4e280093b30ac0a8798d41118845a8107cf5ef58741cfbc39ae00fa2c0bf00a602a0ca004050ca6f0496f8a991df60ead5651d01df0afd4071b99494d54bb0b4015c2f25e060a86e56d853014808fe2f57fce590e9c55907341d2730034b423c9a5408128a00ad0386a9144486643a3c2851c337647a6a104ac4643a0ebd98395419580c7aba6f4e20a00a404edc263d4907045890670598417cbbc134ef676fa50f9f3b57f546c053d843e897dc14fa09e19f50001a60e2af4c98ea71c2854a8c39884f8f4301b831ab000cde7c6f3e833210c5362a08b4166429eee05665e03ddc2f06113266400b1015ea97370fae5b15803cb889057a090cd86310df2ef0ded9f7f4eb2fa9793f10c4cabeb411ab7b7293790df23d57f8861bcc7b8e53728f002d0609ab40423130efa706601d20f7275ec303c6b2e07ed6b48ca432c07801060ebe037e7ff63d030b9514819c424015809cba5d057fb24cdba390e76a9f427f0f984a00f3f703e08c127deec150ad949427047d42e0cf7ddf684cfc01f8e995d28f00e30d8c3560ae12609481598560b21fee8461139390fea3df3623a2244d3d012a02ef82a90c24530b27f05e4911f03d02aa00f8fe1615fc0952b053c053d053e02757fb5d784f852063c4743afaec4b2bdb2554d136bbc29f2bf09be0bbe729e8cf286337c171e219c4114ccc5a04669580598520327155c2e33d466160fa62868902ff0298ca0015012a047cdf07a6a2a0a408f812017d72f9f2b6e84901014ad62ef04ef07e304dfd5cf9d3f49f3162ba5da8bc2521f42b3bf09ae05045ab59fd532950f22f0214f6b40244267aa1005c311c31af3d1299bc66d213337cf67405d01240d7c05be00fc117c054129414015f21a00a80af6e879e0c10a00f9f2578ef04df05a602c0203f06fba59f10b4170cd598153e57f965559d525ab5c228002550048aa11028e52e0231d4239886e0a735203c7649a6c6baa11c5c351c8dc09dcfba07992106075e025301780dfc3af8349831044a8a802f105005c017b7414f02087065bf153c57f0b7e2efb4fbf69937cf00bdd2ca360961855f56bd12ef9743096835417ceac307ea79488c21601061c23a7059a6462f4ac23a70d5642064a85811358c5ef05c45e004fea6a5404911c82a02aa006415fe823f38853b853c57f95ced53f8530948bb999f4577988e1782d02fc30abfacba0b42bfd3fccd7c7c35ed03f502a284ab60080a006305baa10c5c8075e092f99be987192a4e44a14fe14f6b00ad02540aa81c64cc0c81b9951481051150056041687443061108616e9af5e9d7a7e03f00a67f3fad297c8cda677a1e57faa5552b67853e7dfa6d28c0539b378576809bd2221060a1a218e206c24619b8629481f0d845f3372d06ac749866a21be033f09b602a028c17a0bb20ed07c29c4a8ac08208a802b02034ba2103083082ae0bcc95fe1130057f17386d8e7656cf631e7e59d57208fc55b3421f51fc10fac112e817f0f92b29020b22809880e8f4c8ac65a027611918fd02d681cb12a5320065218d94cc1ea022f0329896810be08ca72de0184a8a80e62fe977604910a0d4e58a9f82ff1ef021f06a302d01692146ef335dafbc66b594d76d90f2ead510faed08f0abc6fc456939864e526808cc20a36014ca408f4c8e9e97c9a1cf6572e4bc092864b3a3341257fee7c1af825f045311a045405d030041297308e8933173d8eacc8900be4e00c1953e05ffdd600afe32701aa8c804f33188af0242bfa26e2356fc2b4cbe3e7dfe4a8a40ba10604c002b104e8d5e9289a1cfc09fe3fd45133c885482741d660a13511178054c458096816eb02a02004129fd08a802907e4c75c6040214fcfbc014fc47c114fc6931f5078acb4cc43e4dfc14fce575eba40c51fceca2a7a408641a0176359c1abf0c8bc0995945e00b9359108f517ea785685ea022f012988ac0db602a024a8a405a11500520ad70ea6440a01dbc079c14fcebf13e2d829f657899a35f51bf11827f3dfcfc5d28cbdb6cdae4e2184a8ac09222c0b6c7d3937d880fb80045e0b44c0c7e666a0db010519a888ac069f04b602a02ef827bc04a8a405a105005202d30ea244080a97b4ce7bb0f7c2f9882bf0abc2862501f6bee97d57441e86f82f0df0433ff4a53956f5113ebce8a401a11a0d0a74b6062f014948153323572c1b80cd21434388653a522f03cf88f60a60f32a5504911581402aa002c0a3edd190850c86f06df0f7e00bc155c075e1425cdfce5b56b8dd0afa85d6f82fab432dfa260d59d338c002b0f326870629816815332397c369dee81219c3eeb083c07fe03f82498ca819222901202aa00a4049bee04044260faf593827f0fde37831745c525d530f32f974aacf469eaa79f3f0433bf06f52d0a56dd79891160d06084ee01a410d235300e65208c54c2d8f4683acea40f93bc0b4e2a028c1788a463629da3b0105005a0b0ee77baae96017e7783b9e23f0a5e015e14b1342f53f868e2279743f0f333254520d7118886079146484500ee015a05904ac8cfd2409730c74b602a02af803550102028b947401500f758e9c8849f9fd5fb28f8b9f25f0b5e544a9f11fcb5eba4aa719b54366c35e5798b4be855505204f20b81d8f498293b3c7ee3848c0d7c02f7c0997428024c3d380ba64b808a00ab0af6839514012b02aa005821d2014080427e23f851f02360fafc1755b637585a8715ff5a08feed52d9b80366ff4eedbc075095f21f01c60984d195707ce02328021fc32270168a00ddfb8b229617664cc06fc1bf017f064e5b5e22e652ca43045401c8c39b9ae64b6ac77cc7c04f800f815bc1291353f9ca6ad618c15fd544c18ffcfd6065caf3e98e8a40ae22108b8e9bb880b1fe84223035720e9507179d42d80b3c5e05ff0afc02b807aca408cc8b802a00f3c2a21f0201dae1b9d2a7e07f1cbc1e1c02a744c1500d02fa562756fc10fcecc8a7a6fe94a0d49df20c01ba06d889703ca908a0ec7034c2057dcac480c0d3e05f83a90868b6004050ba1d0155006ec7443f116190df83600aff03e026704a4421cf487eaef6ab60ea670e3f23fd95140145e0ab08304380b504c6e81a8032c00c022a078b20c602bc09a612f07bb006090204a52f1128fef2adbe53048c5f7f2f70f801f8cfc17c4f4b80670a14974a29847d5dfbddd2b0e201a969de6f3af4f17325454011b81d01fe3698f25a56dd05866baca452585e988d87522c285481a3ac06d392570f9e0433d8200c565204441500fd122411602adf37c0ff06fc3098568000d823159987584dcb01a95f7ebfd4b51d46b0df2a94eb55c1ef11481d5ea0081845a0a2d5b8c942152da6d435ad030c1e4c81f81b6e0433887703b80cdc0b1e062b153802aa0014f8170097cf15fe3e3057fc3f04ef0697833d1303fc98ca57df715cea3bef35c57cd4cfef1946dd41113008b0ea65696507140196be4e14d78c2370301e4b6901cfdf34ad0154041ac0e3e01b60c60b28152802aa0014e88d9fbd6c46f83f05fe2b30d3fbdac09e29102c37297d75ed47a561f98352b56c17eaf7374a51510a0604cf47d71d1481fc4580bf2106d096a2cd3515012ad4ac32c80c82997834950ba72b804a006b78f0074a6b405aca13621ea51c434015801cbb61693a5d46f36f01d3d7ff63307dfd9e57fd6cd4535ad96eccfcc6cfdf7ad0e4f3070225984e49115004d285007f5325e5688a0545a0b4aa438a8b2b4c8020e3034466bc1ea60c3bac02d325c01cdc01304b13c6c04a0584802a000574b3672f9511fdc7c17f017e1adc05f69c0d42733f23fb1b3aef93bacee352816a7e8162cf3a040eada40828026e1160932c2add0cb02d41312d12e30352700bf037cf6701d37b3bc0d360660da4146880fd94721001550072f0a62de294bbb0ef77c00cf4632d7f9a033d119bf23087bfaee31e44f7c3dcdfb473b635af671dc2d37175b022a0082411283219022ca245a60b8ee982740bc02f901ce4f69531406bc0b406d032d8035e745942cca1940308a802900337290da7980cf4fb11e6a2d99f69419eedf4acdb5fbd6cb7342e7f406adbee8622b01c5dfa8269383d9d42115004bc22c0df5e49591394801512c22b0d79b1e911933ae8712e3e0b6805606c0017052c3ea001820021df4915807cbfc389d2bd4fe232ff2d98e97d2d5e2f9969496548e5abef386672fa19e91f0c51a750520414816c23500c0b4088d902ac1d80cc01c605305b2085da01b5b8165a02182048ba0aa632a094a708a80290a73776f6b298f6f32c98267fa6fa7976d2339abfa665bf31f7d7b6de65fc8f4501fdda004b2545c03708f0375952da60dc73ac1dc000dd18fa0ac4a3acfde3899201828c0da079ef0a9801824a7988803ec9f3f0a6e292f823de0966843f4dfe6bc09e9cf466d55fbbd6e4f437a0a04f65fd26f81d2b308d9222a008f81581401041821508129c6db2158b4d4a1cf1011ead017c562c03d31ac0baddcc12a04b20a5bc43eca7e453045401f0e98d59c4693134f818f82fc1ace5efb97b9ff1f537ef93c6150f4b2d52fb122b0acde907964a8a80ef1130b5039021402520549ef0f8452343a9c406d4e062e90e60bd1066075c034f8195f204015500f2e446ce5e067fa85f07ff159851fef4e9b92693d78f3ce384afff41acfa371a9fa2eb0974a022a008f8060193328892c2a5559da61477940182a6b990a7ba0134fbad0227e302e812d0c241beb9cb8b3b11550016879f9ff6e60f94e6fe9f8069fe6764af6b6287becac6edc6d75f87087fe61a53215052041481dc4580bfe11264ef9456760a2d7bac1e1843abe19978c4cb45f159b21cbc0eccf757c0740928e53802fa84cff11b88d3a7bf7f1798fefeef81a9ad7b229a09eb3a8e1a937f359400961e5552041481fc41c0f41530b1019d52545c22d1a91b89ba01de2eb111c3a904f001410580b1011a17001072955401c8d53b97386ffafbef0533c5ef71b0a7143f53c3bf7603baf6dd878a7ef74a797517f2faa9e02b29028a40be21c0df76a87c59c225c056c3d12928010810f4d65380c29f4a4027987101bd608d0b0008b948aa00e4e25d4b9c73d2df4fe17f18cc685dd71444ca504deb9dd2b4f211a969de6b52885cefac031501452067116043a132c405d0cdc7e4a068781001829ed205994e9c8c0b6040015d021a170010728d5401c8b53b96385fe6f7d3dccffcfe1de020d835852ada4cbbdec6950f4945dd7a0408d18ba0a4082802858200d37c99ddc300c1a2a2a04c4f0d9872c21eae9fcf1c5a01680d60da209500ad17001072895401c8a5bb9538d7cd78a1e0ff3e988a806b2a0a84a4bc760d4af93e6822fd13817e9adee71a401da808e411028956c3b5c612c01881289a0ac52258c8cf786a0a988c0b6069d06ef0f53c8228ef2f451580dcbac50cf6fbf7e067c0b4dfb92646f9572dbb439a56c0e4df720035c41b5cefab03150145207f1128463c4008ee00f61388233b201a1ef29a25c074e335603624a0127015ac940308a80290033709a74873db21f0ff0266b09fa72e7e6c1852d77e441a573e2a950d5b4c2731cca1a40828028a8041e0a64b003d058af08f2e01f614f04095184b77009b0a3130902e01cfad09b18fd21222a00ac012829de2a1685a7b10fcbf82ef037b70d81799fc5f13e58f0e7ee568e8a3ddfb80a09222a008dc8640b2bb20ad01cc1830a982700b7820b613a612406b00e301680df0547000e39596100155009610ec140ec534bf27c1ff017c10ecda61cfc0be8afa0d28ecf31056ff474dc00ff6575204140145c0118160a83a1117806c017615645cc0cc4cd4719f391bf98cea02b399d008f82258d30401821f4915003fde95c439d149ff34f87f00ef4c7ce4eeffe260a554c3dfdfb8f231a4f8ed430530ea114a8a8022a008b843c0140e822580ee43a608d21a30139f76b77362541b5e6809603be10b604f798618afb40408a802b00420a7700806d3b0a6ff7f07dee665ff6254f1ab657e7fd763b000c0df8f5ee14a8a8022a008784520501c9292f26674176c35418191a9eb4810087b998685c998a9c460820bb3af7851f20b02aa00f8e54e7c791ecd78fb4df0bf036ff9f263fb3bd6fa661dffa6aec791eeb756fdfd76c8748422a00838205014402f81f226b810db20fca7111c78dd6b57413ecfa804d00d70013c0e56f20902aa00f8e446cc9e462b5ebf0d6637bf4db39fb97aa1a9aebee31e98fd1f96b2ea95d887b539941401454011582c0245c68d484b004c01323d0925c05b86c0329c01950006045e00d32da0e403045401f0c14d983d0556d5fa0ef8df8037cc7ee6ea859dbe18e95fdf799fa9ece56a271da40828028a80070482a15a58025a61594c660830c6cf35d1ad492580d18497c09e76c678a50c20a00a4006404d61ca15d8e7bbe09f809946e39a68ea6f84bf3f11e94f6b9b9222a00828029941209121d021c5c81488866f18f67024560da412c05283540286c14a59444015802c823f7be82ebc3e0bfe11780dd82515a1a8cf5659b6e6eba6b29fb6f075099b0e530414814521c0c0e252140c2a295b661400ba043c10b39ba804b08910958021b05296105005204bc0cf1e962bffa4f05fe5f654d8bca3ba69a734affb36d2fd76a3990feb6f2829028a8022b0340804e006a0124097005304134a80ebc27fac649ab4045cc07bb5042ccd6dbbed28aa00dc06c9927d409f3fcdfe5cf9bb16fe2cd959bd6c0f84ffb7a4aa611b3a7969b0df92dd313d9022a008dc4480cf1e2a00a1ca368946864d86c08cfb46422c4ed2056671810b608d0900084b4daa002c35e289e331da9f017ff4f9af497c64ff3f808e5d352dfb61f67f462aeb3d2509d827d7118a8022a008a48040a87c99510462d36312813bc043c1205a02bac02c2e701eacd901006129491580a5443b712c46ea31d58fd1feae03fed8cd8f057e96ad7a4a2aea5865534911500414017f20c034645a03e2d149e30e9841574197c498802e30eb045009d03a010061a9481580a5423a711ca6c2b0c80ff3fc5da7fab194af29f0b3ea0934f4a1eb4c4911500414017f21c016e3a5700750f84f4ff5792918c4ec802ef004984a005f9596000155009600e4d94350d365795f56f8736dbf37057eda8fa2c0cf23b3057e6667d31745401150047c8600172ba5a81a08e99fa81ae8be601017475d60ba01a80468ef00809069520520d30827e667c00b1bfbb0b6bfebf2bea1f21614f7398e8e7e0f6a819f048efabf22a008f81c8144c1202801206607c4d051d025b16260179801815402e81650ca2002aa006410dcd9a92bf0fa04f87f04bb6eec6356fe14fecb21fc615653520414014520571060c120d33f00590191895e2fa5831923d505ee079f057b6a4188f14a1e105005c00358290c0d609f07c1ff017c87dbfd6946ab87d9dfacfc55f8bb854dc729028a808f10282ea932dd0467621164075cf51213c02e822bc0dde03360160d52ca0002aa006400d439531ec4fbff083e34e733c7b78cf667c01f7dfea5552c15a0a40828028a406e22602c016829ccec80c8c4551320e8f24ada318e2e015a012ebbdc478779444015008f807918be196369f6a70520e8663fe6f933d5af09d1fe898e7e6ef6d2318a8022a008f817011313002520363d6adc011eea045009a8047f0ef6546fd8bf68f8ebcc5401c8ccfda0f98a79fecf806bdc1c8215fe4c911fe4f96baa9f1bc4748c22a008e40a02746bb260500c15031913e0b26220174e54028ac0540286c14a69444015803482393b15bfb0df037f1fccf75632b5fd51de9715feb4c88f152e1da0082802398800eb049440099846ef002a01c8157473150ca2e67334023e0f1e052ba509015500d204e4ec34c9423f7f81bfd7b89bba68b6b1cfb7b4bcaf3bc0749422a008e42802cc6e324ac064dfac12e0ea4298464dab2af309cf81b55010404807a902900e141373d0d4ff14d853a19f4a34f4695ef71d34f6d99abe33d1991401454011f0290274055009a015601a8a804b62b5c0e5e0413095803058699108a802b0480067772fc3eb713085ff2e307d5656aaa8db20cd6bbf090b003204b5ab9f152f1da0082802f981400841818c0b6066c0f4d480db8ba28595dc03be088e82951681802a008b006fceae14fa14fe87c1a1399f2ff8b60c35fd97ad7edab4f62d0ab84a1258702edda00828028a404e2180050fdd01ac15108612100d73616f252eaca8005481991e7805acb408045401580478b3bbaec5eb8fc18f835d45fc97562d97a6958f9994bf62a4fe2929028a802250680870e14325201008194b402cc20ac0562ac108160a225109b861dee97f2921a00a404ab0dddc89d1a93f0033ea3ff9a5bcb971be376c99d988f2be75ed4784f9b14a8a8022a008142a0281e290490f2c82d794ee80d8f4981b28ca31a803cc32c1ac14a8990100211552052015d412fb3032f5ebe09f8057253e72febfa4b4c134f7a9efbcd768becea375ab22a0082802f98f4020586e820267e251898cf7a064f0a49b8ba6b5954a006b035009d0c64100c12ba902e015b1c47806fd1d03ff157867e223e7ff59e2b7b61d257e573c946897e93c5cb72a028a80225030081497544209689218847f64dc75c9606606d483bbc11a1498c2b74515801440c32e14fa7f09be1b4c9f9423058acb10ecb71bf5fd1f45953f57c602c7f974a322a0082802f98640305463dca2d1f00d931e3833e32ac89f4a0017648c076076809207045401f000d6ecd0d57865d01f5bfcba70e2174945fd0623fc2b1b3621db4f219fc5515f1401454011f80a026c1e14282e37dd03a727d911d84a738302e90a70954e609db54006a834f276a35b31fc593003fff8de4aa5959d68ebfb90d434ef15faba9414014540115004e647800b24d607602915c603c4a65d65063095aa13cc38002a01ae220931aee0491500f75f01e69e3e0966939f356e76638a4bfdf2fb10f17f74f64bed662f1da30828028a40e122c0cc8092b246d330c80405465d55fe6550601b9866032a01ec1da064414015000b407336efc3fb7f0be62b0b52381283fe98ead7b0fc010955b8ca10749c4f372a028a8022502808b03e0a9580787452c2b004ccc45dc973c603d01a701a7ca950b05acc75aa02e00ebd2e0cfb11f861b0d58e5f84c21655cbeed0a03f80a5a40828028a402a08301ea0183c3dd58f1a01d7446662b669b830a312c0e8c1cfc04360250704540170006776134b4f7e074cbfbfaba57c79ed1a695af18854366c112df33b8ba2be28028a8022e011015a525929303cd12351773d039811405700e300680970e53fc0b8822455009c6f3bebfa1f07d3efbfd97968626ba8a2cd54faab6939803ad7956e76d1318a8022a0082802f320c005148302b9b4a72bc065a54066673192906e80f360abd1e7fc940000200049444154e900630a92540170beed5bb0f92fc0aef2fd83a6d2dfbd52df710cfeab06e79975ab22a00828028a8015814071692228109502a904b8ac14c80241946f9f83e13f509a0f015500e64325f1593b5e68f67f1acc2f932331c5afa6f54ef8fd51e9af92bb2a29028a8022a008a403015a538365f51245c3a008dc012c1b6c21d60758060e83a9048c82956e414015805b0099fd93297f4f8159f0a70b6ca5f2da0de8f0f78854d4ad47b19f8075bc0e50041401454011708f005b07d31a101ebb82c0c0eb6e76e473bc19ccd440c60344c04a73105005600e1873de32d5efafc07bc1d694bf50798bc9f737c57e50f6574911500414014520bd087061c5cc0096088e8c754b2c3aeee600f4c532738b0a80a606de82982a00b700823f5780ff1cfc08985f1c4732f9fe1d47a5811dfe1003a094bf08ccccc491973c8140a4516424856546e2d00ef1cf587cac7a62fe02a357a6082c110289788006d334280c25c0457d00fe30991ac8d5ff29f03058691681a022f11504584deaf1596614a923b16c6545fd26a96d3d849ed6ae32041de7d38dfe41600639c78c388e4cf6c9347290a7d1a0847f93e3b12923f459ef8155cb8a835508526a322d4dd9d12c18aa33a64aff5c8d9e8922903f08f059cb672e1580b1ebef998a8196abe3b39ccff573e09f825dd517c6b8bc275500be7a8bb7e34f36f959fdd58fe7ff2b54d529b56d87a4bcba6bfe01fa694e2130139f866f710091c657c0dd26e23832d18bce645000a606cdea7fbe0e65ecf6c8aa6525e5cd461108f1150fa950f93229ad5a8ecf6819520b414e7d19f4647d8d009fb97cf646f0db0c8f5e7473ae7ca6f3d9fe21f855373b14c2185500bebccb6c26c12fc8ae2f3f5af85db0b41e5ae85d52ddb44b9bfc2c0c534e6c894546656aec924c8e9c93c9e17358595c42a4f15589c2d40f1ba3f51a681148280d57cc585a0698bb4c05a0bc761d0a426dc3eb5aa31c6880a8154e1da008581160d6159fbd54d06f2033201a1eb4ee83017cb6f3197f01dc0d2e78d21880c45780d1a24f82e9fba722e048f4435537ef4397bf0735e5cf11297f6f8c4d8fcb1484fef0d55764f0ca1f65b8f77599183a69228ce3f0f143faa77601701fc411a0343d795da6462f18e67bce499701db9daa22901ab4ba9722904480fd028a433546f89bd4407ba960c674b1b26b1f58b30200822a000001b413cc823f8cfa0f801da90cabb9c6150f4b65fd463cc8154247b07cb89139c4e1b1cb32dcf3b20c76ff5146aebd698474a2c0488a427f81eba4cb80ab93f0d8451ce30bac58fa4c0c01dd06c52515aa082c809b7eac08b8412088d4c0a2a2a0b1c0b92c155c8b7969f9664060c264e7e640793a46a597483beeedb3609a8668097024fa7aeb3b8ec3fc7f10c15f6c3ca5944b08307568fcc649b971e9f758f5bf000bc0792390337d0d0c2a8c4686e16aa022700175cd6f202c20002500b5ce61515252041401ef087001168415805939e1f1cba67ba065162ef01894c31c42360c2ae8024185ae0030699fe97e3f0277811d890fea9a96fd68f17bbfb6f87544ca9f1b19c93f72ed0d19b8f85b191bf8c0a4f32df99922a620069f25239893694c8c1760a5b3a2220d145cf2fba107cc790412d6b4ea842b0001bc54b62dc4951babbbf680e90ab09615c498bca4425700b6e2aefe047c27d88a4559cd2ae3f7af44ea9ffa7073ebf7c0a0be21acf8072efd0ec17e6711db379dd50ba06b806d4ea9045021280a94602593a87496d513d3832b02398800ab04e2a18cdfd3652802b0aed989a981d4b8e90ae8b50fcfcf1156a1979f976dae8ac120df013f03a65fc89118f5cf263f8cfca7ef562957109881c03f2f37b0ea1fbcf2a289ee4f39b82f0397ccc242cc206065b3389492127ccfccc32c03c7d22915817c45800bb260490ddc7993460960668e8528fbe80a6061a093e0826c1b5cc80ac021dc7406fe6d043b125767d5cb7663f5ff8046fd3b22e5af8d8cba1f1bf848fabff88509f48b4686fc7582b36793a83f701d8a009400642630c5890f33b6425552041401770804820cacad44f64d3f147d58f7ed29bc8cf9e26a8ecd825824a8e0a8509f304cf57b00bcd9cd1d2fadec90da960310fecbdd0cd7313e40201e9d9491be77a4ffc22f6572e8b41bbfe0bc675d162a918ee606d9b0b25d5677364b4de557ad3f639353d27d6d402e5cbd2e177aaecbe0c8388e955a26c134aa0e0e763f6f729beb116752d5b40381a695f39e977ea8082802b723c067349fd5ace5c1605b1744194059402b40c1d50628440520841b7d37f87e700dd89182a15a04fe1d90cac61d2687db71b06ef4050234ff8df4bd2dd7cfff0c857dcea4744ead8d75b275ed72d9be768579a502b0aaa3596aab6e510026a000f4410180f03f7bf91ab857ce755f9393e7bba577c0bbc581590aa3fd0850846b8075ceab97ed5197404a7750772a4404586783cfea1a28004cbf65e68d852803280bde03ff1338022e182a4405802521a9f1adb5dde564ad7f2a008972aeb63d747bb611a0f01fe5ca1f66ff54847f636d956c83d03fb66fab1cdeb951d6ad6893fa9a8557e1551565b2b1abc37034169381a131f9a2a74fdefce48cbcfcde49f9f0f445e9bb617d087d05360afe89c153265071261e3399271a17f01588f40f45604104f8ace6339b16003e0b5c640550165026bc0f666a60c150a1c500d0e7c3a03f06ffb14394239556b6a3cbdf7d30c5ee547fac2352fed848e13f36f031ccfebf3202d4cb59555796cb8ef52be599e307e4fb8f1d91070eee9035cb5ba5bc94062377140804840a41674ba36c5edd299b57754a733d7df94532064bc1c49497c545dc3420621f8200fc9a6c80c2d58d9222a008d811a0c2ccd81a6605b07ba785b810665a601ff853b0971f2a86e72e159a02c08a7f3f02efb1dd320662d5b51d96bacee348cfb22609d8a6d3ed4b80c004ccfd03177e2d13374e40eb779fdadbda54274fddb3577efce43179f4eedd66355fe641f0cf7769a5b3b103540436adea9026280291e9a80c8d4d98d7f9f6b9fdb31993d2c486277ca0a912703b42fa8922301f020ca02dc6733b668a6f5d8232607d1ef021cfe01dc602144c85c04252009a7063bf097e0abcb04d171b49e5356b4dd47f059ab96827370389afffa3bf6f080174c3bdafb9a90676f35a56b635c9b71fbc4b7ef2e471d9bb658d549697dedc968e37542496c322b0058a40577bb3d04d70b57f4826c3ee1719bc365502d27137748e4242c0a46b23d33f3c7ad9d4dc7071ed540206c005931658480ac09db8b15cfd6f023b1257fc75ed47a506e57ed9b845c9ff084c0c7d8e3cff7f3539f56ecf763dfcfb3f7ceca87cf7a1c326c2dfed7ea98c2b2f0bc9cab665b2baa3c564095ce9bb21a3700bb8a5a412c0ef666945ab291ce4765f1da70814260245262d30363d66b202120dbe1c91e0c2907e36a6059e771c99271b0b450168c7fdfa0ef82130cbff3a5011dab76e45b95f74faab62b6a0522e20c080bfd1ebefb989fa95504950766d5c253f79ea983c73ef7e93e6b714d7588c18016617acee6c31e770b57f506e0c8fb93e34950076152c296b8212d0a6d5285d23a7030b150196090ea03db729b6856aa02e8859014cdfa115c01a3ce0623e5f0f291405e01edc05b6fa5d65bb1ba1f266d3eca76ad92e7c714a6cc375bb4f10600e3d23e7a7a768c173a6e6861a79f691bbe53b58f937d5553b0fcec0d6869a2a598700c396c65a198002d00b4520eeb27600cb9c521108c10a10aa68c1d9b19aa99222a0082c844000955be3d1296305609aad85b840a4d997f9c3b404e435158202c0653c57fff7811dc3a813cd7e0e487de7bd5865599304f2fa8b916b17c788dfc9e173e6476e3bf75258001898c7a87f46ff6783982db0a10bb5051017303619367101e188bbfe046c7bca0719b354f47b9a8dbba7c7cc2504b89063102d956756db749116c855c12098190123b974ad5ecf35df1500b67e3c0efe0178850d9cd2ea95c20a6cdaecc78694ffb65379e30f7c6ae40b6b7b5f06e04d41d852f8d21c4fd37c3628585c6c8a0bad5bd12ac3c80eb87815cd815c290133c6d241a587552ad90e5549115004164680addb67501a786ab640d0c223cd162e1469096079605a01522bed891dfd4ef9ae00b076ef77c1f7821dedf9d410ebdaef36a97f7caf945b08b05f4351a058c21368ac336ef7f58d4d84a5a23c6452fe6892cf26b5202e80d9085e948044ff00ba3b664c3c807e67d37307896b343c64ca3147b05a9c1ab960ba4752b14cfa91237037c56181091497ccd66650374c7ad0cfdc2c6c16c4df486c9aadb8991618b11d2c190b700203bd55f2b2cdeca3edf9ac007059773f98abff0e1be615751b4cda5f395afe2ae52602ac9bcf485ffec06dbe3ee6e4b3384f670bebfcb7493098dd9f422a4a000b1fb1a5302b563233808d5094bc21407330db3187c72f2386e4244a48bf85c6516f20a0f45d194350e968ff7b787d5fc66f7c2ce3d83e3ef8a9e1c9e1d3a6d29c5106d0c089b118b442f15e28f913015a01a808b0381063862cc40523eb7e331b802d83f3d20a90cfdfd695b869df031f053baefe6942ad6b3f2235cdfbcd8f18e3957210015a018a4baa910930881f397d7dcec53fe87b67b39f8db315fbb27dc9292901588932338091cea14a28012860a5e40e01068c52c00ff5bc2c23a81f31d2fbba69203531f4991112acbd40b7122bc991d94d927f4f4f253a374e400960f6c9d428ad03b39d1ca104f01ea822e0ee1e2cf5a8009480d8f4306a035c308b05cbf1691a640c00ad00de1b7b5826f7c3e67c550058daf141f0b360a6003a5245dd26a4fddd276555daedcf11a81cd8688a7f20a29e56003eac9d28168bc3ec3e6952f31814c8f4c06c532a4a00f39c8d1200c1c3ec00a63e292d8c001b2d4d0e9f85e07f416e5c7aceacf6b92a64e3189bd2f8d559674cd12962cfbaf3642a0dec44c94aa2fc2e72c5a9e41f0412561a5a01ba71af7a6d2796b4025cc0405a01e2b61d726d7bbe2a00ab7123b8fa3f02767caa278afe60f5dfb24f57ffb9f6ed9de77cf9c00d1a5fdf9809f899814bc089588c87829f95fa5812d80f949a12306256a825a58d4609602954a5db11884c5c93e1ab7f92c1cbbf37e67ef65a8043f8f6815e3fc11cb41224dbd052f9a41580d6450a1d25ff20400b8d2911ecce0ac08c00d603604680f38ac23f97e8fa4cf251016004e7436006ffb5da90a8a8df82c8fffb104dcd6c41a57c4080abaf22046885c71010e8a2f8c7d8e4942906b465f5725f5801780f924a40dfe0887c71a5cf9410b6dd1b0a2006373133a0a4bcc936bca0b67355ce5e1183dd7f344c0b804d394c09a09b8ac0e544ca196ad09794369800b494e6d39dd28e8051c818304c2b80fdf9404d9ab10017c1b402c4c07943f9a800308a2fb9fa77bcbe6069ddacef7f2fb474c712017973c30be542687e8d47610518bd085fdfa4e3653316805dffb6ae5d2e2d0d2c07ee0fa212d0b1ac412ef6f6cbf96eac546d04e143337651519151028a434b5fe4c8768ad9d8ce40c991de3760eeff17d31ed6e61a4ac739d295c0e346c6af202075c22801c152369c53f20302092bc008ac848c05b096e466460063013e01e79515c05140fae146793c073adc8e83a9005857ff8992bf5cfd5bc3043c9e860ecf36020c8a6301103e8099be6523d60648b6f12dc97246c0dc736d5f562ff5d595720e0a004b07db88160006b7f1da43551d051d14188fa1de0302f4d823e246f71fe0f73fed26f0cb06b1a7edcc4631df3f2867a5bc1f085255ca3e025cf0d14d96b012f6d84e8872927e9cd3e0bcca08c83705a00d37e8dbe06360e7c87f68e3f5ed47a5ba798f89a0c678a53c4380693f51e4fd3238cb6a05402c003b016e59b35c96a175af5f88ab792a0195e5654609b80e97808de258714ea35c30fdcfa1cab682fc7e33979f11fe372ec1d78f08ff44da577632b9124a196202a09471b1c1efa552f611a0ab9029a089e783d50ac01cdb7ef04760c604e405e59b0270187785abff2edbdda96cdc8e92bf58fda3a98a527e22c007ae5b2bc00c32072651856f456b936c464600abf4f9854a8241b802ea712d0139dbdd2b43a313d653633c00fddea66700fa5b144a343aabbdd1ea6322fc11e8377ee353e0c03cfdec1295b2285c02f43f87f0cc0904355323bb77448c62cc678429f064b71272415904fe1c7c26dbe79eaee3fbe729b7f82b62d4d337c00f831dc36ee98babefc0ea7fd96e2320167f689dc1af0878b1028c2318b0baa25cb6c20ad0988526414e185694951a4b004b05d31d308eb805679a81f5030b159a9e592e18f12ef94e547a28f069ee1fea7971d6f4ee3d668b0a573b324236233364dbba15a673242d432b50ad913122bc17f1785ca6a331a40dbab72af0fce89ee1bd30dd1c217c94b28b80b102dcb4125aad00f4df3077f063b05d0bcfeea5b93a7a3e2900fb70c5cf8237d8aebcb20191ff68f8a3ab7f1b52b9bfdd8b15201e47fd0054085cd3d98c66419d500ea9f0fb876aab2a4c76005b08333380e7ea4489b2b683a6443295807cae14c8f4bea19e976400817e63031f1ad3ae1336f36dababae905d9b56cbe34776cbd78eed93470eed92070e6c97e3fbb6c9e13b36c981ad6b651f78f7e6d5b2656da734d456c9e8f8a43095d42d19cb0cca0db3e688666ab8452d73e368214c5607749111c08525354ac6015c00e73ce58b0240a7edd3e027c08e0e3606e1d4b61d42d53fe6fd6be47fce7f835d5c80372b40d8b408e6caafa6d2f1abe4e2c8e91fc2be0535e860c8cc80ee6b0358893aaf4013e582074c3060084a40bee5a4cf4def1bea7edef87367907ae78592dd219fb9f7a0fce0d123f21484ffc1edeb657547b3b435d54b23043d99efbbda9719cbc0ae8dab8ca588160196951e181933aff6e3ce987a012cd6442540e301ec88657a04efc57478c0341273d12380d5011955cc58009b192ed3a7bee8f9f34501d80624be0fde6143a4bc762d56ffc7a40c9dff940a03012f5600560764e0dda6ae0e59b3bcd57700d12a41f744b038110fe02628909502a3915109952f4b1409ca937af5e948ef6b0296c7f66e951f3e7654be71df01930a5a51665f183046a4a9aec6b4956637477a027a90a56177cdc02b83e254b404b09533eb8fb0899552f610e04290699b4c196699670b715540c1cf94406bfa8065aeac6fce876f1e6f0857fecf801d736ca8e9d5b6de6998be1fa5c241c0580150cbdd4dbb603ec43b9a1b643bac0065a80fe037e28a953502a6a6a6e5f4a5abc2424636a2c0613f93529a9e733c1f9dae0d3eac07b1e24f35bd2f00258fada0bf75ff9df2e74fdc2387766e94fa1aefcd9458459281a36b6795c59eeb374c5747dbfd60602215532e440a213ec38647b6b717d30a00e1cfe7838b72d0fca25c02530998cef6b92fe6f8f9a000ac0300f4fd3306c0d1695b5ad56956ffecfca7545808f0614b62d7b7c884730d7006dab1491083c0a808f891aa9016d80081d53b30648202a3314bb01bbade4591f2444588a6e75c8d42677adf58ff0772e3f2ef50d237b5f43ec6521cd8b64ebe0f73ffb71ebc4b3674b5cb626b3f34d656c365d022539108ee479fdd1280e04c5a6628fca904d017ad943d04b8208cc7268c02c0a64f16a2023006a61bc06a32b0cc95d5cdb9ae00b0f0cfbde06f819905b020b12e37a3fe6bdb0e9bfce80507ea86bc4580d5bfa25337b07a84966fe9073e0525a0abbd59b621fa3bdbad8217ba21752810540c5700ad0057fbad0f2d530b211e9d32ad83998a966ba981e1f11e1962511f08ff54d3fb58ece9e9e3fbe5c74f1d937bf76d4d6bcd0706115211b8022b40a27cb3738f01a606a289b051004aca1c1f5f0b7d05f4f3342240191199e841a7c08b98d531b6860b4d6a6c9f83d923c07130b6fb96725d016801b214fe2cfce3d8fd24845ce8ba8ea35285fc7f6dd5e9dbef63464f8c01700c109b1aa3af8f353d16a6f1a9b0f081be6ddd4af3505f7864f6b650f833127d329c7005b889464f989e8b6105580145b8367b27efe1c85c294f0c7e8a063ecfa59cdec7d4bd1deb57caf71e3e2ccf3e72b7ecc07dcd847b874a19a50395b26b3786ad574925e0a615409b0659f1cae400b340604a20dc00ace068215a01589ffb0330ad013949b9ae00d0ecff1df06a1bfa958d5b51f9ef1ea4de2cb30dd5ed798c40310ab03017dbe6eb63501799c1801b5118c8afc4ea854d58755e1f1c957397af4924ea1c014fff26fb05044a2a4d3c80dfb30212ddfb5e96818bbf95d1810f524aef6b69ac9587eedc293f82afffd1c3bb8c5b87819e99200607d20ac0fe12a72f5eb5ba0298a5c1d8a4f29ad526283013e7a473ba43800bc322fc0b8f5f4ad49070de8d0b4efaff6901f8c279a87fb7e6b202c0e0bf27c10c0074ccd7e24a87a6ff44d95ff5b5f9f7eb98f933a3af8f51d8740344512ed78912c180f566e5c815a45f89960afab0cf60d579a5cfdeab84abce3830606d00530b2343c270317851304ea27b1f83fc18ec9770db382b37b71e8f986c8402f71df8f97ff8f85193c35f8d14ca4c53554519ac479570050c9a264e5164963811e353ca6bd718ab8cd338dd967904181b937413f2376221ca9d0b605a017232183097150046f271f5bf07ec48e5b5eb11fc771c3fb04ec771bab13010e00337823ef08c2467a5bc858895ded82590c180cbe13bf62bb14430eb034ca1a1d1e94bbd3282e23436a289930d93caaa918beeb30635b4d08c5e7bd374ef1be97b1b8a9a5da9b9f57ae91a39b26bb3fce0b123f2ccf10326e29f2e93a5a25a28656e5d018c4729abee928afa0d391797b154782ed571188cc972d2262570b2cf76582a00f4f3b032a075b06db26c6ccf6505e06e00f60db0a34ddfa4feb5dd85d4bf83c6d4960d90f598fe42c044fcc2af3c3972de44623b9ddd34a2ebd7af68936d6b57483104ad5fa91cb9ebcb509466100569ce400970552510d1cec1922ab80256f8a228d60c3215188035d8fd4704fa3d2793439f1b4b8557cc59ace79b4cef7bf21eb91b4a009581a5a6a42ba017710027ce5d366583173a07a635d212c3ec244d4f5e08a5a5fb9c5680444ae0793729813cb113e0934b7786e93b52ae2a000c99fd3af87eb0a34ddfa4fe75dc2315b00228290244c044bfc3c11f4630a0ad5530db04b722e77e2702c86a903ee667a2d999e98bf43d5f4695401b312090c2876981a10ac6d3668f189760d2fbd0bd6ff8eaab2975efa3797fefe63508f23b2cdf7de890b1dc304f3f5b445700cb367ff8f905b901c5cc891808585eb356e3009c405aa26d5c34f2b7c1382197298157706a1f822796e814d376985c550068f6a7f9df22d58ba4aae90ea9d3d4bfb47d61f2652206bfb145ec14ac0014820b114bed9642a86e59d329ab501ad6cfc4c0b67a2801e1e969130f303c667f1ed11550142c350181d9ea159048ef7b01267fa6f77d9252f7be8e650df2c4913d26bdef81833b4ca1243fdc2ba6937e7afeb29c4580a613d112430b00e33294b28f00d333c363dd0937a1f3e97001ca60015a00e053cc2dca4505807d341f033f0576b4ed054b1ba4aefd0894809d5a6e33b7be97193f5b96ff641df94430a0b38f9956000aff1debbb165d3026d317c6d4b66644bd0f8e8c1b4b80dd15103159010c94a52520593029d3e7c9f96308469c183c298358f5b37d6f78bc1b3119968246b79c5859698971cf7c072bfe1f3c7ab7dc811afd7e0ad8a452f6e1e98bf201ac004e144081a68afa4d2616c0699c6e5b1a046805609030dd84f19835a68691a5e7c1b402788b545d9acb59f028fe756a2e78cab2029bf682adcb3156d82aaf5be70bffe6c297a35bb28500dd43f47f5b0a48ca00ccb81fe121dedd6737ab67eb5ae61e77254ad33e7ce80e582d96cffd78c1f7ac8c3872ed2d284317161c93ee0d11585f18dd7fedf4dfca205af732f0cf2b35d7d7c8a3e8d8f73f3ffb286af91f917588d5f05b9c4635dc00acda68239399018554c91f08708140d9e1b2670c651165121f263945b9a8006c04c29bc18ee76e346a98d4ca2add3d0473eaaee9c9a6058192b265880d59ebaa163b0bbb9c816f3d1788abce9d1bba8c1240d3b89510f53c31fcb930e27e3a85887bebfc7306c46311994070dfc0855f49ff17bf9835f97b137c8ce65fbfb2cda4f6fd4fdf7b541ebaeb8eb456f49b73ba8b7ecb180437710831087f5a4494fc830065472230d31afb4359449944d99453e428447d78256cfbbb1bbcda766ea595edb8791ba538546d1baadb0b14016af965356b8cffdb06014bbb7e7ce6a2e9ff6e1beb87ed4c0b7c1882f1d8be2d308987aca714439f80d1be7764e2c649532dd1ba430a03a85c0c5ffd93f49df97b44f9ffd1da9361be4330c6e1d89e2df2df7feb21f9c953c74d8d06063efa95d82a986c2356a874d184c6368d6e4f2302941d942194252e883289b289322a6728d714009a58b6821d4166452756d62aabce398b4cce7c71f2e544e9f7e677a50839f14ec4dcfa4fce5e968bbdfd4ec37cb56d0dbadd5109d88062386e883ef8d1ebefa624981de747c605f3aa59cdeffab97fc431de31ed701df7996723bbee7df7e143f21f7ff8843c73ef01695f563fcf287f7dc4f2cc6eba353228d5ef5519fd85ecd29c0d6588793e40a658883289b229a7844ef672642c682eb09951ff6b17d876f3e320fa6c97c3fcaf0d366e42a26f16402018fa32fd2a32e16ce23fd77dcd74dedbead2b7bec02197ec6356c23bb06dbd51027a5021d0569b9e95cf46d1698f456982650da673e0624f36161995f1a15332dcf30ae67e0f8155f6a645b71e933e7466613c7974af3c71748fac6c732cfd71ebee59fdbb0f7500ae0dd87b0270b5e9b7824c5905ce2707a70ca12c19edff703635d5f1c4289b28a34e388ef2d1c65cb20050c3da01eeb2e1675675d55cd5f9d73468bb06ddbe4408c05f6e82015da45f5dbcda2f9fc20a30eaa2d2de129dbdf530cd0d358805d82977ee58efca17cdd4485a01121dd1acd33b0ea042c5823e7d67fe4e8660fa4f45f8b735d5cbd78eef33abfeef21bf3f97843fc1397fe51a3a033aa700721cb33072a53913cfb750c89469862ca14c71415d184319e568a17631cf920dc92505c09df9df94375d2521777e9b25035a0fe45f04e8e32bab5965cd16199d983455dd72c90d40d437ac6c375600ba04dcd0e4f0590404be63d2a0dc8cbf750cd32bc7063e91ebe77f2efd177e6d82fe6ced976f9da314c173acbef8e3278fc9bffff643721cad7b19d7904bc454cc8fcf5c924b2e8a32952065995500591089f8b12aa2923f10a02c29ab5e657513e26c936e802e7f9cb9fd2c72c905e0cafc5f02f3bf31616af09ffdeeeb0883004dafe5307bd3dcc7a2344e946b6e005e0bfb191c45e0dc67177b842669a6353a118510ad006c50777087c4000020004944415453d3bc1f0f3ef78f89e9c9eb269b60e8ea2ba6990f8599576aaaab96bb766c9027eed92b47776f96169438ce45fa1c78bf77eabc8c210ec04661584b062fffc1582d199cca9814d63131d6a98a56f35e63046c2866667b10b2843285b2c5e626c419d00d40667f00df9335b2c1275740cd8a857f1e04973a9d5345dd7ad4fdbf4bdbfe3a81a4db6e43208e862c2cfd199970560026c3d3b2babdd9a4d9b14260ae10cbe456401138d7dd27177afa049d8e1d8979e96c8c52863a09c190dda2c928f6a9917330f9ffc198fdf99e9f79a100dc31ab61a5f816ebf8a375ef2128012c6f9c8b4425eb172fbc2dfff2da87d696c0bcbe44d19973509a4ea338d229a4479e30a999accd90fc5ec6a6d1c089c182b01464aa9d712e629df9732ebad941d48502c0a24017c0ef83aded043126ab942b0ac006a0f40df04e27b4e8afa96ede2735ad07f043b117df709a4bb71516027cb08621fca746ce3a9a5f99d24553f476f40668ceb195293bd4852351e1ca746874dcf10633252d86864914fea5f07f7255ba10d1b73f7afd6db98128ffe16b6f4098792fea538b3e0b07b6ad93ef3f7a44be85f6bd1bbada7d5f7571213cf8f98bef7e2afff9172f98a051a7714edbd8b6da34a541ebea09b446a6321099ba8eca7453e67e048aa908e49217d7e96afdbdada8b804a581afa032e039c70ea2b80a2e50f903f8086c0ffec0a06c52ae28007701a4af811d9d98211476a945ddff4a94d4c42f239bb8eab1730c012a003153faf39c35458dd1f5dbd62e37422a972eb3b4a4c414cca16ffaf30b3dd68e8189c234e8858054a850f9fc91f7ac973e78e579d3ba97657d5df450bf0db24eb45a7efaf87e53c7ff5ef8fa97a1c25f2e139bfffcf5cf9e97d73e423743f4924807b15f05db2287691180421099b8060b4bc4640e14a38cb052661160eb6cd6b198427c0cfb675888cd453e019fb28ccbfae65c50005c9bff59bab1b6f550d63b9b65fdaeea09a484806b37001abcb045f0ee4dab2408652097882bed00da1a7f0605a01ba98136a22ba03858092560395e69dd4c10ad036cdc3380063e433d2fcffa46bd093bd6ecdf014bcaf71e3e8c0e7e77cb8e752b85bd0c7295d8f9efb9373f92fffd1fff202fbd7752d84322ddc4e040c6684c8d5d32dd2ce3d129f8a61b348320dd40df3a1f1694b4bc2494afde5bb7defa77ceb80172e1e9b50ee87e13ec6cfe2f0a2260690f140098ffe73ca86ebd33fab722b01002c60d300e331fccad585e2d34cc5476eb686e308d6772d1475d8b7800760aa412303ee9eca6e48a9e0fbe50790b2aa2b5c1b0566c569fc3575f4639df7f362d7ce351e7a0c2f9806c41c3a287eedc293f82afffd1c3bb8478e6b25ffb3c6a44fcc31fde90ff04e1ffda47a75d55ff9b0f17d79fe1fb494580edacf9ca2c02ad7be21abd940606100c4b8bd7e430dc00b2f0f3011b936e800ff0be2fa5832dd14eb9a0001c001634ffb73a61c2084db6fdad68d8a27e3127a074db82085001a0cf950a0057be4e54077f3a57afb99697ce6be2cabb127ce1ea75e3a39e41a53e272216458801a012c0c64183c8ed67239fa931743ff598ae46f7c9465426fc0efcfc3f7cfca8ecdbba5618a098ab343115369dfefee637afc8dffeeed545f9fc53c180ca5904151cd94c89bd2d42e5ec4ba3940904f81b880267a6c9da9e0f383e356bc6017c9e897349d79ceef37bd275446ff3d0b9c5260b5db6ddb83a29adec342b14db58ddae082c8440097cdd7c90329dcd892e23b7fb52aff76037a7399772db7ad406b8ffc0763979bedb2ab42864c651098d297db1e951991c3aedc60f7adbe534d456c981adeb4c35bf7bf76d93d6a6badbc6e4d207acacf81282fd7e8668ffd7e1ef676c4536c8547044dd06faa98b4b2a4dca5a36ce23df8f49eb17650c650d170a16eac276caaee7c1ceab090cc816f95d016017866d60e72705226143a8e41642beac9222b018044265cd26e06d62d079965e9477658320ae00fdd47fdef9acbfdc5a595e2ac7f66e35858d28c86cb9ea8c3e8ff4e2a1e7e01af972f6dbdf75b52fbb59ca77cbeae5c2e3e72ac5627139dbdd2bbf7cf11df9059859156e1afe64f27a191bc072b52ce1dcd4f5389e856d993c5cc1ce4d1943592348d3b4fc1628b328bb28c3cefa1530bfbb00f600389aff3b9d0064aa526deb9d52d5b843cdff4e40e9362b025c4531c06a02ab5c27f376341683dfbaded403e0ca3617a9a6920636412cc015e9b96ed1784ce5006757c17c18d0bcbf77f31a04f91d96ef3e744836afee74559278beb9fcf019d3275f878fffa730f9ffe3f36f1aeb492ceee80f763c6db60a667a265d4accd2a03b269662e6c04c9c698309ab14055571496e7e2f1d01cbf246e3269cec4db809111f63219a84e80660d0802fc9cf16008603b3bff26a1b7225152dd0ca60fef750b1cc36a76e2f4c0402c13263e22b29ad97c8e43547102ef45c978bf0a3af5d9e9b96a740a008990cabe10ad881ebe897eb83238ed7eb7563c7b20679f0ce1df2242afaeddab82a678bfa24af9b6e9f7f7ef95db3eaffe4ec2561a73fafc4188876e0b261659bb034736b639d54559419a5683a1a4350e6146a344c98c64ddd381e03357b07865c1f86a6e9a12b2f98fa0df59df7aa12e01a3977032963286b2873187c6921ca2ecab097c0e94f09c1a48b253f2b008c66a109a5c97691a5307795aaf9df06936e7789400982ddf803b7290014fe5402729998737fffc11df2fe675fc81fdef848e296804037d75a565a229b10e8f704baf73d89ee7dacee578cd4c35c25ba794e9ebf22bf7ce96d23fc53bde71d685f7c27aa1b1ebe63a32924450560befe06935311e98332d6dd37206f7e72465e78fb045a515fb296704ee2cbef2d0b3295a1cd7555e3f6e4c7fa9a2604286b2873180b6321ca2eca30cab26ecbd8ac6cf6b30b602710791abcca091956fcab693d880a807bd402e004946e738d00abab4d8d9e4f54fd72d86b0af50036adea907d5bd6e6b4599b69811472a7b0da647ae062a8190ac57dfbb79b52be8f1fd923cb5b9b84257e7395181f41c5e8bffeea45f9cd9f3e90abfd3657c9ed571a2c2e961d1b56ca0f1e3b2acf3e7ab71cd9b519d9236833bb40cd035a09e8125801ec36e3fbb5114c05ea4adfa03556237974a666b27a636925ea37a82b20094b5a5e6fa60b430160c54c07e2179f6635ba012e3a8ccbda26bf2a005c2e1c033f05ae75422784884c16ff29af5deb344cb72902ae11303ff0b1cb892e760e3f70ae9659c5ee8e8d5d92ab710004857ee8fa9a4ad328e8f38b5785a668af545c1c90752b5ae55b0fdc257ff6f83d72603b7a72a0e850ae1203fdce5cbe2afff0dcebf27ffdfa6579ebc459d7c277ee3557c3bc7f7cff56f977df7840a81051a87b291ec5c248dc875694daaa4ae91f1a31ee81b9c798efbda91cc8fa00080a2c453f07758fce87526a9f11cb64ef8658c4ea36a32c6355402a01de8368523b45d77bf9550168c4153c03be07ec788e15751b51fe17cd7f5007404911480702b40024ea01a0ec27d2de9ca806428ef50056a141502e1303021980c680402f3e675e733d1af6b07bdf0f50c7ff1bf71d348a0057bdb94ae908f463a3a8ad6b96cb33c70fc88fd0d2f8f0ce4d8bca16a182b9797587948542721ed92703c3cedf4b62cfb4cd2214482b432967160a524a1f02719466364d9a5088c9422c727109fc2e7871e635cb8152d9ecd75fe9565cccd7c16c02b420f1cb5dd3b25f6a5bd8fc27774b882e7881ba216b08b0f31a0b7ed8e20068e3a30240ce65624020ab1a3200edb32f7a5c97b1e5eaf4ebf71d901f43c8b1e5305bf9e63231d0ef6788eeffcfbf7cc1e4f8db5a27cf77ad8cab388e3a077ff6f8d15985a80d39fafca62c8ecaa05474a26262946988977a1184686bb53c2371d3d0a9164ac04a7d462e0efeafec9db012a22aa0890370cc02a18c6514272d00566de12b0759823ffcaa001cc4b53f0e765c56d1bc55db7608cd7f586f414911482302c8aba602c0dadf4e14467740e6b5ef4745bb5c5ef5f21aabca9101012173fad255f9022d839d8863e9fa78d6d4f13f2c5bd7ae401a9b9f638a9dae064b33c4407c74fa12aaf9fd497efadb3f21e8eeb2e7dc7e0af9b59dadf2cdd976c677ee589ff6cc874ae04e05e33a5c01672ef75add35f118958419d3d659ab043a7f07bc6ce5823361253ceda62a20d3453e049ff4728ca518ebc75f2c7d262bc08eb9ff04a7140519c84a8a40ba1108220d305886205eb8039c0a7e841108c8742d466d2f473c40ae13f3f41fba6b27f2db7b4d6ae07cd7d3d6542ff71dd8660afbecddb266de48f6f9f6f3eb67c98a7e2ceac31c7f37e6f55baf85417b4c757c12990f0fa2c7017b1b648a567736a37fc26ef914551cdff9d49e623e358280d6e1d35251b7015fe7924c9d56c1cd9b943fd353fdb66ba72ca34ca36c733417d8264af7763f2a00fce5ac02b30ba023b1da9556bc72844837a68800b34b1857521cac421c8073a00fcdc6975116381f14801a64043c726897090864005c0fa2de191047e2b60d28214c01f7e43d7b4cfd835cb67aa4aba21feffb6377ef36f50eb6c112429c3249c47c1f142fdea7ee6b37ac99095104aa4d8d5e34816b25da2b206db7e6a6fc19a075df9128cb28d328dbacda82e34c69dee8470560aeb6b4e0e516a1621bebb607438e49020beeaf1b14011b02ecae4625c09502809ced7c21a6a8b1452f23cf3ffbe28ac93f676a1afdfd3b37749978879686dcfedd31d0efdd93e791dbff8e3c87343f7b25c4dbef2ecb19d362c2553f99e58e978a1a116bf120ea377c74faa2fcf32bef212ec03973233cde23e189ab78663a7a5597eaf4f3e238943d944194453371c73a3f73addaaa0058ee3e158076cb1823f8f980d6f4161b52ba3d550428fcf91db3c50130379c6e009684cde58237737162754332eb02303030999b9e8b7d0fe65e17dfa7a3a21f2bf81ddfb7d508fefddbd6496316ca41f3fef01c3e3e73d1dad02902e11f19bf2a8272e94ae94180b287cf072a022e9a0351a651b63116c037e4470b40122847904aca13ab33c741ba5111580402490b806d8af1c9b0f4f60fc9c8d8a4c9a7b78dcfa5edcce5cfe57cfeb958a7a3a25f281894752b5b6faefa59fba0049f6583cacb42a69433ad10e7baaf399e42343c848c963e8963a5ca7e174ae941c02c12208b5c2800ae16b6e9392bf7b364e79bbbf0f9b17208f3a9ac1134c9d5d9c253e91645607108b0c914bf67d4f467e251c7c91848d60766411d25ff21c0204db6eefdb969dd9b5aa01f57f90751e088258e8feddd62eaf867fb4ae9aea12580c59c9c3a12b25b603482788ec8a804f09d564a0f026e1709381a651a651b659c6fea01f84d01605715464b5a55d404f0d63601984a4911480d01464c331ba0b8a4da045039cd42e1df37382c1bbaacde2ba769745b0610a07be6672fbc65aafab1b98e93a05ce8f02cf4c4be064fa0b1d116acb8fde20aa1758656089660eeeebbb1d0e99bcfa3e161d3c0864aad527a10f0208728d328db28e3cea7e7e88b9fc56f0a0001a2a9c49102c172e37b292ea132a5a408640e01930e18aa73a100b044ab73b640e6ce52675e088128ca1abff4de49f92fbf7cd16a269f6f0e46f46f47912706f93d7a78972f333d581c886987560500a581a311d6a4514a17029441540228935879d142946d9471aa002c001401b22a0025a50ccea216bbf8ea5a0b9c877eac08180482a575c60a20968240c602002b8092bf106059e3373e3e6d2d6c34df5953a83e8c9a0834f933c7dfafb110ad8df5c2da0c368aa12a2059299d081419594499148e76db267625df6c93a473bb9f2c004c952040561baafaffd3f915d0b99c1028810ba0044a808d46c6274d0cc05438226ce0a2e40f04fa87464d91a6787cc6f509b14b1fbb3c3e01933f57feab3b5ad252cad7f509781c48ff3fd9465c2e15e9a2c90693e7edc93880f0b855014806b8fba62090fd5be3198e947760b18436b0d5ae9f043ce523e98e8a804b048221540484126023a600d20a4081c30e814afe4080c27ca1b6bbf39d6133ea1b1cd9bdc9087e363862d95dbfd3187a02d8fb02a00c5db0c2b0dfaf27d7cecfc38294b28d328e5f2a5ff862fca400303882ec4c28cd4ac083daddca1927dd9a160402c132a300b032603c36e538276300186dae0a80234c4bbab1b5a94ed6a0a0118bf6305d73210aa29df11a44d3278afaec31150fd9172117e8c6c8b80c826d545c5289ca96d6f5956d1add7e0b029445c6256d291b3ebb5b52cea902700b8e04c65aa6aa3858891aed8de86c557acbeefaa7229019049271002ca6e244ac2ee7e641ec34876e4b2f02f4db6f5fb74256a28ae14954359c8f98bab977f31a23fcef3bb05dda97d92d3ef3cd93adcfba518592990e36520b800da1d4b6531651265136d9da87e308947194759fa576b4f4eee5270b401218c72b4cf86473eb07ea7841bad1f70804910540b629005c618ea3ab9c92bf10d8b571b57cf3813be5bffdcbab72069d0e9344bf39f3e84d6f03f8fab7ae592e551565c9cd39f17a6378cc946b769381c28a75546695d28f40522eb950005c2d74d37f86f3cfe82705c0153034b7b8f1c9ce7fb9faa922e01d81e2922ad402b017f8199f9c9209b092bf1048f6366843b4fc9b27cea06a230ae22028909fefdeb45a0edfb1c9bcf7d759bb3b9b4fcf5f960f3ebf80b6c051c71d8a8a8a8df0674d0ba5f42360d285e9961ebb649bdcd542d73649bab6fb4501a0dadd02b6aaa7c1320665590b05a60b1f9d471180bba9cce4f9daa0e0eadfc9cf6cdb5fb7670e01d6eefffa7d074cedfcab038328893b632af931c8cf4d047de6ce2cf599b9faffd3fb9f99b6c0d6598a8ad012f89c0c5e7e4e022616004a6da8da58b682a5b55a1ed80aa0f300b330856c7241947194759479595f2df8450160493f5a00981ee148250cb8701195ed38896e54043c20c0221f54026ca42e001b42d9dd4e41cfa040723ed0fb9f7f21cfbffd895011b0d14c3c2663fd1f4009380d6516c180c6aa5585e0b50629ab5e25e5b56ba5ac72b9510a6c73e9f6db1148b8005c2d4c29e328eb28f3ba6f9f69693ff18b024040c88e14282e37e67f3e90951481a542c0ad0560123500a804707519086891aaa5ba3f85789c13e72ecbfffb8737dcadfe0d4033268b2591c932276090595558509556ad948abaf586a9109836b7701b28b9438032896e00caa878cc5a113029ef54019885977e11b22395c0c4420b809222b0940814e3c75decc202108bc58d02109e9ef6947bbe94d7a2c7ca7d043e3dd72dffc73ffd517ef7da07323631b5b80b9a89a393dd80e189a153525ad126150d5ba4a679bf51063466c03dbcc63a0d19154651300bb992779639d2b239a72c001a0098967bae937844804d81a8e11715a12be08c73b0d5043301c05e8acf783c1d1d5ea0080c8f4dc8ab1f7e267ffffbd7e4e5f74fa53de594b5ec2747ce4b18e9ae93c3e7a5b6ed2ea96dbd5342e574592bd91048060286c77b6c43931600dbb88c6ff78302409f083522fa441c2901b0ab400bc77974a322e015019af65814c8564b9d3de7c9221a6ded15631dbf3002ccf3ffedabefcb4f7ffb27f9e8f44528a2ee4b1b2f3cebfc5ba8084c0c7e2ad1a97e5806faa5aeed30e204ba5cc5c1cc3f63617cea413e51d651e651f6c5b3898e1f14004657b176aa35caca43a0453631d563e7210214fe8c05b02900939188b01f809222900e041857720a058c7ef9e23bf28b17df96f357fad231adab392293d79035f047999eec9386e50f4965e356cd167040ce4380fa5c9937e13065c637f94101605d646bc16dd39b1dc55898c2a2a4082c3502acf6e5a6fae454785aa622d34b7d7a7abc3c4480bd25d8caf8972fbd23af7df8b9e933b1d497c9c236a37def0a4c0ef8fe871017b0518a027e101b4b8d84fd78944d2c1846593513b73e0392724f1500406b550058669179ab45acb7aca4082c310245819014e10168a33084bf2a00369474bb13025104939eebee35ab7e0affcf2ff44878da39f6c469bec56e63e6c058ff87e6fb4fe1565ebb4e9fc3f3804ad944194559158d0ccd33e22b1f251580deaf7cbac47ff841954b02e178e90658ad62e588916ecc1c020106024209b011853f95002545201504d84be2dd93e7ccaaff0f6f7e2c3dd707539926edfbc4a2e3c612c0df40535748ca6a56a5fd18f93021b32628ab3c280059bdecdc51004ce10a0daccaeab7a5800fced53fad0036321600b801941401af085ceaed975fbffc9e11fe9f9cbd94728a5f7d75a5acea6836e58d9bea6a4c7f83e24040184f308a14b501140eba7663482ef45cf7e456a03b60e4da9ba6885063f03109556876c0adf7d8280090552ec8d5c2d7c53c8b1a92430a4042b35ad4d5eace8a408a0870e5431fa88d68015017800d25dd3e1701f6903881dc7e9afb7ff5d2bb72f1eaf5b99b5dbf6fa8a9929d1b56caa19d1b65c7fa95b2021d109b50eab8babc0c752c120ac0081400560eec1d18928fcf5c9457504a98affd43a3ae8e138d0ccbf0d5575141b049ea3bef35ca80ab1d0b6490074bb52a00b3df09574004615a09bad3ac0ae4aba697b99408b8b500a80b6029ef4aee1feb6aff90fc2bcaf932caffad1367e5c688bdacefad57cdaa936b3a5be5b1bb77c9c377dd61ba1a5657de5e2d95a590d91e79794ba3ec90957260db3ad308e9b7af7e60320cbe709961c0ec80e16b6fc00db05aaa1ab7df7a3a05fd37651465950b7225f75cccb3a8217eb000b03037c170240f9a95e33cba5111480501b716800882b5c84a8a801302fc8e9c466b62aefa29fccf5eee4547bf98d32ef36eabafa994bb766c9027d0cef8e8eecdd2becc7d9d142a0354023a9b1b640d5c067ff39b57e4ed4fcfce7b9c5b3f9c1a390777c05ba67220cb062b251048c600b8c083322feb4d29b2ad0030a4dfaa09b1021b9b57680f00175f2b1d92110498fac496aa36621f8078068bb4d88eafdbfd8fc0c0f0a8bcf1f11923fc5f78e7845c1b18f67cd2a5a112d9b0b24d1e38b8c308ffad6b964b49d0fefd9cef409db0087cfbc1bba4b1ae5afeb7ffe737f20e82106d149b6650e0db2810b452eada8fb84a91b5cd990fdb29a328ab5c540d4dcabdac1603cab602c08208b560c7f30894540054a600a6f605cf872f965e43761160e535fe53520416830003efb8eaff0556fd27cf77cf568df436235b18dfb513abfe237be5c8ee4dd2d2c047e8e2880ac57dfbb799c043c6249c44f1211b45503278b4ef1d29af5983d4c035b6e105b19d328ab28a322b161971ba66ca3cde38cac0acd5027014bc4e679fa66d492dc8713a0f7e15c77974a3229032023330cfa2a5aa9222900a028cbeff1891fd34f7fff32befc96594f6f54a8ce45fddd96c56fc4f1ed9231b5775a4b5e744596948ee3bb0dda41efef5cf9e972bd76f389ee20c7e13e328193c7afd5d6404341bc1e7b843816c4cc6ab591400a291947f05ab00305fc29a339148ad70155851205f31bdcca546804d80f8c0535204bc224041fadceb1f19e1ffde67e76568d4fbf3be0ea97dbb37ad9227e1eba7d9bf037efb4c5013dc008fddbd1b2587afc93f3effa6696ce5749c687850c66f9c90aaa69da812b8c16968c16cf320af5cc9bf4c02976d0b802b0002c10af5ff67f25ba0735b1198c1ea5f15002b4c3a600e02cc08f9ec02ebf8bf6bccfee7bbaf492ceebdf70bd3f91e3fb2db98fcb7ad5d2ef345f8cf39eca2dfd2caf0e8e1ddf2295c14ef7c6a8f07884cf44864fc8a2a00b3c8330e8032cb05b9927f2ee6497948b61500a264458af9d76e72b05346417754042c0850f8ab0260014937df44e0fae088fce983cf8ce07f05ad7bf9b757aaaa2833297d4f1cdd03e1bf07857d9626da3e585c2cfbb6ac91c7a004f4f40d5a5d01ec1838397a41aa512888abdf42270ff2ca95fccb249ed956005c6940893aeca599c441e756041c11300a80c6003862a41b11268215fe39e4d3d3d7cf60bfcf104c974a6128a6f3dd0f7f3c05ff5e08e37a14f9594a6246805b57403c860e985000c2e35761055005a0088dc3dc540dc5fd7425ff3279dffda000b8b300b828c39a49a074eec24660268e18007b872f938a956a3a5661239cfb574fdffe079f7d6104ffef5eff50aef43907d1cd77c5654cefeb6a37be7e0aff35cb5b842bf26c105d0177a3b6c09b9f9c812ba3c7f114a627fb85960091f58ee30a61a3db9a21c082b26f6935bb5b6e40b61500570004026cc56a2fc37acbb5e99f8a40da106047b4782c6c9daf126557c94a858500a3fa7ff327d4f1c7caffe33397842577bd5233d2fb0eefda6456fd87efd824cd0d0c12cf1e51f1d8b0a20d99072d560580cd6f1810a82446565166b9200a7feb02d8c53c290fc9b602e00a00b765585346417754042c08c4a313124747341b55c36f4b562a1c044ec1ccff77bf7fd5e4f6bb2da73b179d20eaf4b394aff1f5c3dfbfb1ab436809f003b1a9d09a8e16d46029420cccc27530d828281abe012b59c4adf9db0f9797917370db3a1c0777b500cec849ce4e9a6d05c0150009938a2b8d2a9358e9dc058c002b9fc5a004d8a8bab2cc745fb38dd3edf9810085fffff9f3e7e5e72fbcedbaa1cedc2b6729dfbd9bd798dc7efafcbd94f29d3b4fa6deb35c704b63ad5148d84d7021a28b8c8d8262d31312443d8142a600620028b35c90ab05b08b79521e924d058025100980f372a92820c6028072c04a8a40b610a0f0a71260a3aa8a7258006e6fc462db4fb7e71e02ac98f77bf8fa5315fe2bdb98deb7c7f8fb59ca9751ff7e249e17d94901e079cfccc435530638b00c3065164c2100c531ed93379c32306be580b32955a92255821dcf211028813685d53f4c504a8a40361060f01fcdff346fda485d003684f267fbc5abfdf2dea9f39e57fe541099cf4f933f1500e6f9fb995881906c230fc16fb6a9727b3b6495895b83ecb2c40d51f6510652164e65e3a21d856f864f889a0fd991ccea5f03001d31d28d994520b1fab79bff79167cb857cdd38a35b367a8b367030136f5e91f1af574e88e650df2c09d6ce0b30795fd564b3d2afcf99db8f2b7adfe790d4510782ed3dffc7ec98b3ebf9b72cb1e389c948305a700d0ff6fb5796906c0a2bf8b3ac1221188454661feb71772090513fdd62b0adc07ba48b873667736d0711bac578eefc446a4f7b16def9310fe8cac77b3aace361851b4281e1e9b90f1294b060c57bd26ffdd1fc18bd9c6cd140382e53a2656059132306b9900d9b400f0d8d64889441bd66c9e66b6bf4a7afc6c23308de8e66917294e0ce86aaaaf966244752be53f02cb5b9a641dd2e458f1cfa9d84f33baf51d417a1febf8b38b1fbbf9e50af50d0e9b7a0654049c28505c66cadf16d1efad948803400b71174419e86aa08bb93c0fc9da8171a6fca658bf2dd02b01a67598e70bdcb17cba0000200049444154d71d1401b70830bd293a65efdec6077d3a5ab3ba3d2f1d975d04181d7f6cef56791fc57f180b307d8b90641efdbae55fa6f76d58d92eb41ae4129d43ff02b28d8a835528036cf5e8daa6c99bed9459945d2ec8951c74314f4a43b2a900f0d8f6e353f8ab0290d2cdd59d168f004b004726afc30260afea4681402540a9301008c0ecbd7fdb5af98baf1d97fff6bb52d338876d7f495ce5efdfb2561ebd7b97dcbb7f9bb435d5e71c281330fb7ff8f945397df1aaf5dc29fc8b4bfc1fcf60bd90740d702fb7dcc9c1749dd72df3d805f02d3ba4f14f579a8fd1a454014823ec3a95170462d36328717a1d5900f6ca6e5cfdab05c00bbab93fb60135fa1fbeeb0ee4ef37182b002b02c66271b3f23fb06d9d6c5cd59eb395212ff45c97b73f3d2b7d2e1a191587e0fad2464037bfd01ee4962b397873e234bfc9a602c063f3e29dc96852d9a985ed7c62bab510104898ffedab7f564ae3ea3fdbe55b0be19ef8ed1ad99ef7f01d1be5ceedeb4dc01c5bfeb2804ea8249b8fd7c5a1c4ee85bf7ffd2363d570aa00c8a330efbdb4b25d42152d8b3b683eed5d0499e56ee14a1998b52f4ad60e8c8b7675e11e7c29f9f4f5d16bf1090234ff936dc4fc7faefe2bcab462a50dab7cddcee0cf86dadcf78333e0efc5773f35e58d69d1b0514959a354d4ae9792d246dbd082d9ee2176cddd423843c8655b01706901b00fcb103e3a6d8e21902c493a3dd997284d0ad3fdcc4cd45c050395b84a09952305cb85bf92453ca6462f4a64c2ee035ddeda88822efa00ccb1af8b9eee2d084c21e7ff85773e35e58d59e6d80d9556af90b29a3558f066539cb839d3251ce33e0680c22d6b022e9b77cc95e6e3c197b28477570fe53704e8ab674ff289e133121ebb24d358b547c343f0c74ea182dfac0200a14fe15f56b3caac58ca6bd7494959c38297328dc8ffa9d12f5003c09acb2beb910ec6943025452057116051a33fbef9b1fcf5cf9e97774e9e737519c150ad54d66f362e00573b14c8200f728bc23f6b72386b07c645bbbc700c73e74b2990af965ee65c0458a6373cd62d23d7df91b1eb1fc8e4e8798945e62fda338d38bea991f33236f0211e589d52dd7487d4b51f350ac1dc3993ef23e33d42b611cdfe1b5775086bbb2b2902b98800bb18fee2c5b7e5ef7fff9a9c74b9f2e77596d7ae95aac61d9a0278eb4d3732cbd5c2ded542f8d6e9d3f577b615002b421e34a97461a2f3e40802ec3e367ee3840cf7be2663fd1f9976a46e4e9d11fd93b014d0b41f99e895c6554f9855ccdc7d69fe9fc4ea3fec4201a0e97f135ab856965b0b5bce3d84be5704b28ec0d0e8847c74e682fceaa577e5b77f7a5fbafbec01afc9932e296b92aaa65d525abd32f991bece22e0416e51065ae560a680cda602c063db8fefde9792298c745e9f21c0ae6314dec3575f83f07fd598fc2d4d37e6bd02ba0d86afbd0e37c1a42c5bfd3494802d37fd989c7f72e87357e6ff3528f6b216aca408e41202977afbe53710fa14fe1f9fb92823b3350cdc5c03cbfe5635ed94ea65bba53898b54ab66e4e353b63dccb2d77723043576117c0193ab04eab08a482008536fdfc14fea37d6f2147bf3f95696eeec3f880b1ebef27fe5e352315f067ce60f53fdaf78e4c4001b0116bbc6f82f9bfab7d996da86e57047c81403c3e239f9ebb2c7fffdc6bf2ab97df15e6fb7b2208379afe6b5b0fa9efdf1370fe1b9c4d0580915989e82c275cd84fd9b9a7b2d3deba2d8f108820b27fa4f77563f29f842f3f1e75d7a1cf0601abfd8d0f7c82954ca5c90e88a2f9cfc83577ca05fdfedbd7ad3079dfb6e3e8764520db0830bfffb58f3e977f7afe4d79f9bd53726364ccf32995d7ac9686150f4965032d66b955dad8f3c5a6ba837bb9e54e0ea67a1e96fdb2a90040b20bd99168ee252b152e02f1e89489f0a7b99ffe7efaedd34d71640b8cf57f681a9accc4d1fe14fe7f1bb1d0cb9ecd6b64fb5af581dab0d2edd947e0f30b3df27304fafdeaa57784297e51542cf44aa5951d52bffc7ea969deaf817f0ee079905baee4a0c3a116b529db0a80dd02401d41158045dde45cde99a97863fdef1b93fff8e029576d7953bdde686408c7f993d9dd8d7581ab7f5680d3e8ff5411d7fd960281c874d494f4fde96f5e913fbef5b1f4dd983f4bc6edb944c6aee037f9819423f7bfa4bcf966dc8cdbfd0b629c9159ae142cca40570333815b3615005717ee4193ca043e3a679610607adf14d2fbb8ea1fc1aa9fa97e34d5679adce4fcf31cb8fadfbf759de15c2ef99a693c75feec2270b57f50fef5ed13f277bf7b55de3a71d6b16db19b330d8f5f3171374ca5ada8db8420c03be00ad826c1d2dc6b76e4e67a531de3416e51f8bb5808a77a26cefb655301e085db351f6a526a0170be8b79b6f5667a1f02fdf8a08986073d5f6100ad58ebdb5648fb86ad122c0949f7a90fe5fa4577c54ddc1c4c57ff6e50d231d942201c99c6aaff9c31f7fff1ad4fe4ece5f4b9cd921532c3e3c894193e2d352d97a4a6f54e29adea944080eded958ccc7227b7dcc9c10c419a6d05c0aaf9184dca859e90217c74daa544003f9830d3fbb0e267947f78eca2a492de57515b2f5d3bf6cbd6638fc8ea3b0e4a30542add273f94d7febfff2267de7a69d15754869eee07b7add7d5ffa291d40932810003fd5e7aefa4fcf4372f23e0efb45019c80499581904e34e43410f8f77232be02ea96cdc8edf9bb6c49e81cca2ec7241ae2ce12ee649694836150077174e1097c0f49b127aba53da10607adfe4f0d984c9df6504fe7c076fe858293b1ff89adcf1e0d3d2b171bb9455569b61edebb722682924a303d7a4f7eca9f97675fdd9c6ae76b9ffe076f5fdbb464c072e05026c437ceeca3593d7ffb37f7d13817e3d08f4cbbcdb8c16bae1de37a0045c917aa4e5d6b61d4689ed02af8a4999e54e01a096605d0867eafb934d05c095e9c3832f255318e9bc19462091def78659f94f8d9c93580ae97da59555d2b161bb11fc54001a3bbb6e3bebf5fb8f48cf034fcb2bfdff49c687ec5dce6e9b001fb42fab97278eee95bb766ecce976aff35d9b7e96bb080c8e8ccbbba7ce1b93ff736f7c243dd7bdbbcd1673f5c61a00059ebf5dc6ead4b51f73ecb3b19863e5c2be1ee4962b3998a96bcea60240adc7aef9180b003152ca3704987ac7063ec98a7ea9a6f7d5b6b4cb96230fc91d10ee5d3bf74b65ddfc0d7eaa9b5a64f723df90de73a7e483dfffcc339c5568f9fbf05d77c8d3c7f74b737d8de7fd7507452013085cbc7a5d7efdf27ba6a8cf89b3976474622a13877135277b67dcb8f47bd4d4a892ba8ea312282ed0f2d8eee5963b39e80a7def83b2a900b8d27c3cf852bc5fbdee913504a6a76e24d2fb10e56fd2fb1668e0e37482f4edb7aedd64043f4dfecdabd6e181e3fc956edfb04df63ff5acf45f3a2f974f7ee034fd6ddb0e6e5b27df7df890ace96cb96d9b7ea0082c3502a328ddfbc9d9cb10fcef180580a57dfd4074050cf5bc24a1ca3664086c95a2a2623f9cd6929e8387d8355772305327effcb4ccd45113f352f389d80ec152adc97eeeb6b1baddff0824d3fb46668bfa8491539ccafdad6e58266bf71d3126fff507ef911aaceeddd2bafd4765ef1367100fd02743d75cf63c47e0df012800776ce8727b181da708640c812b68daf37b98fa59d4e7bd535fc8d0e8784ac762402bdd5a1dcd0d525359818656a5669ed18949b9313c2617a1545c47dd8058dc9b157602d90183ddcf9b80c0b2eaae94ce2d9777e2332dd986dc721d9481764bb865925437675301601d57abad2a1e0f2312dcaa27a47afdbadf12229048effbd404fab1ea5e2ae97d4581802c5bb9f6e6aabf6ddd66f81acb3d5d457975ad6cbff709a4067e24effcea6fa180ccb8daff3c5aa69237ac6c77355e072902e94660722a22a72e5c31817e5cf99fefeef32c9c794eec61b1657527625936c83694b2ee580605a0aa42aaa000f0e7304605006582f97dfff8cc25f9047cfa123274c6dc95df66c7cdd1ebef4201a893c6958f48a8a2b09a6551665176b920ca4077a0ba98cceb906c2a002c426d2d443d0320c94a398c009e2889f4be4429dff0688ae97d3575b262db5eacfabf265bef791479fe9d2983d2dcb54eb61f7f4c2e9f785fae9e3d699d87a954cca7a6f06f7daa4e6bff5b11d301e946e0dac030d2fb3e35c29ff5fcfb8746533a447343ad3c7060bb3c756c1f4a59af96c6da44a6cc7c931d456641efc0907c7abe5bdef8f8b4fceeb50fe424ca0833e3c046d1f0900c5d7dc5940cae5f7e9f9494ce1f9b639b2717b77b905baee460a630c8a67386dfa083e0c3e005fb21cfc80cfc489ba50ad5a6e04cca140e3a6f8610884d8fcbc4e0499803ff2043575e446eff65ac30bca72635b4af90dd8f7e4beefeee5fcaa643f74975e3e2bbef55d637cac4c890f49c3e016b84d51825e39361b3025ad5d1aced7f33f47dd1696f4720128dca67a8e3ff0fcfbd2efff73fbf246fa2a25f2a817e1565a5b217bd2bbefbd021f9fea347643f5c5afccc89028122b806ca4ddccbd635cb8dbb805600561874d34b201e1d1796d82e296b44e7c00e940dcea6c871bad2346ec3828705ccc6063ec2a48ed6459afe9f07bf681b88ed19a16cde0d22b31b4c05c0a17c141480ba8d28305198c12419b9eb4b3429d3fb585bffc6c57f31017f7c1078a5d28a4a59b165b71c7cfa8772f0993f93ce4d3b4c611faff3cc37beb4a20adfad4619ecb9247d5f9c71e50ab83e382aacadbe7e459b7025a5a40864128101acf2d9b5ef6f50d4e767fffa9631c97bf5c7f3fc56b62d93a7b1e2fff153c7e4d1c3bb8dcfdfeb79535958bbbc5556b537ffffecbdf7735b59922e98f4de7b2791944479a9ba4a6555de9bee6a33ddd33d6fe6cd9bddd88d89ddd88dfde1fdb6ffc06cecc69a376fdeccf44c9beaaeee2edf65a592f7de7b43394aa4e80d00020409d0ecf71d902c8a2271ee054112e664549600dc735d5e10274f667e5f22453028ac43b04232448e0f4efce9394be2823298f97ff64af0f45ed29998a1ff1dd023ba81f3b57d315300bc271a8021906cbe994d46d19d8d8c7049a6f5e46c268aa8cf1f84f7b17b5f5b48d797575a216b9e07bc0f15fe7584f761c51e6ea95ef3883cf993ff243df7ef4af3e533dac3935865efc9cb525f5526c50539525e94afddc70c301608c50264f4fb02457e7fd87a48ae20043f306829a7fcc0a972b07a5fbf7c89fcf0854df2ee0b8fc992f2e207b6db7dc3be17ac1bc844ad4012ea71b62225e0021a21987042e464d8dfb542350f62dbed5816ce559cb32c08e7be45cbfff3fa163302c0f3af823e0b0dda4982fda7d97b3a31d95eb1174f6064612d40785f7fe7716081bf1557e7311946373fbb42eefe8a86b5f2e48ffe569efdc5ffa8b0fd8c04cc872420ad440481cfeb51a900feab9341d403b0406a495991acaaab9244939ad299cc6cb76901aeacb76072fdaf1f6e4311de5df10fdb4f9bb1b2ff4720ade2aaff8da7374a59189dd5d2c25cc9cfc94444a2439a3b7a54e160b05b6451a020839b9ebd545233e69ebe0b76aec5de363aec4604e01c984d6fe82ea513031801b8a01b385fdb17db01588e1b7b061a14c3c5d05156c15ad37f7abebe0561382ee17d43ee7bc8f3ef91dee6edc8fb5f43d426f8ca60a6d3661716cb2ae4f839f13ffad64fa5a8a60ee1c3594b44663a84edcf8822c84674c1d9d90692a06b80efe87f6c0991a223c090286154468c05c2690116fc71e5bfebc445db87cd4c4f950da8ecffebb79e43aeff79055dcdd0e4faed9e844e6f616eb68c2291cb4643fc7bd0095b6c9322980bba84188ee612ede4ee392b83ae3b3a933463006b00aeea06ced7f6c54e01580a8104201596422af3652773dc201608c0fbaea06def21e947ee2b24781f7e508a972c5315fe8fbef5334400d6a16a78e158c4ca97af0141d0df4a77f36db97d5a9f921b45a1cfc173d764e9b6c352025640760734622c102e0bb0f29e6a57ca8af2e4a54d6b55c8ff998d2ba5387ff60a7fbbc79e3e9eb0c1b7363fa26a01defb7abf74f63aa70f79e03d7f27d8efc3877e01e9d9350f6c8ba5378194b5a5f96a2205be68b71f090e80d67524cff418f22a4622cc0293f03e74ef4307bfa1fea690baf71197bf64fd2695eb5f4f785fe5e2fc38d43ffa8c6c02d2a0afad451506eaaccd42a86f8f9c9535cbaae56f50599d06521523c602e1b000f3fd7672fecccdaf58528e89ff71f4aad8a48a54f9d97c0bf9037ef0fc63aa46e1dbc3e7b49c047e6f87f807da63da01e05cc539cb8270eed3ce7f168e13f290f9ff8604bf347a40da22081501305c00c12db9c05b09eff3bad0bdafed90b854f7beae90aea0a0a24636bef64384fb7f26d56bbe871f86f95bb1e82e907506eb5e7a47da6e5c91e39fff1e7501daafa6dc6deb96cf761d033f40853c8b0641468c05c26101b2f2e561856d45b8ca7f7a43038afc36c9cb8faf5df0c2547263bcfae47ab974ab599a5a83ff0eb0df870f4e402c8b8df9cad2fc379fb65aec1a0056ff6f8602e43fbbb0bf7456c11ae0482b671f64b62c9805fcde2e4cfc0750e807785fd71985f3b57bf2d48c4c59b2ee5179eaa77f27cf10de87c99fdcfe8b2d9979059209c221f60ae86ed1e6f0d4e5325f4b6856037e088391aa2cf6bd99f3478f0548d17b0793e985c6bb0a763ad395330f5f8fbe143f7ffd19f9efdf7d499efbde2a29405e7ea1859106320bb216807c05c16414b5426959d59299bf127d3b82a0bf831d24c2b70df5df4311e069f1eb0ba04fe35676407b17eb9616db01e037800e00f9006695c4a4347c6156497a6eddac63cc86f9b700e17d5eb4ebed6bd929bd50afebb6d550d70317975b52aea8789fff9bff49b1f1e597553db07db1df10154074403b1802adb40d26214a27f8d20b72b2642dc8524c2a60b19f60f49f3f1d136a727292b47539e43e5afb4e4701b002ffa9f50daac8ef176f6c9655b5959292bc78015df610b803dae033d7eecceab0049eca1868814b2533af010e7f6c76d4f43aae2b1ae4117fbfee8b781403e8002c5a1a60b11d00b2013e33aef86716c18f313d46aa91c5b1807f08f0be8e136ad51f2abc2f29198d475600de87623b56f9d73df294a465cc0fbc6f2e566247c19ca25219e877a87480159640b77750e1a14992426480116381b95a80a17d46947c7ebf0c0ef9641851264eb46beb6be4c780f7fd77efbe282f3fb14e15a1cef55c73dd9fce47b7b35ff50c207f413049492f91cc82d50a11106c5cb46e73f75e840370da4addda5edce376a87fb1ee75f15cc6c01d937f95a5a3a4449cf55a46fd03426f8a14b2f1d85a3260aac5f93f3b5a0d795a54ae5f15fae1b5c52e570f5c30497c963ffebc82f6ad7cfa656114209225afac521effc17f90aebbb7e4c2ce2f41eca187069e47b8f64fdf1e966ae0af190930622c30170b9079eff947574979719e5c05ff7e375828939312a50e24541b1b964a4571649150f17acaa1ec1b104c4600071c0145702c0ae728ce559cb334c2398f739f9e835c73a0b96c9e75d29dcb416deccb0800dd456ae16cfb91498a74922493484a59f81cd76cd715eb9f13b633d07b4555f807e07da1a5aa4a00ef7b046c7e8fbefd33a95c6078df5c9e916209fcf17f54f5002d57cf690fc530ed9e939790972d55ab324315ac359919a0b1009d80471a6a956a862efae6ec8c74c9c9d44377d91f601445c4b1289ca3385771ced2c8c4bca7efaaa439d05c362fb603c06b27d835a803c04123be7ee559190780d6987ff10d74a8b6bde4f21f0c11de979e9d8b42bfc7d4c4bffe6576ef8bbe55f1f2c79f53f0446767abf4f790b82bb89021f09b83a7858d537efcd2e39238cf2446c1afc66c351658380bb0f62535450f85652120351685ab7fce551684739e7da2070b07b63324121c80094f28e8750fc3b0c3f0ac62b36e34e8ad2ff8464efe2cf4eb6bd9153264a700ddfb36bcf2ae9afc6bd602de97b578f0beb91890cd82d87eb8e3ce7539bde56338a13eede15809fdd18e23689a52228faeaed78e37038c0562c1026c92e547e7429d308d1baba95cce519cab2c88a579cfc271e634246a1c001b9ed59c0c12ef3b13dfefea381af2e44f5addaa551b14aeff91377e2cc535d13f012a96c01f055201b7cf1cd17e4546c18f7ae0cc55d581ada4204f6aca8bb4fb9801c602d16e01b6cb764375421ae058a5029e8854eb6c80edc601183792254330af4227c0c8fc59807cfe9edecbe240d83f14b28edc1276ef7b43adfa59e19f955f387f17bbc047264be063dfffb9f4b55b630964bf7632a3adadaf96bf224be002b0b22db049cce98c051eb080d33d20549d2426262335a64f15e88e1389dbd54215739505b134ef5938ce9c86444f0460bc06604e776b760e6a0186fe5d1d47d0c4e256d071d337123657be7cb5aaf067a15f59ddca796fe033fd1ae6fb7d5a56b690a6b8fde655cb2c814dad9df2097ab8af004be066f0b21b311688650b10fea78300f2fe633a0260af06804ec0a24af43800a81c6578656c6c14f9a3f9ed0eb7a84f64914e4ef8ca00082cd8b79bfdacad4a564131e07dcfaa90ffca675e51ad75adee1b6de38a97d4cb133ffa1ba0026ec9d5c3bb44d703158dd2e4f8c51bf2c76f0f4959619ee10788b6076eaed7b205fa3d5eb9d9d2ae6d08c40326a7e64b725a6441182ddf6890819c9b540ac01ac4d14400c66d69c9100c4f0ffb1c0a3e92941a9d056541be3b8bbe6978c8a11c003ba1ff92a5cb5585fc04bc2f12a87ce7db90b51b9e90c7dffd0fd2d3d2249d4d37b4a7f382c065c7d10be8155009bad61725272b43bb8f19602c106d1660e1ebe9ab77847500c124213155d2d0093035236807f8608788d86d8436728ee25c65412ccd7b168e33a72191b0942611420f544b88e01f02252618e98c84df02be81361972375b22f949cfc91592f9bcfa3ffc6779e16fff1705f58b87c99f564f02cc69d5e6574165fcaeb08ba11569ebee93cff79e906397f40e8395e39931c6029164816e47bfec3a7151ce5d6fd25e564a7a91ea0590981c7b8e30e726ce5116c4f29c67e158731a12090e00891008b0eed6dd09fbcc87d26b5e775cb31d5c9468f0e31f0cdec98b764a4e499586a75e9237ffe7ff5d9ef8e1df48417975dc992f1ff7cc7b67ca2331d11a9bf6b9eb0196c02b1a96b4b833a6b9e1a8b6c028e8890f9dbb265fee3b6529ff9f9a598e5e0015517dcfb35dbc8df989731de7bc452501e27d448203c0eb681f57be9e5586e16119076056f3cc69c3b0df85f095be26a5b4ae411e7be7e78ad6978571f12a64097ce2877f2d150d6b2d9980f8e8dd272ec99ff79cb0f44369e9a06690b1c0225be0ccb526d05f1f5254c5ba4be1aa3f236f79cc76750d38009622d496e63b9d3dc3b13d521c007a435a9a35ffa0490184e3a1cf740c16fe5929fe63debf62d96a150a9fe938f1f41959024971ccc64156a407cd52beda7f1a2ba6eb323ac6124123c602d1690192fe9cba725bfee5d31db2fff455191ed1f7ca601be0ac82b5315900c8a7a8520098a32c88a5f9cec271e63c24521c004b1ed1e888574500c8b76c24bc16484c4a97c4640b3cde23c3961ae384f7ea22f368d98560fa7beba7b2fad9d7e11059e3a8bcd6745fb104b2719011638168b440afd3ad72feffe583ad8aeb829d3075c2d57f76d17a440056e88646e576ce498c00708eb22096e63b0bc799f3106b09cc399f467b00f2ab3e06dd0c4d08369a39a40cd54bda200182d9c9ee36e6ffbdce9baa8a35d8becc7997d4ae90b2fa06617bdf78971c380169a039eebcd3287d6dcd5a738c61e5dfdeed90a4a424598d1eeeb9d999da7dcc00638148b140536b977cbceba8fce6cb7d72f442a390f0ca8aa4e7d44941f56b68e91e9b0e800f3554aecee3aa6f8ac61eccfb6f1b573d6fb2e66073dd1c290e000db10efa143468792831a4fc12a566580bbbced540f1b2ff18520024001af2dc0f7acb831eb031621223d94f7e5955d0b1f1b231b7b84cf508686dbc24836e7d1dc510c2a7ec9d5e515c206beaaae00c444a202e5e9e98b94fbb167001e7cf90fffb5b0f285e8babb7ef83f75f1ff6e77992527325bff279c92d7b068b86a03fef762f2b62c60fb9ef4a7fc70930a872711f549823d8023d1c74d4026d8c140780b7bb14fa04b4986f6693c4a45438000d929ec3e146c2658144e07387dcf7100520546df6e2d451e4fadc7ddd9292968e28c04acb50b8705d67241e87c8886c1022b97bbaa4fdd655f43af76b2fd3d13f20de419f2cab29939a32d32b406b303360d12c70bfb35755f9ffeacb3db2f3d80590fde89ddc898b65d39f9cd24d52b4f4fb315bfcc77bf58244ad1f1100b650d708737fdf402f6bc62dc8e64872004a70c79ba0b5c1ee9c6c4b19700032f30db56a303bd9dd4607c03fd4a3a200231a262b9f77405cdded929957a89c003a03f12eec7b905d58ac0882bac01468453a7a411a8268ca4aa4020a73e3175161c55666ccc25b802456176fde532bfedf6f39a070fede21bd733bf54a33f29661f2ff816415ae8d69065777cf79a4004e804745db2df412ecb315da34d54e8bf53a921c00ce228c0004c5558d8d0d63d5592799056bc0291d094cc68bf5e8c27cde04945e404908e4536980e055ea03ce3e7175b54b5175ad7202c27c355179b8bcd24afc008c4aebf58b42fbe88421d4ae5ea714e565cb1a340d4a350d83742633db17c8021df85e6ec76affb75fed95af0f9c96164401ec0257c8f65758f3a6e4953f2d2c328e55217aaa1f933f9d00e44775b779020318012017c0a24b243900ac03781cfa6470ab8c8148a25cd50124a59842c0e0b6b2b735293953c6460651c872cf52e745460138d1111a5850117f8440d3ad9b9098880e884532e072a069d015840383d3a2727f16519147bdbeba54eaabcaa61fd2bc371658500bd0296dbcdb261f6c3f2cef7db55ff5b2b05ae837f54259f457b8e42d4cfe9b2525bd70eaa6987bcd026a57070a005db7addcdb6e0ca20360ad7ad2ca11e73026921c00c64ed643374383969727a3a884701253083887273fd3ae68b2c47696834003586105e421d81e771439eff2e56bd4e437d361e3e933d203e7a028908800220318e2d7093ba80d8f8c4ac3920a2929c8d50d37db8d05e6c50284f71d3c7b4ddefb7abf7c862e96b75a3a6404112d3bc2a86c26505a4575ef4a41e50b313ff9d33683fd77e1001cb3d2427d00c3bf86ee85ea7f183068be25921c001a6429947500415d46b69324a3547a4e2d861a09870546d0c3dad37b599ced875108d888499ddf55bd8c8217a0bfa753724bcaa56ad54654f99ab44c1e6cc116c96d8802d0363ae18f6c7b8f53b232d26435500199e969ba5dcc766381b05a80f0be8f7612deb7570e9cbd2abd2e8fede327256721d7bf418a6b7f808aff27c08d111f752d037d57540460046caa1a6101e057d00b218706f200002000494441549a710bb639921c00de741ef451681ddfcc2663637ee5006415acc610e4ae8dccc9023e6fa7385bf74befbd2de2ee3e879696da4ad607ce4768e0a0c725c535f5c296b94644a1027c036e69bb71052b03bd33353038248e7e8f2cad28519d0313589361c458609e2d4078dfc92bb7e4fd2d0727297dadc2fba65e5a4a4689e4553e8782bfb7e104acc342205ef82dc6a4bfeb8ce200181bd5c2facfc1665f42ef4db5dd62be8e340780806812026d0c66141a3a3d6709ea005663a5658d812dd8f1e2751bd9ab48fed3d7b20bba0339ac3b565b593e643267471b500483525ebf0a21f0d287b6c7db07699959a0082e1167679b74dcbe0ebbea31d33d08c1fafd23b202a980f2a2d8eb971e6fdf8148bf5f16f67db1efa4fcfa8bbd01781f52517685c57dacf42fac7e550a6ade908cdc7a146707cde0da3d45448f1ff10311d5790cd15316f76be520463002e0d08e5ca00191e600b03082933f0981825e5b4a46b18a0224a7991fca50be2bfec11ee5b5f6dcdbaac2576cb43417213c934581e9d93952b572bda4a6c7cb0a6076abb1474006ecd1d574c33a4b608f4392c112b80aa980dcacd8244d99dd6266cb425880fc13176fdc953f6e3b84953fe07d8d4d6217dec7eb4c4e2b94dcd227b0ea7f0b21ffa7f1375f8c4fe32b7245d4141d0072a86884356e5ba1df42b5a102cdb1c2b639e8241bb6b3583f100dc3f0ff13d0a0d550492959ca0148cbaab47e743352adf059b4d2777f8ff4366f570416a3a8fc0f87f807bd4005f42a6860f972a6678cb036621891114203158ba2c624433ebfb0bf7a654981aa07302c811a8399cdb62cd0815a93edc7ce03deb72f64781f0bfdd2b3974841d5cba8f47f5345626395e14f675c2fd8534901ec1fd4a2fada70accfa12775c75cc8ed91e600f0de4908c43480065796000760850a3f7127237a0b90a5cadd7d564dfcceb643e21f206d65788b5159f4e61f1c10b60d262e3ede854d82b20a8a543160c7ed6b9659020741b8b2bca65caa0d4b60bc7f85c272ff0aded7d42a1fec38822aff7d72ecd24dcb3cfe532f8008aceca247d4c49f077adfb4cc8a9826f8997aef33bd66e89f08000b45d357b03fc3ffb7663ace627d16890e00e39e4402045d42b20e80f92616022600be6624880500451b42a8cad1ba17857edb64005f5a56fdcf9730efcd2af88a156b0d55308c4c6e00f60be8b9df245d77adfdfd73a5a6580297564a8161099cafaf6a5c1c97b525acecffdd3707c6e17d9db6e17d0ceda766564a7ed54b52047c3f3bfb25c7390f0be7a0feae93d0d35847696b7c48004408a01e16b480dfca4874009806201280a440b3279460f0b42c40a6400b1c3f15a7f6bf19237e8f10a6c2223fc7fdbd68f6d38c8945fb657de844e9b9f9c8f9a5ab70f6431ba77d30ecf789bbb74b0aab6aa57ad5063cc5d91fe3b45d63f66d1e1a27b18fc2fdab174014d4a7bd4faed83a519455949f0b96c02ac312a8b598193093059a5a3be5e370c0fbb0d02aac791d61ff575401b6616145221fed7f19fe671f008d904c6117f41ba8573376413747a20340fa3412fd93113068151471a68c021842a099bf337ec2fbda0e4aefddad08fd9fd1b6fa9de92849a9a9520ca6bfb5afbe0bac7f05a208cdaaf3dd4c63a77e4686403fe06f25b56409ac99ba292e5f13d697995ba0267f360cb2c4120888167bad9321b0aeca202be2f28b13e24d871fdef78ee4943c86458029ba9e7824444db93a8e803e9da9d4a0428f9ff0bffdd0f0e65c839e56bf31121d001a88c963a60182feeab1f29c644084a118f9ce022cea63710ae17dbd2d3bd5ebb1517b4d3c78b44c34b859fabda765e33b7f296b5ffb9194a0fb5f3fc2fbbdcd77f035d67f8ffb3aeeab9c77856109540f27035194004b608b748025d08a0dbbd0796d1810c286a515528c68801163019d05a6c2fb76b07b5f18e07d99f88d3590eb072d4fce1467fb11e4ffb5a449ccfbd101601d404449243a00341049febf075dc137b3c9d8e810d200d598a8564a621c614f67b3073ff703cec7bed4bd84f7019e320cb89f5d49484c42a86fa9acc1aaff911ffc4296c009a033900d585b52728a7403d6e6e9d556bd22e44d96c00ec9292c014be07a308319ce863c44516843f60ae8efeed03e1ab204b21e202b235dd6189640adbde279c000e07d1700effbd3b780f721df7fee7a930c02556257be83f7bd1db7f03e9dcd46c094eaea38aa22ab8056e9869fc200e6ffefeb062ef4f64875009806605740d602cc7e8d307c0a42521979f5084d152cb4ed22ea7c2c482116d5d142781f0afd1cd7e099da4f37a567e74ad5da4765c35b3f95f56ffc44adfa9353bfa3a6cdcc2f40c8cb23dd58c112f6a79321b0047afbc112b864199a0699480dedc5b6c1b44b5be365f10131a1930996c0daca52d52fc0b004ea2c167fdbe924ee00bcef375fed936f0e8e77efb3698600bc6fa9caf307e07dabe0ac06cdc2da3c43ec0cf7795ac405da7442aa35e2c3f66d502200f47fec9a83857bf3ec936bb8cf64ef7804a64fa401f282ed9a90004c6a6e9dc2a5061b17cbdb867d2ef1a01565efbdede2683ba05afa5af04a1f32496e698534bcf02656fd7f25f54fbd28d960f49b3ed9a480e02713b0363756afbde87bcff6b73a61db60e6bccb914260083cde2535234b3901ce8e56950ab0cc12383cac5802cb8a82fe49c4bb79e3eafe592c7a1df0be0fc7e17dc7c302ef7b2eeee17dba2f910785d50cff0ffbb4a47e5cf57f0c3d0ad5e74d75270ef3f64875006828a6011e81d6426795d1511f26ff2a44011a4041196f8d68c654018ae3fe3e4cc6df222c7fc1521bdfe9c64ccdc894b2156b64dd9b7f817cffcfa49c4c7e98a46613e2dad3b2b2552d80abb375b661939f2b964038016999d952d9c0631b9640c51288ce815d7741c5dcaa65119351d45cb061504a3258026b2b0d4be0e4b72b7e5f2878df9900bcef5374efbbdd1222bc0f646a06de67fd7b343a32845aa86348b19e54c46a9a3dcf62fb9fa14d9a718bb239521d001a83583560c89413302b8e8cc56dc9e9457000964b722a7d86f89011149e78fbae2b785fdffddd2afc3f364604a53d615e9fab7daefa1b5e7803fdbbab514fa1ff5a6423af3f02b85f17c86dd8f446274c17789c3d6009ac1316051a01d52558026997fbd72e2025a0b721f3b96409ac2a2d0cb004261afe8b78fc1eb1fe763abcaf2fd4ee7d06de67fb2ba49aa78d774dd5ecccf0e86ee817509766eca26cd6ffd22fca65a993320db0044a34c0eccb516c4c4c46430ac001d3b22af02ef6c5efed526d7b7bd0bdafbfeb14f0a8da30d44346615ebfa87685ac7bfd47f2c8f77f2155eb1f4324c57a9579524a0afa7e03d6d6d7233d58c58e223cad13720370c2332c81014b4dd8b0bfa74b350c1a19d6176cb163201d8165640984236024be2c4078dfa9cbe3ddfbc0e57ff5ce7d09bd7bdff3e0f107bcafd8c0fbec7c8bbcce1b0afe6781feb70bc7fd144af81f17b4112791ec00d0604c76320d501dcc725cf9b23b6046eef298660564e8c9db7f671cdeb74375f21b430ac4aeb0a29f95fd1bbfff7359fdf2f741eb598f621ffbe913c2da782c677b0b4886b4c530ea321d64094484a11229870c84c0e35db20b8a5524a017f6eb8423a513e6c658f0c574628362090cea1beb0e67b647910526e07dbf0a4bf7bed714b10f21d406de67fd4ba0d8ffba4f05e87ff53d542ee2c874001aad9f61614746b203404b30f44f07603ddfcc26ac03484127aaccfc1598c86233bf4cd6a97ee49c98eb27fcc43f48e7d29e24a2cb5c7e55ed38bcefafe0043ca526707b4779703453082c6de942cb5baf4b1f8960da809180225c47155802a717193e78f4f878975f0e96401453debf761ecd94fab437ed43b4a5b3cf29250539b2b6ae5a5252ec3b6fda939801116381a9f0bedf03de77fefa1ce07d654f82ca97f0bea7d46f6630b2d5883140045d08bba6b28f0a8b002dd4f41dc0a0cfa1bd11740b0f5c4aa43b004c03d4419906487fe0ca1f7833a626fe8c1cb00266c6569539697b87003999e8de37d077d54ae38907acc3370cef57ae03bcefed9fcd08ef7b68078b1f24200f9d8154c060bf53f1038ca0da5f279ce47c48051896c0ef2ca5d229e8a4d876d31a4b2043c11eef90d45797496d25fb671989450b30dab3fd28baf77d1980f7ddefecb55d4a3e09efab7e05abfe37e0f41b785fa8df954127baff21ff6f81fd8fab2116ffed82ea737ba15ed01cf78b7407808663a293a440e5c1ee35c00ab81490c0fa9849038cf8fa55657f1fdaf63a09eff3a0e25e4f3af1909972d1952f00effbc5acf0be8776b2f1415a568e6415a2e3dd384b209bd8e8c441964044032ad03698a8827817a643880ce86b6b964e702c58620904c31b89821a969025307e0a60e3e1bbe2479447c1fbb607baf71dbf1c6af73e7eafbe17e8de5761e07d73f9ee7031c66eaacef6a3561661d770ae4fa097e672cef9de37d21d00de7f0a946980e0dd01477c809795a0306d398a02a39fbcc237d001defd7dd203463f7737e17df68b4809e52b6b580b78df4f64e3db7f0978dfbaa0f03ed83864512c8129698802dc84d3a24f4f2896c0ee4e8587af02ec30d9b004a27d7285b2433ba2005658028747c812e890eccc74a002c088996e981643fe0247d08e3dce7ed94f78dfd7fb55f7bedbf7e706ef2b44c8df74ef9bfb031e01e6df89d5bfa787a97d2dffc9110c62f8bf73ee679ebf23448303c034c07228a300df51d23d64935135f1a7330d9081bc74940a2926bd8e4614faed04abdf4ec534153abcef2545e5dbf0bc7578df5cccc682409fd7235d58c15a65091c542c81f56009e423364278e5a0db25ad8d172dd9d03338240ef780d4912510fd028c44af0518396b6aed928f54f7be7d72f0ec350909de9792a5daa433dc5f50f5b2e9de17a6af84d7751b0ec04184ffb5dc275cad7d05dd06d5e744c3747da11c261a1c001a90690046018227f8f107a49a03811910798050ecb1a8fb1056427629aefafb3b4fa87693762f88f0be62c0fbd6befe63c0fb7e2e55ebecc1fbec9e6feaf894f40ce417c112d8d3897b204ba01ef932c1125856bf4a720d4ba02249ca023220c01278dd12d322096186c108b76249b994151a64c5d4ef64b4bc76c1893b79e596fc7ecb41f960dbe1b9c1fb2a26e07d8f9aee7de1fa0220f5ea06dbaa0be17f72b068e43ab67f043da719b7e89ba3c101a0919806202950d03400d1005cfd67e4230d9014a46690478c201945fa6290f03e10faf4b56c07bcef868c01f26757b8025ffae833b2e19dbf94d5affc00053f7521c1fbec9e77ea78d204a76666a10b6113d00a5a4f19a9ee517175b5a12239432a56ac556c81538f178fafe908b1b0b20be9144b2c81a36009ec76802530192c8155929315fd29b0787aee2d1d3df2f9be93f26bc2fb8e5f9c43f7bee552586de07df3f1dd19f63b55f89f4e80853aacc3b80686ff3be6e35ac279cc687100bcb8697d1a009349524a26f0e5f592827a80681092f8f4779f06bc6f9baa2ef57b9932d217d14dbdb7c4a46429a80e74efdbf82ee07d8fcc1dde37f5f8765f678db30476df6e544d6f74fb2b9640100a15d7d42a2740373e1eb6b36ba07f688225b05f7bcb24076224802c817402920c4ba0d6668b3d804d9e2edcb8277f64f73eacfccf35de0dbd7b9f81f7cdebe31c74dd51e1ff210fa9fd83ca44f8ff5b8cb2bf8a0b7ae8f06f8c1607c07a1a00364acfa9032910d183919b06e0cad7872f93a335d0bdcfd37b1995a5dad0d243df8074548fb37bdffab77f2aebd0bdafb46e25289183944a3c7484f07fa018ee108df03a7aa55bb104ea51309ebe6e4c78835256db20796595e1bfa8283b225b0667e515c239ec9476d02d5b615a244be0101c81e53565ca1188b25b8eabcb6d47f1e636c0fb7ef3e53ed972f08c10de675712d0023d3d1bddfb14bcef4da4df5622e267a23f76eda81f3f86f0ff05959e1df16b29bba326fccffb8e160780d76a2d0d403400b800d81b2031697127425ef44c32e227bcef32c2e43b54a53f71fe88f9cf3434e867b9982857bef0962af4ab7ff20554faa2f831426a1fc81298619325d089c6422406aa204b20f68f77213c92e980ded6bb681a744b6b0ea22f3b7a9dcaed5d89864105398625506bb4051e3001effb60fb6155e57f622ef0bee24740eaf3a6e403de979a591133f0e7057e24dad30d038eed426d96bb1b297dfdef74d484ff79e3d1e400584c038c282f38035180948c62edc35de8013e6f87385bf723e44f78df5919412b5fbbc21c7b19f2e584f791d827d0bd2ff21810553b61dc1c51015e0b0c77e405202f7e61e552a95ebd513903766d136be3c912484e00360cb2c412e8074b60af4b4a0bf2644d3d5802d13dd0486458e04178df090907bc2fab683dd29e8603623e9fb00aff8387452dd4829f28aac2ffbc9568fa75b09c062061431a5b04e7d46212898c5b1c1df6e2071c455d80f6f53513de7707b524c3c1bf4e336ce52a7fd9d32f8fc3fb5e57ddfbc8c6178992901060091c02d4afbbe9067a67eb5362a413664d40c9d2655250511389b7b5c0d794006e8b4271a346a2edc615459ea4bb807eb00432bfbc0c2c814b2ba2a31646774fd1bc7d12deb7e3a80af91f20bc0fe91abb9244785fe11ac5e16fe07d76ad17da78769b658d16d1591652b45115fea745226376b4fe6c2ca501c6d0a42139355775088c04efd83fd8a39a4770d5dfdf41789ffd7c5f721ae07d750d0adec7263e55a0f5b5d3bdcfba89c33b322d2b5b880ce8ef6a97de66383da87dd08903cd854686275802232f8aa3bbfe706f0fb00496045802e14859610964af80111005911bc0b00486fb89583f9e13f0be1380f7b1c84fc1fb9a42edde578a503fe07d4bde91ec1203efb3fe04e6369245d98cd80e20658b3f3cddc1a22afccf9b893607c05a1a800f0ab96416c8a46557eb1edabc6da7f738d87f7792c79f043fa3fa0e520f5d8f82f73db6791cde87ee7d80f72586d0bdefa1032fd007d945250853a6aa28803596c011c58497054e81ca86758b5ed4b840660a7a9a3cd039a7a0b8b3fdd6557175ebd14564096c078f7c4e6686acae47342ccdb0040635f03c6c24bcef0bc0fbd8bd6fd79ce17dafaa957f465e3dba699a67390f8f6bc6437a7aaf88a36d3fa2923d336e9ff261d485ff79edd1e60030869c0b252950d0de009c6853d28b100560bbcb852f061cf639558e9ff03e67fb21f123f76fc183c498ef2400ef43f7bed7de45c89fddfb9e54e1e0ef4644cf2b1604fa0707e0048025d03ba0bdf0218f1bad8f9d8006d64b29888d8c88e44cb0045ebf648d2510cd8248305357550a92a00a63c205b200d32fe71b01efdb66e07d0b64f279390d7bb190f9afbfeb14d2b55a24d3555cc49fa017e6e562e6e9a0d1e600d00c8cc3ac1dd759717e7c600a26935b0b72a005cc8322c43d04aa4847eb5ed5ba77a0ef32f2b65ae808efeb0151f03eb0f86d1887f79520fcbfd8f0be072ed0e69b0996404f6f27ec721b91103dea812b5dd60d94d5af342c81b0776a46a66a9c648f25b03fc012585321a58625d0e6b7d6fe7005ef3b82ee7d5fb17bdf1ce07d3906de67dffae1ddc3ebba258efb7b65c8ddac3b30f39a7ba19f41b5a102ddc116727b343a00ac9e21509cbd01b283198b0c7b6980c7a80e8189f37fab9ce8d9aeb78ff0befb7b54d5280b12edca24bc0fa43e754f3c1f51f03ebbf732753c53196999d9aa16c02a4ba013b5032969e952499640d413c4bb1016c8d6c15d4db7000fbca735c7285802db80394f494946c3a04a9512d0ee6406d8b6800fddfbae35b5ca8753e07dee01b631b127c9a9e8de47785fcd5be3f0be7203efb367c2b08ce6dcd1df713c50fc37c2cc73506178f763e86ea8fdcaeea0879edf8df33f2b86fffa696026c1180520dbcfacc234008b0033d022984581f3293e168bb41d949ebb5b10fa3f8395abd3f6e914bc0f39eff56ffe4500de87d75cf5c592b02090a43684060e79f40c778a25d0d12345d5b5aa1e20966c11eabd289640dfa082065ab1e1e0905f7ad161aebab44856c109488c50d448a8f658ecfd08ef3b80ee7defa17bdf9f77cf15def7325af7be2501789f717817ebd9fa06da1447cb80e39a954b3881411f426f59191c4963a2d101a0fd1805e0e4cf2800910141253d67090a0297041d13ea463a195e17e17dbb14c46f1061230bf9a2874e4778dff26708effb2b59f11ce17d5548614426bcefa18bb7f1018b01190920a6bd075cf723c3dadc9a780081f32315c05a807cc312089e0bb004c286fd5d1daa2890ad9575e2e81f502c81cb6acaa5aaa45037dc6cb76001c2fbeea07bdfc7e3f03ed5bdcfc0fb2c582ef287787ac1fc07ecff305a006b84054d5f40bf84ea8b9b34075be8cdd1ea00d0d0f9503a004113fc8162c0621505087783203fe07c0c13f5defb565c9dc764585f29fad0f34d4678bbb86e05687c7f8c2a7fc0fbd67e2f2ae07d0fdd888d0f58dfc030b61370bfbefb77b1a7165ea3bae3f107b77cf96ab5af8dd3c5e4502224d83a984d97ba5053a113daae03a900322dae5c5a29f986255067b2a0db15bcef7200def72784fdafcd09def782142d35f0bea0065fc08d8cde3adb0e89bbeb0c10b75ae71ab85cf923f4d4025e62d84e15ad0e000dc0e531d3006bf86636e1032419503a8a6a48111c0e2181cf90fb9e385a76239fbd5d182622d18f5d61ebdc5ac0fb3662e25ff572f4c1fbecdeefd4f159887890b3b6fbce75eb2c81280a2ca8581260098cc1e8c854fb58799d5f56856163d27afd22222a7a6e091f5802bbfa5c5256645802add877b631aa7bdf5e76efdb23bb4e5c54369d6dec6c9f733142baf2c29a71781fd14a06de379bb916f4f301c0b559c3e54331b705d98f312cfeebb43036e28644b303c0d2fa6a28a3004113e56cad9b925eac8a0113d140632e320cea5e4fcf39acfab7031f7a105f9236fc06ebc96da69e9318fe42e4b4d7befa43d9f8ee2fd0bd2f7ae17d53efcbce6ba637d8f276c8dd6f9d2510b0c00996c0c2caf949e9d8b987c51ecbd53c53011ed448b4de20dac4a7bd24976109d4da68b60193f03e74effbfd9603721e9dfcd885d1ae24a7154a6ed95320f5795bfd4bb8b291c8b0c0c8f080eacadadf791c48252d736937aefa13e876a8fd2f4204dc72343b00343801feeba14167033ec8c4e4345003a33f407aa8f9cf31c0fbdac5797f9f0af97b7a2fe207575fc436fd1933fc5dbd7e13baf7fd4cb1fa9500e2c6bc783c0aabfab30a8ac759026fc38fd23b528e8efb32ec1f92f265ab54083c1eed36f59ec912c854405f6bb3745a650944af8011d8ba6149a514e5e74c3d9c793d8b0526e07dbff96aaf7c73e8acb476f5cd3272f68f152c59c1fbb8ea7fc374ef9bdd548bb66508c46decd04a08a005398331c4fe375a181b9143a2d901a04119775f0edd084d86ce2a0cdba7669587d41f60046d7a07fac0df4d1efffbbb55f8df426ee8c16bc16a8d857dab5e7c4b36fee017523f01ef7b7054dcbdcbc2e4c5f6c1dd776ea0436297f6fec91f405a61f2e357ae5caf2082da9d627c806209442d897596c011d4033825370b2c8175d5862530c8f7836913e6f73fdc7e0455fefbe424f2fe06de17c46051bc89c5dbaeae93e26a3b8ce264d6990715623cbf817e0eb54ff412f4d00bb731da1d00160316409906081a470b4002b39106a8b30509f47bbb14935fef3dc0fbba4e83c75f5b15fad0d34b05f6bd1c90be7580f771e5cfd7293106ef7be8a66d7cc054c0f0e0a04a055862091cf07cc71208822423e32c818055b6365eb4ce128874405d355802810c30f2b0057a1cfdb21ff0bedf11deb7e784dcb9dfa922270f8f0cf64902f82baa24bfea25295c0a785f21bbf719785f308b2dd6361f22bc8ed67d58ec5dc125680b936f63108bff8e5b198c311129d1ee00f0298d40574157435156369b602872f5e939359620814c1b785db7d58abf17c43e5e27e17dfa1cebf4b36783b865f933afc8c6efff421a9e7b2d66e17dd3efdbce7bb2043215c008400ffade5b6109ecefee342c81538c4cbe88ecfc62a025ee4bc7edeb96d229dd0eb70c23a2b26249b961099c62cb00bcaf533edec9ee7d7be5e0d9eb2176ef438aab70ade2f02f80034028724262d040e594ab302f17da0284fe39d0f86778489bde61ae720ff423685416ff4dd836da1d00de07633584023e020d9ad054904014e064200a90989c81e1330bbf00fd9d2751e1bf0d5dfc8e6245c55a0f7b42785f497dc31478df23684c34bf6444f6ae30b246931b80444884b5b93089e9845d059d5d6d929c92261560094ccf0afae875878b89ed39c5a5aab0b2eb1e78292cb104a26150b743d2908259555b0596c0f498b0c35c6e6202dec722bf0f10f627bb9f7f986b0c7b929231debd6fe9dba67b9f3dd32dca68fee693c8cddd7dd60af40f95dff201944e405416ff4d1839161c003e00fe853202b062e2c666fa3790b747480e510052044f9700bcaf79b27b1f697d4751156a57c8764778df8677fe5256bff48eaaf88fa6ee7d76ef375ce3098b1c053150378ad9880ed0897f6850dc7ddda04d352c8113b6623d00fb27dcbf7641062d302d7a877cd2eb724b753958026be39b257002def72bc0fb769fb8143abc2f1ff0beeaa9f0beb9218f269eadf977fe2ce07180c25d41ff38b76be52046bc0f258949544b2c38007c002cc2e08cce62c0a090c0003110bb04a2ad66d277d5f70ade87cafe3ee0fad9ff5961406dc3fb5210eeab0bc0fb50e8b7e49127b0220b1575803b893309b0041621f5e2402a002c817ebd733d0008dc301c8152d402189640b4f704c49405922e144ab228d00a4b609fcb0396c061598e5a80ca1296d4c497b8bd8372aef1aefc11f0bef7e700ef4b9980f761d59f5bfa94ea461a5f968ccebb650f17766cedef3c6125cdcb70f0c7d06fa15a9c60a45b24561c003e08decb1a682d7456611e9f5c00e9b9b58a1b8003278a3fc8e8e7ee391f1abc2f377f0abcef47c2ee7df10aef9bd5f816367cc712781f1e391c6c30d8e984796fd60d902530cb385ce00628523515dd2d77a4db324ba013f969b004220a104f2c81f73b7b55d7bedf22d7bff5f0b939c0fb6aa5a0fa1503efd3fdb146e0f6c1fedb8af867b0bfc9cad59dc0a03f40af5b191ce96362c501a09d1905203110a300e407985526a200a9196532e8ba1380f781cb9f1850bbf03e92b1e495573f08ef03b4cd48e816203490d27dbbd1224ba05ffac112988fe750bd7a231cbc58fa5a8766c78968486be3251b2c81fd0196404003939363db8613abfe0fb61d56a43ea7afde168fd7fe822ed0bdef7b4843bd69baf785f6555dd4bd26887f9ced47b088d0766f74e1623f837e05b59f1b5ed43b9df9e4b1f457ce07c22aa675d0aa996f37f0291f34dbf412e2e740c3877e603f2d547e3e0247fa5b0000200049444154744812d994038bbefe2d74ef7bf3a7528e623403ef7bc84cb63f986409440e9b0d8318e2d7c9a0db85e73920254b917fad5aaa1b1ef3db69c32ca0023ca0086e034be0b04f8f60214ba077d027cbaacb64494571ccda68eaaa7f0b487d98fb1fb510697ac02070fc0dbcef018b44e59bc0027017168296887fcee326df87f2df9890587200f8408808a885ae8706adbc218b1f1ffa90a75948156c5726e07d8f00deb7e2d9d740e9199bddfbecda255ce3154b2022016eacec7b10c6b6c212e8ec44c536f804cac0ae98c35e03712e1939b90196c0b67b9659023b7a9d0196c0a5155294175bc80a12f89c6b6c92b9aefa89e3cf2a1887f7551b785fb4fe9991ecc785a63fcef6c35656ff5c6072e5cf0880be42394a8c128b0e007fb508090c1a8727eb5300d7afcf314f7d9629691980f7ad54f0be8da8f2af5c63e07d53ed13ced75985c5806b262b5480a7c71a4b20a18199b905862570fc41e49556484aaa4d9640380179d999b2a6ae4ad2d3be2b940de7b35dc8638d8c8c4a536ba77cb9ff34d8fcf6ab5c7f48ab7e5cf477f0bef1ee7da96c4a6a241a2d30489e17a47ef9af05b981315cfdb306c0dea461e1e08b3524d61c003e182ee7eba0ec1418d6fb23594deda66741eaf37305ef2ba8ae551314ce63649e2c106009f45a6609f4210de045d3a0e225f552665802d553c9292a41a4cb8dae8197c437a84f5d323fce74401d5201440644b374c299219bdf1f91ebff006d7bcf5ebf236cea635754f7befc1580f7bda6887d148a688e8dc5ec5e83191f3e0ba8ca7fe0fe5d1d9672ffcc9f6d85b2f14f4ff8ae62f18f14d60972f16f475d018b011905602d4058129949c984f7d5cbdad7d0bd0ff0be9a8d84f7c51f5c4a597781ff37c91208bc7fcf3db2046afb734b7f0f58025137400720b724ba27b070983b353d1321eb2271b4df97f6dbd72ca5537a9cfd0196403800a58579e1b88c053d061d9873d79b149bdfefbf3920fb4f5f51b87ebba97e5e341b88a9ee7d0adef7a481f72de8939c9f93795d20cbe2eabfff8e951370f5cfcaffc35072cec48cc4a203c007c45a802550c202e7c4bd994178df86c76503bbf7bdf62329ae5b61e07d30ea428a620904d56d6ff31d7121cfaf1352b93a3b5a559321c512681818554d0421965de057e86b6bd69950d501b0035e5a2a5802910ac88e12964036efb9d9dc2e5fec3d391eee3f2bb75a3a4262f34b484c45f3b0a5e0f137f03eed17268a06b0fecbd9cad5ff512c28b4d12056207f03fd10aacf4346911d78a9b1e800f0be08d7c882ae8706ad05c0f61925212111b01ec0fb5e7a5bf1f8d73dfe1c78bd433ad48cc7371fdab38062090431507753a3259640b2e1055802eba40a480d2322132c81add72fcaa005a645b2049224a8a6bc58562d254b6042c49a9113ff6d34ebd971ecbc2af2fb64d73155f03700544328929c5600329f4d88fc11def72c68aacb85bf0946a2df025ee78dc0eadf0d9e11bd3462c8efa15cfd8fea8747d788587500f8a058a9b914ca5a005b518034f0ca97afdaa0e07debd1c1afac610dc27e99388c91c5b280620944185bb104221530e2d7ffb00f0002e71f1a92d2da1560090c8a0c5dacdb5ad0f3329595859e0b2e202bda6f5a6409ecf7884fb1049645244be0d4899f2d7b3fd975548e5ec00f3c1c97506462d55f50f5b2142e795335f331ddfb42b16464ee43c65727a1df9dc7acacfe272affb9faef8dcc3b9adb55c5aa0340ab300ac016c18f422d27ec738acb65f9e657d5aa7f05fecd2dab04439af1fc61c34597004b6021603b2d9659021d8a257058ca97812510935fbc8b6209841dba914ee96ebead3507d3294c0524e26f6025a200f93991e108cf34f11f39dfa8f2fc23a3a12dd41e5cf53f079c3ffef61362f92752fbf8636ec080e31ae8de77228ad86ce5deae63d0efa047a13153f93ff5c663f9dbcd07460f8e0de35910a81586f8d7a0d0efd11fff47a95c4d781f6b098d449205080d642157f79debd65802d15c882bde7c34c9a9224b60522c7fe5ad3d29420319cc6f6dbc6c9925b0dbe192f2a27c595d0f96c045b421b1fcd7efb6caaee317e5a31d8115ff5c277eb3eab7f6bd89f651fec11eb4fbddab88df2cb476e7dcf139f463a823daef7db6eb8ff55fc33edc38e9819f826a7b9da665664bc373af4bfd932f48726af4e39f677be8d1fc39a3319979f90ad666872590f040b2041601ba19ef42aae46c3852030eb2045e51dd03753671bac112889a00c512889a80851446213afb5c72eaf26df9eac0294cfc47e58bfda710ea9fdb8a9ff790925e845cff135250f3baa2f235abfe857cb20b772e767aed47abdfbe969d600cedb072e2cb18c4d5ff09684caefe6984587700261e1ca300cb78c3c1c44f8c340a9d8a962c931c031f0b66aa45ddc61a0d466bc812d86b872570c86b5802c79f5c3a901174027a5bc112788728a7893f95d91f6d478f534647c7a401a980a2bcecd90786690bf1fa379b3b1484efcf7b4ec8473b8fcad6436754e73ee6f8430df5f3f29252f01d2a588d063e2f435f1bcff5b36ed8482c5ac0e76945c39f5de241c757d2c06b8450f23f433f853a3563a37a73ac3b007c38dd50267fbf07d5fe857bfa7a8491809265ab2415d03323916901db2c81a3238010b609eb08880a20bf40bc4b5e498524a7a54b07da06334da29361745c24b10eeb00d62015900e8860b885f8fdc67b6d72e2d24df9163cfd9fec3a2e9fef3d217b4f5e963ba8f26714622ec216e0e984f655bea08afc724a1ec7df79a9c9f5cfc5a811be2f1bfe3841f9cbf03f8b002dc8258c790f7ad2c2d8a81e120f0e009963e8c52d81ae8206ade81b017c8ce162b2fc31126024722d403226ffa00d96404478bcfd0e2906a913fb05c4bda0a14d4e5119d229fdd659029183eff70c4a7d55a92c0b134b204987ce37de950367aec83707cec817fb4ecad7074ecbb6a3e71594afdb1120259aebf34a492f51843e8508f7e7553c0f47004c9e70088cc4b605069db7c021b21d354337addc28f3fd9f4099ff8f19ceffd96e3c1e1c00de7b1794abffc7a05af2ee419743925352a5044c7224023212991698ca12c85480159640776f97a2c3254b208be1e25d521109512c81204eeab87ddd124b6060421e958625155252906bcb842ce2bbdbd62d576e37cb71acf2779fb88449ffb49af4bf445e9f2bfdcbb75b844d89867c7e5bc79e6d30abfbb38b368882f655bf2a99056b9002e0cf819158b7c0b0cf8195ff3e90fe10f6474e1fad9cc288df40cf6b47c6c0005bf8f828bfdf43b8fe5dd0bf81062d0824c6fccec98340026c94bcf22af0fd873fd419e5b68c98cb2f5aba4cd6bdfe63e4f7eecabdf3a8d7214420888c228c7dfdc81e29aeaec3a4502a05e5d54146c7c7a6ca8675f2f45ffc9df4c286b7cf1cd1de342178bb4f5c94eab242f9ebb79e9342d403a4a169536a4a40fdc323e2707bc4d13f00e5bf1e85cbef42215f1b2085eddd0e69ebee0bfc8bf7740ae64392d1a827236f199ef346c92ede08585f35fe964d5a6f3e6c1d99c71cc3aaff06aafe4f23f46f2995df89fbd80e3d1799f713feab8a270780a0e7afa19ba08fe84cd98f7cf1cd23bba51cf9e20a38024622d702956b36caaa17df56fc004ef0ddeb64d0ed920b7bbe919a758fc9133ffc6bddf0b8d8be6cd366790cdd2d5914e800cf824e7a9c6e45b7cbd57c616ef6e4e44f274039006ae21f7700e00cb0688f0ec07c4df653af3739354fd273e9e03da226ffb4ec1ab3e29f6aa03879edf37681f0e734582f2d31fed12a5cfdef80b26e2c2e249e1c003ed063503ee07a68d0d825a147f7ce9f946bfbb64a0e42c55c2d1a894c0ba4a26873f9e657a407c43697b67da62082ba2b2527fec9affe24a58006d63ef2a46e78cc6f4fcdc892752fbd036e804b72e2cb3faada0add4d937a971a29a2267ee4f5b310eee7aa9fc57e86c52f529ecec25e07c3fd6eacfcfbbb4ec9e8b0d7cac9ef611057ff57ac0c8e9531f1520330f1bcc80fca78e30a289d80a0c28240b6512da85a2ac5a0933512b916f88e25f0be759640ac7459371060092469647c0b991233730ba41bf5143d600a8c06494844da0155fc5985eb24aff27905ebcb01ae3f1dab7e53e0170d4f707eaed1eb1a2ffc7334e204c1d38218c039610b94b8ff5668dc48bc39007cb00cef1016c83480b6126808bde5493e538c956226b8e88d44ae05b20ac812380a96c0464b2c81a3c32407e900114c8554a1f74312f2d8f12eb98006021c206d37c11208a2a04895c4e40c4cf24bc1d7b109ddfa5e82be88d6cf8f05f2fc4969917ad9e6ba16c002fec15ed404ed19eff66769f57f0d97f51ef430544b1280313123f1e800b0b4d801b5040b1c03afb8a7b75bd27272a514d031e2a68d44a605022c8105aa5b600f42fcc343fae2b24140e0863c1eb0042e033cb02e326f6c01af8a54c93920591a70f68125f0b22596c085babc848464f037204a91b74272cb9f51abfdbc0a76e95c87cf8be1a8a72cd4a598f344a80546477c08fd9f54b03f9f35c63f12037c02fd084ae6d8b892787400f880bba0648279145a000d2a64081c068b5c212ac7c90f6024722d30c112e8e9eec48fc01dc0daf40ebdb3ab155d03c11258b752728acb22f7e616e8cac812c8a6417df7c11278172c811a64c57c5e1627f554e0f733f231e9973ea6e87a39e9e7963d850affe52ac76fdaf4cee71388ae630fba9bd4e43fd087543ea28116e42cc6fc0aca7fe34ee2d501e083a6e74720f83aa836f6ebc58a28312959d502186e00582c82852c816c7ddbdd7443dc3dfa223546799c5d6009c4c457d5b0de3040e2d9e6810a3b45b1045e074b60fb823eed4484f05332cb2433bf0105b84f28d29ebcf2cd80e43e2d99856b2535b31c7f8b2612b7a00f250a4e363c44ccff5ea0810ea1f0cf523b687eb1ff08253a0c3cf0f127f1ec00300dc0e5e12aa8160cce6231f697679eb904a9004e304622d702196818e4b3c1124846412f08a0980628070d74bc4b025902110d194537c57650050fbafbe7cf24098968be05e81eaaf649d2935bf62426fbe7a09b11ea7f4a71f6a7669602c39f81fa84a0449ef3778de6c8116d0136fb71f79cc5ea7f9b90f7df8290537a27f4d75042c4e352e2d901e00367412053001ba05a8610df805be5440b900ac8afd0fa0c38a491c5b2404a7aa662b8636f875ec00359f0a793fe7196c0d2ba156009acd40d8ff9ed6409cc0555301da34e14560e03153367c1049e84899c5df8d8792f23af4175e3532bfcb2a7556e3f17fcfc9908f9a764140756faac4a34622c10c40243ee6674fadb61b5d90f8f7415cac9ff0054ffe38041b128f1ee00b04a8c9180a5d006a8767931d0479f41a408a80072d11b895c0b6402d6467c7b5fcb1d54045b581520d7edc038b6cbad6c582b19681c14ef4268607a4e8e8205f6802990e9122b42c63dc2f352332b905aa9c6dfca0a741f5c87aafd4731e13f8e7f1f57ff32974fcd42683f2dab4a45024c319f150b9b31131620cb9fa3751f1afeec9711bfa548157fc4ff04fd181a77857fb8e7498977078086604120277e4601b48dceb99254a800e48b4bb05234a800582d82854ec0b0df8f7a8046850ed05d2a69a019352804f703bb0632141eef929557a44cc05e016e2062ac081befb0e31edbede6009e9753ba697ce2dfa426fb8cdc7a35e1a780a7dfe0f5ad58d48c99c90263a37eb4053faf42ff8c025810aef6f741ff0d4af85f5c8b7100022c11043cf3576e0d545b5de41bf020cfd40fecf1522934d0b188fe034a4253273a015ea7437aefddc20a81a9bfe042089c1f1d21090d2ca8a8093e380eb626a7a6a21ea0547c0303d271e73afed517582524242105b346e5f149c59b9c963f9ec3373f3971f09559b05b1c74df5393ff40ef45805558d2a5959b18f11be85ea8fec7407bb8e81e60fe1a03cf8f71233644e7afbdb554004852c650185888d6b2ac3a3712b916206a2313e91a27c2fb8e5684b12dc0da1c1df7e12cf8a562f96a554b10b977b730574684046d48bb74dfbda5edbc482ad604a452d8723725a364612ed29c25ae2ce01fec0154753742ff07f1b7eab672ef5ce87d0865e5bfb5509695a346f118e3007cf7f0e80030debb1eaafdc522bedc0d1639b2c715d72e473833e7bb2399571167814c3a696004edbe6d912510ce5d3fb8047251095fbd6aa3417de089922698f5114c05b8009bd4c9d8d8b07200d891cf88b140382d407e7f57e771acfeb78b7fa0ddeaa10f63e02fa197acee10ebe38c03f0e0136641086982574349141454c834e775f421c759aef801c8a26624322dc0898b9180218f4bacb2040e2996c07e295e520f3593189ddd6cb0049234894e00591483c9d8c8106c5ea7520106be17cc52669b5d0b0c386f22a5b715bfbfd7b1ab96eb9f8727d4ef3de80e6818e02c384a0c8899b11e7c88fc4523734c357425548b0a18ec7705a08135b52872aac42e4622d502132c816e1b2c815ce9fa0707a50cdc0f8c06c4bba46566497a56ae748264a9e3b6ae866a0cd5ffcb9403600afde2fd9b13befb27c56f5fcb4ee9ef388e54949eee1b6726d2eb23e8efa0fc7d37326e01e3003cfc55602a8095a2eba0fa5f7ce4933d3d5d2aaf5c84a231c312f8b04123e913d66b24a6a448cf1deb2c817402d2d072b8d2b004aa474947aa13a88abbe74f686b01d2550460adc2fe47d2f7c05c4b745a80303f47eb7e7134ef043d3b53fa5a216ef520f45fa117b5a3e36c807100667ee0fc66b153e0daf17f671e35fee908d8d2e804b0256d31a181a9a61b5950832df2463a693e54f97737dd54d5febacb214b205920154b208a02e35d1241e673e7dc31b979f2a0d601c8cc5f29d9451b8100d0826be2ddace6fe35166095bfa7f73252785b65b0ff8e66f4e466e6087e05dd058dfbaaff49ab8cbf300ec0748b04de13e7c448400594a9006daf0042a398332e2034104c814622d7028a25109100c512780f2c8128f8d3891b04503eaf574a6b57487e597ca77a9ab0f23ffef9fb16520022d9c51b150f4042a2f64f48f708ccf638b7c090a74515fd797ace81904aff370b73b13af00fd00fa03d5023d32c601c80690699f2963011624b080bac866a1961d83f7dc4e703f9491d563d5a20010e6964b12c106009cc442eb1092c816db80c4d2111523d4e40e0d872b862457cb2040eba5d72e5c076d9f3dbff0fabff035a4e0536ec21ad6f76218035865069b1beea31715ebfb70b7fabbb00f9e3f72e78f1e9f80db3b9cfb7d07f83de1cffccfc33cd02c601986690696f5930c2783eeb01b4bcb08406f6031ac8f6a945a81c674ac048e45a2023af504d62765802c9844772a0aa951b943310b97717de2bebba7b534e7dfd81ecfbfd7f959b2748b9aa8fa6a6a2a31f9bf9b00ec088b140a81618f6b9d4c4af207f83246eb5246731ea97d0a3504b0c41968e1a63838c0310fc81f2578edf3880c815343035f870540fa2618aa7b75371d0172ea943d3934cdd2e66fb2259800c770196c03ee4152db204bafa900af02896c0c2ca258b74e50b775a4ef4b74e1d92fdefff3739f1e51fd1148829556bc276be79e5cfe06f807f3e468c05ec5b6014505277f759e9b9b74586faef5a3dc03d0cfc2df42ba8a57081d503c7da38e300e89f28b9011809e0affd32a8161a38e476abfc726e79152201cbe26aa508fb4495b020904d9d5c08ef3b5aef5967091cf6a16df06ac9467be85815b2fe5dd8f9a5ec7defbfc8a5bd5b6400ce8f554906c77f7ec5732aff9f98c4209a116301fb16f0ba6ea9c97fa0f70a22ab9616f21390bfdfe06cadf6cf185f7b1807c0daf36631096b00c81268e917df8baa71f60b6051606e9c178d5933f1e28d5254ce48db58670944aaa7a713751ea56009dc20ec37104b42aae4962b67e5c847bf92c3d07b97cec828d25b9605280156fe17d4bc0ef8647c174c5ab69919f89005863cadd207a63f97c2fb7b1fda3ec3071390bf7fc1b60b336c371f4db3807100a6196496b7ac1063152993fa6ba019d0a0c21fd1feaef60032a0bad6140506b5d6e26e0cb00416a05ba00b3cf737812fd6938b0c79dcc2a238b20496a03574ac081b215dd9ffad5af59fdbfe677176da5f44b1f94f61cd6b28fe639d444aac98c6dcc7025a6082e7df717f0fd2aa5cd45b92ab18f5efd0dd507d918aa543c6f620e300587fbecc25111ac8f2fe1550ed2f1be165aece36553045682043cd4622d3028a25b0a818f9c64e408dee0066a45ff1c61a4b20e97d4f7ef907d9877cffcd1307543d8bdda795965525854bde545d00935373edee6ec61b0be0f7d22dcef6c3a0fadd867a1bcb3cff2d301dc3fe1f432d310419538b1807c0deb780b5005c12b11ea01eaaad07184151607f773bdaa1a6e1877199a4824ad548645a200b3cf789e0bb272a80c44e3a6194c789284f6a46165802d721dc1d9dcf7668c02dd78fec51857ea7befe50baeed9474d91eb9f9dff8a96bc25f9952fa0f0af48673eb3dd58e0210b8c8ef8f0b7773ec0f3efbafdd0f6593e2064fb43281d80e659c6988f67b080710066308ae62382c689315d05255190564812e4c684925b56a19a06114b6e24322dc0a240bf1d964034c6f1387aa4a8a60efc00cc0e4597f4a2f0f1ecb79faa90ffd5433b545ac3ee1d24a5e4a025f67a35f9e7556c961414001a3116b06f8131f13a1b81c8f90648aa2b28c8b544f6c3dfe2ed5052fd5eb67fcef8dec33800f69f3feb011809a0ed56435917a0152f2aa8bd4e0756474b501d5da31d6f062c8e0552323231999125b01bab106b2c811ceb1f1c90d2ba86a86109245cf5ceb9e372e4e35fc9b1cfde93d6eb972c2120a63f95d48c327ca75f94a2a56fa3ce850591d9d38798f7c602962c3008981f27fffece9360e7b454f4c7e39e84b2e88f787f4b1e03c61919b780710042fb2af0dbc9480027ff06a8b6281063543d80a7af4b0ae00498ce81b448640ab901c8dfd0dbd2841f233e660d4b204690259040914ab204228a10c94204c385dd5fc9dedffda35cdcfd7580bccae6052726678243a14115fb15d4bc2a193975a6e0cfa60dcdf0ef2c30e46ec6e4bf45e5fe590360511a318e457fdf402def64f1d87131cc3800a13f6696a6f257bf0cca32706d512019025d1dade27539010f0432a0b814bb1989440bd00918f1fb553dc0905bcf25c2b16e10401594574b255802132330cd333a3222ad372ecbf13fbf2f873ef8a53421026085d16ffaf321b14f5ef96684fcdf8123fb0442fe85d38798f7c602962d40b85f6ff33671b48161d2e7b4ba1f8bfede83fe09aa2fd8c120230f5bc038000fdbc4ce274c05344319d35f06d526f7155d30dacb12214092a0485f2de29ee252d8d1d12e4ba0d7e51016d495a02d7421f81f224908efbbb46fabecfffd3fc9b9ed9f49cffd26db9747429ff4dc7af4ba781505adaf03d5b2420cc98f6d339a1da658c03fd82b7df777299e7f8bed7db937abfc3f82fe1a6a991e10638d4cb3807100a6192484b74405b00a955100a203b4c255178b02d3b273555160725aba761f3360e12d106009cc1757bb759640a60286d11eba026d83238525b0a7e54e80c71f21ff1bc7f7292a63bbd624b35f4ec92695eb27bd6f6a4629fafb901bcb88b140681618191e40c8ff106a6dbeb503f72349c74e28f3fe17433bb3d96bc202c60198b0c4dcfea513e087b20cdc12fec98795228bc7580b50b4b41e3fa6dae0c1dcaed0ec1d9205b248f53b362add771a51c4d9a73d0619f3d8102abba044350c62bf81c592413051de3c7950b1f90578fc9932b5270909c980f7d52065f5b2c2f76715ac9124e4ff8d180bccc50263f89beaef3a85bfabcf65b0bfc9cea14e61f03f430f434dd19f1dcbcd30d63800331825848ff8456c87b2187025d45229b4079de5dc28c8ca2baf51e800ec6724c22c909894845077fe384be02d6b2c8170eebcfd0e29aea997d2da158b72478ef61639b3ed33d5bdef3298fde86cda952410f964176f40a11f887d2a5e90b4ac4a38aae627c3ae1dcdf8872de0e9bd205db73e9601c7b58737cefe093dd87f837e0d35457fb3dbc9f216f3d76cd954da81fc423212c008007ff5d3a05a61131a17e856090dccaba8d68e370316de028a2510244174d6acb2049220c80f8e80b2fa95925b52be6017ed1ff44af3e5b372eccfbf03c4efd7d272f59c8c0edb5d282580b0aa0268959726e17dc9a9390b760fe644b16d014fdf15e9baf121fe9e6cd1f5df835598f3ff106a8afec2f415310e40980c397e18f60b60756a1594350196eceb6c6b513032e504a08adc48e45940b104221ad0dd74034c651656d3447c74b6034e9831ce1268292834a71b7721f5707ee71772e00ffface07dece667579292b324ab601556fd6fa0d8ef1584ff9702de976cf73066bcb1c08c1618705cc7caff13d5e2576474c631337cc8626b4efcbf85d2113012260b589aa0c274ae78390c5301cd509681d7432d554ab910b2254430bf129100b4113612791648274be0c0806a1844b6409df8d15448b104a20f4465c35addf090b78fa0e8b0e35680c7ffe09ffe55ee9c3d0a62225255d893948c12c9ab7c0eabfe77541bdfe4b4c8e633b0777766f4625bc0ebbc899cff9f91fb3f89b21a964c591246563f87fe37a8fd22164ba788df41c601989f67cf28009d805a681dd49238e1049078268f4e409971022c196d0107a582253013458103c8a7f758640974a3ce8393316b01f2e7e1997afa7ae4eae19d72f8c37f9333a0f4ed412323bb9298948e3a87e55258fd9a6ae19b99b70cf0bec52b5eb47bfd667ce45b80857edd77bec022e71820d02ce4b724cc5d6d85fedf505bf9024b473783ac85a88d9d42b2c05decc56800eb01acc5f5d95c06903376a4633a20b7ac32a4139b9de6cf028a25108e405f8b75964007223b940ab00466868d25704cba31d99ffaea0339f0c77f91c6637b413065b96deaa4819241e2935bf6243829dec6bf4f492a487e2c06ad268f615e180b04b34080e5ef1bc5f2373aec093674fab603f8e0ff801e9bbec1bc0f8f054c04203c769ced288c02f057994e80a54a30c2635c1d2d6a95492720a7d452bfa1d9ce6f3e9f070bd00918069743f79d1b3204a89d4e18a227fd6e3e1cbaaa95ebb1ba9edb9f9db7df0916bf6372f4d3dfcaf1cf7f2fedb7ae09e187762421314575ef639e9f55fe99f92b01efb3c4686de734666c9c5b40b1fc01e71f60f973d9b1c6190cfe3fa1bba1968b05ec9cc08cb558a4660c15b205f8abcc4a2c266497414ba05a191b1d55458103ce5e050fcc2926dbb09148b1408025b008bc00bd2a1560854e9793b662095cb25c8aaa6b43be95beb66639bdf563398855ff9503db956361f760c9a9799253fc3d74307c1391a6e750f15f6e7828ec1ad18cd75ac037d08148d90e71b4ee057c96e47d9685e1feff17ba056a395f60f9e866e0a405e6b614993c8c7911492cd5750000200049444154c402fc023312c0aa1716055a220a22553059e506d06a361fc8809c058492e11a8d682ca0580211cee73372a2a5ee18d2373a612a6064d827e5cb564936608576c4e7f548f39573e0f107bcef93df28a81f3bfad912904d11cb5f50f59214a27b5f56e13ad3bdcf9601cd60ab16e0ca5f4dfef7f7a206c6166aef12cef18f5016fed90a1958bd3633ee3b0b1807e03b5bcce72b26be085f61448091004b0dd347113a2644904e401ed301c60980e92247c812c8684d97459640d5070250bdacfc22950a6024c18a385118caee7d8750e1cfee7d21c1fbd0a637ab602dd8fc00ef03ab5f7a768d81f75931be1963db02ccf993de972b7f9b93ff159cec9fa09f42f5b49bb6afccec30dd02c601986e91f97bcf64310b0313a17402f2a05a997402504d9e57510527c0d404688db64003144b606e01a84c5d68650a96409f3e5a3934e051c57a8a25b0ae21e8950efb7cd286ee7d27bef8831cfaf0df55de9ffbdb15f2f6e757bea0e07dd908fd330560c458603e2cc06aff9ebbdfa89cbfcdb0ff355c0f297e3f86924fc5c80258c038000b60e429a760488b4e400a94f0c05ca856c8e4e640ee97e8805c40c90c3a406bb2051b90969d8395753158cd98ef6c424480419ee0e2ea0638049103a202b20b5975ffb0b87bbbe4da91dd8acdefccd64f840d7daca419a61e2911457d19790d20f4790d103f74efcbad439b627ef58c180b84df02019cff17aada7fc4672b7a4f7cffbf423f84daca1784ff2ee2eb88c60158f8e74d5400d301e950d60458a288634d8003b9e67ed0069328c89005c17211225998c4890668bf76c1122a0033b97082671d40d5aa8d929cf21de65ea514eede94935ffe51adfa6f9e38206ce56b5752d28bc025f18ca2f2cd2d7b028c8485760f61c61b0b58b60019fe48f2a370fef6a07e377112f2fbff09da61f9846660582c601c80b098d1f6415812cb484016949100feab154e0e8ed666c515a09c00d33b406bb3f91ee04348bee5c209b9717817f29eb790f3d43304f29a18ca27ca23aba0480aab96222c9f2603ae3eb97dfa8882f7b17b5ffbadab281ab4cc98a66e35213155adf40baa5f5574be19f90d801dd2d734622c303f1650dcfea0f725c39f0d921f5ecc6de8afa09cfc5ba14616d802c6015860834f391df35c8c04300d500bb5d66315ab47a603c81ac81524790212930c573becb7e042d2a66b7bbe91d39ffd4eee9c3aa43a06dab90827a2393d481b781cbdd2d678592eeddda256fe570fed5411023bc7e25852f7e6966e42a1df5b88106d06bcafccc0fbec1ad18cb76e0115c9ba88c63e1f286e7f1bf4be3c4713f437d03f409ba14616c102098b704e73ca072db00e6fff57e84fa03327841f1c3ff9ae6aedf7e4b1bff83ba97ff20510b99810efa461e6f90571ffed8d97e4caaeafe5c641e09ce190cd45d2b373551a60106904dbd03e9c982d7a53b39816da8c42d1cd92860aff4444028c180bcc970546478650f7721e8d7d3e154fef259c460f839d722d5cf9ff16cac9bf096a64912c6022008b64f829a765a7ab262823014c0758a663eb47cb59b6a74d484c04b14b39a05d966a0a710a23a15a802d811b41c0c355ff4d84fd3dc8e5cf5538e9fb903a181dd117104e3f57520a8a108b36a8703f2bfdd3e008d02130622c305f1618f1bb518b744275f51b406b5f9bc29c3fc3fe9cfcefdadcd70c0fb305cc2f45980d1ae2e1269c801cecbf146a2d1d8081036806d3870af1114c2284089a4840884f40b31b2bf0bb81f7bfb0e563398bfc7c2b4879ac30006a0e3ba7cd64f023a90f79fcb38b504c986a1cc03919d4ecacb5c0f0501fb8490ea12df69760c2e45c6e4b58ed3f51f037b7b099add39ac1b359c03800b35966e13fa713c0d018d9616aa074062c0971e8bd2d4dc841f7ab9a80ec227b2c73964e12c783bca8c2bf756c9f5af55fdfb755b56d5e4c732425a32b61fe2a05ed63b15f7a4e2da24006deb798cf241eceedf3768a03cc7e3df7b6ca50bfedc53b71fe84fa9982bf08fab2180720821e062e85f164bad54ca855432d3106629cb03f7ddffdbb8a35301785818635905699bbf436df964bdb3f5793ffbdb347556bdfb91f35f423a4a49720cfff9c22f5c941c15f4a9ae5af48e827357bc6bd05863c2dd2d7bc03d1c69de203cdaf4d619e80243fc4f91ba89f4de3cde770e300cca775433b762f76bb01f541990eb0d43b00e3540199034e801b74b369a807203e7d2ac69c638c58b3c090c72df7d071ef0c58f82eeffc12ce5593b51da78d62989e79fa11bf7d06bfa9874a4c4a93f4bc6520f509c0fb32f39603fdc16091116381f9b3c0d8a80fa1fe5ba835fa569cf7f7d9a5f6e585b142f09fa01f43e75e30838318099f058c03103e5b86f348a4d1ba05754397404ba19684ac817d200c623420313109b9e112148659e21ab274fc7818c4fe0b57c1b97f8af0be930710eee4e3b02749c95988c23ca656ea19b9b5ca0160f1d4d8d8b0bd036174725a21e07d4f8cc3fb9e96d40ca478120c80c7b621cd0eb62cc0efabbbe70242fe5b14c1cfb0cf696b7f0cbe00fd47e8a750c29e8d4498058c0310610f64cae570f2674d00bd66d60454422d090983dca09b0d10d378e1049499e2400b9663353e8bfbce7df527b9b0f553e9ba7d5dc642a8cc67c7bd7c14e715d7fd104ec02640f42a3169077c38fe888e8eb03bb45e925272f1dc56a2d0ef0554f9bf0ed2a0d5c2fcbf116381f9b6807fb04751faf662f227cc6f7478c0ee294f6187ff07fa05d43e95a5ddb399f12159c0380021996dc176e25f1dd3012d507601625d4022542fa85a67f11a73d8ec5bcf9a809c224c4266e538a3edfa913669dcbf2d00ef3bb207e88aee19c705fb908578d980e415d7beab1c0042f22864e24bcdac405aa65a9250a99f90988c5e0023f88fed7c47d59889ff91c98f79fd8cdce568e0f39c14d4bc86c2cec7b17fb981f74d18c9fc3baf1650ad7cefefc602621b1a57ddb61bb51ac4c5ed83fe5fd02d5036413312a1163071c4087d30d32e8b93feb3d0ff0c7d156a6b19989a9125b58f3f2b1bdefe99d46c781c0d624ce1186ca884d192cedbd740eaf3955cdff7ade25598d866e7df94f462b5da2fa87e4532b1529f0d8bcfb02a7f6087dc778555d5237ee2fff99b2958dd67a87a0176eb63d480d5fd06da67e72998b173b1001d5276f363a5bfb3fd30f2fdb69d60eeb00dfa2fd063d007bd5b7c6024b22c601c80c87a1ebaabd98401ff1bf46d68a16ef0d4ed89c9c952ba6c95ac79f55d59f9c25b082bb3be30be650014bc774f1f96cb98fc9bcf9f501113bb164948488443b502abf517d1a5f149b5d2b77a8cb1b140142010091893a4a48c40611f8e69c45860212d308cee7d1ee4fbfb5af7e2df8b704c6d2fdc9b70bd9f427f0bbd0235120516302980287848532e91f81ba604c816c8ba806ca82551750160ad63df7a76aecb2e2e53bd042ced1c83837ad0b8e7d2b63fab903f27ffe1a1c02adccead7275ce49bfb8f687a0e17d06c57af6222b741ed89e57adfcb1fa57587e93a2b1f308ccd83058c0efed02b9cf0155ec37d07bc5728dca945393e0e757d05f436f4ef9dcbc8c700b180720c21fd00c97d789cff847c6674727200f6a5938f9933ed8d3d3350e152c42d839d5f2fed13e90644977d171efcc17efabb03f5b2c8722e9d94b1424af68e9f701b75c6388784231a2d967512dc00894c2f7b7a09365f3f600b90f3eb3210cf15f86fe2bf403286b958c4491058c0310450f6bcaa51252432760185a0db5cc1580b18a2fa0afa509a41e4dc2c840567e11f2cdb14f23cbc93e00ef7b4f9a4ea27b1f9c21bb92882a7cc2fb58e19f87223d16e719311688360b30c4efe9bdac267eaefefd83b621fa2c503e0165be9fa17f43f00323449b180720da9ed877d7ebc04b3a0104e712210070b845840006b2f14c3fdad17637dd546d6cb3c017c0f6c2b1280cefdfbf745ac1fb2e6efb0c9cfe3794e363f75e39d9b3e10e43fed9c5df53d5fd768f61c61b0b2cb6057cde0e71b4ee473a702b2281ec6961db112659d92ee83f43b7420dcc0f468846310e40343eb5efae997fb9b7a077a0ec1d40dc99ad78fe60bf13b9bf5be2e9ee9494f40cc517909c968ec3c486b06322abfb4f7ff69edc3cba1754c9fcedb22764dccb2a5c27854bdf41f1e4cbe8bac8cc8b116381e8b2c0e8b05706d0c08774be8ee69da8f8bf03479841445bc230ff4750aefc8f403d5023516a01e30044e9839b72d96495b90e653480f0403a015950cb42021c3613a223c0d7994809443b5490118e8e1b57e4fcd71fcab96f3e94f6eb174166e2b76c93898164e1cb2bdf8c90ff8f141edfc0f2262c63fe8d260b90d8c7d5791cd8feadd2df711c45aff61d61dc2f8bfdde83fe1a7a116adb7bc03e4622c802c60188a08731c74b2142804e000b739898ce875a86798e81988664380c8f0f387a401f9c033c3b0a0493a3afcb9c072d926f1edea52afc1b0f6c57bd11600b5b42b29e0cf0ed9381af70c91beaf56cd87e5b0736838d0516d00263a37e1974931a1cc43e28f4f33aae4ff24ed8b80ce6fb4f42ff1dfa27e85da89118b080710062e0214eb90556f2301ac07fc9134047c0d633f60db81554d071ff9e5a313312909e630b6880532e9eb0a6e1e2b79fca99cfdf97960b275544c3eed590ad2fb794f0be7715bc8f243f468c05a2cd02a49d76779fc7c4bf0d30bf83e21f68c72d8cd9bd0d92fb6c8732e4ff0d94bf2d4662c402b6268718b9e758bf0d176e904e006b03b2a04c09d84aeab3a190b3fdbe74ddb92edebe5e49cbcc1e8f0680c2364265d0ed42e39e8398f87f2f57f77c8d1fbc501049098046d620cfff0a9af810deb716857eb64a2a22d43ae6b2e2c902cceb0fb99b51e8b74f4dfe03bd24f671876202fe117d0825ccef2834a483603f23116a01e30044e88399e365b195f06d2853029cc1e804b048d0868c297440cfdd1ba006bdab88723272f3c151cfcc4264093b1f5e41cbde5328f4bb7beab0f806ecd72525a5b07bdfa358f5ff00f0bee7e1f45444d64d9aab3116b06081e121073af89d45a1df0e38c1fb952340bcbf4d611af12af437e37a19ff9a7c3f8c106b621c80587ba20fde0f637e2cdca1e75e3caeb67866475038c7d574273ae30d20b79e9a9e89684061449007f907bd08f39f92b35ffe412e6dffb34a5d8ca109925d4941a7befc0ac0fb50e8975dfc88e9b867d78066fca25b6074c4875c3f78fc41e5cb90bf47adfa6dc3fb781f84171f8432dfff31b4196a24462d601c80187db0536e8be5bed7a04c09904298d18034a80d413400a4393d776f2ab4807f7050a104161329e0ea68956b84f77dfa9edc3ab6175dcbf8bb654fd8a58f2c7e85356f80d5ef15d43a2c41131fcb7593f64e66461b0bcc9305fc83bde2ee3aa98afc9ced87c487665321acfa7975a4c59c80f8edc6eb90a0023c9091e8b0807100a2e339cdf52a59c5cbba808994008b0373ed1e94b501ae0ed406201ae0e9eb42dbdaf4006f40aa4d7fc2ee89a78ce735b401d2770ef0bef35b3e02d4ef32aa9aed472753d28b24afe25945ea935bf60478fc232fb531e5b6cd4b6381872cc02e925ed72da4e8f6a8c97fa00f3cfec3f6d35f38307f1fce42d9c88761ff0b50a6118dc4b8058c0310e30f78daedb5e13d1d01c606d9b9866901dbdf81005200d180e6db2adfae6a03f20ae77df5ec4133a31b8776c929acfa6f1cda011633b645b0276cb89391bb4cf1f8172e793300ef03e4cf88b140f458600cada4bbc4d57e444dfcae8ea378df81027fa6ee6d0bd384df427f09fd0a4a38b19138b180ed1fff38b14b2cdf26c37a2cf06982a6432bc7ffc53fd685ab6e57479b74ddba06a851bb820ca665e728fe00eb47b13eb2eb4ea35cd8fa099af8fc41d1fa8ef8ec2f509253f325afec692942a15f2efe4dcd28b17e0166a4b140045860d8e7407eff92385af6286cbfd7d1184af73ede09bd052e06fe00fd37e85168484503d8cf48945ac0380051fae0e678d95eec7f03da0865fc9c9c018c81db2a10c478f17b0754f15d271c01b5224f4c544801a607c22183c8eddf3e714091fa5cdbb345a520ec1e976d77d3b2ab158d6f512de07d056b00ef5bb8b485ddeb35e38d05a65b60647840069d08f7b712dab703a45d67c6d9fcec17bde2d813857ebfc2eb0fa04c0dda860a601f23516e0153f114e50f300c97cf08c0b3d09f415f85869c0c672f819265aba5ee89e764c5e657a56cc59a393109b26d71e3816d7279e757d279f32a0a9bec8738935272148f3fe97cb38b37a2df01b31e468c05a2c302c4f4fb40e0d3df751a7a4abcce1b20b762ffaf90e536f664a8ff33e83928114246e2d402c60188d3073fc36d6fc0677f057d1bba0a1a32034e5a76aed46c785cea9f785e6a37a1d0ae6e050e675d7c882ab45e3e8389ff4bb97d7c3f7ef898a6b42fa91965928b89bfa0ea4554f8d709e97d8d180b448b05c8dfef41619f1b13bfbbfb9ccafb87c0e43771bb4cfd9d817e09a503c08a7f23716e01e300c4f91760daed131df00cf42fa08c0694424312c2e9d84ba0f6b1cd52ffd48bca21c8af5ca23d96b3bd456e1ed9a3887ddaae5d0889ca3731395315fae5556c46aeff29e4facbb4e735038c0522c502c33e97ead41758f59f06acef3ef2fc43a15e1e537c13ab7e4efe17a0ae500f66f68b2d0b180720b69e67b8ee660d0ef413e80fa08c0c849cd04f4c4ac2245c254b1f7b46ea1f7f5eaa376c02e31efd8c0765c4ef97f6c68b6ae267a5bfa3adf9c10116df31c4cf493fafe23955e19f0467c088b140345860c4df8f89ff2e98fcce2b0e7fb6eb0d91c277e276c9e37f0cca897f1bb4056ac45860d202c6019834857931cd028578ff0494b5016f42592b10b224a2ab6061756dc011406aa06aeda32a42c003babb3bc1e37f4085fc5b2e62c58386447685457d69d94b54eb5e4efe695973ba5cbba737e38d0542b600277976ecf3a0718fbbe7029c80db887ccd6991eec3c53442bf8272f2bf02b5ff47859d8cc4b6058c0310dbcf371c77d78083b02ee087503a04735a5227a5a64a496d036a0336a358f079452674f3e85eb0fa6d45af72462aed4b725a01a20a9bd4e49f59b04a9253a3a77ba1fdbb357bc48a054640dac3a63decd8a7267e90faccb1c08fa661c1cc212827fe3d5083eb87118ccc6c01e300cc6c17f3e98316e0a43f110d781daf6ba173aaa82362a0ac61ad7200da1b2fa3bab90f87b4272cea4bcbaa56137f7ee50b0aea2762bed2f6ac68462fb40508e91b72b700361b98f8bdae9b80f41199372761c8802bfd2dd06fa0d7a0835023c602b35ac0fc5ace6a1ab361060bd4e2b367a0ac0d609160317451242935f73b785fd12380f7316361c45820722dc050ff9007133f887cdc3d170390be21fb8eefb43be4244f1cff0ee876282bfd99fb37622ca0b5807100b426320366b0c03a7cf67de81bd04dd06ce8024982a466550472fde5cf02deb7d490fa2c90e5cd6942b3c03026792f0afa06faae2af5ba90e39ffbc4cf8b21946f1f9413ff01a829f283118c58b7807100acdbca8c7cd0029cf439f9bf056534600d3464b400f6d54a524a16e07dcb51e10f785fe9539262a87cb536330316c70263a37ee0f63b159c6fa00f2c9998fc99ef67a57f18a413c73805e5c4cf953f8b677c5023c602b62c601c005be6328367b040293e637dc08423508fd773aa0f98e11ce8d657a0f8fbf32b5f8413502f74068c180b449a0598df673bde01676360b5efbca998fcd8b92f0cc242814bd089899f397f77188e6b0e11a71608fb0f759cda319e6f9bab916fa017a007a174045e84564313a161930093df182881c96d62c45820722cc0ea7d62f85598df7155065d4de21fecc677352c14fb9ce41ba1bba03ba1a4f0ed861a31169893054c04604ee6333bcf6081e5f8ec79e86bd017a18c1084c51120bc8f587f42fd32f31b243dbb16698052d400a4e214468c0516d602a3233e34c34298dfdd2403e8cac750ff10f0fc6180f24ddcc8005e70e2df07dd0b65d8bf156ac458202c16300e4058cc680e328305581330e108f0dfe219c684f4516252baa466962b7effccfc959291bf42d2b36a24293527a4e3999d8c05ec5860c407c63e4fb3781d3730f15f57797e36ec0953989f97c2899f79fd7d504efc27a02d5023c60261b540c21824ac47340733163016301630163016301688780b8425341bf177692ed058c058c058c058c058c058e0010b1807e001739837c602c602c602c602c602f16101d6009814407c3c6b7397c602c602c602c602c602931630118049539817c602c602c602c602c602f16301e300c4cfb336776a2c602c602c602c602c306901e3004c9ac2bc30163016301630163016881f0b1807207e9eb5b95363016301630163016381490b180760d214e685b180b180b180b180b140fc58c03800f1f3accd9d1a0b180b180b180b180b4c5ac0380093a6302f8c058c058c058c058c05e2c702c601889f676deed458c058c058c058c05860d202c60198348579612c602c602c602c602c103f16300e40fc3c6b73a7c602c602c602c602c6029316300ec0a429cc0b63016301630163016381f8b1807100e2e7599b3b3516301630163016301698b4807100264d615e180b180b180b180b180bc48f058c03103fcfdadca9b180b180b180b180b1c0a4058c0330690af3c258c058c058c058c058207e2c90bc50b7faf77ffff70f9ceadab56bb27ffffe073e0bf6e6a73ffda91415154d0ee9e9e9914f3ffd74f27d3cbe78e1851764d5aa5593b7bed036997e7e5ec82f7ff9cbc9eb312f8c058c058c05c26181e5cb97cb2bafbcf2c0a1ecfcd6ccb4bfdd39e88193c7d09b31dc8b65edeaea1a9b2ac78f1f9f755f4c1063dc3e9b783c1eb5fd1ffee11f663dc6fbefbf3fc67133093fdfbd7bf7181eee8cfbf3b853a5a9a969d6b1d3ef8be79d6a97e9dba71e97af792d972fffffed9d5be8a6d317c79fbf068de38d99a6497183a290a93934dc88121794c4054318394c3335c9cc348c1c2e24dc2824878822255c4c4ab941332932f227c722242939e490f4fbefcfdbacf7bf9ef5acfd9cdfe19d59abde9e67ef67edbdd7feee67efbdf65afbd9ef7f17eaea427e4911b24927e1a674220b75adc384cc90031ec18576b064eb47fec4792465cb1559ebf000675dbea4cb5d6db9b4698ed7ca6771b3cf9bc249b1ccb64953da975e7a292b674efe886f3fd6cc3356bc575d883e23f5a5ff36515d1feb5a366317634497f2b57c0f3df4d034ade491bb7ab2d93eacd36eddba7581bae6887188f1827c753ab9a75e3ccf11e9ebcab7f357aecf7bf562ac1739fec5d76e1dd202c9cbea550e50bb90058b86ab9b6474debcc0de0b602716d2e41a50e7c73d6975bdecf3ba302fac4cbe3a0fee732fa31e006c1a0953c7bace6065923a784a873c93bc73eda53b0775ea53be9491bb7aed44c7f7f87375145efbbc290c361e3e4de9789e7bf74596b8761b5bf627bcfabc5352ff360a80bc9fded8d7a76cd2f4291f39ec5822f978574fb65cfadc582975d757e60a5b1e6317f8b42130f7c66caf2d345652a6572f8f4ff8db5c0f3becb085c71e7b6ce1eebbef5e38e8a0832af56b934713cf4cf600a48a1769004f65b727cc3142a9218aa79e7aaa38e6986324aaf69a809af093ae892ebcf0c202f96649c71d775cf1ecb3cfba459c7aeaa96e3c6992d2e33e2392badd77df7d057c6353522c8a8d1b3756b27dfdf5d78b6ddbb64de3a95397f253e799a6ed7a73db6db74deadc355df007020712028c7d0f3ffcf07ed757d242ad38fbecb35b37659ae84bbc32a6814f1b3af9e493b363b64d9f26e499e37de49147168f3cf24871cd35d714dbb76f2f28731634933d005d85fdedb7df4afb016ebffd7677a2f9e1871f8aefbfffbe58ba74694539a0a14977c5155734e2847c5dfc475e86c89c56c3c5e1871feecaba72e5ca829750ef53205ca7d45c7ae9a5251c74b9394c348fbd7ff9e5976d54258c62c100623bca871f7e58f2b9213b75f248da854ea469d7ae5d3ad8e91e79503856ad5ad5299d6516d96cbc84d93701515f4dde3b6679de7df75d9d24ee03815a049adec55c62196b786efb18718c299b376f2e6ebcf146822e3595ad176036035dbe7d46f8ebafbff6a27bc7b11062a1d6853efffcf3123b8b253ba6c1207df8f8e38faf3c677c6371d834378037f95f74d145a532c70c3cf9e493c5c5175f3ccd9285d8a2458b8a2d5bb614c9a2318d1fe3a69369c19a5330912421a63f4cb71ee5fc34696259c0dcaff3f04cffda140daf6736c6dca3f3f17844366b769278b9363dd7f5467ecf546465c6fda0c99aa730af6bf9f5bde5251f70f2cc4cc8a3e3b9b724f5f3e4468ea4189464f1da95b4960f9989a35db5fc75f775ed645d01b97a48fe4dcf85afe9eac9d494269eff7f1c38d0b1a8eb734dd8d83e4958a7b1e308efbcde8b35a46cca692a5fcbd2f5be8d6c5efda8237b0dec7843983c75bc5706e3a71e93e0679cb3c43ca5eb64b1d0fc9423bc5e99fab9f0b5bdbef0c20bbaa8e9fd830f3eb870c821874ccb6d9b5f8e6f7417c029a79c92ca2a93ac26f56a583888d35f0324d02aabe42fbffcb2648a262d2b7de235a1f1b1526d43975f7e796bdea6fc90ff95575ea9b01d7becb1a5b8b56bd796c2bb77ef2e85736e00eae469b337dc7083abad224f93164bc198d9ec8a026dffe69b6f2e3efbecb3926c5ebbb202b67c2422ce6beb52862d03e10a680954b01d3008d03f2d1d71c411366a6ec3769ca4225829b170d8f18630639d8e3ff3cc332b757ff1c5174b6312fc575e7965852fe7a2ad30a688ae966e2f8f5c1ca6ffe79e7baef278c3860dc5fdf7df5f1c7cf0c195677d22465700ce38e38c8a1cdee45861da1b71da69a7551ebdf1c61b953822bc78fda9a09b484562c6198b8e3efae8daac98c4adf9ffce3bef2c987035e106b0b462c50a1b55bcfdf6dba517bac2d01071d65967b966364c89dee49d34e14a8ee79d775e91ac1c33f587a1f8b451662ac24544201008cc2502769ca4120f3cf040ebba7873d09b6fbe5949cf42c92e22bdb22b09f746c09b2c85b9c783e27ffef9e7e2aaabae72f34709607f80b728ec5ae8e80a003e714b8f3ffeb88dca86d9fc60c99b7ce0f17c4f9ef667f393302beea10d984c499349f0924b2e916ca7572d9fddd0824f8e17f0830f3e98f27373fef9e797c204ac2581b84f3ef9844b6ff236f3dd73cf3dd9c9d6530ae8006cf6fcf4d34f8b644e9b5814b0e08c4d60d7375f2c3dc97ee6fe903d2810d85708e4de45fa4e1d31a6f2fef34b66f0c2db5bf3dd77dfd56551e4caa66f34594db112e6fa1056c431c993050bb25ee1f7292fb78848ae813ed94dd38c69499e66baf7e6cf3fff2cb0f23efdf4d3f65171f5d5574fe2bb2c782b99a488d115006f6219da783ffef8a327fb64d2711fd444da1577df06944ec1e4c77fa8577e000009854944415444623547cad18a8f9dd8df7ffffd8994efbcf34e49da9c1ba0c49402bffcf28b8d1a1caeb362d086759b0a919b8d3b68a60c685e47ee22a06d27cc6d285b6392e7d61833ffc82b106883803766ea743ca75ff16342b0630dbc98c8fbd29049e484134ee85bac9b6e882c92a1756b4abc7765fcb654b7d860e166694c4bb2cd1b05e5baebae2b9e78e209fb68b24990afe5962c595279d636627405a06dc1ff141f8059bae38e3b6cd4e0303e27517cd2a6bcca9702afbdf6daa48ce79f7fbe5296e706b04c5f7df5958d1a1cc62786ac3962d76b9d1220e918b0c079881260db89416f961d4d648f6b20306f083cf3cc33aedb6edeeaf14fc8db7521c55768e0ad89f1cefb8c5af30cb9c7128052e22979175c7041e1cd216dcb5bd496b12d1f2bb7317c136dcbebcab767cf9ec924a63f33e9a231b6294f36ac086f6e42174dd362e6f9fc252fb9ce62f54abbdd7befbdb59fdea104b012e7b344f611e4562fe4050e9eeb40ea507765c30fca886e1bdd667569f5b3bacf9f72ae259d3eee0381b110c8bd8bbffefa6bef22f83c0cd75d13e5ca269d7c0a9bcb83f109ab9e47ffc64f61f1ebe7c6255b87134f3cd14665dda0c2c806743bf6e9714af8e6e13aba02c08b62c16025d8772200446f6320f19ebfdfdbec01af2676d1b2d3d433a569beba7baf53d019d2c94da5af1ac8c35b55b3792e477c8fca242b16048fcfdb2be1f1d5c559c5035ecac6a55137a820979cb7809cb4efb9e79e5b39b8037ca93b7b1dfa104ac0ce9d3b072994afbefaea54d63e32449a40602c04fabe8b4cdea465739b1d5bebdc765aeebe65930763fa2c161c5a3eb9f7ce23e04c8e2ee4f9f573e350dfaf2718bf71c9ec0b3af4d043277b3ff0fb5b627c64b3605f1add05e069b376035c9db0deaaeca4934e729378da9bcb682299c06ebdf55613db2d289d828e213f26453bd93141da4edba6243e0311f23039fdf4d3e571efeb5d77dd5531679159974fefc01265813feae0e4404bfacf8aecb3a630585a5740539a781e08ec6f086076666cc1ea66e9da6bafb551731db6e327956121d1c59de86d885cb3664d05176f6c46d96a436c2a6ce30e6d93571d0f1b401f7df4d1c9a63fcbc706cc75ebd615e93c18fba875787405c06e6a43127ccb6d1bd0dbe1ba7af5eaca0630f2b327d3b1a2cdedf6b488ecab06d413b995a12eac95260f134c5c755684babc79c6cbcbc4cdfe07fbd263beefe36f5fb66c5953b19d9f630590d3bb3a278e0481c07e84005654db17981cf7b7af596c1d6942c62926ec36f4f1c71f57d8c462a91ff0c9b3a52fbef8c24665c35892edd89965eef180953f6e5426794bec4360037b93fbc6a6b3e1d15d006c4860a7aa2626145672c47ffbedb7fa51c12a1eab81fcd5231a202f805e35939e49309d8e54e0c3c725e01de2600fd62915e404c6700538d996a2f444ce039414efc5c397a7fd56da0de061425e747cf2b79f042e5fbebc603266f2f4346ad2cae61756f01c2c619509fcedec51d00a553a6dacc064267e3ff2a03d70c5d08ebacd28034a276b4dae745e9421eac53b4087a6ec3634c41580d9b4ee53cf2e72b491357802815922c0bb6cfb2a935b9dcb0e79eafa01fd983e96234cf0757d88c5c41017af2d977363ec58429839e0adb7de9a8e5da4c315ca9708a491ff2de1cc003b07911e4b2a7c3ffdf493ebb2243fcf8a49bc478c5f94c3bc34361d75d45193b1f7b2cb2eab64cd170137dd7453f1c71f7f549ef589e874ace0f44cc2bd3709d44afadc518e36ad0e271fcd349f34b1e947adef751e0908f7b8e034a94dcb8187b047e9852ff1591eafdee4a77f69d2b3c926ff06a879e49e632e2da58e3ecd2f27a74da3c3f2379d5e5a5b3fea6389a386a903327a79587e1bd618d977421f5d8a2c960417b97af890c6d6c3e6d314b6e9a5bc3632096f5ccbef7de0e1f797dcbb66f1b27d51f72378bda3d2e99f924f9fbeaad3dbf29bfa90954fe4f0ae9e6c1e2e5e1debe4482ed969fd29d78e377569e599cd837c2c165e5dbdb1823c35a61e167571b9a380d3e4bfb078f1e2525debf2697a36ba0b201538394ad69eb0447c1d695f31da6c57ff0a6972abddba7267e90af0ccff9ce0e791a7796aeb411f39737b27bcf25901609dd0847951fc8eb98d989a5fdfd3fe7ad7befd5eb8ebe61be4f34c83baccb80f040e0404d8686c69969fa1d9b2f6459895b51d8feacad5d653f8b0ee769983288b347d080b4c97b2fa94411adc01ebd7af2f7efffdf7be5954d2cd4401c03472ce39e7b436a7009eddfdc9e76654b8e925e039a61f31ff546ad8226256be1cbb470151f4e1405a344c68d69f64d383098a4e1326e40b8f9c35a0cbc9dda33c71768125fc4ceca0c5d4dfa65cd2a3e4e0a2d1267ebb39d4866db95ed853523cbe880b04f6670418436c5fc4c4dd769fd53c60c378c818d27662b50bab2e73100b0b0e6a1be2c6e8ab3ce4da424efa93e79c00b969d3a6e2efbfff96a851ae9df7003001e9a3699349c4158406c0afcfe4c177f07cdbae577d9cc0842f98956f0e78067cfc39e23bd69bcc48ffd1471fd54efcf877f16fc92773dc6b9fb6088eac741ebda3d65a205030f4a730b97a4b9e5c9980f59e07d2e84951f372cf9709dea78d9a0f3918003c4cd8fd4a797c0aa9ebc93d2b78c181fc6cfd884393e5f862ddbec47ff3cd3713eb0af980139609f2d2676eb32f007cd903e259626eb9e59662c78e1d93bd09c8c9ff2008d14e9af411ca3a9e7c1914b465c1ae86501a753d757aefdec3013e1b4fdd820281b608d0576c5fb6ef542eaf6452ae1d6b18436c3f20aff7de7b6f92a55776ae2c8997bd3a846df9c293bbb6190b252de5d883746cff175ee6057eec7562ecd5e30d3c8c398c157ce2e88d397a0e626c679f92cc412c40d83b459be4e61fcac002aac79b5c5dc9e3faebaf2fb5b9c694bcba10e30d5610267c6445c1f8ebafbfba64d18af73f890b7f4250201008040281402010081c4008ccc4057000e117550d0402814020100804e612815000e6b2d942e84020100804028140601802a1000cc32f52070281402010080402738940280073d96c21742010080402814020300c81500086e117a9038140201008040281b944201480b96cb6103a10080402814020101886402800c3f08bd48140201008040281c05c22100ac05c365b081d08040281402010080c4320148061f845ea4020100804028140602e110805602e9b2d840e04028140201008048621100ac030fc2275201008040281402030970884023097cd1642070281402010080402c310080560187e913a1008040281402010984b04420198cb660ba103814020100804028161088402300cbf481d0804028140201008cc2502a100cc65b385d08140201008040281c03004fe0744e09c800ccf2c0f0000000049454e44ae426082, 1);
INSERT INTO `premio` (`id`, `idCreatore`, `nome`, `descrizione`, `foto`, `numMinimoPunti`) VALUES
(2, 1, 'On Fire', 'Vai a fuoco ', 0xffd8ffe000104a46494600010100000100010000ffe1001845786966000049492a00080000000000000000000000ffe1032b687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f003c3f787061636b657420626567696e3d22efbbbf222069643d2257354d304d7043656869487a7265537a4e54637a6b633964223f3e203c783a786d706d65746120786d6c6e733a783d2261646f62653a6e733a6d6574612f2220783a786d70746b3d2241646f626520584d5020436f726520352e332d633031312036362e3134353636312c20323031322f30322f30362d31343a35363a32372020202020202020223e203c7264663a52444620786d6c6e733a7264663d22687474703a2f2f7777772e77332e6f72672f313939392f30322f32322d7264662d73796e7461782d6e7323223e203c7264663a4465736372697074696f6e207264663a61626f75743d222220786d6c6e733a786d703d22687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f2220786d6c6e733a786d704d4d3d22687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f6d6d2f2220786d6c6e733a73745265663d22687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f73547970652f5265736f75726365526566232220786d703a43726561746f72546f6f6c3d2241646f62652050686f746f73686f7020435336202857696e646f7773292220786d704d4d3a496e7374616e636549443d22786d702e6969643a36333744313032444430313231314537393030464645434531393739334245412220786d704d4d3a446f63756d656e7449443d22786d702e6469643a3633374431303245443031323131453739303046464543453139373933424541223e203c786d704d4d3a4465726976656446726f6d2073745265663a696e7374616e636549443d22786d702e6969643a3633374431303242443031323131453739303046464543453139373933424541222073745265663a646f63756d656e7449443d22786d702e6469643a3633374431303243443031323131453739303046464543453139373933424541222f3e203c2f7264663a4465736372697074696f6e3e203c2f7264663a5244463e203c2f783a786d706d6574613e203c3f787061636b657420656e643d2272223f3effdb004300030202020202030202020303030304060404040404080606050609080a0a090809090a0c0f0c0a0b0e0b09090d110d0e0f101011100a0c12131210130f101010ffdb00430103030304030408040408100b090b1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010ffc00011080168010403011100021101031101ffc4001d000100030003010101000000000000000000050607010408030209ffc4004d100000040205070a020804040309000000000102030405061112136107152131415171224464818291a1a2c1e10814233235425263b1d1336272f01624439253b2c218252654567393a5d3ffc4001d010100010501010100000000000000000000060104050708030209ffc4004711000102050005090603050606030100000001020304051112062131415107132261718191a1b114233242c1d152e1f0152462728216435492b2d2081733a2a3f12544c263ffda000c03010002110311003f00fea980000889f737ed7a0022000005b80000444fb9bf6bd0011000002dc00002227dcdfb5e800cd6914d6614727b7d0abb4c44a49c3695a52665a0f81e8d9bc7357281a4f59e4f74a966a41f7811da8f586ed6d554e8badf857522dd38ebb935a448cb55e4308a967316d74dbc53b49d9252597ced04969776f91729a51e9eade436b686728d48d32868c80ee6e3a6d86e5d7dad5f993b35f14430152a34c5356ee4bb78a7d781a209f989000889f737ed7a0022000005b80000444fb9bf6bd0011000002dc00002227dcdfb5e80088000016e000000000000444fb9bf6bd0011000002dc00002227dcdfb5e80088000016e00001113ee6fdaf40067794585b72f878d22d2cb960cf0517ee4341f2f94be7e952d516a6b86f56af63d3eed4f125ba231f1987c15f992fe1ffb2808796d2c9c6d6a4a92759288ea3231cb1023459688d8d05cad7356e8a9a9517a949f3a1a3daad725d14d3287e5508cd12ea4cadc9445917fce5ea3a4340b969be34fd245ea48bfef4fff0049de9bc85d5b4636c6924fe9fb7d8d31b71b79b4bad2d2b42cab4a92759196f231d1f0a2c38ec48b09c8e6aeb454d68a9c51484b9aac556b92ca8454fb9bf6bd07a1422000005b80000444fb9bf6bd0011000002dc00002227dcdfb5e80088000016e00000004467ee87e7f60033f743f3fb001f6dfe4dcf6ad57ddb800cc3d33c9ee00661e99e4f70033f743f3fb0019fba1f9fd800fb6ff26e7b56abeedc00661e99e4f700330f4cf27b8019fba1f9fd800cfdd0fcfec007db7f9373dab55f76e0041537a3d6a8bcc165116cd96ef48acfe1323dfbab101e542412a1a2938cb6b6b734fe9545f445331408bccd4612f15b78ea312b65bc70cd8db3616cb785858b4511ca04ca8baca1d75c54099f29852b4a7149ece1a86cbd05e52aa3a1f112044bc5965dac55d69d6c5dcbd5b17ab6982ab5060d49334e8c4e3c7b4d5e5b3482a630a98b81789286b596b3acf61968a8f40ebfa0e9053f4924db3b4e888e62ede28bc1c9b97f486b59c928d231561476d97d7b0ede61e99e4f719a2d4661e99e4f70033f743f3fb0019fba1f9fd800fb6ff26e7b56abeedc00661e99e4f700330f4cf27b8019fba1f9fd800cfdd0fcfec007db7f9373dab55f76e00330f4cf27b801987a6793dc00cfdd0fcfec0067ee87e7f60033f743f3fb0022000004bc879c767d4012e00002a2000025e43ce3b3ea00970000151000012f21e71d9f50076a74c144c9e3a1ccabbc86713de93189af4ba4dd2a6602fcd0de9e2d52e64dfcdcc437f0727a9e63b5c47e7a58dd7616b8858585ae2161624e8fd259a51a8e28e963e693d4e367a50e27728848b46b49ea3a29389394f7d97e66afc2e4e0e4faed4dc594fd3a05461735193b177a761bb511a672ba5b09790caba8a6c8afa1d47ca4e25bcb11d93a17a734ed3395e725d718cdf8d8bb53ad38b782f8d94d5d55a447a544b3f5b5762f1fb296013631254400004bc879c767d4012e00002a2000025e43ce3b3ea009700001510000000000004bc879c767d4012e00002a2000025e43ce3b3ea00970000151000012f21e71d9f5004944911c3ba47b50afd0784d25e03d1782fa1f70f53d3b4f2bad644b5157b4c7e75bd2ce5437aa26a3f36cb78f9b15c45e05862716c82c2c76a5d358d94c6371f2e885b0fb475a5693f03de580c8532a739469a64ec8bd5911bb153d178a2ef45d4a78cc4b429a86b0a325daa6f140e9fc152e86f9778d2c4c9a4d6eb35e8597e24e186c1d89c9ff002872ba632fccc5b3269a9d26ee5fe26f5714da9d9acd575ba144a53f36eb86bb178752feb581b24c00004bc879c767d4012e00002a2000025e43ce3b3ea0097000015100000005b80000444fb9bf6bd0011000002dc00002227dcdfb5e80088000016e00001113ee6fdaf4004146b84d41bee9ea434b577118b2a945481251a2afcad72f8229ed2edce331bc553d4f3e1aab3aead63f3d175adcded88b42961616c856c311682c3138b5c02c5713ed0b1b110510dc5c23c6d3ad2ad25493d2462ee4676669930c9b947ab22316e8a9b514f28d2f0e621ac28a976aed43d0b93fa770b4c65f61d34353187495fb45a95fce9c0fc0765727da77034c64f18966ccb13a6de3fc4dea5dfc17570352d7688fa4c5bb75c35d8bf45ebf52da3619812227dcdfb5e80088000016e00001113ee6fdaf4004400000b70000000000002227dcdfb5e80088000016e00001113ee6fdaf4004400000b700000889f737ed7a002a34ba2ca0a8ccc5faea3b8520b8ab417ea225a773bec1a373b1affddb913b5dd14f532b4483cfd460b3f8917c359835e10e18b1bb05e10580bc20b017a4161638bd0b0b0bc0b0b1dd934f63e4332666b2d78db7d855647b145b5265b48c6528d579ba0cec39f92762f62f72f145e28bb150b69c93853d05d02325dabfab9e96a1f4b2029849db99c19925c2e43ecd7a5a5ed2e1b8f70ed8d11d2995d2da736765f53b63dbbdaede9d9bd177a1a6aad4b8b4a985831366e5e29fada7d67dcdfb5e825063088000016e00001113ee6fdaf4004400000b700000002233f743f3fb0019fba1f9fd800fb6ff0026e7b56abeedc00661e99e4f700330f4cf27b8019fba1f9fd800cfdd0fcfec007db7f9373dab55f76e00330f4cf27b801987a6793dc00cfdd0fcfec0067ee87e7f6003edbfc9b9ed5aafbb70033ccb49a6514761e08a2adae39f22b3555c8415667af7d91a6796da9a4ad0e1c922eb8cf4f06eb5f3b132d0a95e7a79d1976313cd757a5cc4ede23952c6d3c45bc456c3116c2c57116c2c3116c2c3116f8858622d710b0c4b0d07a671b4367288f648dc8772a444b35e8711fb96b2312fd0ad2b98d10a9366e1eb86ed4f6fe26fdd36a786c53115aa443abcb2c276a726b6af05fb2ef3d0f05190d4ae11a8d837492c9a49685172ad92bbb70ed6909e97a9cb327255d9437a5d17a97f5acd2d310224ac57418a967356ca7df30f4cf27b8bb3c4661e99e4f70033f743f3fb0019fba1f9fd800fb6ff0026e7b56abeedc00661e99e4f700330f4cf27b8019fba1f9fd800cfdd0fcfec0067ee87e7f60044000009790f38ecfa8025c000054400004bc879c767d4012e00002a2000025e43ce3b3ea00c332e1484a674c0e5ccaeb6a58d133a3fe21f295e85d4392f961aca54ebfec8c5bb60371fea5d6efa2771b734364565a9fcf3b6c45bf726a4fbf799e5e18d4f625b61786161638bc30b0b0bc50ad858e2f0f7858ae22f02c311787bc82c311787bc82c3134fc8b53d4c9664746e68f114247a88985a8f434eec2e0aafbea1bab924d355a4cd251675dee622f4157e57aeeec77af6a909d2fa17b5c2f6d809d36edeb4fba7a1e801d426ab000a8800009790f38ecfa8025c00005440000000000012f21e71d9f5004b80000a8800009790f38ecfa8025c000054400007d5d9dc3d1c914d67514656215ab645f895a6ca7acea2189aed5a150e9d1aa11b6436aaf6aee4ef5b21794f937cfcd32599b5cb6fbaf81e5a8d8e7a6118fc7452edbd10e29d71467ad4a3acc70b4dcc459d8ef998cb773d55cabd6ab7537f4182d810db099b111113b8f85a16f63d2c2d858585b0b0b0b6161616c82c56c716cb7858585e62162961798858ad813a6932325191969232154d4b7418a2ea53d31920a7654be43f271aed733971136f567a5c47dd73d0f1e23aef932d2ffed2d33d9e65dfbc41b23b8b9373be8bd7da699d2aa2feca9ae72127bb7eb4ea5de9f6ea2fc3659162a2000025e43ce3b3ea0097000015100000005b80000444fb9bf6bd0011000002da1b0023af49022df5a02267dcdfb5e80088000016e00001857c4352c439110744a11dacd92f988aa8f69fd44f769eb21cf5cb469266e874280bb3a6fedf953ebe06cbd04a5591d50889b7537eabf4f1317b67bc681b1b1ec716c2c2c2d858585b0b0b1d98682898c61d7a1937973a5682fac49fc556d21e4f8ac86e46bf55cf27c56437235faafb0eb5ae23dac7b58e2d858585bc7c42c2c2de3e2161616ffbac2c56c4b515a4713462770f35873334a0ecba823faed9fd62fef6d4245a2d5f8fa3354875083b116ce4fc4d5da9f6ebb18cabd319569474b3f7ec5e0bb97f5b8f4ac14643cc21198e84709c65f41388516d2321daf253906a12ec9a9775d8f44545ea5341c780f968ae83152ce6ad94ba0b93c8002227dcdfb5e80088000016e000000000000444fb9bf6bd0011000002da644a234995647a0c851511c96508b6d6879fa6b4b694e4da96c74aa06396f4134f1a910d1066b6cdb5729245b53a0ead039367f4a2b9c9e6904c53e5a2aba0b5d7463f5b7177492dbd352db52a1b72569521a474f871e2b2cf54d6e4d4b74d4bdbde68123ca249e9c433250d5c3c732466f42aceb32d5a527f78bfb31bef4374ee9fa6106d0ba119a9d262eded45de9e69bd08156f47a668afbbfa50d76393d1782928270600002dc0088a5548e0a89c822e7d1ea2bb86419a535e97167a1292c4cea187afd66068fd3a2d4263631352715dc9dea5fd3242254e6992b0b6b97c137af71e3c9bce63277338a9b47bb6e222dd53ab3c4cf51605a8712d467a3d566e24eccaddef5555effb6c43a0256561c9c16c084966b52c8752f3116562e2c2f310b0b1c5e1058585e10585891a3d353964d98883554852ac39fd27aff7ea16d392e91e0ab77ee2d6765fda20b99bf716da47449a8e2546cb092dc46b5365a12e7ec630d2551742f77175b7d0c2c9549d06d0e2eb6fa14376f19714d3a8521683a9495154646244db392e9b091b551c976ec3f1782b89f56178161638bce21616179c42c2c6c3912a5b7cdbb45231ce53646f42199eb4fde4f56bef1d0bc8e6932c463e8530badb7743ecf99bddb53bcd61a7947c1cda9424d4ba9ddbb97e9e07a1c6f935b000444fb9bf6bd0011000002dc000000088cfdd0fcfec0067ee87e7f6003edbfc9b9ed5aafbb7001987a6793dc00cc3d33c9ee0067ee87e7f60062596eb2f523868f4b3766fc2925455d759a54655f7190e59e5be4d20d720cca7f790d2fdad554f45436be824657c8be12fcaef543378498c64aa39a98403ca69f615690a2fd0f790d554ba8ccd2a6993928ec62316e8bfadcbbd379398f2b0a760ba0474bb5da94f4b5078e85a674761a770f15616bad0fb566bbb74beb16beb2c0c876be89e9142d28a5c3a843d4aba9c9c1c9b53ea9d4a8685add29f479c74abf5a6d45e28bb3f3eb27f30f4cf27b89218919fba1f9fd801e78cb7e518e94cd912097aaccbe5aa3b7655593afea33e09d45d6397b955d2cfdb33dfb3255d7830575f073f7af6376275dcdc9a1742f6096f6c8c9ef226cea6eef1dbe06616cb78d4d627189c5e16f20b0c45b2de16188bcc42c2c2f310b0b0bcc42c2c6b1208df9e934244a8eb529a2251e25a0ff410d9c85cd47737ac85ce42e6a3b9bd647d27a34d4e1a389852244620b41ea270b71fee2ea4279d2cb83fe1f42ea4279659d83fe15f23387096cb8a69d4a90b41d4a49eb231286d9c974d84a5b6725d361f9bc15c4ad8e2f3886256c2f388622c7764d398991cd6166d06a34bb0ae13858d5acb819565d632349a8c6a3cf429e975e9315153ea9d8a9a94b49e93873f2ef968a9a9c96fcfb8f604a298c2ce6590d358385b4cc534971276f5565ab56b2d43b6a9950835593873b016ed7a22a77eeeed8a73b4e4ac492987cbc5f89ab63b99fba1f9fd85f16c3edbfc9b9ed5aafbb7001987a6793dc00cc3d33c9ee0067ee87e7f60033f743f3fb0019fba1f9fd80110000025e43ce3b3ea0097000015100657967527e765a9da4cb867c2b21cd5cbbb9167a4dbbf077aa1b3b40117998cbd69e8a658f6b1a3186ca866a9f0e93f5c34f63e8eb8b3ba8c67e61b4ee710751f7a4fc06f5e452aee833f1a98e5e8c46e49fccddbe28be440f94290489290e71135b56cbd8bf9fa9e811d266a3315cad53a4d159366f81748a651e934b751e969bd46be3b0b1e035af293a5e9a3d21ecb2cefde22a2a27f0b77bbe89d7af7131d0fa02d5a6b9f8c9ee99b7ad7727d57f33ce86e199999e933d758e5554555ba9bbb1b1c5e602962b89c5e058622f02c311782b6188bc3de416188bc3de416189a55037cdca3e9499ff0dd5a7d7d4456aecb4cdf8a2115abb3199bf1442c56c62ec630a9536a3c516caa6f048a9f6cbe95245f5d25b7890cd52e739b773111752ecea3334a9dc1dcc44d8bb3a8cfed9ef124b125c45b3de16189c5b0b15c45b0b0c4dc7207498e2a022e8c44395ae14fe621c8cffd351f288b82aa3ed0e88e472bbcfcac5a4455d6ce937f9576a772ebef352f2854be6a332a0c4d4ee8bbb53678a7a1ad0dd86b725e43ce3b3ea009700001510000000000004bc879c767d4012e00002a200c672b11c51549be5d2aaca1194b67c4eb51fea43927965a8a4ee92730d5d5098d6f7addcbea86dfd09965834de717e7555eed9f433e7b58d5ac2730cb3647e2950b949931a4eabd71c68f829b510d87c99c7581a4f2aa9bd553c5aa60f4ba1245a2c7bee445f0543d2f4b6944b2874862a7f3672cb30e9e4a48f94e2cfeaa138998eafae5665a8122f9f9a5e8b5366f55dc89d6a692a653a355669b2b0135af926f55ec3c5948e9147d279c444e662bb4ebeaac93b109d892c08871d56eaf315e9e893f34bd272f7226e44ea443a1e9b4e834b956cac04d4df35deabda465bc0626c5fd85e700c458e2f056c2c2f02c2c2f02c2c2f0f790585945e1ef0c4ad94d1b276b33923ba79c2bf42117ad27bf4ec22f5a4fde13b0b4dac4622c61ec2bacaa3d24161632ca6127ccd3433652650f115b8dee2de9ea12fa6ccfb4c1e97c49a949853667da60f4be24d4a40de623238990c45e6216188bc2de1618962c9f523ff0dd2f974cd4b34b57a4d3ff00fb6bd0aeeaebea127d0eabad0eb5026d56cdbe2efe576a5f0dbdc61348a9bfb4e9b16026db5d3b535a7d8f589191956475918ec845beb439d3612f21e71d9f5004b80000a880000002dc00002227dcdfb5e80088000016598c7c3cae02226316bb2cc336a7567811562caa33f0697291276616cc86d572f6221ed2f01f3315b061ed72d90f27cf664f4e2691734883fa48a794e9e159eaead43832a9518b579f8d3f1be288e572f7aeceed86fe91976ca4064066c6a22106f6b16ec3290c97c9d927fc6f2b71c59210d38b716a51d4494a50a3333ee13de4e911749655ce5b2355555782235caa61f4a557f63476a25d551113b55510e8e55f286ba6739f968171452a8251a582ff008aadae1f1d987119fe5034b9da4d3dcd405fdde1ea6ff12ef72f6eee09daa79e8968e25125738a9ef9fb7a93737efd6512dff758d7f892eb0b78f88622c2de3e2188b0b7fdd6188b0b4188b1c5b15c4585b0c4585b0c458d3b27cdddd1e4b8aff55e5a8b8682f4113ac2e5336e088452b0a8e99b70442cd68862ac62ac2d10585880a6d2e4cc644f2d09add85fa646fa8b59770c8d2e37333088bb1da8c8d2e37313089b975194de622638930b0bc2de188b1c5e16f30c4585e62188b1edec95522ff1464fe4b365b96dd387265e3fcc6f90aaf8d9afac761e86d4ff006bd0e5e65cb776365ed6ea5f4b9ce1a4b23fb3aab1a0226abdd3b175a7a92b3ee6fdaf41273064400000b70000000000002227dcdfb5e800880000156cb652c26e1d145609de5b953b16647a93f751d7afa8873df2d9a5c90e1b747a55dadd6744b6e4f95bdfb57a913893ed0ca564f59f889a93537b77afd3c4c45e1ce4c367308f7b58b961790cafcd26ce43ad50d0af290a524d0e29275724f5a7acb58cc48f3906f118b6ba2a772ea5f142f5901b11115e97de9da9bc85bc17362e7117816189c5e710b0c45e710b0c45e60162b616c56c2c716f00b0b0bce0188c4e4966a324915667a0882d616b1b4c8e0f36ca21208cb94d3444afea3d27e2620737139f8ee89c5482cd44e7a33a27153bd6885bd8b7b0b4416163f2b4a5d429b59569591a4f818aa5dab742a9d15ba18746b6a848c7e155ad97148ee3a86c084bce311e9bd09fc25e7188fe287c6f0f78f4c4fbc45e62161638b67bc2c2c7a83e1467671745e6d2471759c0c625e416e4b89fdd07de3a1b91f9d5894e8f26abf039153b1c9f7434cf29729cd4ec2994f99b6ef6afd94d727dcdfb5e836f9ad488000016e00000004467ee87e7f60033f743f3fb001f6dfe4dcf6ad57ddb800cc3d33c9ee0087a54ec2d1793bb33888cb4b2e4b2dd9a8dc59ea2d7df808b6986944be8952a25423eb76c637f139762766f5e08646974e7d4e65b019b37af043019b4744cca31f8f8c70dc79f59ad6a3da66386a7a7e62a937127669d9447aaaaaf5afeb5751baa560325a1b61434b3512c843bc3e186458404fe66997b1524caf9cd082dd88c94a4058ceea43252b09622f514c53aa528d4a5566675998ce236da90cae2717862b88c45e186231178162b638b6161616cc2c2c2f056c2c2f02c2c2f02c2c58683ca4e6d3b6dc7135b10953ae6e332faa5dffa0c655663d9e5d5136bb527d4c6d5263d9e02a26d76a4fa9ad5b310cb10eb0b66161616cc2c2c2d985858c6e98a099a4d30416a376df7911fa89c535739462f5136a6ae72ac5ea21ade22fec5f585b0b0b0b6161636af85a9f1cb6964d600d16d317024bb35d5a50b2f4518db7c904c737548f2ff008997ff002aa7dd4d6dca64be54f851bf0bede28bf63d251d1f07110ca8c8f884c1b10ea4a54e2ceb4f2cc88ab3d151575691bfe3cc4395673b196cdd5ad766b5b7a9a620c18930fe6e125d78766b3b1984bff39e4f71ec790cc3d33c9ee0067ee87e7f60033f743f3fb0019fba1f9fd80110000025e43ce3b3ea009475d6d8696f3cb2421093529467511116b31e71a3439786e8d156cd6a2aaaaec444daa7d35aaf7235a9755301ca052c7294cd94e36a51414399a21d1bcb6a8f13fd2a1c45ca2e9a44d31aaac486aa92f0ee90d3ab7b97adde496436d50694da64bd97e376b55fa7714c7f68833492b08998c533050ee45442aca1b2acff006179021ba2b918ddaa5ec062c47235bbccca6333726316b8a74feb1f24abfaa5b084ae0c0482c462126850521351a875af4bfb31eb63d3117a2b88c4e2f0831188bd20c4622f4312b88bd0b0c4e2f4311617a188c4fd3578f38865a4296b5a892949169333d828eb3515ced8851d66a2b9761b2d1591a6412a4432aa3887396fa8b6ab7702d420f509a59c8cae4d89a90844fcd2cdc65726c4d84c5ac458d8b2b0b58858585ac42c2c2d62161631da76e91d2a8eb27a8d05e42137a4b7f73677fa935a525a5197ebf5202f0f78c8e2646c2f05711638bc3de188b1a57c3dc51b794b846ebd0f433e83ff00657e8360f262fe6f4861a716b93caff4211ca1434750debc1cd5f3b7d4f51d24836e3e82529847488d2e4b5fef26d665e243a074860b662933309dbe1bbd14d23428ab02a72f11bb9edf5433af870cb3aa7ec3740a93c5da9843a3fc84438ad310d917f0cccf5a925ab7970d3aef938d3259e625227ddef1a9d055f991372f5a6ee29d84eb4f344fd89cb53936fbb55e9227caabbd3a97c97b4df46dd3581510000000000004bc879c767d4014dcacd2a36192a3502ed4b7489714647a93b11d7acf0ab78e77e5b74d7d9e1a68e493ba4e4bc554dcddccefdabd56e24d3456979bbdb62a6a4f87b78f71913ba873234d84c3a2fed172d2ed86634da7df3b1872e865d6c43ab96647f597b7b84b29729cd43e75e9ad7d094536579b6738edabe8562d8cb58ca622d86231178188c4e2de3e216188b78f8858622de3e22b895c45bc7c4311883585862716c2c31345c9f517361299f4c1ba9c517f96428bea97e33c4f608c5667f35f6684bab7fd88d55e7b25f6784bab7fd8be5e6223b891fc45e62188c45e62188c45e0623117988623130da431e98e9e47452555a5c7d564f023a8bf41b024a17352ec62ee4427b270b9a976338211f782eac5ce2717a5bc31188bc2de188b1a37c3f19b99519659fbad4419ff00f1284ef93762ae9141ec77fa5485f28164a045ed6ffa90f5453298a25593aa591ee1d44dcb5e22e2a42925e26437fe934c24ad1a6a2aee63bcd2df5346e8ec0599ab4b424def6f92dcf0c40cce2e591ac4c65f10b622619c4bad3883a948591d6464392a045892d15b1a0ad9cd5ba2a6e543a8a34087310dd0a2a5dae4b2a71453ddd91fca442e53287313823422610f543c7b29fb8f116b22fc2a2d25d65b0755689690b348e9cd98d911353d382f1ec5da9e1b8e67d29a0bf47ea0e97dac5d6d5e29f74d8a76849c8e0000016e000015ca6b326a532f4473ba6c12aca7f12b4544239a57a4503456931aa71fe54e8a7e272fc29debb7aaea5e53e4df3f30d80cdfb7a937a985c6c43b16fb912facd4e3aab4a3c4c703d42a131559b893b34eca2445572af5afeb5751b7a5a0b25e1b61434b22258e83ba85bb4bc6153a713e291ca9574aaa2627e8dac34695750cd52a53dae36bf8535afd8cd52e57daa2a5fe14da63e6e999d667599eb3135c498a345e622b895b0bcc4311638bc3de188b0bc3de616161787bcc31188b61895c45b0c46271798862312e341a891cd1d4cda64d9fca3675b683ff005545ff0049788c2556a3cc27330be25dbd5f9985aa4ff309ccc35e92edeafccd409751545a08b61089588b585e1ef30b0b0bc3de6161617861894c45e18623122a94ce4a4f238a8cb553868bb6b15ab417efd42f2425bda661acddb57b10bc91965998ed66edfd86256ebd26627d627388b616189c5b0b0c45b0b0c4dafe12a057199507232aad3052d79c33dc6a34a0bfe631b2392d975895b589f858e5f1b27d4d79ca6c648546487f89e89e175fa1ab7c5b52544a682c248db72a7e6f1162c91e9ba459528fbec97589ff002a152494a424a22f4a2b913b9bad7cec413934a6acdd5566953a309157bd752795d4f1ede6239e3137fe268590fa7aaa174d184c53d665d3434c2c5119e84d67c85f519f71989ae82575687556a445f7513a2efa2f72f95c8769bd052b54b72c34f790fa4dfaa77a79d8f7a6bd243a70e6b3900000000019065427e5329aa656c2eb6202b25197de70f5f76aef1c81cb5e972d66ac9489777ba97dbd71176ff953576dcd87a334ff006781ed0f4e93fd3f3284e6a1a59a4b18755e32249999d4443d5a7bb0c229a521cfb3c79e6d75c3b066d3055fdd2dbd67a46c4a5c9fb24ba357e25d6a6c1a64a7b2cba3576aeb5206f4bfb3191c4c8585e97f66188b0bd20c458e2f48311617a41895b0bd0c4585e8622c2f7015c458b350ca2ce4fe23e6e2d2a440b4ae51ea370ff097a98c4d4ea0928dc19f1af97598ba8cfa4ab7067c4be46b0d136cb696594250841125294e8222dc21aebb97276d222ebb96ebb4fd5e0a62531178188c45e06231178188c45e0623132cca2d242994c8a590ce56c4199928c8f429cdbddabbc4be8b25cc42e75fb5de84ae8f27ccc3e75db5de8542f0f78cde2666c717a7bc2c2c2f0f78ad858e2f310c4ae27a9be0ca4a4ccbe9252c88a9085ada8342d5a0889046b5e9ed23b86e9e4a24921c2999e76a45b353bb5afaa1a5b9569b57c597916edd6e54edd49e8a64397cca4a728b4fa262e05e354ae5c5f270356a52127ca73b4aacf854209a6b5dfdbd5474486beed9d16f626d5ef5f2b13bd0ba02d0a96d87113de3fa4eed5d89dc9e77337bc3de6223625d88bc32d246616189efdc82d363a75933954ca21db71b089f918b333d26e37515a3e29b2aeb1d43a19565ac51e1457addede8bbb537f7a594e5fd33a47ec6ac4582d4b31dd26f62fd96e8686254454002233f743f3fb0023e7b4bb364adf8a4c2925cb365bad7f7cf56cebea111d39d246e8a50a3d47e744b3138bdda9be1b57a914bfa649acf4d3616edfd8862cfad6e2d4e38a3529466a519eb3331c06f8af8ef58b116ee72aaaaf155daa6d886d46a235361d37350fa6970c29f9499ee64a34f5d2ecbf167f2ed6f2afeb1f51563374394f6a9a4bec6eb5fa7999ca24afb54d25f6375afd0c22d8d896360d85b0b0b0b6161638bc0c4ae22de3e2188c45bc7c456c2c2de3e2161616f1f10b0b1354568ebf48e3ac1d688568c8de730fc25898c7d4275b250eff32ec42c67a6db270eff0032ec436085661e0a1db84856c9b69a4d94a53a88842623dd15caf7add54873dce88e57b96eaa7d6f07c58f9c45e058622f02c3117816189cdbc7c42c312b34de9526432ff978770be72248d2d911fd44ed57ed88cad2a9eb3717277c29b7afa8c953243daa264ef853f5632237ab333355667a4ccc4d71b130b585e96f0b0b1c5e96f0b0b0bd2fecc2c56c2f482c2c6cb3acabb54332492fc93d13748a3a35a3889dc636aaec9bbca36127f8acd94a8f61155bead83395f6d26870e8922bd3725e2393765af14ebb5917c0d7725a3aeabd762572793a0d5b426aefc7564bd57baa7898cde90d7f6362585e9058585e862313d1bf0774d552e9acf28a3a9b6dc5b288d6536aaa9683b2aab89293fed1b6f92a9f56478f22e5d4e447276a6a5f254f0350f2b14eca5e04fb535b555abd8bad3cd17c4f52e7ee87e7f61bacd1c33f743f3fb00220014aa751e6ec4b52f41f2592b6bfea3d5e1fa8e50e5f348966aa30689097a3093277f33b67837fd44e345e53084e9976d76a4ec4fcfd0a838340b49834eab9a87ab4f76186e59275f37489a9536badb8068ad17e62f49f8591b03466579b9558cbb5cbe484ff0046a579b9658cbb5cbe48502f31124b123b0bc3de161638bc3de616188bc3de616188b67bcc2c2c2d858ad8e2de3e22b88c4efc9655173c983701085a55a56bd884ed3316d3530c9486b11fff00b3c2663325a1ac479b3ca25b0925806e020d165082d27b56adaa3c441a663be6a22c47aeb2193119f3311623f69dcbcc47858f1c45e6216188bcc42c311798858622f310b0c4e8ce6750b2497b9308b5f25055253b56ad8921712d2af9a8a90d87bcbcb3e662243618acda6f17398f766118badc70f56c496c22c084ee5e5992d0d21b362134812ed978690d9b10e9db1ef89ed88b6188c45b0b0b0b6162b638b78f88ae22c2de3e2188b0b78f88622c2de3e2188b0b78f88622c6879009caa53959912ed5498a75708bc49c419178d425ba0f30b2b5d80bb9caadf1454f5b10fd3d9349bd1f984ded447782a2fa5cf708e94396c003852890935a8ea24956663ce2c564086e8b116c8d4555ec42ad4572d90cb26714a8d8c7e2947fc459abab60fcebd22abbebd5698a944fef1ee5eebea4ee4b21b624e024b406424dc847b8314d2fda755d324a4d4a3a88b49f01eadd7a90f766bd48795690cd4e6b3c8f9928ebf98885acbfa6bd1e150dc1272e92f2ec85c110dbd270125e5d909372211f7a588b9c4b9c45e90ad858e2f4312b617a188b0bdc0311617b805858fdb097a25e443b0da96e38a24a125acccc7cbd5ac6ab9da910f972a3115ce5d486c74528fb54765e4d9d4a8a74894facb69fe12c0841ea138e9d8b7f953621109e9a59b897f95361376c5858b1c45b0b0c45b0b0c45b0b0c45b3de16189f972210cb6a75d70908411a94a33a8888b68aa315cb64da5518ae5b218ed31a54e521989dd28ca0d8334b29dfbd4789fe826f4ca7a4942d7f12edfb130a7c8a4a43d7f12edfb15fbc3de32762ff0011787bc2c31179885858e2f0f7858ad85e1ef30b0c45e1ef30b0c45b3de6161616c2c2c716f1f115c4ae22de3e2188c49ea031ca81a7347e2d2aa8da99c32b5fe6a464a8afe66a52f11373dbea8626bd039ea5ccc35dec7ffa54fe880ea938ec0025298c61c0d1a8f78955294d5da78a8eaf5104e532a6b49d149d8ed5b2ab304ed7aa37ea64a91079f9d86d5e37f0d6620e6a1c0ed367b761d6707b34f769034b63337d199ac691d46cc23aa23c6c9d43214e85cf4d4387c5c9ea64a9b0f9e9a870f8b93d4f285bc46e4b1b8b117816188bc0b0c45e058622f02c3138b6161638bc20c458d27275473e5da29fc6b7f4ae9550e93fba9fc5c4f661c445eb53b9bbd9a1aea4dbf623b569bcd79866c4dbf62f37823d8984c45e0623139bce0188c45e700c4622f38058622f380586267b948a5757fe1e8272a33a8e25447dc8f53124a253effbcc44ecfb99ea448fff0061e9d9f733cbcc449ac482c2f7115c4585ee2188b0bdc4312b638bd20b0b0bc0b0b0bc0b0b1c5e858585e858585e710b0b0bc15b0b12f43d6a552e92253ace650c45c6f522f29cdfdf215bf137d50b1aa25a4635ff0003bd14fea70eaa38bc0029f94f7eee8fb6c91ff1621247c088cc68fe5f26d6068d43809fde456a7722397d6c48b469994dabb822fd0c99cd438f1a4fdbb0eb383d9a7bb4a5e559e366804e5447ad94a7bd69219dd1e6e552849d7f4533da3cdcea3093afe8a7976f0f798db789b6b138bcde62b62b88bcc42c3138b78f8858622de3e216188b78f8858624f50e911cfe6c943a47f2ac54e3c7bcb627aff718ea9cdfb1c1ba7c4ba93ee58cfcc7b2c2ba7c4bb0d912a2424908224a52551111682210754555ba9125455d6a73787bc312988bc3de188c45e1ef0c4622f0f7862311787bc311891349e90b747e52ec6a8c8dd3e43293fbcb3d5d45ac5e4849ace46487bb7f61752728b351519bb7f6189bd14e443cb7de714b71c51a94a3d6667ac4f5b0d18d46b53521326b1ac446a6c43f17988ae27d5905e06231438bc15c45905e0622c2f388622c2f388622c2f0c312b6438bc15c4585e700c4585e700c458e2f031162d59298354d329b45601255df4e2108cb0275267e043294382b1aa52ece2f6faa185d248c92f479a8bc21bffd2a7f51474e9c6a0019ce51a65f3b2f856ee2ec92e99fd6aebd1c073cff00c43b97f65c9b7ffe8eff004928d174f7d13b3ea678e6a1ca4d272dd8759c1ecd3dda51b2be93564ee7356c6d07dce2448346d6d5385dabe8a48746d6d5385dabe8a7962f388dbd89b771179c431188bce2188c4e2f02c311782b61884acd4649495666751116d14b22056db59b4511932643266a1d4553eefd2be7fcc7b3ab50825466966e3ab93626a42213d1fda632b93626c26ef0f798b1b16788bc3de616188bc3de616188bc30b0c45e18a62311798862531321ca052239bce550ccaeb8682adb4547a14afbc7dfa3a84d68f27ecd03272749dafbb712ca5ca7310725daefd2157bc3de632f632589f78361c8e89442b4e210b70eca2daac919ec2af60f38af484c57aa6a43e222a436ab97621f4984ba652976e66308eb0ad9693a0f81ea31f3063c2984ca13914f985161c74bc35b9d4370f78f6b1eb89c5e058ae22de3e216188b78f8858622de3e22b6188b78f885862717988586282f0b79062a56c2f0b790622c6adf0bd019c72d947ddbbbc44029d8d597f436aa8ffdc6912ad0a95598ad41fe1bbbc117ea4179489a494d1b98e2eb37c553e973fa179fba1f9fd87411c9e54a92e58a4f4666672c8d6129749b4b951b9b0fab01859ead40908bcd445d76b924a5e8d4d5565fda2126abaa781d3a6e8ae5ecaff0bb577918d37ff107015f43958c9f2c5b78b5df63eb461d6987b78a7d4a339a8725349db761d6707b34f76953ca4429c65059ec3a4ab33827145c5256bd066289139aa84172fe24f3d466689139aa84172fe24f3d47906f380dd789baac2f380622c2f3806256c2f03116178188b166c9f4a8a6b3d4beea6b6208af55b8d5f74bbf4f50c556263d9e5f16ed76afb98da9c6e660629b5dabee6bd6c42ac45ac2d858585b0b0b0b6161616c2c2c2f02c2c42d2f9e66490c44521553cb2ba6bfad5b7a8ab3ea17f4d95f6a986b1766d5ec2ee465bda23a35766d5312374cccccceb33da627b8931c45e058622f4c8eb2af406231367a311d0f49e8c43aa62ca220ec9b2f25655d6a4e8af8d551882cfc27484dbb9a5b6f4ef2233909d2732a90d6dbd0aad29c9dae192b8f905a71b2e52e18ceb524bf94f6f0d63314fad23d521ccea5e3f7327275447aa323ede3f72846b32332323232d06462456b99bc4e0dc15b15c4e2f38058622f38058622f38058622f02c3117816189c5e1ef15b15c50f4d7c1251e544cf690d2b75bad1090cdc134aabef38ab4af041778d97c9c49e51e34daee446a77eb5f4349f2cd504872b2d20d5d6e72b97b1a964f355f03d7436d9cf878472c594372916526771f04f9aa11111f2d0e693d0686c89159713499f58e75d25ad2cf55634586bd1bd93b13579dae76168568da532832f062a59eadc9ddae5bf922a2771ed7a56c9bd2578c8b4b6695f8fb89a72d14f59ed108ee6a6b86ac7f82d97c954e57a045e6e79a8bbee8676e6a1c44d363b761d6707b34f7691f3186446c14441b855a621a5347c14932f51710622c27b6226e545f02ea03d613daf4dca8be0788a2da5c145bf06e9192d8714d28b149d47fa0dfb0dc91588f4d8a97f137e437245623d362a5fc4f85e16f21e963eec2f0b79058585e16f20b0b0bc20b0b1ae64e65e501479112a4d4e46a8dd3fe9d49fdfac42eb51b9d995626c6eafb917aac4e723e29b1ba8b4de70188b18dc45e700b0c45e700b0c45e700b0c45e700b0c45e700b0c4ceb2b31cab72f8123e4d4b74cb1d045ea24fa3d092cf89d8867a8b0f53dfdc67b79c4497133d88bdc431189c5e06231351c943ea549a2d07a93135975a4844b481968ed5eafa91bacb7deb57a8bbde70180b187c4a253da1a98c6dc9dca5a2288415a7da497f10b6a8b1fd44869153586a90232eadcbc3f23354d9e586a9062aeadcbc0cc6f04b3124588bc0c4622f310b15b0bdc4856c2c71798858585ee21616179885858f7ffc2bd123a2d92197443ed58899d2d73276b2a8ecaea26fc8949f58deba1721ec54962b935bfa4bdfb3cac726f29d55fda7a43158d5bb6122313b535af9aaf81ddf883ca537406853d0904f9266f384aa1a15247ca6d26552ddea23a8b1321e3a6d5f4a2d3d61c35f7b12e8dea4debddbbacaf26fa2eba45566c48a9ee6159cee0abf2b7bd76f5229e1872b3519e931cf6875e26a43fabb32844c7cbe26095a9f6948ef21d435ca6b6b14c98a7bf644639be28a89e67034b4558119b15372a2980c4b6b69c5b4e154a428d2a2dc643f39a2c17cbc574188967355517b516ca6da86e47351c9b14ea382ad2e1a755cd43d5a7bb4f20658a4e722ca1cd9824d96e25c28b6ff00a5c2acfcd6886ebd1a99f6ba64276f44c57bb57a58dd5a3733ed74c84ede898af77e452ef067b133b88bc0c4622f0f7858ae2a7e9925bef36c23eb38a2417133a851ca8c6ab9771477451554dfa0da441c23308d9112596d2d97515435c4472c47abd77adc843d7372b9779f5bc1f189f388bc0c4622f031188bc0c4627378188b0bc0c458ce32b4caef25f1a45c9b2b68cf1ac8cbd449f475c967c3ec533d4554b3d9de67b7824b899dc45e0ae231178188c4d772670cb85a344f2caa38a754e957f87517e82175c7a449ac53e54b7d48bd59c8f98b26e4b16cbc186c4c6585e0622c64f945a345298dced04dd50b14ae5a48b436e7ec7fb898d1677da19ccc4f89be69f9126a5cd73cce69fb53cd0a65e10ce6265b11782b88c45e06231178188b0bc0c4ad8b0e4f68ac553ba6b27a27084ab5328a434b517dc6ebad6aea4928fa85f53245d519b872cdf996dddbfc8c457aa90e894d8d3f13e46aaa75aee4ef5b21fd4ca514a68be4ae87e729a3a98597cb584b10eca6ab6e594d486905b4cc888bc4f40df152a94a5024963c75b31a9644debc113ace37a5d2e7b49ea3cc4ba6511eaaaabb92ebadcbd47f3e32a39419d653295c55279caec9b87621d823ad10ec91f2509fd4cf699998e6eacd663d7671d371f7ec4dc89b913f5ad4ebcd18a04b68dc832465b76b55dee76f55fa704d47de825028aa53297e60cb26b4b712a66b22da4949ff00d432349a53e7a02c46a6c5b7927dcf2ae57594b986c172daed45f354fa1fd271d2c71698d65125272ca40f3a94d4cc67d3a37567f58bbff51c43cb068ead0749a2c5625a1c7f78ded5f893fcd75ec54363d026fda64d1abb5ba97e9e4549c1ac1a485a755cd43d5a7bb0c13e2728ea950d2ca58c37fc151c144196e3e520cfaed1758d8da093b67449376fe927a2fd0d8ba0b3b67449372ede927a2fd0f3f5ee2364626c8b1c5e622b62961785bc2c3125a89365154965cc9e92f984a8fab4fa0b2a8af372b11dd45b4ef425debd46e378201622161785bcc2c2c2f0b79858585e16f30b0b1cde16f0c4622f0b7862311785bc31189154964ed521943b2f5a892b3e5b4b32faab2d5fb758bb91995938c915366fec2e25232cb4547a6cde6231f09172c8b720a398369e6cea349fea5bc84fa0c4647624486b74525f0dcd8ad47b16e8a75ef380f5c4fbc49ea2b45e369245911254dc1a0fe95eab455b8b798c75427e1c8b38bb721673934c956f176e4368866d984876e161d161a692484248b5111681047aba2395eedaa449caaf72b9db54fade16f1f3894c45e16f0c46274e6f010f38973f2d892e43c834d757d53d87d463da5e2ba5a2b62b36a1eb0623a044488ddc60b1ac3d2f8b7a0a20aa75859b6a2c48c6c584f6c662446ec5d64d21b9b11a8f6ec53e17b88fbb1f588bcc42c3117988ad8622f710c4ae286f3f0c33aa33405d9b65167adae2a3d0d1c0caa11b4f28cd5a5c70d47a1255594d7af4ab40cdd16bd4fd1c57ce4cddd16d66353af6aaaec44ddc76ea359f2854aa8691b60d22517184ab94472f57c2889b5576af0d9ac90ca7e53e94653a70734a41124965aaca1a11a332661d27b125b4f7a8f49f808757348a7748a639f9a5d49b1a9b1a9d5f55daa64f46746a4746a5f98946eb5f89cbb5cbd7d5c136219f446d18c612e867b4fe11e8741af244dcc6398ad53098c4be8332fba565bfd5b31bef93fa73168e912227c4e72fa27d0e68e55eaf11348560c25d4c6353bf5bbffd1b241d26bf6d49542d6e32a36dc2b7b4b6eadbac4a285566d4e0bd8e5f7b09cb0de9c1cddfd8e4b393a94d55310799722a6c725d3b3f2d84353669348652696e12cc4431de34a25575ef4eada5fa1086f2ada1eba574372cbb6f1e0ddece2bf89bde9b3ad10c8d0e7fd8665325e8bb52fd14c95cd15918e2044545b29b3da755cd43d5a7bb0add38a38cd2da2f31a3ef544716c9936a3fbae16942ba94443294a9d753a6e1ccb7e55d7d9bfc8cad2a75d4f9b64cb7e55d7d9bfc8f1145b3110314f4145366dbd0ee29a7107ad2a49d465de37ec37b62b122316e8a97437d437b62b122316e8bad0f8de18fbb1f76178616162c340175d2c81af61acfc8631b574fdcdfddea58d453f7677eb79b45e082588ae22f031188bc0c4622f031188bc0c4622f031188bc0c4622f031189d19a49e533a6c9b99c136fd9faaa32a949e065a45ccbccc6955bc272a1ed0634480b786b62218c9f51461d277e456e55a492e3aa34f70bc7d6271e96cadd885cbaa332e4b65e458984310cd25887690d3682a9284154445c08631eae7ae4e5ba962ebb96ee5ba9fbbc1f3894c45e06231178188c45e06231327caa4bd3093b6a60da6a4c6b7caabf1a741f854265408dce40584bf2af92924a444ce12b1777d4a55e0cf58cbe27179c42c31179c42c313ed06cbf1d14d41c320d4ebcb2420b131f111ed84c57bb621f2f56c36ab9db10da20a5cd4a65cc4bd9faaca09267bcf69f59882c58cb311562bb791974458cf57aef3ad11b47ab0ba86463e46a559495667a08885db12fa8be62db5a9fd15c9643950ec9d51ea367055390700d93bcaabe9145697b3f128c753d064bf67d3204b2ed6b52fdabad7cce2ad29a97ed6acccce26c73d6dd89a93c910e8cda2dc91cddb981119c3c52492f24b796de350d35a6d598fc9d696c2aeb11565669a8d8ad4fc4cd5927f123551538d950f5a7cbb6ab24e965f8d9adbdfbbb09e61f6a25a4bec2c96859569516d1bc29f3f2d549664e49bd1f0de97454d8a9faf023f1613e0bd61c44b2a147a6746dc855b9388368ce194a2bd222fe1a8f6f03abbc72af2c7c9fba8f36b5da7b3dc445e9a27c8f5dffcaef25d5bd09e68e5592619ecb197a49b3ad3ee8531cd4346b497b0eabba87ab4f761e5cf88fa14725a42dd2d816aa849b1d97ea2d088822d7da2d3c48c6ddd09aa7b4cb2c9445e933675b7f2fb1b6f42ea7ed32cb27117a4cd9fcbf918dde09c624d6c2f3886256c4ed068926695cb947a2d3868ef4990c7d561aba4e2761673ecca59e86dd6f1f1101b113c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c45bc7c42c3116f1f10b0c4a4e561827640c4555a588822af051197a10cfe8f3f1997338a7a196a3ada32b78a1935e09962493138b78f886257116f1f10c46269192ba3a6bbca4914df2535b50d5ed3fbcaf4ef117d209d44b4ab3b57e88606af336b4bb7b54bdc4ed11e618b8645c46d176c2fa1964c8f5125533ca4c9e54b6adc334f145c56e269be5191f13224f5896e88d316ab56830553a28b92f6375f9ecef23fa6d594a1d063cca2d9ca98b7f99dabcb5af71ef11d3871c91d3f97e72963aca4ab71256dbfea2d9d6205ca4e8c7f6af47a34a434bc56f4d9fccdddfd4974ef325499cf629a6bd762ea5ec529926a43132574db511b90ea3e5b7b4b12c472af27fca3cfe83c7e62222be59cbd262ed45deade0bc5362efd7ac9bd4e910aa4cc9353d362fdcd368d44cb27d0316941a221875249710adc75e832d83b0a9758a369b535cf967362c17a59cd5da97da8e6ed45ff00da1028d2f334d8c88f456b9362fd94cc69dd0989a33107130c953b2e755f46e6b36cff000abd0f68e4ce51793999d0d9959897457ca3d7a2eded55f95df45dfda6c6a1d69952660fd51136a71eb4298eea1ad1a49185629bd1881a63476368fc791122251c85d559b6e1694acb818cbd2e7e2536699330f6a79a6f43314b9e894e9964cc3da9e69bd0f124f2551f4766f172499b3751306e1b4e24f0d465819692c0c6fb9498873b05b31056ed725d0def2b310e720b63c25bb5c973a379c05c627bd8ed4aa3be466709195d572f2167c08c8794c42e761399c514f38b0f9c86e67143d029709492524c8c8cab21ad95aa9a9486622d858622d858622d858622d85862736c82c3116c82c3116c82c53116c82c3116c82c3116f1f10c4622de3e2188c45bc7c431188b78f88623116f1f10c46255b296a23a231467b1c68cbfdc432d434b4eb7b17d0c8d2d2d329de62f78277892ac4e2f38062312568cc8e2a934e61e530a555e1d6e2f636d97d651ff007aea1693d34c9180e8cfddb3ad77216d3930d9382b15dffb53d0ac40c34b20d997c23648661d04da125b886b474574788b11ebad75906588e8af588fdaa74a2768b861770c8b88da2ed85f433d3df0ab411528a3f174d6399b311373b986acb4943a0f49f695e0921beb933a32cac9baa3153a513537f953eebe873df2bba409393aca4c15e8c2d6efe65dddc9eaa6ee3679a74b700321ca351e394cd0e3e1d15434699a8aa2d0973ef17a8e31e593435747ab1fb4659b68130aabd4d7fcc9dff1276af036168f543daa5f997af49be69bbec54a1a3a2e5ef14441bea6965b527af896d1ad68b5ba85026526e9b1561bd37a6fea54d8a9d4a67e3cac19b673719b742cb074f6162593839fc11290b2b2a5a0ab499629fd874051396d93a94b2d3f4a6591cd72595cd4bb553f898bf455ea422d31a2d160bf9e907d9535a22edee5fb95f9e482094954751d8d6e2e1feb299257d2b7d47a4c840b49b4369cfcaa3a2b30d8f036ab2fef19fd2b6739bd76ba6fe267e9b548cd54815162b1fc7e55efd88a545fda35d349530c3be20f26ca9fcbbfc5f2687b53097b7544a105a5f60b6e2a4fe95ee213fd0eae7b1c5f628ebd076c5e0bf65f527ba215a49489ec51d7a0ed9d4bf65f53cc96c6d8c4da988b61616373a1b3629ad1b82893556b43774e7f52747ec7d635f54a5fd9e69ecdd7bf89129d81cd47737bfc49ab62c6c5a622d8a623116c31188b6188c45b0c4622d8623116c31188b6188c45b0c4622d8623116c31188b6188c45b0c4622d862312a59508926a8a38833d2ebeda4bbebf419aa0c3ca7117822992a532f328bc114c6ef0b789ce24a2c09cb46494d6667a0888b58a2a5b5a8b58f42e4ce851d1591945c73554ca3d24b76b2d2da3eea3d4f1e035a572a9fb4263086bd06eceb5debf620357a8fb6c7c18bd06ecebeb2c911acc62d8594322e2768bc617f0c9bc9964fa3f2974d20a8cc21292c2d57b18f1168661d27cb571d85899093e8d5162d7aa0c9466cdae5e0d4dabf44eb317a4b5f85a374d893b13e24d4d4e2e5d89f55ea43fa172c974149e5d0d2a9730962160da430cb692d09424aa22ee21d51020439684d83092cd6a22227521c833331166e33a6232ddce55555e2abad4ec8f53c40023e7b27869f4b1e96c516870ab4ab6a145a94423da53a392ba574b8b4c9ad8e4d4bbdae4d8e4ec5f14ba1772338f918ed8ccdde69c0c1e6f2d8a94473d2f8d6ec3ad2aa3dc65b0cb031c115aa2cde8f4fc4a74eb6d118b6ea54dca9c51535a1b5a52661cdc26c684ba948b7350c7b4be61d674ccb491d4758f662ab56e87b352fb4e83e75d6662e1ab75ba9770c8e7c88eb232ac8c5cb0bc86795b2e992e5d15982e9448983cd118e56eb692d10ae9ecc1067ab71e8dc370689d7d2a109252617de3762fe24fba6ff00136de8b57527e1a4acc2fbc6ec5fc49f74323bc3de2698930b1a0e49e7a4d4544c8de5e87caf99aff117d62eed3d4235a4329931b30ddda97e861aad2f76a454dda94d3ad889d8c0d85b0b0b0b6161616c2c2c2d858585b0b0b0b6161616c2c2c2d858585b0b0b0b616188b616188b616188b6161899de57e60450d2f96a55a56b53ca2c08aa2fd4c49b46e0ddef8bdc66a8f0ba4e7f7198d6625b633c6b3912c9e2a6b1454ba6ec7f93855ff94428b43ae97defe94febc04334a6b292ecf6280bd277c5d49c3b57d08a691d5b986fb2415e92edea4e1dabe86db13b440a190d8445c46b3176c2fa191e70efc5be88586696ebcf2890da1055a94a33a8888b78bf810df15c90e1a5d5752226f52f39c64162c488b66a25d557721eddc8364999c98516238e6d0a9e4cc92ec7385a6eff000b447b935e9de66780e9fd0bd196e8ec8fbd4f7cfd6e5e1c1bddea730e9ce953b49a7fdd2fb887a989c78b97ad7c90d384c8840004467ee87e7f60033f743f3fb0020694d1c45348553f0c84311b0a9fa3519d77a47f74cf46ed03587295c9ec1d3393e7a5ecd9a869d15fc49f81dd5c1772f52a99ca2d5dd4d898bf5c35dbd5d6863b1d0b1104fb90b14ca9a75a5595a14551918e2f9b9298a74c3a56698ac88c5b2a2ea5453684088c8cc4890d6e8bbce83ba879b4ba61d17f68b96976c239e172c2ed8444d6060e6706f4be3e1d0fc3c420db75b59564a49eb2317b2f15f02224486b6726b452fe5e2be0bd22435b2a6c53c95955c97c6502999c442256fc9e2567f2ef1e936cff00e1af12d87b486e7d1faf32af0b17ea8a9b538f5a7eb51b7a855b6556162fd51136a71eb4fd6a2972e8e7e591cc47c32aa718592d3d5b06763426c786b0dfb14ce4462456ab1db14de65934626d00c4c61955b6fa09445b8f69751e81aee3c074bc4584fda844e2c2584f563b71dabcc47958f8b0bcc42c2c2f3114b0b0bcc42c2c2f310b0b0bcc42c2c2f310b0b0bcc42c2c2f310b0b0bcc42c2c2f0f7858a622f0f7858622f0f78586262d4fe6c536a4910a42ad350d5308ddc9d7e3589dd1e5fd9e55b7dabafc493c842e66025f6aeb3b9934a01194f67a985225b72f86327231f22faa8fc25fcc7a8bacf60f1ae56194897cf6bd75353af8f6216959aab297033daf5f853ebd887a99981849641332f80612cc3c3a09b69b4954494916821a85d15f1deb1622ddcbad54d5cb15f19eb1222dd575a9d189da2e219770c8c7c8cd551156667a085dc3d65f3351e93c826415c9532cd37a568ba983a9b5030ab45670e832faea2af42ccb516c2c75742f279a12b4f6b6ab506fbc5f81abf2a715fe25ddc13af6690e5034dbdbd56934f77bb4f8dc9f32f04fe14dfc57ab6ee19fba1f9fd86db3528cfdd0fcfec0067ee87e7f60044000009790f38ecfa802369ad0683a530e6fb565898369e43b568597e15618ec1acf941e4e24f4ce0f3f0ad0e69a9d176e77f0bb8a705da9d9a8ced1ab71296fc5dae1aed4e1d6861b3895c7c9e2dc8098c329979b3d29516b2de47b4b11c7755a3ced0a6dd235086ac88ddcbea8bbd1772a1b464e6614dc348b05d745219fda2d5a64d8473c2e585db08f7b58b961790c859dcae02752f7a573485444434424d0e36b2d065e8788bf958f1256224582b6726c53212b1e24b4448b096ce43cb794bc974c283c62a2e10971328755f44f5559b467f717b8f71ea31b76855f8555660fd51136a71eb4fb6e369d1ab50ea6cc5daa226d4e3d687cb27149be4224e4916e54c442ab64ccf425cddd7fa8fbadc8f3acf68626b4dbd9f91775096e71bceb76a6dec34ebcc4448c2e22f310188bcc40a622f310188bcc40622f310188bcc40622f310188bcc42c311787bc2c311787bc2c311787bc2c31222954f4a47257e2c9457cb2bb64b7acff006d7d42f69f29ed71d19bb6af61712b2fcf4446eede65f43e884ea9d4f5b934a1a35b8e1db79e57d46515e95a8ffbacc4baa55281499758f197526c4deabc10cb546a302970163c65d5b937aaf043d6f45a884a684c89991ca5be4a0ad3ae99729e736ad5fde82d034bd42a51aab30b311976ec4dc89c10d473b508d539858f1b7ec4e09c0ec44ed1e6c290c8c75b71d5934d214b5acc9294a4ab3333d44442f60b55ee46b52eaa5f31c8d4c9cb6443d11913c80a656e314c29c42a551855390700b2ac99dcb70b6ab72766dd3aba1740b93cf63c6a7566f4f6b58bf2f5bbaf826edfaf669ed33d3c59a4753a96ee86c73d37f537ab8aefecdbbe8dca6a62a20000000000009790f38ecfa8025c010d4968aca694c1fcacc99e5a4be89e4e85b6781eec3508b695687d334be57d9e7d9d24f85e9f1357a9787145d4a6469b5498a5c4ce0aeade9b94c02945119ad1f5a9c75b37a14cf92fa0b475ee31c95a5dc9ed5b44222ba2b7381ba235357f527cabdbab82a9b568f5e95aaa235ab8bf7b57e9c4a93c218c24cc23ded62e585e4323df172c2ee19153185868e86760e31843cc3c93438dad35a5447b0c85e4188f84e47b16ca9bcbe80f742723d8b6543cfb945c8fc5c8dc727345d0e444091db5b0559b8c625b549f121b2a8ba4ac9b448139a9fc772fd97c8d8349afb665120ccea771dcbf653f542e9694de1ca5f1ae1146b29aab3ff5525b78ef1f354a72cb3b9c87f02f9179372bcd3b26ec5f22d17988c458b2c45e6216188bc3de162988bc3de16188bc3de416188bc3de416188bc3de416188bc3de416188bc3de416188bc3de41618853c4849a96a2249156667b08551aaba90ae37286995520cadd2c44928db0a5c3c3e837555936d22be53ab3d9816b312259896d1d935989a5e92eedeabb910bc989c97a14aac7995d6bbb7aaf043d3b41f27d24c9dc9132a9522f1e5d4a8a8a5172df5ef3dc45b0b60d4d55accc56a639e8da93726e44fd6d535354eaf1eb11f9e8da93726e44fd6d524e23518b461e30cf840496693f8e4cb65106e44bee1e84a0b516f33d445898ce526953958986cac94357bd7727aaaee4eb53ee6a7e5a9b0566269e8d6a71fa715ea3d1191fc8eca28aad5399c21b8e9c20926859956dc399d75d823d67fcddd50e9cd0be4ee574711b373968931c7e56ff002f5ff17858d31a4fa6b315abcb4b5d907cdddbd5d5e26ba365905000a880000002dc00002227dcdfb5e80088000016b75a69e6d4cbcda5c42caa5254559196e321e71613233161c54456aea545d68bda87d35ce62a39ab654333a6191195cd6dc651b7932f883accd85566ca8f0da9f12c0696d29e46642a2ae99a2bb9988bf2aeb62f66f6f75d3a909b5234d23cada1cea66de3f37e7ea6254a288522a2cfdd4ea58eb093d09748ad36be0a2d0342d6b45aafa39130a8c156a6e76d6af639357d4d9d4cabc954db94b44455e1b153bb69567c61d8676191ef6d172d2ed847bdb45cb4bb619ad33c9740cd9f39cd1f70a5b344aadd68d0db8ac48b51e25d642554cafc4976f313299c3f3424f4eacc4809cd47e933cd0af404de3a1a20a4d49614e0a609d093517d1be5bd07a8f80c9c69686f6f3f2ab933cd3b4cd2b21c56f3b016edf4ed25ef3116363cf11798858622f310b0c45e6216188bcc42c311798858622d96f0b14c45b2de16188b65bc2c313892d0da4b9548d549e415c2c9da5d9984d169e462db7f8d5c346f159aa9cae8fc3e7e67a5157e166fed5e0858d4ab5294187ce46e9445f85bbfb57821e86a2741a8f50092a24947a0c9a6cb4baeab4b8faff12d5b4fc0b60d6951aaccd623acc4cbaebb937227044355542a933578eb1e65d75dc9b913821db891e30f69f10cb850bc8b521a56a446ccc952b96ab4de389fa570bf9127fa9e8e236d688725f54afe331368b0607154e9393f85bf55d5c2e476b1a65274a458703de44e09b13b57e89e46fd45a8751fa1b0050122804b247fc474f4b8e9ef52b59fe83a6283a394ed1b97f67a7c3c537aed73bad577fa704352d52af37588bcecd3efc13727621f49f737ed7a0ce18c22000005b8000000000001113ee6fdaf4004400000b70000085a46cb4fb6cb2fb4871b55a25256923232d1ac8c79c5830e3b161c56a39abb5152e8bdca7d31ee86e47b16ca9bd0cd27f921a2739b4e4332e4b9e3d36a1cf935e283d1dd50d6f5ae4a68154558901ab05ebbd9b3fcababc2c4be9ba715490b3622a446ff0016df1dbe373389f642a94c25a7251110d316f59249576e771e8f11ac2a9c8f5664eee927b6337fcaef05d5e64f69dca25363d9b34d586be29e29afc8cfe9050ea554794a4cee8fc742117de719558ea56a3ef1049ea0d4e94b69c80e676a2dbc767993a90abc85412f2d19aeec54bf86d2aef8b1619d610b3795cbe6f0ca85994236fb67a48965a8f791eb23c485f4b4c459676709d652fe5e33e0bb286b652aafd1e8f9656500faa321cb534f2be950582b52baea3c46659390e3ff00d44c5dc536786eeef03370a79b17fea25978a6cf03aa9788d46852548596b42caa51750f5c355f71769654ba6b3f56c52c56c2d858585b0b0b0b6161616c2c2c7eda4bafba96586d4e38b3b2942126a528f71116b1f2e54622b9cb6443e5ee6c36abdeb644dea69b4432151f37244753453905027caf916d553cf16e7145f51381728f0113a96964396bc390e93ff12ec4ec4debd7b3b4815634d61c1bc1a6f49df8b727626fed5d5da6cb052c819541332c9541350b0cc2490d32ca0929496e2221087c58d371562445573ddbf6aaa9aee2c7891e22c68cebb975aaa9352da053f9d192ee3e5583ff0051f2ab4609d66365e8cf259a415fb44743e6612fccfd5aba9bf12f822759869dd2690a7a2a659bb837eabb0bdd1ec9e48644a4c42daf9c8a4e9bd78ab249ff002a7517ea3a2f45b930a2e8d5a339bcf464f99c9a917f85bb13b75af5905aa694cf549161a2e0ce09f55dabe86ac36411a000889f737ed7a0022000005b80000001119fba1f9fd800cfdd0fcfec007db7f9373dab55f76e00330f4cf27b801987a6793dc00cfdd0fcfec0067ee87e7f6003edbfc9b9ed5aafbb7001987a6793dc00cc3d33c9ee00fcae7687126872009493d0646aac8fc051cd47259c9742a8aad5ba1559ed08c9dd23b4a9a50780538ad6e34574bff72088c4727f4428752bacc4b36ebbd1315f16d8cf48e94d629d648130eb7055ba782dca3c77c2ed049e9b8b93cc2672a34fddbc4be83aebd44a223d9bc4466f927a3c6d72ef7c3ef47279a5fcc97c972a95697d51d8c7f72a2f92dbc8a9cd7e0da73ca3945368274b614442a9b3ef49a847e3f24730d5fdde65abdad54f45525329cb04b7ff006659c9fcae45f54429b37f83eca8694b45248e496ab314693f324aa18d772675c80beed58eec75bd51091caf2b7415d6fcd9fd37f45529913f0bb95e6ccfe5a8f36b2dc51ec197996463e3fb07a409b6022f63dbf73350b957d1977c71d53fa1ff0046a9d357c3465b5275150ab5894c613d5d14fec257ff00c3ff00decff71749ca9689aed9affc713fd87d61fe17f2eb155dc505b566aaff00ef3832fd5dc053fb095fff000fff007b3fdc57fe68e897f8bffc717fd87dbfecab97cffd05ff00dac17ffb07f612bffe1ffef67fb87fcd1d12ff0017ff008e2ffb09ca33f07995899bf5d2380624f0e93d25f36c3ce28b0242cd25d67d42ca6f42f4a21a5a5a4b25eb890d13bfa77f231752e57347e5996927ac577f2b9a9df76a2f91b1d0fc82cb6893659b60d86e20caa5c53eabc795d7568e0550c2af241a615b77ff0021161c26f0c956ddcd45bf7a9ab6b3ca33eaabef5caaddcd44b37f5db72ed0593e96a144b99443efef4b464d977d46625d48e4029d0151d539a744ea6a2353c5725f422b1f4b632ea80c44edd7f62d928a2f204a6a96cb5a85533ad66578b5d7fcc7a760db344d0aa0e8ea22d3e59ad77e254c9dfe65baf81809aaace4eea8d1155386c4f0425730f4cf27b89498f1987a6793dc00cfdd0fcfec0067ee87e7f6003edbfc9b9ed5aafbb7001987a6793dc00cc3d33c9ee0067ee87e7f60033f743f3fb0019fba1f9fd80110000025e43ce3b3ea00970000151000012f21e71d9f5004b80000a8800009790f38ecfa8025c000054400004bc879c767d4012e00002a2000025e43ce3b3ea00970000151000012f21e71d9f5004b80000a880000000000025e43ce3b3ea00970000151000012f21e71d9f5004b80000a8800009790f38ecfa8025c000054400004bc879c767d4012e00002a2000025e43ce3b3ea00970000151000012f21e71d9f5004b80000a880000003ffd9, 5);

-- --------------------------------------------------------

--
-- Struttura della tabella `rispostaaperta`
--

CREATE TABLE `rispostaaperta` (
  `id` int(11) NOT NULL,
  `idDomanda` int(11) NOT NULL,
  `idUtente` int(11) NOT NULL,
  `testoRisposta` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `rispostaaperta`
--

INSERT INTO `rispostaaperta` (`id`, `idDomanda`, `idUtente`, `testoRisposta`) VALUES
(1, 1, 1, 'inter'),
(2, 2, 1, 'serie a');

-- --------------------------------------------------------

--
-- Struttura della tabella `rispostachiusa`
--

CREATE TABLE `rispostachiusa` (
  `id` int(11) NOT NULL,
  `idUtente` int(11) NOT NULL,
  `idDomanda` int(11) NOT NULL,
  `idOpzione` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `rispostachiusa`
--

INSERT INTO `rispostachiusa` (`id`, `idUtente`, `idDomanda`, `idOpzione`) VALUES
(1, 1, 3, 1);

-- --------------------------------------------------------

--
-- Struttura della tabella `sondaggio`
--

CREATE TABLE `sondaggio` (
  `id` int(11) NOT NULL,
  `idUtenteCreatore` int(11) NOT NULL,
  `tipoCreatore` enum('Premium','Azienda') NOT NULL,
  `idDominio` int(11) NOT NULL,
  `titolo` varchar(100) NOT NULL,
  `dataCreazione` date NOT NULL,
  `dataAttuale` date NOT NULL DEFAULT current_timestamp(),
  `dataChiusura` date NOT NULL,
  `stato` enum('Aperto','Creazione','Chiuso') NOT NULL DEFAULT 'Creazione',
  `numMaxPartecipanti` int(11) NOT NULL,
  `numeroIscritti` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `sondaggio`
--

INSERT INTO `sondaggio` (`id`, `idUtenteCreatore`, `tipoCreatore`, `idDominio`, `titolo`, `dataCreazione`, `dataAttuale`, `dataChiusura`, `stato`, `numMaxPartecipanti`, `numeroIscritti`) VALUES
(1, 2, 'Premium', 1, 'Sondaggione sullo sport', '2023-09-17', '2023-09-17', '2023-09-20', 'Aperto', 10, 2);

--
-- Trigger `sondaggio`
--
DELIMITER $$
CREATE TRIGGER `aggiungiPuntoUtentePremium` AFTER INSERT ON `sondaggio` FOR EACH ROW BEGIN
    -- Controlla se l'autore è un UtentePremium
    IF NEW.tipoCreatore = 'Premium' THEN
        -- Aggiornamento numSondaggi per l'ideatore
        UPDATE utentepremium
        SET numSondaggi = numSondaggi + 1
        WHERE idUtente = NEW.idUtenteCreatore;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `chiudiSondaggio` BEFORE UPDATE ON `sondaggio` FOR EACH ROW BEGIN
IF NEW.dataAttuale >= NEW.dataChiusura THEN
        SET NEW.stato = 'Chiuso';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `triggerChiamataGenerazioneInviti` AFTER UPDATE ON `sondaggio` FOR EACH ROW BEGIN
    IF NEW.stato = 'Aperto' AND NEW.tipoCreatore = 'Azienda' THEN
        CALL generazioneAutomaticaInviti(NEW.idUtenteCreatore, NEW.numMaxPartecipanti, New.id);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `utente`
--

CREATE TABLE `utente` (
  `idUtente` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `cognome` varchar(100) NOT NULL,
  `luogoNascita` varchar(100) NOT NULL,
  `annoNascita` date NOT NULL,
  `campoTotale` double NOT NULL DEFAULT 0,
  `tipologia` enum('Semplice','Premium','Amministratore') NOT NULL DEFAULT 'Semplice',
  `tipoAbbonamento` enum('0','1','2','3') NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `utente`
--

INSERT INTO `utente` (`idUtente`, `nome`, `cognome`, `luogoNascita`, `annoNascita`, `campoTotale`, `tipologia`, `tipoAbbonamento`) VALUES
(1, 'Gio', 'Kaciu', 'bologna', '2000-12-12', 0.5, 'Amministratore', '1'),
(2, 'Halit', 'Hoxha', 'bologna', '2000-12-12', 0, 'Premium', '3'),
(5, 'Ali', 'G', 'bologna', '2000-12-12', 0.5, 'Semplice', '0');

--
-- Trigger `utente`
--
DELIMITER $$
CREATE TRIGGER `assegnazionePremio` AFTER UPDATE ON `utente` FOR EACH ROW BEGIN
    DECLARE userId INT;
    DECLARE newCampoTotale DOUBLE;
    
    SET userId = NEW.idUtente;
    SET newCampoTotale = NEW.campoTotale;

    INSERT INTO utentexpremio (idPremio, idUtenteVincitore)
    SELECT id, userId
    FROM premio
    WHERE numMinimoPunti <= newCampoTotale;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `assegnazionePremium` AFTER INSERT ON `utente` FOR EACH ROW BEGIN
    DECLARE inizio DATE;
    DECLARE fine DATE;
    DECLARE numSondaggi SMALLINT;
    DECLARE costo SMALLINT;
    
    IF NEW.tipoAbbonamento != 0 THEN
        SET inizio = NOW();
        CASE NEW.tipoAbbonamento
            WHEN '1' THEN
                SET fine = DATE_ADD(inizio, INTERVAL 1 MONTH);
                SET costo = 10;
                SET numSondaggi = 0;
            WHEN '2' THEN
                SET fine = DATE_ADD(inizio, INTERVAL 1 YEAR);
                SET costo = 100;
                SET numSondaggi = 0;
            WHEN '3' THEN
                SET fine = DATE_ADD(inizio, INTERVAL 2 YEAR);
                SET costo = 180;
                SET numSondaggi = 0;
            ELSE
                SET fine = inizio;
                SET costo = 0;
                SET numSondaggi = 0;
        END CASE;
        INSERT INTO UtentePremium (idUtente, inizioAbbonamento, fineAbbonamento, costoAbbonamento, numSondaggi) 
        VALUES (NEW.idUtente, inizio, fine, costo, numSondaggi); 
    ELSE
        SET inizio = NOW();
        SET fine = inizio;
        SET costo = 0;
        SET numSondaggi = 0;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `updateUtentebase` AFTER INSERT ON `utente` FOR EACH ROW BEGIN
    CASE NEW.tipologia
        WHEN 'Semplice' THEN
            UPDATE utentebase SET tipologia = 'Semplice' WHERE id = NEW.idUtente;
        WHEN 'Premium' THEN
                    UPDATE utentebase SET tipologia = 'Premium' WHERE id = NEW.idUtente;
        WHEN 'Amministratore' THEN
                    UPDATE utentebase SET tipologia = 'Amministratore' WHERE id = NEW.idUtente;
    END CASE;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `updateUtentebase2` AFTER UPDATE ON `utente` FOR EACH ROW BEGIN
    CASE NEW.tipologia
        WHEN 'Semplice' THEN
            UPDATE utentebase SET tipologia = 'Semplice' WHERE id = NEW.idUtente;
        WHEN 'Premium' THEN
                    UPDATE utentebase SET tipologia = 'Premium' WHERE id = NEW.idUtente;
        WHEN 'Amministratore' THEN
                    UPDATE utentebase SET tipologia = 'Amministratore' WHERE id = NEW.idUtente;
    END CASE;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `utentebase`
--

CREATE TABLE `utentebase` (
  `id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `tipologiaUtente` enum('Azienda','Utente') NOT NULL,
  `tipologia` enum('Azienda','Semplice','Premium','Amministratore') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `utentebase`
--

INSERT INTO `utentebase` (`id`, `email`, `password`, `tipologiaUtente`, `tipologia`) VALUES
(1, 'amministratore@gmail.com', 'Amministratore', 'Utente', 'Amministratore'),
(2, 'halit@gmail.com', 'Prova', 'Utente', 'Premium'),
(5, 'alioune@gmail.com', 'Prova', 'Utente', 'Semplice'),
(6, 'azienda@gmail.com', 'Azienda', 'Azienda', 'Azienda'),
(7, 'azienda2@gmail.com', 'Azienda', 'Azienda', 'Azienda');

-- --------------------------------------------------------

--
-- Struttura della tabella `utentepremium`
--

CREATE TABLE `utentepremium` (
  `idUtente` int(11) NOT NULL,
  `inizioAbbonamento` date NOT NULL,
  `fineAbbonamento` date NOT NULL,
  `costoAbbonamento` smallint(6) NOT NULL,
  `numSondaggi` smallint(6) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `utentepremium`
--

INSERT INTO `utentepremium` (`idUtente`, `inizioAbbonamento`, `fineAbbonamento`, `costoAbbonamento`, `numSondaggi`) VALUES
(1, '2023-09-17', '2023-10-17', 10, 0),
(2, '2023-09-17', '2025-09-17', 180, 1),
(5, '2023-09-17', '2023-09-17', 0, 0);

-- --------------------------------------------------------

--
-- Struttura della tabella `utentexdominio`
--

CREATE TABLE `utentexdominio` (
  `idUtente` int(11) NOT NULL,
  `idDominio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `utentexdominio`
--

INSERT INTO `utentexdominio` (`idUtente`, `idDominio`) VALUES
(1, 1),
(1, 2),
(1, 3),
(2, 2),
(2, 3),
(2, 4),
(5, 1),
(5, 2),
(5, 3),
(5, 4);

-- --------------------------------------------------------

--
-- Struttura della tabella `utentexpremio`
--

CREATE TABLE `utentexpremio` (
  `idPremio` int(11) NOT NULL,
  `idUtenteVincitore` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `utentexsondaggio`
--

CREATE TABLE `utentexsondaggio` (
  `idSondaggio` int(11) NOT NULL,
  `idUtente` int(11) NOT NULL,
  `completato` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `utentexsondaggio`
--

INSERT INTO `utentexsondaggio` (`idSondaggio`, `idUtente`, `completato`) VALUES
(1, 1, 1),
(1, 5, 0);

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `azienda`
--
ALTER TABLE `azienda`
  ADD PRIMARY KEY (`idUtente`),
  ADD UNIQUE KEY `nome_UNIQUE` (`nome`),
  ADD UNIQUE KEY `codiceFiscale` (`codiceFiscale`);

--
-- Indici per le tabelle `domanda`
--
ALTER TABLE `domanda`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idSondaggio` (`idSondaggio`) USING BTREE;

--
-- Indici per le tabelle `dominio`
--
ALTER TABLE `dominio`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`);

--
-- Indici per le tabelle `invito`
--
ALTER TABLE `invito`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codice` (`codice`),
  ADD KEY `idMittente` (`idMittente`) USING BTREE,
  ADD KEY `idSondaggio` (`idSondaggio`) USING BTREE,
  ADD KEY `idRicevente` (`idRicevente`) USING BTREE;

--
-- Indici per le tabelle `opzione`
--
ALTER TABLE `opzione`
  ADD PRIMARY KEY (`idDomanda`,`idOpzione`),
  ADD KEY `idDomanda` (`idDomanda`) USING BTREE;

--
-- Indici per le tabelle `premio`
--
ALTER TABLE `premio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idCreatore` (`idCreatore`) USING BTREE;

--
-- Indici per le tabelle `rispostaaperta`
--
ALTER TABLE `rispostaaperta`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idDomanda` (`idDomanda`),
  ADD KEY `idUtente` (`idUtente`);

--
-- Indici per le tabelle `rispostachiusa`
--
ALTER TABLE `rispostachiusa`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idDomanda` (`idDomanda`),
  ADD UNIQUE KEY `idUtente` (`idUtente`);

--
-- Indici per le tabelle `sondaggio`
--
ALTER TABLE `sondaggio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sondaggio_ibfk_3` (`idDominio`),
  ADD KEY `idUtente` (`idUtenteCreatore`) USING BTREE;

--
-- Indici per le tabelle `utente`
--
ALTER TABLE `utente`
  ADD PRIMARY KEY (`idUtente`);

--
-- Indici per le tabelle `utentebase`
--
ALTER TABLE `utentebase`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indici per le tabelle `utentepremium`
--
ALTER TABLE `utentepremium`
  ADD PRIMARY KEY (`idUtente`);

--
-- Indici per le tabelle `utentexdominio`
--
ALTER TABLE `utentexdominio`
  ADD KEY `utentedominio_ibfk_1` (`idDominio`),
  ADD KEY `utentedominio_ibfk_2` (`idUtente`);

--
-- Indici per le tabelle `utentexpremio`
--
ALTER TABLE `utentexpremio`
  ADD KEY `idPremio` (`idPremio`),
  ADD KEY `idUtenteVincitore` (`idUtenteVincitore`);

--
-- Indici per le tabelle `utentexsondaggio`
--
ALTER TABLE `utentexsondaggio`
  ADD KEY `idSondaggio` (`idSondaggio`),
  ADD KEY `idUtente` (`idUtente`);

--
-- AUTO_INCREMENT per le tabelle scaricate
--

--
-- AUTO_INCREMENT per la tabella `domanda`
--
ALTER TABLE `domanda`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT per la tabella `dominio`
--
ALTER TABLE `dominio`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT per la tabella `invito`
--
ALTER TABLE `invito`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT per la tabella `premio`
--
ALTER TABLE `premio`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT per la tabella `rispostaaperta`
--
ALTER TABLE `rispostaaperta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT per la tabella `rispostachiusa`
--
ALTER TABLE `rispostachiusa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT per la tabella `sondaggio`
--
ALTER TABLE `sondaggio`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT per la tabella `utentebase`
--
ALTER TABLE `utentebase`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `azienda`
--
ALTER TABLE `azienda`
  ADD CONSTRAINT `azienda_ibfk_1` FOREIGN KEY (`idUtente`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `domanda`
--
ALTER TABLE `domanda`
  ADD CONSTRAINT `domanda_ibfk_1` FOREIGN KEY (`idSondaggio`) REFERENCES `sondaggio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `invito`
--
ALTER TABLE `invito`
  ADD CONSTRAINT `invito_ibfk_1` FOREIGN KEY (`idMittente`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `invito_ibfk_2` FOREIGN KEY (`idRicevente`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `invito_ibfk_3` FOREIGN KEY (`idSondaggio`) REFERENCES `sondaggio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `opzione`
--
ALTER TABLE `opzione`
  ADD CONSTRAINT `opzione_ibfk_1` FOREIGN KEY (`idDomanda`) REFERENCES `domanda` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `premio`
--
ALTER TABLE `premio`
  ADD CONSTRAINT `premio_ibfk_1` FOREIGN KEY (`idCreatore`) REFERENCES `utente` (`idUtente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `rispostaaperta`
--
ALTER TABLE `rispostaaperta`
  ADD CONSTRAINT `rispostaaperta_ibfk_1` FOREIGN KEY (`idDomanda`) REFERENCES `domanda` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rispostaaperta_ibfk_2` FOREIGN KEY (`idUtente`) REFERENCES `utente` (`idUtente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `rispostachiusa`
--
ALTER TABLE `rispostachiusa`
  ADD CONSTRAINT `rispostachiusa_ibfk_1` FOREIGN KEY (`idDomanda`) REFERENCES `domanda` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rispostachiusa_ibfk_2` FOREIGN KEY (`idUtente`) REFERENCES `utente` (`idUtente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `sondaggio`
--
ALTER TABLE `sondaggio`
  ADD CONSTRAINT `sondaggio_ibfk_2` FOREIGN KEY (`idUtenteCreatore`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `sondaggio_ibfk_3` FOREIGN KEY (`idDominio`) REFERENCES `dominio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `utente`
--
ALTER TABLE `utente`
  ADD CONSTRAINT `utente_ibfk_1` FOREIGN KEY (`idUtente`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `utentepremium`
--
ALTER TABLE `utentepremium`
  ADD CONSTRAINT `utentepremium_ibfk_1` FOREIGN KEY (`idUtente`) REFERENCES `utente` (`idUtente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `utentexdominio`
--
ALTER TABLE `utentexdominio`
  ADD CONSTRAINT `utentexdominio_ibfk_1` FOREIGN KEY (`idDominio`) REFERENCES `dominio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `utentexdominio_ibfk_2` FOREIGN KEY (`idUtente`) REFERENCES `utente` (`idUtente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `utentexpremio`
--
ALTER TABLE `utentexpremio`
  ADD CONSTRAINT `utentexpremio_ibfk_1` FOREIGN KEY (`idPremio`) REFERENCES `premio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `utentexpremio_ibfk_2` FOREIGN KEY (`idUtenteVincitore`) REFERENCES `utente` (`idUtente`);

--
-- Limiti per la tabella `utentexsondaggio`
--
ALTER TABLE `utentexsondaggio`
  ADD CONSTRAINT `utentexsondaggio_ibfk_1` FOREIGN KEY (`idSondaggio`) REFERENCES `sondaggio` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `utentexsondaggio_ibfk_2` FOREIGN KEY (`idUtente`) REFERENCES `utentebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Eventi
--
CREATE DEFINER=`root`@`localhost` EVENT `updateDate` ON SCHEDULE EVERY 1 HOUR STARTS '2023-09-04 13:26:52' ENDS '2024-09-04 13:26:52' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN 
    UPDATE sondaggio 
    SET dataAttuale = CURRENT_TIMESTAMP() 
    WHERE stato = 'Aperto'; 
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
