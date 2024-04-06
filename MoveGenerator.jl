include("DataManager.jl")
include("Chess.jl")

"""
Legal move generator step by step

Chess Rules:
documantion about the rules of chess are taken from FIDE: https://handbook.fide.com/chapter/E012023 
"""


# main function that generates and formats list of legal moves
# TODO: everything
function generateMoves()
    if(getTurnGameState() == WHITE)
        # as first we want to generate EnemyOrEmpty bitboard variable
        occupied = getOccupancies()
        empty = ~occupied
        enemyOrEmpty = ~getWhiteOccupancies()
    else # Black move generator
        occupied = getOccupancies()
        empty = ~occupied
        enemyOrEmpty = ~getBlackOccupancies()
    end
    return moves
end

# function that moves a piece from one bitsquare to another one, if the target square is occupied it replaces the piece.
# note that alliance pieces are removed from the board too.
function move(from::UInt64, to::UInt64)
    indexFrom = getBitBoardsIndex(from)
    if(indexFrom !== nothing)
    indexTo = getBitBoardsIndex(to)
    bitBoards[indexFrom] = (bitBoards[indexFrom] & ~from) | to
        if(indexTo !== nothing)
            bitBoards[indexTo] = bitBoards[indexTo] & ~to
        end
    end
end

# move function as above, but takes normal notation as input
function move(fromSquare::String, toSquare::String)
    from = get(SQUARES_TO_BITBOARDS, fromSquare, 0x0000000000000000)
    to = get(SQUARES_TO_BITBOARDS, toSquare, 0x0000000000000000)
    move(from, to)
end

# returns index of bitBoards array that contains a bitsquare received as input
function getBitBoardsIndex(bitsquare::UInt64)
    if(bitsquare & getOccupancies() != 0b0)
    for i=1:12
        square = bitsquare & bitBoards[i]
        if(square != 0b0)
            return i
        end
    end
else
    return nothing
end
end