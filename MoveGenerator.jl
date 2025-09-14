include("Chess.jl")
include("MoveData.jl")

"""
File contenente ciò che riguarda la generazione di mosse
(tranne l'effetturare mosse con aggiornamento di hash Zobrist che si trova in Eval.jl)
"""

mutable struct Move
    source::UInt8
    target::UInt8
    moving_piece::UInt8
    promotion::UInt8
    enpassant::Bool
    castling::UInt8
    double_push::Bool
    capture::Bool
end

mutable struct MoveList
    moves::Vector{Move}
    amount::Int
end

# Riempie movelist con le catture pseudo-legali disponibili in una posizione.
# Queste catture devono essere filtrate per legalità.
# Nelle passate versioni tale sistema era utilizzato anche per le mosse standard.
function goCapturesPseudo(p::Position, move_list::MoveList)
    move_list.amount = 0

    if(p.turn == true)

        # mosse del re
        if(p.kings & p.white_occ != 0)
            index = trailing_zeros(p.kings & p.white_occ) + 1
            captures = getKingAttacks(index) & p.black_occ
            if(captures != 0)
                temp2 = captures
                    for i=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x06, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
            end
        end
        # mosse di regina
        if(p.queens & p.white_occ != 0)
            temp = p.queens & p.white_occ
            for i=1:count_ones(p.queens & p.white_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getQueenAttacks(p, index) & p.black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x05, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di alfiere
        if(p.bishops & p.white_occ != 0)
            temp = p.bishops & p.white_occ
            for i=1:count_ones(p.bishops & p.white_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getBishopAttacks(p, index) & p.black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x03, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di cavallo
        if(p.knights & p.white_occ != 0)
            temp = p.knights & p.white_occ
            for i=1:count_ones(p.knights & p.white_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getKnightAttacks(index) & p.black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x02, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di torre
        if(p.rooks & p.white_occ != 0)
            temp = p.rooks & p.white_occ
            for i=1:count_ones(p.rooks & p.white_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getRookAttacks(p, index) & p.black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x04, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di pedone
        if(p.pawns & p.white_occ != 0)
            temp = p.pawns & p.white_occ
            for i=1:count_ones(p.pawns & p.white_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                
                attacks = white_pawn_attacks(index) & p.black_occ
                last_rank_attacks = attacks & RANKS[8]
                normal_attacks = attacks & ~RANKS[8]

                enpassant = white_pawn_attacks(index) & p.enpassant

                    if(enpassant != 0)
                        index2 = trailing_zeros(enpassant) + 1
                        addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x00, true, 0x00, false, true)
                    end

                    if(last_rank_attacks != 0)
                    temp2 = last_rank_attacks
                        for j=1:count_ones(last_rank_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x02, false, 0x00, false, true)
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x03, false, 0x00, false, true)
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x04, false, 0x00, false, true) 
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x05, false, 0x00, false, true)
                        end
                    end
                    if(normal_attacks != 0)
                        temp2 = normal_attacks
                        for k=1:count_ones(normal_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x00, false, 0x00, false, true)
                        end
                    end
                temp &= ~least_bit
            end
        end
    else # turno del nero
        # mosse del re
        if(p.kings & p.black_occ != 0)
            index = trailing_zeros(p.kings & p.black_occ) + 1
            captures = getKingAttacks(index) & p.white_occ
            if(captures != 0)
                temp2 = captures
                    for i=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x06, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
            end
        end
        # mosse di regina
        if(p.queens & p.black_occ != 0)
            temp = p.queens & p.black_occ
            for i=1:count_ones(p.queens & p.black_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getQueenAttacks(p, index) & p.white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x05, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di alfiere
        if(p.bishops & p.black_occ != 0)
            temp = p.bishops & p.black_occ
            for i=1:count_ones(p.bishops & p.black_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getBishopAttacks(p, index) & p.white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x03, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di cavallo
        if(p.knights & p.black_occ != 0)
            temp = p.knights & p.black_occ
            for i=1:count_ones(p.knights & p.black_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getKnightAttacks(index) & p.white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x02, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di torre
        if(p.rooks & p.black_occ != 0)
            temp = p.rooks & p.black_occ
            for i=1:count_ones(p.rooks & p.black_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                captures = getRookAttacks(p, index) & p.white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    addMove(move_list, UInt8(index), UInt8(index2), 0x04, 0x00, false, 0x00, false, true)
                    temp2 &= ~least_bit2
                    end
                end
                temp &= ~least_bit
            end
        end

        # mosse di pedone
        if(p.pawns & p.black_occ != 0)
            temp = p.pawns & p.black_occ
            for i=1:count_ones(p.pawns & p.black_occ)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                
                attacks = black_pawn_attacks(index) & p.white_occ
                last_rank_attacks = attacks & RANKS[1]
                normal_attacks = attacks & ~RANKS[1]

                enpassant = black_pawn_attacks(index) & p.enpassant

                    if(enpassant != 0)
                        index2 = trailing_zeros(enpassant) + 1
                        addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x00, true, 0x00, false, true)
                    end

                    if(last_rank_attacks != 0)
                    temp2 = last_rank_attacks
                        for j=1:count_ones(last_rank_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x02, false, 0x00, false, true)
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x03, false, 0x00, false, true)
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x04, false, 0x00, false, true)
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x05, false, 0x00, false, true)
                        end
                    end
                    if(normal_attacks != 0)
                        temp2 = normal_attacks
                        for k=1:count_ones(normal_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            addMove(move_list, UInt8(index), UInt8(index2), 0x01, 0x00, false, 0x00, false, true)
                        end
                    end
                temp &= ~least_bit
            end
        end
    end
end

# Funzioni ausiliarie per accesso statico a bitboard dei pezzi
@inline function get_piece_board(p::Position, i::Int64)
    if i == 1
        return p.pawns
    elseif i == 2
        return p.knights
    elseif i == 3
        return p.bishops
    elseif i == 4
        return p.rooks
    elseif i == 5
        return p.queens
    else
        return p.kings
    end
end

@inline function set_piece_board!(p::Position, i::Int64, value::UInt64)
    if i == 1
        p.pawns = value
    elseif i == 2
        p.knights = value
    elseif i == 3
        p.bishops = value
    elseif i == 4
        p.rooks = value
    elseif i == 5
        p.queens = value
    else
        p.kings = value
    end
end

# esegue una mossa in una data posizione
function makeMove!(p::Position, move::Move)
    source_mask = UInt64(1) << (move.source - 1)
    target_mask = UInt64(1) << (move.target - 1)
    
    if move.capture # gestione catture
        if move.enpassant #enpassant
            if(p.turn == true)
            p.pawns &= ~(p.enpassant >> 8)
            p.black_occ &= ~(p.enpassant >> 8)
            else
            p.pawns &= ~(p.enpassant << 8)
            p.white_occ &= ~(p.enpassant << 8)
            end
        else # catture normali
            for i in 1:6
                board = get_piece_board(p, i)
                if (board & target_mask) != 0
                    set_piece_board!(p, i, board & ~target_mask)
                    break
                end
            end
            # aggiornamento occupazione avversaria
            if p.turn
                p.black_occ &= ~target_mask
            else
                p.white_occ &= ~target_mask
            end
        end
    end
    
    # spostamento del pezzo che muove
    piece_board = get_piece_board(p, Int64(move.moving_piece))
    set_piece_board!(p, Int64(move.moving_piece), (piece_board & ~source_mask) | target_mask)
    
    # aggiorna l'occupazione del colore attivo
    if p.turn
        p.white_occ = (p.white_occ & ~source_mask) | target_mask
    else
        p.black_occ = (p.black_occ & ~source_mask) | target_mask
    end

    # resetta la casa en passant precedente
    p.enpassant = 0
    
    # gestione promozione
    if move.promotion != 0
        p.pawns &= ~target_mask # rimuove il pedone che abbiamo spostato
        promoted_piece_board = get_piece_board(p, Int64(move.promotion))
        set_piece_board!(p, Int64(move.promotion), promoted_piece_board | target_mask) # aggiunge il pezzo promosso
    
    elseif move.castling != 0 # gestione arrocco
        # il re è già stato mosso, muoviamo la torre corrispondente.
        local rook_source_mask, rook_target_mask
        if move.castling == 1 # bianco, corto
            rook_source_mask = 0x0000000000000001 # h1
            rook_target_mask = 0x0000000000000004 # f1
        elseif move.castling == 2 # bianco, lungo
            rook_source_mask = 0x0000000000000080 # a1
            rook_target_mask = 0x0000000000000010 # d1
        elseif move.castling == 3 # nero, corto
            rook_source_mask = 0x0100000000000000 # h8
            rook_target_mask = 0x0400000000000000 # f8
        else # nero, lungo
            rook_source_mask = 0x8000000000000000 # a8
            rook_target_mask = 0x1000000000000000 # d8
        end
        # muove la torre e aggiorna l'occupazione del colore
        p.rooks = (p.rooks & ~rook_source_mask) | rook_target_mask
        if p.turn
            p.white_occ = (p.white_occ & ~rook_source_mask) | rook_target_mask
        else
            p.black_occ = (p.black_occ & ~rook_source_mask) | rook_target_mask
        end

    elseif move.double_push
        # imposta la casa per una possibile cattura en passant
        p.enpassant = (UInt64(1) << Int64((move.source + move.target) / 2 - 1))
    end
    
    # aggiornamento diritti arrocco
    if p.w_kingside && (move.source == 1 || move.source == 4) p.w_kingside = false end
    if p.w_queenside && (move.source == 8 || move.source == 4) p.w_queenside = false end
    if p.b_kingside && (move.source == 57 || move.source == 60) p.b_kingside = false end
    if p.b_queenside && (move.source == 64 || move.source == 60) p.b_queenside = false end

    if move.target == 1 p.w_kingside = false end
    if move.target == 8 p.w_queenside = false end
    if move.target == 57 p.b_kingside = false end
    if move.target == 64 p.b_queenside = false end
    
    # aggiornamento del turno
    p.turn = !p.turn
end

# funzione helper che aggiunge una mossa a una movelist
function addMove(move_list::MoveList, source::UInt8, target::UInt8, moving_piece::UInt8, promotion::UInt8, enpassant::Bool, castling::UInt8, double_push::Bool, capture::Bool)
    move_list.amount += 1
    move_list.moves[move_list.amount].source = source
    move_list.moves[move_list.amount].target = target
    move_list.moves[move_list.amount].moving_piece = moving_piece
    move_list.moves[move_list.amount].promotion = promotion
    move_list.moves[move_list.amount].enpassant = enpassant
    move_list.moves[move_list.amount].castling = castling
    move_list.moves[move_list.amount].double_push = double_push
    move_list.moves[move_list.amount].capture = capture
end

# funzione helper che aggiunge una mossa a una movelist
function addMove(move_list::MoveList, move::Move)
    move_list.amount += 1
    move_list.moves[move_list.amount].source = move.source
    move_list.moves[move_list.amount].target = move.target
    move_list.moves[move_list.amount].moving_piece = move.moving_piece
    move_list.moves[move_list.amount].promotion = move.promotion
    move_list.moves[move_list.amount].enpassant = move.enpassant
    move_list.moves[move_list.amount].castling = move.castling
    move_list.moves[move_list.amount].double_push = move.double_push
    move_list.moves[move_list.amount].capture = move.capture
end

# funzione che controlla se una casa è attaccata
function is_attacked(p::Position, square::Int64, by_white::Bool)::Bool
    if by_white
        if(getKnightAttacks(square) & p.knights & p.white_occ != 0)
            return true
        end
        if(getBishopAttacks(p, square) & (p.bishops | p.queens) & p.white_occ != 0)
            return true
        end
        if(getRookAttacks(p, square) & (p.rooks | p.queens) & p.white_occ != 0)
            return true
        end
        if(black_pawn_attacks(square) & p.pawns & p.white_occ != 0)
            return true
        end
        if(getKingAttacks(square) & p.kings & p.white_occ != 0)
            return true
        end
    else
        if(getKnightAttacks(square) & p.knights & p.black_occ != 0)
            return true
        end
        if(getBishopAttacks(p, square) & (p.bishops | p.queens) & p.black_occ != 0)
            return true
        end
        if(getRookAttacks(p, square) & (p.rooks | p.queens) & p.black_occ != 0)
            return true
        end
        if(white_pawn_attacks(square) & p.pawns & p.black_occ != 0)
            return true
        end
        if(getKingAttacks(square) & p.kings & p.black_occ != 0)
            return true
        end
    end
    return false
end

# funzione che controlla se in una posizione il re di un certo colore è sotto attacco
function is_king_attacked(p::Position, is_king_white::Bool)::Bool
    king = is_king_white ? trailing_zeros((p.kings & p.white_occ)) + 1 : trailing_zeros((p.kings & p.black_occ)) + 1
    return is_attacked(p, king, !is_king_white)
end

# funzione che controlla se c'è scacco nella posizione
function in_check(p::Position)::Bool
    square = trailing_zeros(p.kings & (p.turn ? p.white_occ : p.black_occ)) + 1
    return is_attacked(p, square, !p.turn)
end

# funzione helper che copia una posizione senza creare allocazioni
function copy_position!(dest::Position, src::Position)
    dest.pawns = src.pawns
    dest.knights = src.knights
    dest.bishops = src.bishops
    dest.rooks = src.rooks
    dest.queens = src.queens
    dest.kings = src.kings
    dest.black_occ = src.black_occ
    dest.white_occ = src.white_occ
    dest.enpassant = src.enpassant
    dest.turn = src.turn
    dest.w_kingside = src.w_kingside
    dest.w_queenside = src.w_queenside
    dest.b_kingside = src.b_kingside
    dest.b_queenside = src.b_queenside
end

# calcolo degli attacchi di torre da una casa grazie ai magic numbers
function getRookAttacks(p::Position, id::Int64)::UInt64
    occ = p.white_occ | p.black_occ
    relevant_occupancy = occ & ECO_ROOK_MASKS_BY_ID[id]
    magic_index = (relevant_occupancy * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id])
    return UInt64(ROOK_ATTACKS[id][magic_index + 1])
end

# calcolo degli attacchi di alfiere da una casa grazie ai magic numbers
function getBishopAttacks(p::Position, id)::UInt64
    occ = p.white_occ | p.black_occ
    relevant_occupancy = occ & ECO_BISHOP_MASKS_BY_ID[id]
    magic_index = (relevant_occupancy * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id])
    return BISHOP_ATTACKS[id][magic_index + 1]
