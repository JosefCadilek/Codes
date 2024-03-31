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

# Definisco, per facile lettura per ora
WHITE::Bool=true
BLACK::Bool=false


#TODO:implementare
#enpassantSquare=0b0000000000000000000000000000000000000000000000000000000000000000; da inserire nel gameState e modificare metodi correlati

bitBoards = [0x0000000000000008, 0x0000000000000010, 0x0000000000000024, 0x0000000000000042, 0x0000000000000081, 0x000000000000ff00, 0x0800000000000000, 0x1000000000000000, 0x2400000000000000, 0x4200000000000000, 0x8100000000000000, 0x00ff000000000000];
gameState = [true, WHITE, false, false, true, true, true, true];



"""
Funzione che ritorna una matrice. Questa matrice rappresenta la scacchiera e si può stampare con printBoard()
"""
function getBoardToPrint()
    A=Matrix{Char}(undef, 8, 8) # Inizializzo la matrice da stampare
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # creo e shifto la casella a8
    v = divrem(i, 8); # Divisione col resto per trovare le coordinate della casella
    if((square & getBlackPieces()) == square)
        if ((getBlackKing() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='k';
            continue;
        end
        if ((getBlackQueens() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='q';
            continue;
        end
        if ((getBlackBishops() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='b';
            continue;
        end
        if ((getBlackKnights() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='n';
            continue;
        end
        if ((getBlackRooks() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='r';
            continue;
        end
        if ((getBlackPawns() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='p';
            continue;
        end
    elseif((square & getWhitePieces()) == square)
        if ((getWhiteKing() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='K';
            continue;
        end
        if ((getWhiteQueens() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='Q';
            continue;
        end
        if ((getWhiteBishops() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='B';
            continue;
        end
        if ((getWhiteKnights() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='N';
            continue;
        end
        if ((getWhiteRooks() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='R';
            continue;
        end
        if ((getWhitePawns() & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='P';
            continue;
        end
    else
        A[v[1] + 1, v[2] + 1]='-';
    end

end
return A
end

"""
Stampa a schermo la scacchiera
"""
function printBoard()
    display("text/plain", getBoardToPrint())
end

"""
Stampa a schermo lo stato della scacchiera, informazioni cruciali.
"""
function printState()
    if(getRunningGameState())
        if (getTurnGameState() == WHITE)
            println("Partita in corso: BIANCO muove!")
            if(getWhiteCastleKingside())
                println("potrebbe arroccare corto!")
            end
            if(getWhiteCastleQueenside())
                println("potrebbe arroccare lungo!")
            end
        else
            println("Partita in corso: NERO muove!")
            if(getBlackCastleKingside())
                println("potrebbe arroccare corto!")
            end
            if(getBlackCastleQueenside())
                println("potrebbe arroccare lungo!")
            end
        end
    else
        if(getDecisiveGameState())
            if(getWinnerGameState() == WHITE)
            println("Partita terminata: BIANCO ha VINTO!")
            else
                println("Partita terminata: NERO ha VINTO!")
            end
        else
            println("Partita terminata: PATTA!")
        end
    end
end

"""
    Prende una stringa FEN e ritorna bitBoards, ossia l'insieme delle 12 bitBoard fondamentali.
    Oltre alle bitBoards ritorna anche il gameState della stringa FEN.
"""
function bitBoardsfromFEN(fen::String)
    # Inizializzo bitBoards vuote
    white_king  = 0b0000000000000000000000000000000000000000000000000000000000000000;
    white_queens  = 0b0000000000000000000000000000000000000000000000000000000000000000;
    white_bishops = 0b0000000000000000000000000000000000000000000000000000000000000000;
    white_knights = 0b0000000000000000000000000000000000000000000000000000000000000000;
    white_rooks = 0b0000000000000000000000000000000000000000000000000000000000000000;
    white_pawns = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_king = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_queens = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_bishops = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_knights = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_rooks  = 0b0000000000000000000000000000000000000000000000000000000000000000;
    black_pawns = 0b0000000000000000000000000000000000000000000000000000000000000000;
    playing_turn = false;
    b_cast_king=false;
    b_cast_queen=false;
    w_cast_king=false;
    w_cast_queen=false;
    # Spezzo la stringa FEN lungo gli spazi
    fenPieces = split(fen, r"\s+");
    count = 0; # contatore da 1 a 63

    #Creo bitBoards
    for letter in fenPieces[1]
        # Creo e shfito la casella
        square=0b1000000000000000000000000000000000000000000000000000000000000000 >> count;
        if(letter >= '1' && letter <='8')
            count+=letter-'0';
            continue;
        elseif(letter == '/')
            continue;
        else
        if(letter=='k')
            black_king=square;
            count+=1;
            continue;
        end
        if(letter=='q')
            black_queens=black_queens|square;
            count+=1;
            continue;
        end
        if(letter=='b')
            black_bishops=black_bishops|square;
            count+=1;
            continue;
        end
        if(letter=='n')
            black_knights=black_knights|square;
            count+=1;
            continue;
        end
        if(letter=='r')
            black_rooks=black_rooks|square;
            count+=1;
            continue;
        end
        if(letter=='p')
            black_pawns=black_pawns|square;
            count+=1;
            continue;
        end

        if(letter=='K')
            white_king=square;
            count+=1;
            continue;
        end
        if(letter=='Q')
            white_queens=white_queens|square;
            count+=1;
            continue;
        end
        if(letter=='B')
            white_bishops=white_bishops|square;
            count+=1;
            continue;
        end
        if(letter=='N')
            white_knights=white_knights|square;
            count+=1;
            continue;
        end
        if(letter=='R')
            white_rooks=white_rooks|square;
            count+=1;
            continue;
        end
        if(letter=='P')
            white_pawns=white_pawns|square;
            count+=1;
            continue;
        end
    end
end

if (occursin('w', fenPieces[2]))
    playing_turn=WHITE;
else
    playing_turn=BLACK;
end

if (occursin('k', fenPieces[3]))
    b_cast_king=true;
end
if(occursin('q', fenPieces[3]))
    b_cast_queen=true;
end
if (occursin('K', fenPieces[3]))
    w_cast_king=true;
end
if (occursin('Q', fenPieces[3]))
    w_cast_queen=true;
end
    return [white_king, white_queens, white_bishops, white_knights, white_rooks, white_pawns, black_king, black_queens, black_bishops, black_knights, black_rooks, black_pawns], [true, playing_turn, false, false, w_cast_king, w_cast_queen, b_cast_king, b_cast_queen];
end


"""
Imposta le bitBoards e lo stato del gioco secondo la stringa FEN ricevuta come input
"""
function setBitBoardsFromFEN(fen::String)
    newValues = bitBoardsfromFEN(fen);
    bitBoards.=newValues[1];
    gameState.=newValues[2];
end




"""
Questa serie di funzioni get ritorna la bitBoard o lo stato del gioco particolare.
In questo modo non devo cercarli tramite l'indice dell'array... (doloroso)
"""
function getWhiteKing()
    return bitBoards[1]
end

function getWhiteQueens()
    return bitBoards[2]
end

function getWhiteBishops()
    return bitBoards[3]
end

function getWhiteKnights()
    return bitBoards[4]
end

function getWhiteRooks()
    return bitBoards[5]
end

function getWhitePawns()
    return bitBoards[6]
end

function getBlackKing()
    return bitBoards[7]
end

function getBlackQueens()
    return bitBoards[8]
end

function getBlackBishops()
    return bitBoards[9]
end

function getBlackKnights()
    return bitBoards[10]
end

function getBlackRooks()
    return bitBoards[11]
end

function getBlackPawns()
    return bitBoards[12]
end

function getWhitePieces()
    return getWhiteKing() | getWhiteQueens() | getWhiteBishops() | getWhiteKnights() | getWhiteRooks() | getWhitePawns()
end

function getBlackPieces()
    return getBlackKing() | getBlackQueens() | getBlackBishops() | getBlackKnights() | getBlackRooks() | getBlackPawns()
end

function getChessBoard()
    return getWhitePieces() | getBlackPieces()
end

function getRunningGameState()
    return gameState[1]
end

function getTurnGameState()
    return gameState[2]    
end

function getDecisiveGameState()
    return gameState[3]
end

function getWinnerGameState()
    return gameState[4]
end

function getWhiteCastleKingside()
    return gameState[5]
end

function getWhiteCastleQueenside()
    return gameState[6]
end

function getBlackCastleKingside()
    return gameState[7]
end

function getBlackCastleQueenside()
    return gameState[8]
end



"""
Imposta la posizione iniziale, per ora da FEN, per provare, ma in seguito
TODO: Sciverlo a partire dalle bitboards, così non c'è bisogno di alcun calcolo. (copia incolla da sopra, ma non ho voglia è quasi mezzanotte)
"""
function setStartingPosition()
    setBitBoardsFromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
end






"""
Per ora è qui che si esegue il codice del gioco
"""

println("Scacchi in Julia")
println("Loading game...") # Stampo messaggi a caso che sembrano avere la loro importanza, solo per eludere l'utente sulla complessità
setStartingPosition()
println("Game loaded -> sending output...")
printBoard()
printState()

#posizione trovata a caso
setBitBoardsFromFEN("r1bk3r/p2pBpNp/n4n2/1p1NP2P/6P1/3P4/P1P1K3/q5b1 w ----")
printBoard()

