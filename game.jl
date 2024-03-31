WHITE::Bool=true
BLACK::Bool=false


#TODO:implementare
#enpassantSquare=0b0000000000000000000000000000000000000000000000000000000000000000; da inserire nel gameState e modificare metodi correlati

white_pieces = 0x0000000000000008 | 0x0000000000000010 | 0x0000000000000024 | 0x0000000000000042 | 0x0000000000000081 | 0x000000000000ff00;  # 13
black_pieces = 0x0800000000000000 | 0x1000000000000000 | 0x2400000000000000 | 0x4200000000000000 | 0x8100000000000000 | 0x00ff000000000000;  # 14
chessboard = white_pieces | black_pieces;  # 15

bitBoards = [0x0000000000000008, 0x0000000000000010, 0x0000000000000024, 0x0000000000000042, 0x0000000000000081, 0x000000000000ff00, 0x0800000000000000, 0x1000000000000000, 0x2400000000000000, 0x4200000000000000, 0x8100000000000000, 0x00ff000000000000, white_pieces, black_pieces, chessboard];
gameState = [true, WHITE, false, false, true, true, true, true];

function getBoardToPrint()
    A=Matrix{Char}(undef, 8, 8) # Inizializzo la matrice da stampare
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # creo e shifto la casella a8
    v = divrem(i, 8);
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
    bitBoardsfromFEN(fen::String)
    Prende una stringa FEN e ritorna bitBoards, ossia l'insieme delle 12 + 3 bitBoard fondamentali.
    Oltre alle bitBoards ritorna anche il gameState della stringa FEN.
TBW
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
new_white_pieces = white_king | white_queens | white_bishops | white_knights | white_rooks | white_pawns;  # 13
new_black_pieces = black_king | black_queens | black_bishops | black_knights | black_rooks | black_pawns;  # 14
new_chessboard = new_white_pieces | new_black_pieces;  # 15
    return [white_king, white_queens, white_bishops, white_knights, white_rooks, white_pawns, black_king, black_queens, black_bishops, black_knights, black_rooks, black_pawns, new_white_pieces, new_black_pieces, new_chessboard], [true, playing_turn, false, false, w_cast_king, w_cast_queen, b_cast_king, b_cast_queen];
end

function setBitBoardsFromFEN!(fen::String)
    newValues = bitBoardsfromFEN(fen);
    bitBoards.=newValues[1];
    gameState.=newValues[2];
end




"""
Questa serie di funzioni get ritorna la bitBoard o lo stato del gioco particolare.
In questo modo non devo 
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
    return bitBoards[13]
end

function getBlackPieces()
    return bitBoards[14]
end

function getChessBoard()
    return bitBoards[15]
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






# Per ora è qui che si esegue il codice del gioco
#
#
display("text/plain", getBoardToPrint())
printState()
setBitBoardsFromFEN!("4kb1r/p4ppp/4q3/8/8/1B6/PPP2PPP/2KR4 w --k- - 1 2")
display("text/plain", getBoardToPrint())
printState()
setBitBoardsFromFEN!("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
display("text/plain", getBoardToPrint())
printState()