end

# calcolo degli attacchi di regina da una casa grazie ai magic numbers
function getQueenAttacks(p::Position, id)::UInt64
    return getBishopAttacks(p, id) | getRookAttacks(p, id)
end

# Tutte queste altre funzioni calcolano gli attacchi dei pezzi rimanenti, consultando semplicemente tabelle precalcolate.
@inline
function getKingAttacks(id)::UInt64
    return KING_MASKS_BY_ID[id]
end

@inline
function getKnightAttacks(id)::UInt64
    return KNIGHT_MASKS_BY_ID[id]
end

@inline
function white_pawn_attacks(id)::UInt64
    return W_PAWN_ATTACKS_BY_ID[id]
end

@inline
function black_pawn_attacks(id)::UInt64
    return B_PAWN_ATTACKS_BY_ID[id]
end

# per riempire le tabelle degli attacchi delle torri in base all'occupazione dei pezzi
# è necessario prima generare gli attacchi in tutte le situazioni possibili al lancio.
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

# per riempire le tabelle degli attacchi degli alfieri in base all'occupazione dei pezzi
# è necessario prima generare gli attacchi in tutte le situazioni possibili al lancio.
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

function switchBit(bitboard::UInt64, id)::UInt64
    return xor(bitboard, (0x0000000000000001 << (id - 1)))
