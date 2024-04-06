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
    else # Black move generator
    end
    return moves
end


# returns white pawns pseudo forward moves, only possibility for it being illegal is that it causes the check of the king.
# Enpassant, captures and general PROMOTION is handled elsewhere
function w_pawns_forward()
    empty = ~getOccupancies()
    return (getWhitePawns() << 8 & ~RANKS[8] & empty) | (getWhitePawns() << 16 & empty & RANKS[4] & ((empty & RANKS[3]) << 8))
end

# returns black pawns pseudo forward moves, only possibility for it being illegal is that it causes the check of the king.
# Enpassant, captures and promotion is handled elsewhere
function b_pawns_forward()
    empty = ~getOccupancies()
    return (getBlackPawns() >> 8 & ~RANKS[1] & empty) | (getBlackPawns() >> 16 & empty & RANKS[5] & ((empty & RANKS[6]) >> 8))
end

# Knight MOVEMENT ONLY mask: knight mask is special as it is also a SeenByKnightMap (an enemy king cannot move to these squares)
function knight_mask(bitsquare::UInt64)
    mask = bitsquare << 10 | bitsquare << 17 | bitsquare << 6 | bitsquare << 15 | bitsquare >> 10 | bitsquare >> 17 | bitsquare >> 6 | bitsquare >> 15
    if(get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 1 || get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 2)
    mask = mask & ~FILES[8] & ~FILES[7]
    end
    if(get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 7 || get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 8)
        mask = mask & ~FILES[1] & ~FILES[2]
    end
    return mask
end

# Rook MOVEMENT ONLY mask
function rook_mask(bitsquare::UInt64)
    rank = get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[1]
    file = get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2]
    return xor(RANKS[rank], FILES[file])
end

# Bishop MOVEMENT ONLY mask
function bishop_mask(bitsquare::UInt64)
    diagonal = get(BITSQUARES_TO_DAD, bitsquare, nothing)[1]
    anti_diagonal = get(BITSQUARES_TO_DAD, bitsquare, nothing)[2]
    return xor(DIAGONALS[diagonal], ANTI_DIAGONALS[anti_diagonal])
end

# King MOVEMENT ONLY mask
function king_mask(bitsquare::UInt64)
    mask = bitsquare << 9 | bitsquare << 8 | bitsquare << 7 | bitsquare >> 1 | bitsquare >> 9 | bitsquare >> 8 | bitsquare >> 7 | bitsquare << 1
    if(get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 1)
    mask = mask & ~FILES[8]
    end
    if(get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)[2] == 8)
        mask = mask & ~FILES[1]
    end
    return mask
end

# Queen MOVEMENT ONLY mask
function queen_mask(bitsquare::UInt64)
    return xor(bishop_mask(bitsquare), rook_mask(bitsquare))
end

# White Pawn attack mask
function w_pawn_attack(bitsquare::UInt64)
    right_attack = bitsquare << 7
    left_attack = bitsquare << 9
    return (right_attack & ~FILES[1] & ~RANKS[8]) | (left_attack & ~FILES[8] & ~RANKS[8])
end

# Black Pawn attack mask
function b_pawn_attack(bitsquare::UInt64)
    right_attack = bitsquare >> 7
    left_attack = bitsquare >> 9
    return (right_attack & ~FILES[8] & ~RANKS[1]) | (left_attack & ~FILES[1] & ~RANKS[1])
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


"""
Game runs from here right now: sort of MAIN
"""

###################################################MAIN################################################################
setStartingPosition()
printBoard()
printState()
#########################################################################################################################