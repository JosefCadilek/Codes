include("Chess.jl")
include("MoveData.jl")

MOVES = []

rook_final = Dict()

"""
Legal move generator step by step

Chess Rules:
documantion about the rules of chess are taken from FIDE: https://handbook.fide.com/chapter/E012023 
"""


# main function that generates and formats list of legal moves
# TODO: everything
function generateMoves()
    moves = []
    if(getTurnGameState() == WHITE)
        enemyOrEmpty = ~getWhiteOccupancies()
        occ = getWhiteOccupancies()
        while(occ != 0b0)
            piece = leastSignificantBit(occ)
            index = getBitBoardsIndex(piece)
            if(index == 1)
                push!(moves, (piece , get(KING_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 2)
                push!(moves, (piece , get(QUEEN_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index ==3)
                push!(moves, (piece , get(BISHOP_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 4)
                push!(moves, (piece , get(KNIGHT_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 5)
                push!(moves, (piece , get(ROOK_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index==6)
                push!(moves, (piece , get(W_PAWN_ATTACKS, piece, nothing) & getBlackOccupancies()))
            end
            occ &= ~piece
        end
    else # Black move generator
        enemyOrEmpty = ~getBlackOccupancies()
        occ = getBlackOccupancies()
        while(occ != 0b0)
            piece = leastSignificantBit(occ)
            index = getBitBoardsIndex(piece)
            if(index == 7)
                push!(moves, (piece , get(KING_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 8)
                push!(moves, (piece , get(QUEEN_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 9)
                push!(moves, (piece , get(BISHOP_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 10)
                push!(moves, (piece , get(KNIGHT_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index == 11)
                push!(moves, (piece , get(ROOK_MASKS, piece, nothing) & enemyOrEmpty))
            elseif(index== 12)
                push!(moves, (piece , get(B_PAWN_ATTACKS, piece, nothing) & getWhiteOccupancies()))
            end
            occ &= ~piece
        end
    end
    moves
end


# returns white pawns pseudo forward moves, only possibility for it being illegal is that it causes the check of the king.
# Enpassant, captures and general PROMOTION is handled elsewhere
function w_pawns_forward()
    empty = ~getOccupancies()
    return (getWhitePawns() << 8 & ~RANKS[8] & empty) | (getWhitePawns() << 16 & empty & RANKS[4] & (empty << 8))
end

# returns black pawns pseudo forward moves, only possibility for it being illegal is that it causes the check of the king.
# Enpassant, captures and promotion is handled elsewhere
function b_pawns_forward()
    empty = ~getOccupancies()
    return (getBlackPawns() >> 8 & ~RANKS[1] & empty) | (getBlackPawns() >> 16 & empty & RANKS[5] & (empty >> 8))
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

# Only one-time use function. It has served for generating data, in particular the relevant bits for sliding pieces.
# TODO: remove function when no needed
function initECORook()
    array = []
    result = 0
    for i=1:64
        cleanBitBoards()
        bitBoards[5] = setBitOn(getWhiteRooks(), i)
        result = rook_mask(getWhiteRooks())
        if(get(BITSQUARES_TO_COORDINATES, getWhiteRooks(), nothing)[2] != 1)
            result &= ~FILES[1]
        end
            if(get(BITSQUARES_TO_COORDINATES, getWhiteRooks(), nothing)[2] != 8)
                result &= ~FILES[8]
            end
                if(get(BITSQUARES_TO_COORDINATES, getWhiteRooks(), nothing)[1] != 1)
                    result &= ~RANKS[1]
                end
                    if(get(BITSQUARES_TO_COORDINATES, getWhiteRooks(), nothing)[1] != 8)
                        result &= ~RANKS[8]
                    end
                    println("0b" * bitstring(getWhiteRooks()) * " => 0b" * bitstring(result) * ",")
    end
end

    # Only one-time use function. It has served for generating data, in particular the relevant bits for sliding pieces.
    function initECOBishop()
        array = []
        result = 0
        for i=1:64
            cleanBitBoards()
            bitBoards[3] = setBitOn(getWhiteBishops(), i)
            result = bishop_mask(getWhiteBishops())
            if(get(BITSQUARES_TO_COORDINATES, getWhiteBishops(), nothing)[2] != 1)
                result &= ~FILES[1]
            end
                if(get(BITSQUARES_TO_COORDINATES, getWhiteBishops(), nothing)[2] != 8)
                    result &= ~FILES[8]
                end
                    if(get(BITSQUARES_TO_COORDINATES, getWhiteBishops(), nothing)[1] != 1)
                        result &= ~RANKS[1]
                    end
                        if(get(BITSQUARES_TO_COORDINATES, getWhiteBishops(), nothing)[1] != 8)
                            result &= ~RANKS[8]
                        end
                    println("0b" * bitstring(getWhiteBishops()) * " => 0b" * bitstring(result) * ",")
        end
        end


# generate valid rook attacks during runtime
function rook_attacks_run(occupancy::UInt64, bitsquare::UInt64)
    attack = 0x0000000000000000
    coordinates = get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)
    rank = coordinates[1]
    file = coordinates[2]
    relevant_occupancy = occupancy & get(ECO_ROOK_MASKS, bitsquare, nothing)
    target_n = rank + 1
    target_s = rank - 1
    target_e = file + 1
    target_w = file - 1
    loop = true
    while (target_n <= 8 && loop)
        target_square = RANKS[target_n] & FILES[file]
        target_n += 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    loop = true
    while (target_s >= 1 && loop)
        target_square = RANKS[target_s] & FILES[file]
        target_s -= 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    loop = true
    while (target_e <= 8 && loop)
        target_square = RANKS[rank] & FILES[target_e]
        target_e += 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    loop = true
    while (target_w >= 1 && loop)
        target_square = RANKS[rank] & FILES[target_w]
        target_w -= 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    return attack
end

# generate valid bishop attacks during runtime
function bishop_attacks_run(occupancy::UInt64, bitsquare::UInt64)
    attack = 0x0000000000000000
    coordinates = get(BITSQUARES_TO_COORDINATES, bitsquare, nothing)
    rank = coordinates[1]
    file = coordinates[2]
    relevant_occupancy = occupancy & get(ECO_BISHOP_MASKS, bitsquare, nothing)
    target_n = rank + 1
    target_s = rank - 1
    target_e = file + 1
    target_w = file - 1
    loop = true
    while (target_w >= 1 && target_n <= 8 && loop)
        target_square = RANKS[target_n] & FILES[target_w]
        target_n += 1
        target_w -= 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    target_n = rank + 1
    target_e = file + 1
    loop = true
    while (target_e <= 8 && target_n <= 8 && loop)
        target_square = RANKS[target_n] & FILES[target_e]
        target_n += 1
        target_e += 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    target_s = rank - 1
    target_e = file + 1
    loop = true
    while (target_e <= 8 && target_s >= 1 && loop)
        target_square = RANKS[target_s] & FILES[target_e]
        target_s -= 1
        target_e += 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    target_s = rank - 1
    target_w = file - 1
    loop = true
    while (target_w >= 1 && target_s >= 1 && loop)
        target_square = RANKS[target_s] & FILES[target_w]
        target_s -= 1
        target_w -= 1
        attack |= target_square
        if((relevant_occupancy & target_square) != 0b0)
            loop = false
        end
    end
    return attack
end


# set blockers for rook
function setBlockersRook(index, bitsquare::UInt64)::UInt64
    occupancy = 0b0000000000000000000000000000000000000000000000000000000000000000
    attack_mask = get(ECO_ROOK_MASKS, bitsquare, nothing)
    ID = leastSignificantBit(attack_mask)
    rl_bits = get(ROOK_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    for i=0:rl_bits
        square = leastSignificantBit(attack_mask)
        id = ID
        if(square != 0b0)
        id = get(BITSQUARES_TO_ID, square, nothing)
        end
        attack_mask = switchBit(attack_mask, id)
        if(((index) & (0b0000000000000000000000000000000000000000000000000000000000000001 << i)) != 0b0000000000000000000000000000000000000000000000000000000000000000)
            occupancy |= square
        end
    end
    return occupancy
end

# set blockers for rook
function setBlockersBishop(index, bitsquare::UInt64)::UInt64
    occupancy = 0b0000000000000000000000000000000000000000000000000000000000000000
    attack_mask = get(ECO_BISHOP_MASKS, bitsquare, nothing)
    ID = leastSignificantBit(attack_mask)
    rl_bits = get(BISHOP_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    for i=0:rl_bits
        square = leastSignificantBit(attack_mask)
        id = ID
        if(square != 0b0)
        id = get(BITSQUARES_TO_ID, square, nothing)
        end
        attack_mask = switchBit(attack_mask, id)
        if(((index) & (0b0000000000000000000000000000000000000000000000000000000000000001 << i)) != 0b0000000000000000000000000000000000000000000000000000000000000000)
            occupancy |= square
        end
    end
    return occupancy
end

function random_uint64()::UInt64
  u1::UInt64 = rand(UInt64) & 0xFFFF
  u2::UInt64 = rand(UInt64) & 0xFFFF
  u3::UInt64 = rand(UInt64) & 0xFFFF
  u4::UInt64 = rand(UInt64) & 0xFFFF
  return u1 | (u2 << 16) | (u3 << 32) | (u4 << 48)
end

function random_uint64_fewbits()::UInt64
  return random_uint64() & random_uint64() & random_uint64()
end


function magic_rooks(bitsquare::UInt64)
    fail = false
    occupancies = []
    attacks = []
    used_attacks = Dict()
    attack_mask = get(ECO_ROOK_MASKS, bitsquare, nothing)
    rl_bits = get(ROOK_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << rl_bits
    for i=0:(occupancy_indicies-1)
        push!(occupancies, setBlockersRook(i, bitsquare))
        push!(attacks, rook_attacks_run(occupancies[i + 1], bitsquare))
    end

    for count=1:10000000
            magic_number = random_uint64_fewbits()
            
            if (count_ones((attack_mask * magic_number) & 0xFF00000000000000) < 6) 
                continue
            end
            
            fail = false
            index = 0
            while(!fail && index < occupancy_indicies)

                index += 1
                magic_index = (occupancies[index] * magic_number) >> (64 - rl_bits)
                
                if (get(used_attacks, magic_index, nothing) === nothing)

                    used_attacks[magic_index] = attacks[index]

                elseif(get(used_attacks, magic_index, nothing) != attacks[index])
                    fail = true
                    used_attacks = Dict()
                end
            end
            if (!fail)
                println("vittoria")
                return magic_number
            end
        end
        return "---"
end

"""
Game runs from here right now: sort of MAIN
"""

###################################################MAIN################################################################
#for i=1:64
cleanBitBoards()
bitBoards[5] = setBitOn(getWhiteRooks(), 1)
magically = magic_rooks(getWhiteRooks())
println(magically)
#end
#magic, attacks = magic_rooks(getWhiteRooks())
#result = (occ * magic) >> (64 - 12)
#printBitBoard(attacks[result])
#########################################################################################################################