end

# genera occupazione lungo traverse e colonne per una casa
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

# genera occupazione lungo diagonali e anti-diagonali per una casa
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

# funzione che serve per riempire al lancio una grande tabella contenente tutti gli scenari per gli attacchi delle torri
function init_rook_attacks()
    rook_attacks = Vector{Vector{UInt64}}(undef, 64)
    for i=1:64
    bitsquare = occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << (i-1)
    occupancies = []
    attacks = []
    rl_bits = get(ROOK_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    used_attacks = Vector{UInt64}(undef, 2^rl_bits)
    occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << rl_bits
    for i=0:(occupancy_indicies-1)
        push!(occupancies, setBlockersRook(i, bitsquare))
        push!(attacks, rook_attacks_run(occupancies[i + 1], bitsquare))
    end

            magic_number = get(MAGIC_ROOK, bitsquare, nothing)
            
            index = 0
            while(index < occupancy_indicies)

                index += 1
                magic_index = Int((occupancies[index] * magic_number) >> (64 - rl_bits))

                    used_attacks[magic_index+1] = attacks[index]
            end
            rook_attacks[get(BITSQUARES_TO_ID, bitsquare, 0x0000000000000000)] = used_attacks
        end
        return rook_attacks
end

# funzione che serve per riempire al lancio una grande tabella contenente tutti gli scenari per gli attacchi degli alfieri
function init_bishop_attacks()
    bishop_attacks = Vector{Vector{UInt64}}(undef, 64)
    for i=1:64
    bitsquare = occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << (i-1)
    occupancies = []
    attacks = []
    rl_bits = get(BISHOP_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    used_attacks = Vector{UInt64}(undef, 2^rl_bits)
    occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << rl_bits
    for i=0:(occupancy_indicies-1)
        push!(occupancies, setBlockersBishop(i, bitsquare))
        push!(attacks, bishop_attacks_run(occupancies[i + 1], bitsquare))
    end

            magic_number = get(MAGIC_BISHOP, bitsquare, nothing)
            
            index = 0
            while(index < occupancy_indicies)

                index += 1
                magic_index = Int((occupancies[index] * magic_number) >> (64 - rl_bits))
                used_attacks[magic_index + 1] = attacks[index]
            end
            bishop_attacks[get(BITSQUARES_TO_ID, bitsquare, -1)] = used_attacks
        end
        return bishop_attacks
end

################################################################################################

# tabelle di attacchi per torri e alfieri: generazione al lancio
const ROOK_ATTACKS::Vector{Vector{UInt64}} = init_rook_attacks()
const BISHOP_ATTACKS::Vector{Vector{UInt64}} = init_bishop_attacks()


setStartingPosition(POSITION)
printBoard(POSITION)
MOVE_LIST = MoveList([Move(0,0,0,0,false,0,false,false) for _ in 1:256], 0)
MoveList() = MoveList([Move(0,0,0,0,false,0,false,false) for _ in 1:256], 0)
Position() = Position(UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), true, true, true, true, true)
COPY_POS = deepcopy(POSITION)

################################################################################################

const F1::UInt64 = RANKS[1] & FILES[6]
const G1::UInt64 = RANKS[1] & FILES[7]
const F1_G1::UInt64 = F1 | G1

const B1::UInt64 = RANKS[1] & FILES[2]
const C1::UInt64 = RANKS[1] & FILES[3]
const D1::UInt64 = RANKS[1] & FILES[4]
const C1_D1::UInt64 = C1 | D1
const B1_C1_D1::UInt64 = B1 | C1 | D1

const F8::UInt64 = RANKS[8] & FILES[6]
const G8::UInt64 = RANKS[8] & FILES[7]
const F8_G8::UInt64 = F8 | G8

const B8::UInt64 = RANKS[8] & FILES[2]
const C8::UInt64 = RANKS[8] & FILES[3]
const D8::UInt64 = RANKS[8] & FILES[4]
const C8_D8::UInt64 = C8 | D8
const B8_C8_D8::UInt64 = B8 | C8 | D8

const INDEX_G1::Int64 = trailing_zeros(G1) + 1
const INDEX_C1::Int64 = trailing_zeros(C1) + 1
const INDEX_C8::Int64 = trailing_zeros(C8) + 1
const INDEX_G8::Int64 = trailing_zeros(G8) + 1

@inline
function getRookAttacksByOcc(id::Int64, occ::UInt64)::UInt64
    relevant_occupancy = occ & ECO_ROOK_MASKS_BY_ID[id]
    magic_index = (relevant_occupancy * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id])
    return UInt64(ROOK_ATTACKS[id][magic_index + 1])
