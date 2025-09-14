include("Test.jl")

"""
File contenente tutto ciò che riguarda la ricerca e la valutazione
"""

using Random
using StaticArrays


"""
La prima parte riguarda l'hashing di Zobrist per rilevare la tripla ripetizione durante la ricerca
"""
const ZOBRIST_PIECES::Array{UInt64} = Array{UInt64}(undef, 12, 64)
const ZOBRIST_CASTLING::Array{UInt64} = Array{UInt64}(undef, 16)
const ZOBRIST_ENPASSANT::Array{UInt64} = Array{UInt64}(undef, 8)
const ZOBRIST_TURN::UInt64 = rand(UInt64)

function init_zobrist!()
    rng = MersenneTwister(123456)
    for i in 1:12, sq in 1:64
        ZOBRIST_PIECES[i, sq] = rand(rng, UInt64)
    end
    for i in 1:16
        ZOBRIST_CASTLING[i] = rand(rng, UInt64)
    end
    for i in 1:8
        ZOBRIST_ENPASSANT[i] = rand(rng, UInt64)
    end
end

init_zobrist!()

@inline function file_of(bb::UInt64)::Int
    sq_minus1 = trailing_zeros(bb)
    mod8 = sq_minus1 % 8
    return 8 - mod8
end

# funzione che genera la chiave di Zobrist
function compute_zobrist_key(pos::Position)
    key::UInt64 = 0

    function add_piece(bb::UInt64, idx::Int)
        while bb != 0
            sq = trailing_zeros(bb) + 1
            key ⊻= ZOBRIST_PIECES[idx, sq]
            bb &= bb - 1
        end
    end

    # bianchi
    add_piece(pos.pawns & pos.white_occ, 1)
    add_piece(pos.knights & pos.white_occ, 2)
    add_piece(pos.bishops & pos.white_occ, 3)
    add_piece(pos.rooks & pos.white_occ, 4)
    add_piece(pos.queens & pos.white_occ, 5)
    add_piece(pos.kings & pos.white_occ, 6)

    # neri
    add_piece(pos.pawns & pos.black_occ, 7)
    add_piece(pos.knights & pos.black_occ, 8)
    add_piece(pos.bishops & pos.black_occ, 9)
    add_piece(pos.rooks & pos.black_occ, 10)
    add_piece(pos.queens & pos.black_occ, 11)
    add_piece(pos.kings & pos.black_occ, 12)

    # arrocco
    castle_index = (pos.w_kingside ? 1 : 0) |
                   (pos.w_queenside ? 2 : 0) |
                   (pos.b_kingside ? 4 : 0) |
                   (pos.b_queenside ? 8 : 0)
    key ⊻= ZOBRIST_CASTLING[castle_index + 1]

    # en passant
    if pos.enpassant != 0
        key ⊻= ZOBRIST_ENPASSANT[file_of(pos.enpassant)]
    end

    # turno
    if !pos.turn
        key ⊻= ZOBRIST_TURN
    end

    return key
end

# funzione che esegue una mossa e aggiorna l'hash
function makeMove_and_updateHash!(p::Position, move::Move, current_key::UInt64)
    new_key = current_key
    source_mask = UInt64(1) << (move.source - 1)
    target_mask = UInt64(1) << (move.target - 1)

    # rimuove il pezzo che muove dalla casa di partenza
    piece_index = p.turn ? move.moving_piece : (move.moving_piece + 6)
    new_key ⊻= ZOBRIST_PIECES[piece_index, move.source]

    # gestione catture
    if move.capture
        if move.enpassant
            # pedone rimosso en passant
            if p.turn
                cap_sq = trailing_zeros(p.enpassant >> 8) + 1
                new_key ⊻= ZOBRIST_PIECES[1 + 6, cap_sq] # pedone nero
                p.pawns &= ~(p.enpassant >> 8)
                p.black_occ &= ~(p.enpassant >> 8)
            else
                cap_sq = trailing_zeros(p.enpassant << 8) + 1
                new_key ⊻= ZOBRIST_PIECES[1, cap_sq] # pedone bianco
                p.pawns &= ~(p.enpassant << 8)
                p.white_occ &= ~(p.enpassant << 8)
            end
        else
            # cattura normale
            for i in 1:6
                board = get_piece_board(p, i)
                if (board & target_mask) != 0
                    set_piece_board!(p, i, board & ~target_mask)
                    victim_idx = if p.turn
                        i + 6 # cattura pezzo nero
                    else
                        i     # cattura pezzo bianco
                    end
                    new_key ⊻= ZOBRIST_PIECES[victim_idx, move.target]
                    break
                end
            end
            if p.turn
                p.black_occ &= ~target_mask
            else
                p.white_occ &= ~target_mask
            end
        end
    end

    # sposta il pezzo che muove
    piece_board = get_piece_board(p, Int64(move.moving_piece))
    set_piece_board!(p, Int64(move.moving_piece), (piece_board & ~source_mask) | target_mask)

    # aggiunge il pezzo mosso nella nuova casa
    new_key ⊻= ZOBRIST_PIECES[piece_index, move.target]

    # Aggiorna occupazione
    if p.turn
        p.white_occ = (p.white_occ & ~source_mask) | target_mask
    else
        p.black_occ = (p.black_occ & ~source_mask) | target_mask
    end

    # rimuove la vecchia en passant
    if p.enpassant != 0
        new_key ⊻= ZOBRIST_ENPASSANT[file_of(p.enpassant)]
        p.enpassant = 0
    end

    # gestione promozione
    if move.promotion != 0
        p.pawns &= ~target_mask
        promoted_piece_board = get_piece_board(p, Int64(move.promotion))
        set_piece_board!(p, Int64(move.promotion), promoted_piece_board | target_mask)

        # aggiorna hash: togli pedone, aggiungi pezzo promosso
        new_key ⊻= ZOBRIST_PIECES[piece_index, move.target]
        new_idx = p.turn ? move.promotion : (move.promotion + 6)
        new_key ⊻= ZOBRIST_PIECES[new_idx, move.target]

    elseif move.castling != 0
        # arrocco
        local rook_source_mask, rook_target_mask, rook_source_sq, rook_target_sq
        rook_index = p.turn ? 4 : 10 # torre bianca=4, nera=10

        if move.castling == 1
            rook_source_mask = 0x0000000000000001; rook_target_mask = 0x0000000000000004
            rook_source_sq, rook_target_sq = 1, 3
        elseif move.castling == 2
            rook_source_mask = 0x0000000000000080; rook_target_mask = 0x0000000000000010
            rook_source_sq, rook_target_sq = 8, 5
        elseif move.castling == 3
            rook_source_mask = 0x0100000000000000; rook_target_mask = 0x0400000000000000
            rook_source_sq, rook_target_sq = 57, 59
        else
            rook_source_mask = 0x8000000000000000; rook_target_mask = 0x1000000000000000
            rook_source_sq, rook_target_sq = 64, 61
        end

        p.rooks = (p.rooks & ~rook_source_mask) | rook_target_mask
        if p.turn
            p.white_occ = (p.white_occ & ~rook_source_mask) | rook_target_mask
        else
            p.black_occ = (p.black_occ & ~rook_source_mask) | rook_target_mask
        end

        # aggiorna zobrist per la torre
        new_key ⊻= ZOBRIST_PIECES[rook_index, rook_source_sq]
        new_key ⊻= ZOBRIST_PIECES[rook_index, rook_target_sq]

    elseif move.double_push
        p.enpassant = UInt64(1) << Int64((move.source + move.target) ÷ 2 - 1)
        new_key ⊻= ZOBRIST_ENPASSANT[file_of(p.enpassant)]
    end

    # aggiorna diritti di arrocco: XOR con chiave vecchia e nuova
    old_castle_index = (p.w_kingside ? 1 : 0) | (p.w_queenside ? 2 : 0) | (p.b_kingside ? 4 : 0) | (p.b_queenside ? 8 : 0)
    new_key ⊻= ZOBRIST_CASTLING[old_castle_index + 1]

    if p.w_kingside && (move.source == 1 || move.source == 4) p.w_kingside = false end
    if p.w_queenside && (move.source == 8 || move.source == 4) p.w_queenside = false end
    if p.b_kingside && (move.source == 57 || move.source == 60) p.b_kingside = false end
    if p.b_queenside && (move.source == 64 || move.source == 60) p.b_queenside = false end
    if move.target == 1 p.w_kingside = false end
    if move.target == 8 p.w_queenside = false end
    if move.target == 57 p.b_kingside = false end
    if move.target == 64 p.b_queenside = false end

    new_castle_index = (p.w_kingside ? 1 : 0) | (p.w_queenside ? 2 : 0) | (p.b_kingside ? 4 : 0) | (p.b_queenside ? 8 : 0)
    new_key ⊻= ZOBRIST_CASTLING[new_castle_index + 1]

    # cambio del turno
    new_key ⊻= ZOBRIST_TURN
    p.turn = !p.turn
    return new_key
