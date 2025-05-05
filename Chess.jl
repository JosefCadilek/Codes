include("DataManager.jl")

"""
File containing the basis of our ChessGame representation.
- bitBoards
- gameState
- cleanBitBoards()
- printBitBoard()
- setStartingPosition()
- 
"""

WHITE::Bool=true
BLACK::Bool=false

# contains 12 key bitBoards: white king, queens, bishops, knights, rooks, pawns. For black the same, in the same order
bitBoards = [0x0000000000000008, 0x0000000000000010, 0x0000000000000024, 0x0000000000000042, 0x0000000000000081, 0x000000000000ff00, 0x0800000000000000, 0x1000000000000000, 0x2400000000000000, 0x4200000000000000, 0x8100000000000000, 0x00ff000000000000]
# additional bitBoards, we will call them bittyBoards: for now only enpassant
bittyBoards = [0x0000000000000000]
# Holds: running, turn, decisive, winner, K, Q, k, q, CHECK
gameState = [true, WHITE, false, false, true, true, true, true, false]

"""
---------------------------------------------------
- a8, b8, c8, ...                                   the bit with major value is the top left corner,
- a7                                                the value one is the h1 square
- a6
- a5
- .
- .
- .
-
---------------------------------------------------
"""

# Returns the least significant bit set only
function leastSignificantBit(bitboard::UInt64)::UInt64
    return bitboard & ~(bitboard - 1)
end

# Turns on bit of given bitboard and ID
# It returns the modified bitboard but it does not modify the inputed variable.
function setBitOn(bitboard::UInt64, id)::UInt64
    return bitboard | (0x0000000000000001 << (id - 1))
end

# UGLY written function: sets off a bit in a given position. (TODO: should use dictionaries maybe)
function setBitOff(bitboard::UInt64, id)::UInt64
    return xor(setBitOn(bitboard, id), (0x0000000000000001 << (id - 1)))
end

# pops a particular bit. it turns 1 if it was 0. it turns 0 if it was 1.
function switchBit(bitboard::UInt64, id)::UInt64
    return xor(bitboard, (0x0000000000000001 << (id - 1)))
end

# Given a bitBoard it prints it
function printBitBoard(bitboard::UInt64)
    for i=1:8:64
        println(SubString(bitstring(bitboard), i:(i+7)))
    end
end

# sets every bitboard, bittyboard and gamestate to 0 or false. Except of running.
function cleanBitBoards()
    bitBoards .= 0x0000000000000000
    bittyBoards .= 0x0000000000000000
    gameState .= [true, false, false, false, false, false, false, false, false]
end

# sets bitboards, bittyboards and gamestate as in the classical starting chess game position.
function setStartingPosition()
    bitBoards .= [0x0000000000000008, 0x0000000000000010, 0x0000000000000024, 0x0000000000000042, 0x0000000000000081, 0x000000000000ff00, 0x0800000000000000, 0x1000000000000000, 0x2400000000000000, 0x4200000000000000, 0x8100000000000000, 0x00ff000000000000]
    bittyBoards .= [0x0000000000000000]
    gameState .= [true, WHITE, false, false, true, true, true, true, false]
end


##################################
#TODO list
# 1) getFENfromBitBoards -> takes bitBitboards and gamestate and returns a fen string associated with them.
##################################




"""
    Takes a FEN string as input and outputs bitBoards, bittyBoards with gameState
    //TODO: Check and move counter
"""
function bitBoardsfromFEN(fen::String)
    # empty bitboards
    white_king  = 0x0000000000000000
    white_queens  = 0x0000000000000000
    white_bishops = 0x0000000000000000
    white_knights = 0x0000000000000000
    white_rooks = 0x0000000000000000
    white_pawns = 0x0000000000000000
    black_king = 0x0000000000000000
    black_queens = 0x0000000000000000
    black_bishops = 0x0000000000000000
    black_knights = 0x0000000000000000
    black_rooks  = 0x0000000000000000
    black_pawns = 0x0000000000000000
    EP = 0x0000000000000000
    playing_turn = false;
    b_cast_king=false;
    b_cast_queen=false;
    w_cast_king=false;
    w_cast_queen=false;
    # split FEN in pieces
    fenPieces = split(fen, r"\s+");
    count = 0; # counter from 1 to 63

    #create bitboards
    for letter in fenPieces[1]
        # Create A8 square and shift
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
    playing_turn=true