end

@inline
function getBishopAttacksByOcc(id::Int64, occ::UInt64)::UInt64
    relevant_occupancy = occ & ECO_BISHOP_MASKS_BY_ID[id]
    magic_index = (relevant_occupancy * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id])
    return BISHOP_ATTACKS[id][magic_index + 1]
end

@inline
function getQueenAttacksByOcc(id::Int64, occ::UInt64)::UInt64
    return getBishopAttacksByOcc(id, occ) | getRookAttacksByOcc(id, occ)
end

const RAY_TABLE::Array{UInt64} = Array{UInt64}(undef, 64, 64) # tabella contenente bitboards di raggi tra casa1 e casa2
const LINE_TABLE::Array{UInt64} = Array{UInt64}(undef, 64, 64) # tabella contenente linee di scacchiera tra casa1 e casa2 (intere traverse, colonne, diagonali o anti-diagonali)
# queste tabelle contengono bitboard vuota se le case non sono allineate in alcun modo

# costruzione delle tabelle RAY_TABLE e LINE_TABLE
function init_ray_table()
    for sq1 in 1:64
        for sq2 in 1:64
            RAY_TABLE[sq1, sq2] = UInt64(0)
            LINE_TABLE[sq1, sq2] = UInt64(0)
            
            if sq1 == sq2
                continue
            end
            
            line = UInt64(0)
            ray = UInt64(0)

            bishop_attacks1 = UInt64(0)
            bishop_attacks2 = UInt64(0)
            rook_attacks1 = UInt64(0)
            rook_attacks2 = UInt64(0)

            sq1_bb = UInt64(1) << (sq1 - 1)
            sq2_bb = UInt64(1) << (sq2 - 1)

            rank_sq1 = BITSQUARES_TO_COORDINATES[sq1_bb][1]
            file_sq1 = BITSQUARES_TO_COORDINATES[sq1_bb][2]
            rank_sq2 = BITSQUARES_TO_COORDINATES[sq2_bb][1]
            file_sq2 = BITSQUARES_TO_COORDINATES[sq2_bb][2]

            diag_sq1 = BITSQUARES_TO_DAD[sq1_bb][1]
            anti_diag_sq1 = BITSQUARES_TO_DAD[sq1_bb][2]
            diag_sq2 = BITSQUARES_TO_DAD[sq2_bb][1]
            anti_diag_sq2 = BITSQUARES_TO_DAD[sq2_bb][2]

            if rank_sq1 == rank_sq2
                line = RANKS[rank_sq1]
                rook_attacks1 = getRookAttacksByOcc(sq1, sq2_bb)
                rook_attacks2 = getRookAttacksByOcc(sq2, sq1_bb)
                ray = rook_attacks1 & rook_attacks2
            elseif file_sq1 == file_sq2
                line = FILES[file_sq1]
                rook_attacks1 = getRookAttacksByOcc(sq1, sq2_bb)
                rook_attacks2 = getRookAttacksByOcc(sq2, sq1_bb)
                ray = rook_attacks1 & rook_attacks2
            elseif diag_sq1 == diag_sq2
                line = DIAGONALS[diag_sq1]
                bishop_attacks1 = getBishopAttacksByOcc(sq1, sq2_bb)
                bishop_attacks2 = getBishopAttacksByOcc(sq2, sq1_bb)
                ray = bishop_attacks1 & bishop_attacks2
            elseif anti_diag_sq1 == anti_diag_sq2
                line = ANTI_DIAGONALS[anti_diag_sq1]
                bishop_attacks1 = getBishopAttacksByOcc(sq1, sq2_bb)
                bishop_attacks2 = getBishopAttacksByOcc(sq2, sq1_bb)
                ray = bishop_attacks1 & bishop_attacks2
            end

            if line != 0
                LINE_TABLE[sq1, sq2] = line
                RAY_TABLE[sq1, sq2] = ray
            end
        end
    end