end

# funzione che conta le ripetizioni della posizione durante una ricerca in un ramo
@inline function repetition_count(zstack::Vector{UInt64}, ply::Int64)::Int
    key = zstack[ply]
    cnt::Int = 0
    for i in (ply-2):-2:1
        if zstack[i] == key
            cnt += 1
        end
    end
    return cnt
end

# funzione che rileva una tripla ripetizione durante la ricerca
@inline function is_repetition(zstack::Vector{UInt64}, ply::Int64)::Bool
    return repetition_count(zstack, ply) >= 2
end

# aggiornamento della chiave Zobrist dopo la mossa nulla
@inline function zobrist_after_nullmove(curr_key::UInt64, pos::Position)::UInt64
    k = curr_key
    if pos.enpassant != 0
        k ⊻= ZOBRIST_ENPASSANT[file_of(pos.enpassant)]
    end
    k ⊻= ZOBRIST_TURN
    return k
end

ZSTACK::Vector{UInt64} = Vector{UInt64}(undef, 64)

###################################################################################################

const MATE_VALUE::Int64 = 50000
nodes_counted::Int64 = 0
const NO_MOVE::Move = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
# Valori dei pezzi per l'ordinamento MVV-LVA
const MVV_LVA_VALUES = [100, 320, 330, 500, 900, 1000] # P, N, B, R, Q, K
# offset per assicurare che i punteggi delle catture siano sempre maggiori di quelli delle mosse quiete
const CAPTURE_SCORE_OFFSET::Int64 = 10000
SCORES_MOVES::Vector{Int64} = zeros(Int64, 256) # punteggi assegnati alle mosse, ordinamento in-place
KILLER_MOVES::Array{Move} = Array{Move}(undef, 64, 2) # [max_ply, indice]
# inizializzazione a "mossa vuota"
for ply in 1:64
    KILLER_MOVES[ply, 1] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
    KILLER_MOVES[ply, 2] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
end
HISTORY_MOVES::Array{Int64} = Array{Int64}(undef, 2, 6, 64) # [colore, tipo_pezzo, casa_target]
fill!(HISTORY_MOVES, 0)
PV = Array{Move}(undef, 64, 64)
PV_LENGTH = zeros(Int64, 64)
for ply1 in 1:64
    for ply2 in 1:64
        PV[ply1, ply2] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
    end
end
PV_MOVE::Vector{Move} = [Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false) for _ in 1:64]

# funzione che traduce mosse nella notazione UCI algebrica
function move_to_algebra(move::Move)::String
    algebra = ID_TO_NOTATION[move.source] * ID_TO_NOTATION[move.target]
    if(move.promotion != 0)
            if(move.promotion == 0x02)
                algebra *= "n"
            elseif(move.promotion == 0x03)
                algebra *= "b"
            elseif(move.promotion == 0x04)
                algebra *= "r"
            elseif(move.promotion == 0x05)
                algebra *= "q"
            end
    end
    return algebra
end

# funzione che traduce la notazione algebrica di UCI grazie al confronto con le mosse legali nella move list
function algebra_to_move(algebra::String, move_list::MoveList)::Move
    parts=split(algebra, "")
    source::UInt8 = UInt8(NOTATION_TO_ID[parts[1]*parts[2]])
    target::UInt8 = UInt8(NOTATION_TO_ID[parts[3]*parts[4]])
    promotion = 0x00
    if(length(parts) > 4)
        if (parts[5] == "n")
            promotion = 0x02
        elseif(parts[5] == "b")
            promotion = 0x03
        elseif(parts[5] == "r")
            promotion = 0x04
        elseif(parts[5] == "q")
            promotion = 0x05
        end
    end
    for i=1:move_list.amount
        if(move_list.moves[i].source == source)
            if(move_list.moves[i].target == target)
                if(move_list.moves[i].promotion == promotion)
                    return move_list.moves[i]
                end
            end
        end
    end
    return Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
end

function get_victim_piece(p::Position, target_square_mask::UInt64)::UInt8
    if (target_square_mask & p.pawns) != 0; return 0x01; end
    if (target_square_mask & p.knights) != 0; return 0x02; end
    if (target_square_mask & p.bishops) != 0; return 0x03; end
    if (target_square_mask & p.rooks) != 0; return 0x04; end
    if (target_square_mask & p.queens) != 0; return 0x05; end
    if (target_square_mask & p.kings) != 0; return 0x06; end
    return 0x00
end

#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
######################################## NEGAMAX ######################################

# funzione helper che serve a trovare la mossa migliore usando negamax e altro...
function bestMove(position::Position, depth::Int64)::Move
zobrist_key = compute_zobrist_key(position) # chiave zobrist radice
# reset tabelle
for ply in 1:64 # killers
    KILLER_MOVES[ply, 1] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
    KILLER_MOVES[ply, 2] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
end
fill!(HISTORY_MOVES, 0) # history
for ply1 in 1:64
    for ply2 in 1:64
        PV[ply1, ply2] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
    end
end
fill!(PV_LENGTH, 0)
for i in 1:64
    PV_MOVE[i] = Move(0x00, 0x00, 0x00, 0x00, false, 0x00, false, false)
end
global nodes_counted = 0 # nodi a 0

    return iterative_deepening(position, depth, ZSTACK, zobrist_key)
end

function copy_move!(dest::Move, src::Move)
    dest.source = src.source
    dest.target = src.target
    dest.moving_piece = src.moving_piece
    dest.promotion = src.promotion
    dest.enpassant = src.enpassant
    dest.castling = src.castling
    dest.double_push = src.double_push
    dest.capture = src.capture
