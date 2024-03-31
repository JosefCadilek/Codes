---------------------------------------------------------------------------------------------------------------------------
FOR NOT ITALIAN SPEAKERS: Translation in (bad) english will be performed in future versions
---------------------------------------------------------------------------------------------------------------------------


Chissà se questa è la sezione più esatta per progetti di questo tipo, quindi forse verrà spostato in futuro.

"""
Data 31/03/2024 - 23:00

Questa per ora è il file principale del programma, in seguito verrà adottata una struttura più complessa (immagino)

Per ora ci sono stati questi obiettivi:
1) Sviluppare un efficiente metodo di rappresentazione della scacchiera e dei pezzi attraverso la più semplice
    delle possibilità (in termini di lavoro computazionale, non di facilità di scrittura).
    SOLUZIONE:
    Ritengo che l'opzione vincente sia quella delle bitboards ovvero 12 scacchiere che rappresentano ciascuna in bit
    un insieme di pezzi di un certo colore.
    (ci saranno varie migliorie nel tempo credo)

2) Traduzione dalla notazione FEN in bitboards (non deve essere per forza ottimizzatissimo)
3) Un modo basilare di visualizzare la scacchiera
    In futuro verrà creata un'interfaccia grafica o in alternativa verrà implementato un bridge tra il motore e una gui esterna.
    Ci sono insomma varie modalità, ma una cosa che sicuramente è nei piani futuri è quella di collegare il motore al sito lichess
    e iscriverlo come BOT ufficiale. (ci sarà da decidere il suo nome)


    OBIETTIVI FUTURI PIU' PROSSIMI:
Ora sto studiando vari approcci per la generazione di mosse a partire dalle bitboards e il tema è vasto. Ci sono metodi brillanti
che risolvono il problema e non è detto che non sia possibile migliorarli.
La scelta vincente in questo caso è secondo me la generazione di mosse legali invece di quelle pseudo-legali.
Ci sono motori infatti che calcolano mosse pseudo-legali, ossia magari muovono un cavallo, ma solo dopo valutano che è scacco e
perciò la mossa è illegale.
Questa a lungo andare è una scelta sicuramente perdente.
E' necessaria la più veloce delle ricerche di mosse possibili in quanto le mosse da calcolare si moltiplicano a dismisura.
Generare solo mosse legali attraverso le bitboards è possibile, ma nella programmazione ci vuole cautela e strategia.
Per sfruttare la loro rappresentazionen conviene usare le bitwise operation, così si ottimizza la velocità di calcolo.

Inoltre, conviene prima fare un leggero punto sulla programmazione generale in Julia prima di procedere con la scrittura
così che il codice possa essere più decente possibile già alle prime stesure, per evitare grossi gap futuri.
"""