end

# inizializzazione delle tabelle
init_ray_table()

const NOT_FIRST_FILE::UInt64 = ~FILES[1]
const NOT_LAST_FILE::UInt64 = ~FILES[8]

# nuova (e si spera performante) funzione che genera solo ed esclusivamente mosse legali
function generate_legal_moves(p::Position, move_list::MoveList)
    move_list.amount = 0 # poniamo a zero il counter delle mosse nella move_list

    occ = p.white_occ | p.black_occ # occupazione di tutti i pezzi sulla scacchiera
    empty = ~occ # case vuote
    ally_occ = p.turn ? p.white_occ : p.black_occ # occupazione dei pezzi alleati
    enemy_occ = occ & ~ally_occ # occupazione dei pezzi nemici
    enemyOrEmpty = ~ally_occ # case vuote o occupate dai nemici

    our_king_bb = p.kings & ally_occ # il re del colore corrente (bitboard)
    our_king_sq = trailing_zeros(our_king_bb) + 1 # indice casa del nostro re

    # calcoliamo la bitboard di attacchi dei nemici, la bitboard dei pezzi che danno scacco, e la bitboard dei pezzi inchiodati
    occ_for_attacks = occ & ~our_king_bb # bisogna togliere il re per calcolare attacchi nemici, perchè potrebbe coprire attacchi a raggi x
    enemy_attack_map = generate_enemy_attacks(p, enemy_occ, occ_for_attacks)
    safe_squares = ~enemy_attack_map
    checkers, pinned_pieces = calculate_checkers_and_pins(p, our_king_sq, ally_occ, enemy_occ, occ)

    # MOSSE DEL RE : si generano sempre, dividiamo tra catture e mosse quieti
    king_moves = getKingAttacks(our_king_sq) & enemyOrEmpty & safe_squares
    quiet_king_moves = king_moves & empty
    attack_king_moves = king_moves & enemy_occ
    while quiet_king_moves != 0
        target_sq = trailing_zeros(quiet_king_moves) + 1
        addMove(move_list, UInt8(our_king_sq), UInt8(target_sq), 0x06, 0x00, false, 0x00, false, false)
        quiet_king_moves &= quiet_king_moves - 1
    end
    while attack_king_moves != 0
        target_sq = trailing_zeros(attack_king_moves) + 1
        addMove(move_list, UInt8(our_king_sq), UInt8(target_sq), 0x06, 0x00, false, 0x00, false, true)
        attack_king_moves &= attack_king_moves - 1
    end

    # CUORE DELLA FUNZIONE: dividiamo in tre casi: scacco doppio (o più), scacco singolo, nessuno scacco
    check_count = count_ones(checkers) # numero di scacchi

    # CASO 1: scacco doppio (o più)
    if check_count > 1
        # sono legali solo le mosse del re quindi abbiamo finito
        return
        
    # CASO 2: scacco singolo
    elseif check_count == 1
        attacker_sq = trailing_zeros(checkers) + 1
        # la maschera delle mosse valide è catturare l'attaccante o bloccare il raggio, le mosse del re sono già state gestite
        check_mask = checkers | RAY_TABLE[our_king_sq, attacker_sq]
        
        movable_pieces = ally_occ & ~pinned_pieces & ~our_king_bb
        
        # generiamo le mosse di tutti i pezzi che si possono muovere, filtriamo con check_mask i movimenti
        generate_all_moves!(p, move_list, movable_pieces, check_mask, enemy_occ, occ, empty, enemyOrEmpty, our_king_bb)

    # CASO 3: nessuno scacco
    else # check_count == 0
        
        # PASSO 1: generiamo mosse di tutti i pezzi non inchiodati (filtro con maschera ~UInt64(0))
        unpinned_movers = ally_occ & ~pinned_pieces & ~our_king_bb
        generate_all_moves!(p, move_list, unpinned_movers, ~UInt64(0), enemy_occ, occ, empty, enemyOrEmpty, our_king_bb)
        
        # PASSO 2: generiamo mosse solo per i pezzi inchiodati.
        pinned_movers = pinned_pieces
        while pinned_movers != 0
            pinned_bb = leastSignificantBit(pinned_movers)
            pinned_sq = trailing_zeros(pinned_bb) + 1
            
            # il pezzo inchiodato si può muovere solo tra il re e il pezzo che inchioda, tuttavia possiamo filtrare con l'intera linea
            pin_mask = LINE_TABLE[our_king_sq, pinned_sq]
            
            # Generiamo le mosse solo per questo pezzo, ma filtrate dalla sua prigione.
            generate_all_moves!(p, move_list, pinned_bb, pin_mask, enemy_occ, occ, empty, enemyOrEmpty, our_king_bb)
            
            pinned_movers &= pinned_movers - 1
        end

        # PASSO 3: arrocchi, perchè non siamo sotto scacco quindi possono essere legali
        if p.turn # arrocchi bianco
            if ((p.w_kingside == true) && ((F1_G1 & empty & safe_squares) == F1_G1))
                addMove(move_list, UInt8(our_king_sq), UInt8(INDEX_G1), 0x06, 0x00, false, 0x01, false, false)
            end
            if ((p.w_queenside == true) && ((B1_C1_D1 & empty) == B1_C1_D1) && ((C1_D1 & safe_squares) == C1_D1))
                addMove(move_list, UInt8(our_king_sq), UInt8(INDEX_C1), 0x06, 0x00, false, 0x02, false, false)
            end
        else # arrocchi nero
            if ((p.b_kingside == true) && ((F8_G8 & empty & safe_squares) == F8_G8))
                addMove(move_list, UInt8(our_king_sq), UInt8(INDEX_G8), 0x06, 0x00, false, 0x03, false, false)
            end
            if ((p.b_queenside == true) && ((B8_C8_D8 & empty) == B8_C8_D8) && ((C8_D8 & safe_squares) == C8_D8))
                addMove(move_list, UInt8(our_king_sq), UInt8(INDEX_C8), 0x06, 0x00, false, 0x04, false, false)
            end
        end
    end