end

# iterative deepening: processo di aumento graduale della profondità.
# possibile gestione del tempo per mossa, non ancora aggiunto.
function iterative_deepening(p::Position, depth::Int64, zstack::Vector{UInt64}, current_key::UInt64)::Move
    IN_PV_LINE = false
    for current_depth in 1:depth
        if (current_depth > 1) # alla prima iterazione non seguiamo la linea principale perchè non c'è
        IN_PV_LINE = true
        end
        score = negamax_search(p, COPY_STACK, MOVE_STACK, KILLER_MOVES, HISTORY_MOVES, PV, PV_LENGTH, PV_MOVE, IN_PV_LINE, current_depth, 1, -50000, 50000, true, zstack, current_key)
        print("Profondità: ", current_depth,  ". Valutazione: ", score, ". Nodi: ", nodes_counted)
        println()
        print("PV: ")
        for i in 1:(PV_LENGTH[1]-1)
            print(move_to_algebra(PV[1, i]) * " ")
        end
        println()
        # SALVA PV DELL'ITERAZIONE CORRENTE
        if current_depth < depth
            for i in 1:(PV_LENGTH[1]-1)
                copy_move!(PV_MOVE[i], PV[1, i])
            end
        end
        if (score > 49000)
            break
        end
    end
    println("Mossa migliore: ", move_to_algebra(PV[1, 1]))
    return PV[1,1]
end

# Negamax sostituisce il Minimax. Il concetto è il medesimo, ma non viene duplicato il codice per due colori.
# In questo modo è più facile da mantenere e gestire.
function negamax_search(position::Position, copy_stack::Vector{Position}, move_stack::Vector{MoveList}, killer_moves::Array{Move}, history_moves::Array{Int64}, pv::Array{Move}, pv_length::Array{Int64}, pv_move::Vector{Move}, in_pv_line::Bool, depth::Int64, ply::Int64, alpha::Int64, beta::Int64, null_move_allowed::Bool, zstack::Vector{UInt64}, current_key::UInt64)::Int64
    zstack[ply] = current_key
    # controllo tripla ripetizione nel sottoramo di ricerca attuale
    if ply > 4 && is_repetition(zstack, ply)
        return 0
    end
    turn = position.turn ? 0x01 : 0x02
    pv_length[ply] = ply
    king_in_check = in_check(position)

   # condizione di uscita dalla valutazione
    if depth == 0
        return q_search(position, copy_stack, move_stack, ply, alpha, beta)
    end

    global nodes_counted +=1

    # NULL MOVE PRUNING 
    R = 2 # valore di riduzione
    side_occ = position.turn ? position.white_occ : position.black_occ
    side_occ_without_king_and_pawns = side_occ & ~(position.pawns | position.kings) # evitiamo zugzwang
    if null_move_allowed && depth >= R + 1 && !in_pv_line && ply > 1 && (side_occ_without_king_and_pawns != 0) && !king_in_check
        # fai null move
        temp_pos = copy_stack[ply]
        copy_position!(temp_pos, position)
        make_null_move!(temp_pos)
        child_key = zobrist_after_nullmove(current_key, position)

        score = -negamax_search(temp_pos, copy_stack, move_stack, killer_moves, history_moves, pv, pv_length, pv_move, false, depth - R - 1, ply + 1, -beta, -beta + 1, false, zstack, child_key)

        if score >= beta
            return beta
        end
    end
    

    # generazione di mosse legali
    move_list = move_stack[ply]
    generate_legal_moves(position, move_list)
    order_moves!(position, move_list, SCORES_MOVES, killer_moves, history_moves, pv_move, in_pv_line, ply)

    # ciclo sulle mosse disponibili
    amount = move_list.amount # numero di mosse legali
    for i in 1:amount
        move = move_list.moves[i]

        # creazione di una copia della posizione su cui si lavorerà
        temp_pos = copy_stack[ply]
        copy_position!(temp_pos, position)
        new_key = makeMove_and_updateHash!(temp_pos, move, current_key) # esecuzione mossa sulla posizione copiata

        # variazione principale al nodo figlio
        next_in_pv_line = in_pv_line && (move.source == pv_move[ply].source && move.target == pv_move[ply].target && move.promotion == pv_move[ply].promotion)

        # ---- Late Move Reductions ----
        reduction = 0
        is_move_check = in_check(temp_pos)
        extension = (is_move_check && depth <= 2) ? 1 : 0
        is_move_killer = ((move.source == killer_moves[ply, 1].source) && (move.target == killer_moves[ply, 1].target)) || ((move.source == killer_moves[ply, 2].source) && (move.target == killer_moves[ply, 2].target))
        if null_move_allowed && depth >= 3 && !in_pv_line && !move.capture && move.promotion == 0x00 && i >= 4 && !king_in_check && !is_move_killer && !is_move_check #########legal_moves_count >= 4
            reduction = 1
        end

        if reduction > 0 # ricerca ridotta, mossa non promettente
            score = -negamax_search(temp_pos, copy_stack, move_stack, killer_moves, history_moves,
                                pv, pv_length, pv_move, next_in_pv_line,
                                depth - 1 - reduction, ply + 1, -alpha - 1, -alpha, true, zstack, new_key)

            # se migliora alpha: ricerca completa. controllo che score non abbia superato beta sennò c'è il cutoff.
            if score > alpha && score < beta
                score = -negamax_search(temp_pos, copy_stack, move_stack, killer_moves, history_moves,
                                    pv, pv_length, pv_move, next_in_pv_line,
                                    depth - 1, ply + 1, -beta, -alpha, true, zstack, new_key)
            end
        else
            # ricerca normale
            score = -negamax_search(temp_pos, copy_stack, move_stack, killer_moves, history_moves,
                                pv, pv_length, pv_move, next_in_pv_line,
                                depth - 1 + extension, ply + 1, -beta, -alpha, true, zstack, new_key)
        end
    # ---- fine Late Move Reductions ----

        # taglio potatura alfa-beta nel negamax
        if score >= beta
            # mosse killer per l'ordinamento
            if !move.capture
                if (move.source != killer_moves[ply, 1].source || move.target != killer_moves[ply, 1].target)
                    copy_move!(killer_moves[ply, 2], killer_moves[ply, 1])
                    copy_move!(killer_moves[ply, 1], move)
                end
            end
            return beta
        end
        # mossa migliore trovata
        if score > alpha
            # mosse history per l'ordinamento
            if !move.capture
                history_moves[turn, move.moving_piece, move.target] += depth
            end
            alpha = score

            # variazione principale nuova
            copy_move!(pv[ply,ply], move)
            for next_ply in (ply + 1):(pv_length[ply + 1]-1)
                copy_move!(pv[ply, next_ply], pv[ply + 1, next_ply])
            end
            pv_length[ply] = pv_length[ply + 1]
        end
    end

    # GESTIONE MATTO e STALLO
    if amount == 0 # nessuna mossa legale trovata
        # matto o stallo
        if king_in_check
            # matto
            return -MATE_VALUE + ply
        else
            # stallo
            return 0
        end
    end

    return alpha
