include("DataManager.jl")

export bitBoards, bittyBoards, gameState

"""
File containing the basis of our ChessGame rapresentation.
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


"""
Prints the board in a human representation
"""
function printBoard()
    A=Matrix{Char}(undef, 8, 8) # The matrix to be printed
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # A8 square that gets shifted
    v = divrem(i, 8); # division with rem.
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
Game runs from here right now: sort of MAIN
"""

###################################################MAIN################################################################
setStartingPosition()
printBoard()
printState()
#########################################################################################################################

