include("MoveGenerator.jl")

function eval(BITBOARDS, GAMESTATE, BITTYBOARDS)
    w_kings = BITBOARDS[1]
    w_queens = BITBOARDS[2]
    w_bishops = BITBOARDS[3]
    w_knights = BITBOARDS[4]
    w_rooks = BITBOARDS[5]
    w_pawns = BITBOARDS[6]
    b_kings = BITBOARDS[7]
    b_queens = BITBOARDS[8]
    b_bishops = BITBOARDS[9]
    b_knights = BITBOARDS[10]
    b_rooks = BITBOARDS[11]
    b_pawns = BITBOARDS[12]

    #Heatmap scores
    score_w = 0
    score_b = 0

    #white pawns score
    temp = w_pawns
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_PAWN[65-index]
        temp &= ~least_bit
    end
    #white knights score
    temp = w_knights
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_KNIGHT[65-index]
        temp &= ~least_bit
    end
    #white bishops score
    temp = w_bishops
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_BISHOP[65-index]
        temp &= ~least_bit
    end
    #white rooks score
    temp = w_rooks
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_ROOK[65-index]
        temp &= ~least_bit
    end
    #white queens score
    temp = w_queens
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_QUEEN[65-index]
        temp &= ~least_bit
    end
    #white king score
    temp = w_kings
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_w += HM_W_KING[65-index]
        temp &= ~least_bit
    end

    #black pawns score
    temp = b_pawns
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_PAWN[65-index]
        temp &= ~least_bit
    end
    #black knights score
    temp = b_knights
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_KNIGHT[65-index]
        temp &= ~least_bit
    end
    #black bishops score
    temp = b_bishops
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_BISHOP[65-index]
        temp &= ~least_bit
    end
    #black rooks score
    temp = b_rooks
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_ROOK[65-index]
        temp &= ~least_bit
    end
    #black queens score
    temp = b_queens
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_QUEEN[65-index]
        temp &= ~least_bit
    end
    #black king score
    temp = b_kings
    while (temp !=0)
        least_bit = leastSignificantBit(temp)
        index = trailing_zeros(least_bit) + 1
        score_b += HM_B_KING[65-index]
        temp &= ~least_bit
    end

    return 2000*(count_ones(w_kings) - count_ones(b_kings)) + 
            900*(count_ones(w_queens) - count_ones(b_queens)) +
            500*(count_ones(w_rooks) - count_ones(b_rooks)) +
            330*(count_ones(w_bishops) - count_ones(b_bishops)) +
            320*(count_ones(w_knights) - count_ones(b_knights)) +
            100*(count_ones(w_pawns) - count_ones(b_pawns)) +
            score_w -
            score_b
end

nodes2::Ref{Int} = 0

function ab_minimax(BITBOARDS, GAMESTATE, BITTYBOARDS, depth, alpha, beta, maximizer)
    legal_moves = goFullLegal(BITBOARDS, GAMESTATE, BITTYBOARDS)
    #Check if it is checkmate or stalemate
    if(isempty(legal_moves))
        if(isKingInCheck(BITBOARDS, GAMESTATE[2]))
            if(GAMESTATE[2] == WHITE)
                return -50000
            else
                return 50000
            end
        else
            return 0
        end
    end
    if(depth == 0)
        return eval(BITBOARDS, GAMESTATE, BITTYBOARDS)
    end
    if(maximizer) #White
        v = -100000
        for move in legal_moves
            incr(nodes2)
            var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
            v = max(v, ab_minimax(var[1], var[2], var[3], depth - 1, alpha, beta, BLACK))
            alpha = max(alpha, v)
            if(v >= beta)
                break #potatura
            end
        end
        return v
    else #Black
        v = +100000
        for move in legal_moves
            incr(nodes2)
            var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
            v = min(v, ab_minimax(var[1], var[2], var[3], depth - 1, alpha, beta, WHITE))
            beta = min(beta, v)
            if(v <= alpha)
                break #potatura
            end
        end
        return v
    end
end

function best_move(BITBOARDS, GAMESTATE, BITTYBOARDS, depth, maximizer)
legal_moves = goFullLegal(BITBOARDS, GAMESTATE, BITTYBOARDS)
best_move = nothing
if(isempty(legal_moves))
    return nothing
end
if(maximizer)#white
    best_value = -1000000
    for move in legal_moves
        var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
        v = ab_minimax(var[1], var[2], var[3], depth - 1, -1000000, 1000000, BLACK)
        if(v > best_value)
            best_value = v
            best_move = move
        end
    end
else#black
    best_value = 1000000
    for move in legal_moves
        var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
        v = ab_minimax(var[1], var[2], var[3], depth - 1, -1000000, 1000000, WHITE)
        if(v < best_value)
            best_value = v
            best_move = move
        end
    end
end
return best_move
end

function incr(var::Ref{Int})
    var[] +=1
end