end

function q_search(position::Position, copy_stack::Vector{Position}, move_stack::Vector{MoveList}, ply::Int64, alpha::Int64, beta::Int64)::Int64

    global nodes_counted +=1
    king_in_check = in_check(position)
    move_list = move_stack[ply]
    stand_pat = 0

    if king_in_check # se il re è sotto scacco, si cerca la fuga
        generate_legal_moves(position, move_list) # generazione di tutte le mosse legali
        if move_list.amount == 0
            return -MATE_VALUE + ply
        end
        order_qsearch_moves!(position, move_list, SCORES_MOVES)
    else # altrimenti se non c'è scacco

    stand_pat = evaluate(position) # sempre positivo se in vantaggio sia per il bianco che per il nero

        if stand_pat >= beta
            return beta
        end
        if stand_pat > alpha
            alpha = stand_pat
        end

    # generazione di catture pseudo legali
    goCapturesPseudo(position, move_list)
    order_captures!(position, move_list, SCORES_MOVES)
    end

    # ciclo sulle mosse disponibili
    amount = move_list.amount
    for i in 1:amount
        move = move_list.moves[i]

        if !king_in_check
            if see_capture(position, move, SEE_BUFFER) < 0 #SEE: Static Exchange Evaluation
                continue
            end
        end

        # creazione di una copia della posizione su cui si lavorerà
        temp_pos = copy_stack[ply]
        copy_position!(temp_pos, position)
        makeMove!(temp_pos, move) # esecuzione mossa sulla posizione copiata

        # se il re del giocatore che doveva muovere nella posizione, finisce sotto scacco nella posizione
        # che risulta dopo la mossa allora abbiamo fatto una mossa illegale
        if !king_in_check && is_king_attacked(temp_pos, position.turn)
            continue # saltiamo la mossa
        end

        # a questo punto la mossa è legale

        # chiamata ricorsiva
        score = -q_search(temp_pos, copy_stack, move_stack, ply + 1, -beta, -alpha)

        # taglio alfa-beta
        if score >= beta
            return beta
        end
        # mossa migliore trovata
        if score > alpha
            alpha = score
        end
    end
    return alpha
end

# ordinamento delle mosse per l'efficienza della potatura alfa-beta
# si ordinano linea principale, mosse di cattura secondo MVV-LVA, killer e history
function order_moves!(position::Position, move_list::MoveList, scores::Vector{Int64}, killer_moves::Array{Move}, history_moves::Array{Int64}, pv_move::Vector{Move}, in_pv_line::Bool, ply::Int64)
    nmoves = move_list.amount
    turn = position.turn ? 0x01 : 0x02

    @inbounds for i in 1:nmoves
        move = move_list.moves[i]
        # primo controllo è sulla PV
        if in_pv_line && (move.source == pv_move[ply].source && move.target == pv_move[ply].target && move.promotion == pv_move[ply].promotion)
                scores[i] = 200000  # valore più alto di qualsiasi altra mossa
                continue
        end
        if move.capture # mosse di cattura
            attacker_value = MVV_LVA_VALUES[move.moving_piece]

            victim_value::Int64 = 0
            if move.enpassant
                victim_value = MVV_LVA_VALUES[0x01]
            else
                target_mask = UInt64(1) << (move.target - 1)
                victim_piece_type = get_victim_piece(position, target_mask)
                victim_value = MVV_LVA_VALUES[victim_piece_type]
            end
            scores[i] = CAPTURE_SCORE_OFFSET + victim_value - attacker_value
        else # mosse di quiete
            if (killer_moves[ply, 1].source == move.source && killer_moves[ply, 1].target == move.target)
                scores[i] = 9000 # killer 1
            elseif (killer_moves[ply, 2].source == move.source && killer_moves[ply, 2].target == move.target)
                scores[i] = 8000 # killer 2
            else
                scores[i] = history_moves[turn, move.moving_piece, move.target]
            end
        end
    end

    # sort
    @inbounds for i in 2:nmoves
        key_move = move_list.moves[i]
        key_score = scores[i]
        j = i - 1
        while j ≥ 1 && scores[j] < key_score
            move_list.moves[j+1] = move_list.moves[j]
            scores[j+1] = scores[j]
            j -= 1
        end
        move_list.moves[j+1] = key_move
        scores[j+1] = key_score
    end
end

# ordinamento delle sole catture, per velocità nella q_search
function order_captures!(position::Position, move_list::MoveList, scores::Vector{Int64})
    nmoves = move_list.amount

    @inbounds for i in 1:nmoves
        move = move_list.moves[i]
            attacker_value = MVV_LVA_VALUES[move.moving_piece]

            victim_value::Int64 = 0
            if move.enpassant
                victim_value = MVV_LVA_VALUES[0x01]
            else
                target_mask = UInt64(1) << (move.target - 1)
                victim_piece_type = get_victim_piece(position, target_mask)
                victim_value = MVV_LVA_VALUES[victim_piece_type]
            end
            scores[i] = CAPTURE_SCORE_OFFSET + victim_value - attacker_value
    end

    # sort
    @inbounds for i in 2:nmoves
        key_move = move_list.moves[i]
        key_score = scores[i]
        j = i - 1
        while j ≥ 1 && scores[j] < key_score
            move_list.moves[j+1] = move_list.moves[j]
            scores[j+1] = scores[j]
            j -= 1
        end
        move_list.moves[j+1] = key_move
        scores[j+1] = key_score
    end
end

# ordinamento delle mosse di cattura quando siamo in fuga nella q_search
function order_qsearch_moves!(position::Position, move_list::MoveList, scores::Vector{Int64})
    nmoves = move_list.amount

    @inbounds for i in 1:nmoves
        move = move_list.moves[i]

        if move.capture
            attacker_value = MVV_LVA_VALUES[move.moving_piece]
            victim_value::Int64 = 0
            if move.enpassant
                victim_value = MVV_LVA_VALUES[0x01]
            else
                target_mask = UInt64(1) << (move.target - 1)
                victim_piece_type = get_victim_piece(position, target_mask)
                victim_value = MVV_LVA_VALUES[victim_piece_type]
            end
            scores[i] = CAPTURE_SCORE_OFFSET + victim_value - attacker_value
        else
            scores[i] = 0
        end
            end
end

# funzione helper per il null move pruning: esegue mossa nulla
function make_null_move!(pos::Position)
    pos.turn = !pos.turn
    pos.enpassant = UInt64(0)
end


const PIECE_VALUES = (100, 320, 330, 500, 900, 10000)
const SEE_BUFFER::Vector{Int64} = Vector{Int64}(undef, 64)

@inline function get_piece_type(p::Position, sq_bb::UInt64)::UInt8
    if (sq_bb & p.pawns) != 0; return 0x01; end
    if (sq_bb & p.knights) != 0; return 0x02; end
    if (sq_bb & p.bishops) != 0; return 0x03; end
    if (sq_bb & p.rooks) != 0; return 0x04; end
    if (sq_bb & p.queens) != 0; return 0x05; end
    if (sq_bb & p.kings) != 0; return 0x06; end
    return 0x00
end