end

# funzione helper che genera una bitboard di case attaccate dall'esercito nemico
function generate_enemy_attacks(p::Position, enemy_occ::UInt64, occ::UInt64)::UInt64
    enemy_pawns = p.pawns & enemy_occ
    enemy_knights = p.knights & enemy_occ
    enemy_bishops = p.bishops & enemy_occ
    enemy_rooks = p.rooks & enemy_occ
    enemy_queens = p.queens & enemy_occ
    enemy_king = p.kings & enemy_occ
    enemy_attacks = UInt64(0)

    enemy_attacks |= KING_MASKS_BY_ID[(trailing_zeros(enemy_king) + 1)]

    not_file1_pawns = enemy_pawns & NOT_FIRST_FILE
    not_file8_pawns = enemy_pawns & NOT_LAST_FILE

    # dobbiamo differenziare tra attacchi pedonali neri e bianchi
    if p.turn # se il turno è del bianco guardiamo attacchi dei pedoni neri
        enemy_attacks |= (not_file1_pawns >> 7)
        enemy_attacks |= (not_file8_pawns >> 9)
    else # altrimenti dei bianchi
        enemy_attacks |= (not_file1_pawns << 9)
        enemy_attacks |= (not_file8_pawns << 7)
    end

    while (enemy_knights != 0)
        sq = trailing_zeros(enemy_knights) + 1
        enemy_attacks |= getKnightAttacks(sq)
        enemy_knights &= enemy_knights - 1
    end

    while (enemy_bishops != 0)
        sq = trailing_zeros(enemy_bishops) + 1
        enemy_attacks |= getBishopAttacksByOcc(sq, occ)
        enemy_bishops &= enemy_bishops - 1
    end

    while (enemy_rooks != 0)
        sq = trailing_zeros(enemy_rooks) + 1
        enemy_attacks |= getRookAttacksByOcc(sq, occ)
        enemy_rooks &= enemy_rooks - 1
    end

    while (enemy_queens != 0)
        sq = trailing_zeros(enemy_queens) + 1
        enemy_attacks |= getQueenAttacksByOcc(sq, occ)
        enemy_queens &= enemy_queens - 1
    end

    return enemy_attacks
end

# funzione che calcola maschere bitboard di pezzi inchiodati e di pezzi che danno scacco al re
function calculate_checkers_and_pins(p::Position, our_king_sq::Int64, us_occ::UInt64, them_occ::UInt64, all_occ::UInt64)::Tuple{UInt64, UInt64}
    checkers = UInt64(0)
    pinned_pieces = UInt64(0)
    
    them_rooks_queens = (p.rooks | p.queens) & them_occ
    them_bishops_queens = (p.bishops | p.queens) & them_occ
    
    # Caso orizzontale e verticale
    potential_hv_attackers = ROOK_MASKS_BY_ID[our_king_sq] & them_rooks_queens
    while potential_hv_attackers != 0
        attacker_sq = trailing_zeros(potential_hv_attackers) + 1
        attacker_bb = UInt64(1) << (attacker_sq - 1)
        intervening = RAY_TABLE[our_king_sq, attacker_sq] & all_occ
        count_of_pieces_on_ray = count_ones(intervening)
        if count_of_pieces_on_ray == 0
            checkers |= attacker_bb
        elseif count_of_pieces_on_ray == 1 && (intervening & us_occ) != 0
            pinned_pieces |= intervening
        end
        potential_hv_attackers &= potential_hv_attackers - 1
    end
    
    # Caso diagonale
    potential_d12_attackers = BISHOP_MASKS_BY_ID[our_king_sq] & them_bishops_queens
    while potential_d12_attackers != 0
        attacker_sq = trailing_zeros(potential_d12_attackers) + 1
        attacker_bb = UInt64(1) << (attacker_sq - 1)
        intervening = RAY_TABLE[our_king_sq, attacker_sq] & all_occ
        count_of_pieces_on_ray = count_ones(intervening)
        if count_of_pieces_on_ray == 0
            checkers |= attacker_bb
        elseif count_of_pieces_on_ray == 1 && (intervening & us_occ) != 0
            pinned_pieces |= intervening
        end
        potential_d12_attackers &= potential_d12_attackers - 1
    end
    
    # scacchi diretti
    checkers |= getKnightAttacks(our_king_sq) & (p.knights & them_occ)
    pawn_attack_func = p.turn ? white_pawn_attacks : black_pawn_attacks
    checkers |= pawn_attack_func(our_king_sq) & (p.pawns & them_occ)
    
    return (checkers, pinned_pieces)