else
    playing_turn=false
end

if (occursin('k', fenPieces[3]))
    b_cast_king=true
end
if(occursin('q', fenPieces[3]))
    b_cast_queen=true
end
if (occursin('K', fenPieces[3]))
    w_cast_king=true
end
if (occursin('Q', fenPieces[3]))
    w_cast_queen=true
end

if(!occursin('-', fenPieces[4]))
    EP = get(SQUARES_TO_BITBOARDS, fenPieces[4], 0x0000000000000000)
    printBitBoard(EP)
end
    return [white_king, white_queens, white_bishops, white_knights, white_rooks, white_pawns, black_king, black_queens, black_bishops, black_knights, black_rooks, black_pawns], [true, playing_turn, false, false, w_cast_king, w_cast_queen, b_cast_king, b_cast_queen, false], [EP];
end


"""
Sets bitboards and gamestate from a FEN string
"""
function setBitBoardsFromFEN(fen::String)
    newValues = bitBoardsfromFEN(fen)
    bitBoards .= newValues[1]
    gameState .= newValues[2]
    bittyBoards .= newValues[3]
end


"""
These functions sets bitboards, gamestate and bittyboards if inputed with proper array
"""
function setBitBoards(bitboards)
    bitBoards .= bitboards
end

function setGameState(gamestate)
    gameState .= gamestate
end

function setBittyBoards(bittyboards)
    bitBoards .= bittyboards
end


"""
Prints the board in a human representation
"""
function printBoard()
    A=Matrix{Char}(undef, 8, 8) # The matrix to be printed
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # A8 square that gets shifted
    v = divrem(i, 8); # division with rem.
    if((square & getBlackOccupancies()) == square)
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
    elseif((square & getWhiteOccupancies()) == square)
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
display("text/plain", A)
end

function printBoard(BITBOARDS)
    black_occ = BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
    white_occ = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6]
    A=Matrix{Char}(undef, 8, 8) # The matrix to be printed
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # A8 square that gets shifted
    v = divrem(i, 8); # division with rem.
    if((square & black_occ) == square)
        if ((BITBOARDS[7] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='k';
            continue;
        end
        if ((BITBOARDS[8] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='q';
            continue;
        end
        if ((BITBOARDS[9] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='b';
            continue;
        end
        if ((BITBOARDS[10] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='n';
            continue;
        end
        if ((BITBOARDS[11] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='r';
            continue;
        end
        if ((BITBOARDS[12] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='p';
            continue;
        end
    elseif((square & white_occ) == square)
        if ((BITBOARDS[1] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='K';
            continue;
        end
        if ((BITBOARDS[2] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='Q';
            continue;
        end
        if ((BITBOARDS[3] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='B';
            continue;
        end
        if ((BITBOARDS[4] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='N';
            continue;
        end
        if ((BITBOARDS[5] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='R';
            continue;
        end
        if ((BITBOARDS[6] & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='P';
            continue;
        end
    else
        A[v[1] + 1, v[2] + 1]='-';
    end

end
display("text/plain", A)
end


# Prints crucial information about game state.
function printState()
    if(getRunningGameState())
        if (getTurnGameState() == WHITE)
            println("game running: WHITE to move")
        else
            println("game running: BLACK to move!")
        end
    else
        if(getDecisiveGameState())
            if(getWinnerGameState() == WHITE)
            println("Game Over: WHITE has WON!")
            else
                println("Game Over: BLACK has WON!")
            end
        else
            println("Draw :(")
        end
    end
end

"""
get functions for bitboards and gamestate
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

function getWhiteOccupancies()
    return getWhiteKing() | getWhiteQueens() | getWhiteBishops() | getWhiteKnights() | getWhiteRooks() | getWhitePawns()
end

function getBlackOccupancies()
    return getBlackKing() | getBlackQueens() | getBlackBishops() | getBlackKnights() | getBlackRooks() | getBlackPawns()
end

function getOccupancies()
    return getWhiteOccupancies() | getBlackOccupancies()
end

# returns current EnPassant square
function getEPsquare()
    return bittyBoards[1]
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

function getCheck()
    return gameState[9]
end

function getBitBoards()
    return bitBoards
end

function getGameState()
    return gameState
end

function getBittyBoards()
    return bittyBoards
end