@inline function get_attackers(p::Position, sq::Int, for_white::Bool, occ::UInt64)::UInt64
    (enemy_pawns, enemy_knights, enemy_bishops, enemy_rooks, enemy_queens, enemy_king, pawn_attack_func) = if for_white
        (p.pawns & p.white_occ, p.knights & p.white_occ, p.bishops & p.white_occ, p.rooks & p.white_occ, p.queens & p.white_occ, p.kings & p.white_occ, black_pawn_attacks)
    else
        (p.pawns & p.black_occ, p.knights & p.black_occ, p.bishops & p.black_occ, p.rooks & p.black_occ, p.queens & p.black_occ, p.kings & p.black_occ, white_pawn_attacks)
    end

    return (pawn_attack_func(sq) & enemy_pawns) |
           (getKnightAttacks(sq) & enemy_knights) |
           (getBishopAttacksByOcc(sq, occ) & (enemy_bishops | enemy_queens)) |
           (getRookAttacksByOcc(sq, occ) & (enemy_rooks | enemy_queens)) |
           (getKingAttacks(sq) & enemy_king)
end

# SEE: Static Exchange Evaluation
function see_capture(p::Position, move::Move, gain::Vector{Int64})::Int64
    depth = 1

    from_board = p.white_occ | p.black_occ
    occ = from_board

    target_sq = Int(move.target)
    
    local captured_piece_type::UInt8

    if move.enpassant
        captured_piece_type = 0x01
    else
        target_mask = UInt64(1) << (target_sq - 1)
        captured_piece_type = get_victim_piece(p, target_mask)
    end

    gain[1] = PIECE_VALUES[captured_piece_type]

    side_to_move = p.turn
    attacker_mask = UInt64(1) << (move.source - 1)
    attacker_piece_type = move.moving_piece
    
    captured_mask = if move.enpassant
        p.turn ? (UInt64(1) << (target_sq - 1 - 8)) : (UInt64(1) << (target_sq - 1 + 8))
    else
        UInt64(1) << (target_sq - 1)
    end
    
    occ ⊻= (attacker_mask | captured_mask)
    from_board ⊻= (attacker_mask | captured_mask)

    while true
        side_to_move = !side_to_move
        attackers_bb = get_attackers(p, target_sq, side_to_move, occ)
        attackers_bb &= from_board

        if attackers_bb == 0; break; end
        depth += 1
        
        next_attacker_type = 0x00

        if (side_to_move ? (p.pawns & p.white_occ) : (p.pawns & p.black_occ)) & attackers_bb != 0
            next_attacker_type = 0x01
        elseif (side_to_move ? (p.knights & p.white_occ) : (p.knights & p.black_occ)) & attackers_bb != 0
            next_attacker_type = 0x02
        elseif (side_to_move ? (p.bishops & p.white_occ) : (p.bishops & p.black_occ)) & attackers_bb != 0
            next_attacker_type = 0x03
        elseif (side_to_move ? (p.rooks & p.white_occ) : (p.rooks & p.black_occ)) & attackers_bb != 0
            next_attacker_type = 0x04
        elseif (side_to_move ? (p.queens & p.white_occ) : (p.queens & p.black_occ)) & attackers_bb != 0
            next_attacker_type = 0x05
        else
            next_attacker_type = 0x06
        end

        piece_bb = get_piece_board(p, Int64(next_attacker_type)) & attackers_bb
        next_attacker_mask = leastSignificantBit(piece_bb)

        gain[depth] = PIECE_VALUES[attacker_piece_type] - gain[depth - 1]
        
        occ ⊻= next_attacker_mask
        from_board ⊻= next_attacker_mask
        
        attacker_piece_type = next_attacker_type

        if next_attacker_type == 0x06; break; end
    end

    while depth > 1
        depth -= 1
        gain[depth] = -max(-gain[depth], gain[depth + 1])
    end

    return gain[1]
end


#################################################################
#################################################################
#################################################################
############################ EVAL ###############################

mutable struct InfoEval
    is_endgame::Bool
    white_king_sq::Int64
    black_king_sq::Int64
end

INFO_EVAL::InfoEval = InfoEval(false, Int64(0), Int64(0))

# funzione che valuta la posizione secondo il punto di vista del giocatore corrente
# a differenza del Minimax, Negamax si serve di questa funzione che cambia prospettiva
@inline
function evaluate(position::Position)::Int64
    eval = eval_material(position, INFO_EVAL) + eval_heatmap(position, INFO_EVAL) + eval_pawn_structure_new(position) + eval_king_safety_non_linear(position, INFO_EVAL) + eval_rooks_new(position)
    return position.turn ? eval : -eval
end

# valutazione del materiale
function eval_material(position::Position, info_eval::InfoEval)::Int64
    w_queens = position.queens & position.white_occ
    w_bishops = position.bishops & position.white_occ
    w_knights = position.knights & position.white_occ
    w_rooks = position.rooks & position.white_occ
    w_pawns = position.pawns & position.white_occ
    b_queens = position.queens & position.black_occ
    b_bishops = position.bishops & position.black_occ
    b_knights = position.knights & position.black_occ
    b_rooks = position.rooks & position.black_occ
    b_pawns = position.pawns & position.black_occ

    count_w_queens = count_ones(w_queens)
    count_b_queens = count_ones(b_queens)
    count_w_rooks = count_ones(w_rooks)
    count_b_rooks = count_ones(b_rooks)
    count_w_bishops = count_ones(w_bishops)
    count_b_bishops = count_ones(b_bishops)
    count_w_knights = count_ones(w_knights)
    count_b_knights = count_ones(b_knights)

    endgame_pieces = 500*(count_w_rooks + count_b_rooks) +
                     330*(count_w_bishops + count_b_bishops) +
                     320*(count_w_knights + count_b_knights) +
                     900*(count_w_queens + count_b_queens)

    info_eval.is_endgame = (endgame_pieces <= 2000)

    return 900*(count_w_queens - count_b_queens) +
           500*(count_w_rooks - count_b_rooks) +
           330*(count_w_bishops - count_b_bishops) +
           320*(count_w_knights - count_b_knights) +
           100*(count_ones(w_pawns) - count_ones(b_pawns))
end

# valutazione delle mappe di calore
function eval_heatmap(p::Position, info_eval::InfoEval)::Int64
    score::Int64 = 0

    score += eval_piece_heatmap(p.pawns & p.white_occ, HM_W_PAWN)
    score += eval_piece_heatmap(p.knights & p.white_occ, HM_W_KNIGHT)
    score += eval_piece_heatmap(p.bishops & p.white_occ, HM_W_BISHOP)
    score += eval_piece_heatmap(p.rooks & p.white_occ, HM_W_ROOK)
    score += eval_piece_heatmap(p.queens & p.white_occ, HM_W_QUEEN)
    score += eval_white_king_heatmap(p.kings & p.white_occ, info_eval.is_endgame ? HM_W_KING_ENDGAME : HM_W_KING, info_eval)

    score -= eval_piece_heatmap(p.pawns & p.black_occ, HM_B_PAWN)
    score -= eval_piece_heatmap(p.knights & p.black_occ, HM_B_KNIGHT)
    score -= eval_piece_heatmap(p.bishops & p.black_occ, HM_B_BISHOP)
    score -= eval_piece_heatmap(p.rooks & p.black_occ, HM_B_ROOK)
    score -= eval_piece_heatmap(p.queens & p.black_occ, HM_B_QUEEN)
    score -= eval_black_king_heatmap(p.kings & p.black_occ, info_eval.is_endgame ? HM_B_KING_ENDGAME : HM_B_KING, info_eval)

    return score