end

const FIRST_RANK::UInt64 = RANKS[1]
const SECOND_RANK::UInt64 = RANKS[2]
const FOURTH_RANK::UInt64 = RANKS[4]
const FIFTH_RANK::UInt64 = RANKS[5]
const SEVENTH_RANK::UInt64 = RANKS[7]
const EIGHT_RANK::UInt64 = RANKS[8]

# generiamo tutte le mosse di "movers" filtrate con "move_mask": non gestiamo mosse del re e arrocchi
function generate_all_moves!(p::Position, move_list::MoveList, movers::UInt64, move_mask::UInt64, enemy_occ::UInt64, all_occ::UInt64, empty::UInt64, enemyOrEmpty::UInt64, our_king_bb::UInt64)
    # --- TORRI ---
    our_rooks = p.rooks & movers
    while our_rooks != 0
        from_sq = trailing_zeros(our_rooks) + 1
        
        attacks = getRookAttacksByOcc(from_sq, all_occ)
        legal_targets = attacks & enemyOrEmpty & move_mask
        
        captures = legal_targets & enemy_occ
        quiet_moves = legal_targets & empty
        
        while captures != 0
            to_sq = trailing_zeros(captures) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x04, 0x00, false, 0x00, false, true)
            captures &= captures - 1
        end
        while quiet_moves != 0
            to_sq = trailing_zeros(quiet_moves) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x04, 0x00, false, 0x00, false, false)
            quiet_moves &= quiet_moves - 1
        end
        our_rooks &= our_rooks - 1
    end

    # --- ALFIERI ---
    our_bishops = p.bishops & movers
    while our_bishops != 0
        from_sq = trailing_zeros(our_bishops) + 1
        
        attacks = getBishopAttacksByOcc(from_sq, all_occ)
        legal_targets = attacks & enemyOrEmpty & move_mask
        
        captures = legal_targets & enemy_occ
        quiet_moves = legal_targets & empty
        
        while captures != 0
            to_sq = trailing_zeros(captures) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x03, 0x00, false, 0x00, false, true)
            captures &= captures - 1
        end
        while quiet_moves != 0
            to_sq = trailing_zeros(quiet_moves) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x03, 0x00, false, 0x00, false, false)
            quiet_moves &= quiet_moves - 1
        end
        our_bishops &= our_bishops - 1
    end

    # --- REGINE ---
    our_queens = p.queens & movers
    while our_queens != 0
        from_sq = trailing_zeros(our_queens) + 1
        
        attacks = getQueenAttacksByOcc(from_sq, all_occ)
        legal_targets = attacks & enemyOrEmpty & move_mask
        
        captures = legal_targets & enemy_occ
        quiet_moves = legal_targets & empty
        
        while captures != 0
            to_sq = trailing_zeros(captures) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x05, 0x00, false, 0x00, false, true)
            captures &= captures - 1
        end
        while quiet_moves != 0
            to_sq = trailing_zeros(quiet_moves) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x05, 0x00, false, 0x00, false, false)
            quiet_moves &= quiet_moves - 1
        end
        our_queens &= our_queens - 1
    end

    # --- CAVALLI ---
    our_knights = p.knights & movers
    while our_knights != 0
        from_sq = trailing_zeros(our_knights) + 1
        
        attacks = getKnightAttacks(from_sq)
        legal_targets = attacks & enemyOrEmpty & move_mask
        
        captures = legal_targets & enemy_occ
        quiet_moves = legal_targets & empty
        
        while captures != 0
            to_sq = trailing_zeros(captures) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x02, 0x00, false, 0x00, false, true)
            captures &= captures - 1
        end
        while quiet_moves != 0
            to_sq = trailing_zeros(quiet_moves) + 1
            addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x02, 0x00, false, 0x00, false, false)
            quiet_moves &= quiet_moves - 1
        end
        our_knights &= our_knights - 1
    end

    # --- PEDONI ---
    our_pawns = p.pawns & movers
    if p.turn # pedoni bianchi
        single_pushes = (our_pawns << 8) & empty & move_mask
        double_pushes = ((our_pawns & SECOND_RANK) << 16) & empty & move_mask & (((our_pawns << 8) & empty) << 8)
        
        pawns_to_move = our_pawns
        # iteriamo sui pedoni
        while pawns_to_move != 0
            from_sq_bb = leastSignificantBit(pawns_to_move)
            from_sq = trailing_zeros(from_sq_bb) + 1
            
            # catture di pedone
            attacks = white_pawn_attacks(from_sq)
            legal_captures = attacks & enemy_occ & move_mask
            while legal_captures != 0
                to_sq_bb = leastSignificantBit(legal_captures)
                to_sq = trailing_zeros(to_sq_bb) + 1
                
                if (to_sq_bb & EIGHT_RANK) != 0 # catture con promozione
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x05, false, 0x00, false, true) # Regina
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x04, false, 0x00, false, true) # Torre
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x03, false, 0x00, false, true) # Alfiere
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x02, false, 0x00, false, true) # Cavallo
                else # catture normali
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, false, true)
                end
                legal_captures &= legal_captures - 1
            end

            # spinta singola di pedone
            if ((from_sq_bb << 8) & single_pushes) != 0
                to_sq = from_sq + 8
                if ((UInt64(1) << (to_sq - 1)) & EIGHT_RANK) != 0 # spinta con promozione
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x05, false, 0x00, false, false) # Regina
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x04, false, 0x00, false, false) # Torre
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x03, false, 0x00, false, false) # Alfiere
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x02, false, 0x00, false, false) # Cavallo
                else # spinta singola normale
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, false, false)
                end
            end
            if ((from_sq_bb << 16) & double_pushes) != 0
                to_sq = from_sq + 16
                addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, true, false)
            end

            # en passant
            if p.enpassant != 0
                ep_capture = attacks & p.enpassant
                if ep_capture != 0
                en_passant_check = move_mask == (ep_capture >> 8)
                if en_passant_check || ((ep_capture & move_mask) != 0)
                    is_legal = true # assumiamo la mossa legale per ora
                    to_sq = trailing_zeros(ep_capture) + 1
        
                    # controllo apposito per inchiodatura speciale en-passant
                    captured_pawn_sq = to_sq - 8
        
                    # se il nostro re è sulla quinta traversa (quella dell'enpassant per il bianco)
                    if our_king_bb & FIFTH_RANK != 0
            
                    # rimuoviamo entrambi i pedoni per vedere se si scopre uno scacco
                    occ_without_pawns = all_occ & ~from_sq_bb & ~(UInt64(1) << (captured_pawn_sq - 1))
            
                    # ci sono torri o regine nemiche sulla stessa traversa?
                    enemy_rooks_queens = (p.rooks | p.queens) & enemy_occ & FIFTH_RANK
                        if enemy_rooks_queens != 0
                        # controlliamo se una di queste dà scacco al re sulla scacchiera fittizia
                        rook_attacks_on_king = getRookAttacksByOcc(trailing_zeros(our_king_bb) + 1, occ_without_pawns)
                            if (rook_attacks_on_king & enemy_rooks_queens) != 0
                                is_legal = false
                            end
                        end
                    end

                    if is_legal
                        addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, true, 0x00, false, true)
                    end
                end
                end
            end
            
            pawns_to_move &= pawns_to_move - 1
        end
    else # pedoni neri
        single_pushes = (our_pawns >> 8) & empty & move_mask
        double_pushes = ((our_pawns & SEVENTH_RANK) >> 16) & empty & move_mask & (((our_pawns >> 8) & empty) >> 8)
        
        pawns_to_move = our_pawns
        while pawns_to_move != 0
            from_sq_bb = leastSignificantBit(pawns_to_move)
            from_sq = trailing_zeros(from_sq_bb) + 1
            
            # catture
            attacks = black_pawn_attacks(from_sq)
            legal_captures = attacks & move_mask & enemy_occ
            
            while legal_captures != 0
                to_sq_bb = leastSignificantBit(legal_captures)
                to_sq = trailing_zeros(to_sq_bb) + 1
                
                if (to_sq_bb & FIRST_RANK) != 0 # catture con promozione
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x05, false, 0x00, false, true) # Regina
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x04, false, 0x00, false, true) # Torre
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x03, false, 0x00, false, true) # Alfiere
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x02, false, 0x00, false, true) # Cavallo
                else # catture normali
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, false, true)
                end
                legal_captures &= legal_captures - 1
            end

            # spinta singola di pedone
            if ((from_sq_bb >> 8) & single_pushes) != 0
                to_sq = from_sq - 8
                if ((UInt64(1) << (to_sq - 1)) & FIRST_RANK) != 0 # spinta con promozione
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x05, false, 0x00, false, false) # Regina
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x04, false, 0x00, false, false) # Torre
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x03, false, 0x00, false, false) # Alfiere
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x02, false, 0x00, false, false) # Cavallo
                else # spinta singola normale
                    addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, false, false)
                end
            end
            if ((from_sq_bb >> 16) & double_pushes) != 0
                to_sq = from_sq - 16
                addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, false, 0x00, true, false)
            end
            
            # en passant
            if p.enpassant != 0
                ep_capture = attacks & p.enpassant
                if ep_capture != 0
                en_passant_check = move_mask == (ep_capture << 8)
                if en_passant_check || ((ep_capture & move_mask) != 0)
                    is_legal = true
                    to_sq = trailing_zeros(ep_capture) + 1
        
                    captured_pawn_sq = to_sq + 8
        
                    if (our_king_bb & FOURTH_RANK) != 0
                        occ_without_pawns = all_occ & ~from_sq_bb & ~(UInt64(1) << (captured_pawn_sq - 1))
                        enemy_rooks_queens = (p.rooks | p.queens) & enemy_occ & FOURTH_RANK
                        if enemy_rooks_queens != 0
                            our_king_sq = trailing_zeros(our_king_bb) + 1
                            rook_attacks_on_king = getRookAttacksByOcc(our_king_sq, occ_without_pawns)
                            if (rook_attacks_on_king & enemy_rooks_queens) != 0
                            is_legal = false
                            end
                        end
                    end

                    if is_legal
                        addMove(move_list, UInt8(from_sq), UInt8(to_sq), 0x01, 0x00, true, 0x00, false, true)
                    end
                end
                end
            end
            pawns_to_move &= pawns_to_move - 1
        end
    end
end


