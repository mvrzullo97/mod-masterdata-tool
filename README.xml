lo script bash 'changeLMDFiles.sh' è stato sviluppato con l'intento di velocizzare i futuri test di SdC riguardanti il modulo LMD.

attualmente modifica il seguente set di file presenti nella cartella 'TEMPLATE':

	- Pedaggi_YYYYMMDD_RRR_PPPPP
	- Punti_YYYYMMDD_RRR_PPPPP
	- Percorsi-Portali_YYYYMMDD_RRR_PPPPP

---------------------- Usage ----------------------

   bash changeLMDFiles.sh

    -d <input directory> 
    -v <validity date (YYYY-MM-DD)> 
    -r <rete (ex. 1)> 
    -u <punto uscita (ex. 410)> 
    -e <punto entrata (solo per rete 1)>
    -c <classe veicolo (10,20,30,40,50)> 
    -s <società (ex. 6)> 
    -n <nuovo importo non arrotondato (ex. 00241769)> 
    -i <nuovo importo arrotondato (ex. 00242)>        

----------------------------------------------------

di seguito i controlli relativi alla validità del dato inserito in input dall'utente:

	- controllo sui parametri necessari per eseguire correttamente lo script
	- esistenza file Pedaggi, Percorsi-Portali e Punti
	- esistenza directory di output 'OUT_DIR' (se non esiste la crea automaticamente)
	- controllo dateFormat (YYYY-MM-DD)
	- esistenza classe veicolo
	- esistenza rete
	- esistenza stazioni in relazione alla rete inserita
	- esistenza società in relazione alla rete
	- lunghezza 'importo non arrotondato' e 'importo arrotondato'

modificati i file d'interesse, chiede all'utente se vuole lanciare lo script 'createFileIndex.sh' per creare il file index.xml da dare in pasto a LMD:

- se si, lo lancia prendendo in input 'OUT_DIR', calcola l'hashcode (MD5) di ogni file presente nella directory e crea il file index_TMP.xml.
Creato il file temporaneo fa partire un timer di 10 secondi al termine del quale rinomina il file in index.xml per la gestione corretta da parte di LMD.

- altrimenti, lo script termina salvando i file modificati in 'OUT_DIR' e persistendo il numero progressivo pedaggi utilizzato nel file 'PRG_persistence.txt' presente
nella cartella 'TEMPLATE'. 

NOTA: attualmente lo script modifica un solo set di file per ogni rete, sviluppi futuri permetteranno di cambiare più pedaggi per la stessa rete.