end

# funzione helper per una singola mappa di calore
function eval_piece_heatmap(bb::UInt64, table::Vector{Int64})::Int64
    score::Int64 = 0
    while bb != 0
        sq = trailing_zeros(bb) + 1
        score += table[sq]
        bb &= bb - 1
    end
    return score
end

# funzione helper per il re bianco, leggermente più efficiente in questo caso particolare
function eval_white_king_heatmap(bb::UInt64, table::Vector{Int64}, info_eval::InfoEval)::Int64
        sq = trailing_zeros(bb) + 1
        info_eval.white_king_sq = sq
    return table[sq]
end

# funzione helper per il re nero, leggermente più efficiente in questo caso particolare
function eval_black_king_heatmap(bb::UInt64, table::Vector{Int64}, info_eval::InfoEval)::Int64
        sq = trailing_zeros(bb) + 1
        info_eval.black_king_sq = sq
    return table[sq]
end

@inline function is_open_file(sq::Int64, p::Position)::Bool
    return (SAME_FILE_MASK[sq] & (p.pawns)) == 0
end

@inline function is_semiopen_file(sq::Int64, p::Position, white::Bool)::Bool
    if white
        return (SAME_FILE_MASK[sq] & (p.pawns & p.white_occ)) == 0
    else
        return (SAME_FILE_MASK[sq] & (p.pawns & p.black_occ)) == 0
    end
end

@inline function is_semiopen_file(sq::Int64, p::Position)::Bool
        return count_ones(SAME_FILE_MASK[sq] & p.pawns) == 1
end

const ADJACENT_FILES_MASK::Vector{UInt64} = Vector{UInt64}(undef, 64)
const SAME_FILE_MASK::Vector{UInt64} = Vector{UInt64}(undef, 64)
const PASSED_PAWN_MASK_W::Vector{UInt64} = Vector{UInt64}(undef, 64)
const PASSED_PAWN_MASK_B::Vector{UInt64} = Vector{UInt64}(undef, 64)
const PASSED_PAWN_MASKS::Array{UInt64} = Array{UInt64}(undef, 64, 2)
const PAWN_SHIELD_WHITE::Vector{UInt64} = Vector{UInt64}(undef, 64)
const PAWN_SHIELD_BLACK::Vector{UInt64} = Vector{UInt64}(undef, 64)
const PAWN_SHIELD_MASKS::Array{UInt64} = Array{UInt64}(undef, 64, 2)


function init_eval_masks()
    for sq in 1:64
        bb = UInt64(1) << (sq - 1)
        rank = BITSQUARES_TO_COORDINATES[bb][1]
        file = BITSQUARES_TO_COORDINATES[bb][2]

        # stessa colonna
        SAME_FILE_MASK[sq] = FILES[file]

        # colonne adiacenti
        adj_files = UInt64(0)
        if file > 1; adj_files |= FILES[file - 1]; end
        if file < 8; adj_files |= FILES[file + 1]; end
        ADJACENT_FILES_MASK[sq] = adj_files

        # pedoni passati
        PASSED_PAWN_MASK_W[sq] = passed_pawn_mask_white(file, rank)
        PASSED_PAWN_MASK_B[sq] = passed_pawn_mask_black(file, rank)
        PASSED_PAWN_MASKS[sq, 1] = passed_pawn_mask_white(file, rank)
        PASSED_PAWN_MASKS[sq, 2] = passed_pawn_mask_black(file, rank)

        #scudo di pedoni del re
        PAWN_SHIELD_WHITE[sq] = pawn_shield_white(sq)
        PAWN_SHIELD_BLACK[sq] = pawn_shield_black(sq)
        PAWN_SHIELD_MASKS[sq, 1] = pawn_shield_white(sq)
        PAWN_SHIELD_MASKS[sq, 2] = pawn_shield_black(sq)
    end
end

@inline function passed_pawn_mask_white(file::Int, rank::Int)::UInt64
    mask = UInt64(0)
    for r in rank+1:8
        for f in max(1, file-1):min(8, file+1)
            mask |= FILES[f] & RANKS[r]
        end
    end
    return mask
end

@inline function passed_pawn_mask_black(file::Int, rank::Int)::UInt64
    mask = UInt64(0)
    for r in 1:rank-1
        for f in max(1, file-1):min(8, file+1)
            mask |= FILES[f] & RANKS[r]
        end
    end
    return mask
end

@inline function pawn_shield_white(king_sq::Int)::UInt64
    bb = UInt64(1) << (king_sq - 1)
    f = BITSQUARES_TO_COORDINATES[bb][2]
    r = BITSQUARES_TO_COORDINATES[bb][1] + 1
    mask = UInt64(0)
    if r <= 8
        for df in -1:1
            nf = f + df
            if 1 <= nf <= 8
                mask |= FILES[nf] & RANKS[r]
            end
        end
    end
    return mask
end

@inline function pawn_shield_black(king_sq::Int)::UInt64
    bb = UInt64(1) << (king_sq - 1)
    f = BITSQUARES_TO_COORDINATES[bb][2]
    r = BITSQUARES_TO_COORDINATES[bb][1] - 1
    mask = UInt64(0)
    if r >= 1
        for df in -1:1
            nf = f + df
            if 1 <= nf <= 8
                mask |= FILES[nf] & RANKS[r]
            end
        end
    end
    return mask
end

init_eval_masks()

const KING_ZONES::Array{UInt64} = Array{UInt64}(undef, 64, 2)

function init_king_zone()
    for sq in 1:64
        KING_ZONES[sq, 1] = KING_MASKS_BY_ID[sq] | (PAWN_SHIELD_WHITE[sq] << 8)
    end
    for sq in 1:64
        KING_ZONES[sq, 2] = KING_MASKS_BY_ID[sq] | (PAWN_SHIELD_BLACK[sq] >> 8)
    end
end

init_king_zone()

# tabella di sicurezza basata su Stockfish, riscalata in centesimi di pedone.
const SAFETY_TABLE = Int64[
      0,   0,   1,   2,   3,   5,   7,   9,  12,  15,
     18,  22,  26,  30,  35,  39,  44,  50,  56,  62,
     68,  75,  82,  85,  89,  97, 105, 113, 122, 131,
    140, 150, 169, 180, 191, 202, 213, 225, 237, 248,
    260, 272, 283, 295, 307, 319, 330, 342, 354, 366,
    377, 389, 401, 412, 424, 436, 448, 459, 471, 483,
    494, 500, 500, 500, 500, 500, 500, 500, 500, 500,
    500, 500, 500, 500, 500, 500, 500, 500, 500, 500,
    500, 500, 500, 500, 500, 500, 500, 500, 500, 500,
    500, 500, 500, 500, 500, 500, 500, 500, 500, 500
]

# pesi delle unità d'attacco per ogni tipo di pezzo
const KNIGHT_ATTACK_UNITS::Int64 = 3
const BISHOP_ATTACK_UNITS::Int64 = 3
const ROOK_ATTACK_UNITS::Int64   = 4
const QUEEN_ATTACK_UNITS::Int64  = 6

const QUEEN_IN_CONE_UNITS::Int64  = 3
const ROOK_IN_CONE_UNITS::Int64   = 2
const BISHOP_IN_CONE_UNITS::Int64 = 1
const KNIGHT_IN_CONE_UNITS::Int64 = 2

const QUEEN_CONTACT_BONUS::Int64  = 6
const ROOK_CONTACT_BONUS::Int64   = 4
const ATTACKER_COUNT_BONUS = Int64[0, 1, 2, 4, 7, 12, 20]

const WHITE_SIDE_BOARD::UInt64 = 0x00000000ffffffff
const BLACK_SIDE_BOARD::UInt64 = 0xffffffff00000000

# funzione che calcola il punteggio della sicurezza del re
function calculate_danger_for_king(p::Position, king_sq::Int64, color_of_king::Int64, ally_occ::UInt64, attackers_occ::UInt64)::Int64
    king_zone::UInt64 = KING_ZONES[king_sq, color_of_king]
    occ = p.white_occ | p.black_occ
    
    attack_units = 0
    num_attackers = 0

    # pezzi attaccanti
    enemy_knights = p.knights & attackers_occ
    enemy_bishops = p.bishops & attackers_occ
    enemy_rooks   = p.rooks   & attackers_occ
    enemy_queens  = p.queens  & attackers_occ

    # --- Cavalli ---
    temp_knights = enemy_knights
    while temp_knights != 0
        sq = trailing_zeros(temp_knights) + 1
        if (getKnightAttacks(sq) & king_zone) != 0
            attack_units += KNIGHT_ATTACK_UNITS
            num_attackers += 1
        end
        temp_knights &= temp_knights - 1
    end

    # --- Alfieri ---
    temp_bishops = enemy_bishops
    while temp_bishops != 0
        sq = trailing_zeros(temp_bishops) + 1
        if (getBishopAttacksByOcc(sq, occ) & king_zone) != 0
            attack_units += BISHOP_ATTACK_UNITS
            num_attackers += 1
        end
        temp_bishops &= temp_bishops - 1
    end

    # --- Torri ---
    temp_rooks = enemy_rooks
    while temp_rooks != 0
        sq = trailing_zeros(temp_rooks) + 1
        if (getRookAttacksByOcc(sq, occ) & king_zone) != 0
            attack_units += ROOK_ATTACK_UNITS
            num_attackers += 1
        end
        temp_rooks &= temp_rooks - 1
    end
    
    # --- Regine ---
    temp_queens = enemy_queens
    while temp_queens != 0
        sq = trailing_zeros(temp_queens) + 1
        if (getQueenAttacksByOcc(sq, occ) & king_zone) != 0
            attack_units += QUEEN_ATTACK_UNITS
            num_attackers += 1
        end
        temp_queens &= temp_queens - 1
    end

    # non è un attacco se ci sono meno di 2 pezzi attaccanti
    if num_attackers < 2
        return 0
    end

    # se ci sono almeno due attaccanti valutiamo anche altri fattori aggiuntivi

    # NUOVO: bonus non lineare per il numero di attaccanti
    safe_idx = min(num_attackers, 7) # l'indice massimo è 7 per 7 o più attaccanti
    attack_units += ATTACKER_COUNT_BONUS[safe_idx]

    pawn_shield_mask::UInt64 = PAWN_SHIELD_MASKS[king_sq, color_of_king]
    full_shield_count = count_ones(pawn_shield_mask)
    shield_pawns_count = count_ones(p.pawns & ally_occ & pawn_shield_mask)
    missing_pawns = full_shield_count - shield_pawns_count
    attack_units += 5 * missing_pawns

    adj_king_files = ADJACENT_FILES_MASK[king_sq]
    adj_sig = files_sig(adj_king_files)
    ally_pawns = p.pawns & ally_occ

    # firme di presenza pedoni (almeno uno) su quelle colonne
    ally_sig = files_sig(ally_pawns & adj_king_files)
    enemy_sig = files_sig((p.pawns & attackers_occ) & adj_king_files)

    # conteggi branchless colonne aperte/semi-aperte
    semi_open_adj = count_ones(adj_sig & ~ally_sig) # nessun pedone amico
    open_adj = count_ones(adj_sig & ~(ally_sig | enemy_sig)) # nessun pedone

    attack_units += 2 * semi_open_adj
    attack_units += 3 * open_adj

    king_file_mask = SAME_FILE_MASK[king_sq]
    kf_ally  = files_sig(ally_pawns & king_file_mask)
    kf_any = files_sig(p.pawns & king_file_mask)

    semi_open_king = Int64(kf_ally == 0) # Bool -> 0/1
    open_king = Int64(kf_any  == 0) # nessun pedone su quella colonna

    attack_units += 4 * semi_open_king
    attack_units += 3 * open_king

    king_cone::UInt64 = PASSED_PAWN_MASKS[king_sq, color_of_king]

    enemy_side_board::UInt64 = color_of_king == 1 ? BLACK_SIDE_BOARD : WHITE_SIDE_BOARD
    ally_side_board = ~enemy_side_board

    enemy_queens_in_cone  = enemy_queens & king_cone
    enemy_rooks_in_cone   = enemy_rooks & king_cone
    enemy_bishops_in_cone = enemy_bishops & king_cone
    enemy_knights_in_cone = enemy_knights & king_cone

    enemy_queens_in_cone_near = enemy_queens_in_cone & ally_side_board
    enemy_rooks_in_cone_near = enemy_rooks_in_cone & ally_side_board
    enemy_bishops_in_cone_near = enemy_bishops_in_cone & ally_side_board
    enemy_knights_in_cone_near = enemy_knights_in_cone & ally_side_board

    attack_units += (QUEEN_IN_CONE_UNITS  * count_ones(enemy_queens_in_cone))
    attack_units += (ROOK_IN_CONE_UNITS   * count_ones(enemy_rooks_in_cone))
    attack_units += (BISHOP_IN_CONE_UNITS * count_ones(enemy_bishops_in_cone))
    attack_units += (KNIGHT_IN_CONE_UNITS * count_ones(enemy_knights_in_cone))
    # bonus raddoppio se sono nel cono vicino
    attack_units += (QUEEN_IN_CONE_UNITS  * count_ones(enemy_queens_in_cone_near))
    attack_units += (ROOK_IN_CONE_UNITS   * count_ones(enemy_rooks_in_cone_near))
    attack_units += (BISHOP_IN_CONE_UNITS * count_ones(enemy_bishops_in_cone_near))
    attack_units += (KNIGHT_IN_CONE_UNITS * count_ones(enemy_knights_in_cone_near))

    # NUOVO: bonus contatto con il re per torri e regine
    king_contact_mask = KING_MASKS_BY_ID[king_sq]
    contact_queens = enemy_queens & king_contact_mask
    contact_rooks  = enemy_rooks  & king_contact_mask

    attack_units += QUEEN_CONTACT_BONUS * count_ones(contact_queens)
    attack_units += ROOK_CONTACT_BONUS * count_ones(contact_rooks)

    index = min(attack_units, 99) + 1
    return SAFETY_TABLE[index]
end

# funzione che valuta la sicurezza del re
function eval_king_safety_non_linear(p::Position, info_eval::InfoEval)::Int64
    if info_eval.is_endgame
        return 0
    end
    black_king_danger = calculate_danger_for_king(p, info_eval.black_king_sq, 2, p.black_occ, p.white_occ)
    white_king_danger = calculate_danger_for_king(p, info_eval.white_king_sq, 1, p.white_occ ,p.black_occ)
    return black_king_danger - white_king_danger
end

const RANK_1_MASK::UInt64 = UInt64(0x00000000000000ff)

# collassa verticalmente verso sud fino alla prima traversa
@inline function files_sig(bb::UInt64)::UInt64
    bb |= bb >> 8
    bb |= bb >> 16
    bb |= bb >> 32
    return bb & RANK_1_MASK  # un bit per colonna
end

const FILE_A::UInt64 = FILES[1]
const FILE_H::UInt64 = FILES[8]

const FILE_MASK_FROM_SIG = let lut = Vector{UInt64}(undef, 256)
    for sig in 0:255
        m = UInt64(0)
        s = sig
        idx = 8
        while s != 0
            if (s & 1) != 0
                m |= FILES[idx]
            end
            s >>= 1
            idx -= 1
        end
        lut[sig+1] = m
    end
    lut
end

# propaga verso nord
@inline function north_fill(x::UInt64)::UInt64
    x |= x << 8
    x |= x << 16
    x |= x << 32
    return x
end

# propaga verso sud
@inline function south_fill(x::UInt64)::UInt64
    x |= x >> 8
    x |= x >> 16
    x |= x >> 32
    return x
end

@inline function white_passed_mask(w_pawns::UInt64, b_pawns::UInt64)::UInt64
    b_adj = b_pawns | ((b_pawns & ~FILE_H) >> 9) | ((b_pawns & ~FILE_A) >> 7)
    # i neri "sopra" i bianchi rispetto ai bianchi: riempie verso sud (verso i bianchi)
    b_block_south = south_fill(b_adj)
    # un bianco è passato se non ha blocchi sopra (nessun nero a nord di lui su file stessi/adiacenti)
    return w_pawns & ~b_block_south
end

@inline function black_passed_mask(w_pawns::UInt64, b_pawns::UInt64)::UInt64
    w_adj = w_pawns | ((w_pawns & ~FILE_H) << 7) | ((w_pawns & ~FILE_A) << 9)
    # i bianchi "sopra" i neri rispetto ai neri: riempie verso nord (verso i neri)
    w_block_north = north_fill(w_adj)
    # un nero è passato se non ha blocchi sopra (nessun bianco a sud di lui su file stessi/adiacenti)
    return b_pawns & ~w_block_north
end

const ISOLATED_PAWN_MALUS::Int64 = 15
const DOUBLE_PAWN_MALUS::Int64 = 10

# funzione che valuta la struttura pedonale
@inline function eval_pawn_structure_new(p::Position)::Int64
    score::Int64 = 0

    w_pawns = p.pawns & p.white_occ
    b_pawns = p.pawns & p.black_occ

    # doppiati
    extra_w_pawns = w_pawns & (south_fill(w_pawns) >> 8)
    doubled_w_files_sig = files_sig(extra_w_pawns)
    doubled_w_files_mask = FILE_MASK_FROM_SIG[Int(doubled_w_files_sig) + 1]
    total_w_doubled_count = count_ones(w_pawns & doubled_w_files_mask)

    extra_b_pawns = b_pawns & (north_fill(b_pawns) << 8)
    doubled_b_files_sig = files_sig(extra_b_pawns)
    doubled_b_files_mask = FILE_MASK_FROM_SIG[Int(doubled_b_files_sig) + 1]
    total_b_doubled_count = count_ones(b_pawns & doubled_b_files_mask)

    score -= total_w_doubled_count * DOUBLE_PAWN_MALUS
    score += total_b_doubled_count * DOUBLE_PAWN_MALUS

    # isolati
    w_files = files_sig(w_pawns)
    b_files = files_sig(b_pawns)

    w_iso_cols = w_files & ~((w_files << 1) | (w_files >> 1))
    b_iso_cols = b_files & ~((b_files << 1) | (b_files >> 1))

    # espandiamo le colonne isolate
    w_iso_mask = FILE_MASK_FROM_SIG[Int(w_iso_cols) + 1]
    b_iso_mask = FILE_MASK_FROM_SIG[Int(b_iso_cols) + 1]

    w_isolated_count = count_ones(w_pawns & w_iso_mask)
    b_isolated_count = count_ones(b_pawns & b_iso_mask)

    score -= Int64(w_isolated_count) * ISOLATED_PAWN_MALUS
    score += Int64(b_isolated_count) * ISOLATED_PAWN_MALUS

    # passati
    w_passed = white_passed_mask(w_pawns, b_pawns)
    b_passed = black_passed_mask(w_pawns, b_pawns)

    # loop solo su pedoni passati
    while w_passed != 0
        sq = trailing_zeros(w_passed) + 1
        score += HM_W_PP[sq]
        w_passed &= w_passed - 1
    end

    while b_passed != 0
        sq = trailing_zeros(b_passed) + 1
        score -= HM_B_PP[sq]
        b_passed &= b_passed - 1
    end

    return score
end

const ROOK_OPEN_FILE_BONUS::Int64 = 40
const ROOK_SEMI_OPEN_FILE_BONUS::Int64 = 15

# funzione che valuta il posizionamento delle torri
@inline function eval_rooks_new(p::Position)::Int64
    all_pawns = p.pawns
    w_pawns = all_pawns & p.white_occ
    b_pawns = all_pawns & p.black_occ

    # colonne occupate da pedoni bianchi/neri/tutti
    w_sig = files_sig(w_pawns)
    b_sig = files_sig(b_pawns)
    all_sig = w_sig | b_sig

    # espansione colonne aperte
    open_files_mask = FILE_MASK_FROM_SIG[Int(~all_sig & 0xFF) + 1]

    # colonne semiaperte: quelle SENZA pedoni nostri, ma con almeno un pedone avversario
    semi_open_w_sig = (~w_sig & b_sig)
    semi_open_b_sig = (~b_sig & w_sig)

    semi_open_w_mask = FILE_MASK_FROM_SIG[Int(semi_open_w_sig) + 1]
    semi_open_b_mask = FILE_MASK_FROM_SIG[Int(semi_open_b_sig) + 1]

    w_rooks = p.rooks & p.white_occ
    b_rooks = p.rooks & p.black_occ

    # conteggio torri bianche su colonne aperte/semiaperte
    w_open  = count_ones(w_rooks & open_files_mask)
    w_semi  = count_ones(w_rooks & semi_open_w_mask)

    # conteggio torri nere su colonne aperte/semiaperte
    b_open  = count_ones(b_rooks & open_files_mask)
    b_semi  = count_ones(b_rooks & semi_open_b_mask)

    return (w_open - b_open) * ROOK_OPEN_FILE_BONUS + (w_semi - b_semi) * ROOK_SEMI_OPEN_FILE_BONUS
end

