include("Chess.jl")
include("MoveData.jl")

"""
Legal move generator step by step

Chess Rules:
documantion about the rules of chess are taken from FIDE: https://handbook.fide.com/chapter/E012023 
"""

function isSquareAttackedByBlack(bitsquare::UInt64)
        #Ranks and Files check
        if((getBishopAttacks(bitsquare) & (getBlackBishops() | getBlackQueens())) != 0)
            return true
        end
        if((getRookAttacks(bitsquare) & (getBlackRooks() | getBlackQueens())) != 0)
            return true
        end
        #Knight check
        if((getKnightAttacks(bitsquare) & getBlackKnights()) != 0)
            return true
        end
        if((white_pawn_attacks(bitsquare) & getBlackPawns()) != 0)
            return true
        end
        if((getKingAttacks(getBlackKing()) & bitsquare) != 0)
            return true
        end
        return false
end

function getEnemyAttackersOnSquare(bitsquare::UInt64, turn)
    if(turn == WHITE)
    DAD_Attackers = getBishopAttacks(bitsquare) & (getBlackBishops() | getBlackQueens())
    LINE_Attackers = getRookAttacks(bitsquare) & (getBlackRooks() | getBlackQueens())
    KNIGHT_Attackers = getKnightAttacks(bitsquare) & getBlackKnights()
    PAWN_Attackers = white_pawn_attacks(bitsquare) & getBlackPawns()
    KING_Attackers = getKingAttacks(getBlackKing()) & bitsquare
    Attackers = DAD_Attackers | LINE_Attackers | KNIGHT_Attackers | PAWN_Attackers | KING_Attackers
    return Attackers
else #Black Turn
    DAD_Attackers = getBishopAttacks(bitsquare) & (getWhiteBishops() | getWhiteQueens())
    LINE_Attackers = getRookAttacks(bitsquare) & (getWhiteRooks() | getWhiteQueens())
    KNIGHT_Attackers = getKnightAttacks(bitsquare) & getWhiteKnights()
    PAWN_Attackers = black_pawn_attacks(bitsquare) & getWhitePawns()
    KING_Attackers = getKingAttacks(getWhiteKing()) & bitsquare
    Attackers = DAD_Attackers | LINE_Attackers | KNIGHT_Attackers | PAWN_Attackers | KING_Attackers
    return Attackers
end
end


#TODO: check if is correct
function isSquareAttackedByWhite(bitsquare::UInt64)
    #Ranks and Files check
    if((getBishopAttacks(bitsquare) & (getWhiteBishops() | getWhiteQueens())) != 0)
        #println("Diag")
        return true
    end
    if((getRookAttacks(bitsquare) & (getWhiteRooks() | getWhiteQueens())) != 0)
        #println("File or Rank")
        return true
    end
    #Knight check
    if((getKnightAttacks(bitsquare) & getWhiteKnights()) != 0)
        #println("Knight")
        return true
    end
    if((black_pawn_attacks(bitsquare) & getWhitePawns()) != 0)
        #println("Pawn")
        return true
    end
    if((getKingAttacks(getWhiteKing()) & bitsquare) != 0)
        #println("King")
        return true
    end
    return false
end

#Run only if in check
function isWhiteInDoubleCheck()
    check_amount=0
    bitsquare = getWhiteKing()
    if((getBishopAttacks(bitsquare) & (getBlackBishops() | getBlackQueens())) != 0)
        check_amount+=count_ones(getBishopAttacks(bitsquare) & (getBlackBishops() | getBlackQueens()))
        if(check_amount >= 2)
            return true
        end
    end
    if((getRookAttacks(bitsquare) & (getBlackRooks() | getBlackQueens())) != 0)
        check_amount+=count_ones((getRookAttacks(bitsquare) & (getBlackRooks() | getBlackQueens())))
        if(check_amount >= 2)
            return true
        end
    end
    #Knight check
    if((getKnightAttacks(bitsquare) & getBlackKnights()) != 0)
        check_amount+=count_ones((getKnightAttacks(bitsquare) & getBlackKnights()))
        if(check_amount >= 2)
            return true
        end
    end
    if((white_pawn_attacks(bitsquare) & getBlackPawns()) != 0)
        check_amount+=count_ones((white_pawn_attacks(bitsquare) & getBlackPawns()))
        if(check_amount >= 2)
            return true
        end
    end
    return false
end

function isBlackInDoubleCheck()
    check_amount=0
    bitsquare = getBlackKing()
    if((getBishopAttacks(bitsquare) & (getWhiteBishops() | getWhiteQueens())) != 0)
        check_amount+=count_ones(getBishopAttacks(bitsquare) & (getWhiteBishops() | getWhiteQueens()))
        if(check_amount >= 2)
            return true
        end
    end
    if((getRookAttacks(bitsquare) & (getWhiteRooks() | getWhiteQueens())) != 0)
        check_amount+=count_ones((getRookAttacks(bitsquare) & (getWhiteRooks() | getWhiteQueens())))
        if(check_amount >= 2)
            return true
        end
    end
    #Knight check
    if((getKnightAttacks(bitsquare) & getWhiteKnights()) != 0)
        check_amount+=count_ones((getKnightAttacks(bitsquare) & getWhiteKnights()))
        if(check_amount >= 2)
            return true
        end
    end
    if((black_pawn_attacks(bitsquare) & getWhitePawns()) != 0)
        check_amount+=count_ones((black_pawn_attacks(bitsquare) & getWhitePawns()))
        if(check_amount >= 2)
            return true
        end
    end
    return false
end



#############################################################################################################################################################
#############################################################################################################################################################
#############################################################################################################################################################


#This should be a complete PSEUDO-Legal-MoveGenerator. Takes as input a position (bitboards) and gamestate
function getPseudoMovesGivenPosition(BITBOARDS, GAMESTATE)
    moves = []
    #We name the variables for clarity of the code
    w_king = BITBOARDS[1]
    w_queens = BITBOARDS[2]
    w_bishops = BITBOARDS[3]
    w_knights = BITBOARDS[4]
    w_rooks = BITBOARDS[5]
    w_pawns = BITBOARDS[6]

    b_king = BITBOARDS[7]
    b_queens = BITBOARDS[8]
    b_bishops = BITBOARDS[9]
    b_knights = BITBOARDS[10]
    b_rooks = BITBOARDS[11]
    b_pawns = BITBOARDS[12]

    if(GAMESTATE[2] == WHITE)
        enemyOrEmpty = ~(w_king | w_queens | w_bishops | w_knights | w_rooks | w_pawns)

        #KING MOVES
        if(w_king != 0)
            index = trailing_zeros(w_king) + 1
            push!(moves, (w_king, KING_MASKS_BY_ID[index] & enemyOrEmpty))
        end

        #QUEEN MOVES
        if(w_queens != 0)
            temp = w_queens
            for i=1:count_ones(w_queens)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getQueenAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #BISHOP MOVES
        if(w_bishops != 0)
            temp = w_bishops
            for i=1:count_ones(w_bishops)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getBishopAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #KNIGHT MOVES
        if(w_knights != 0)
            temp = w_knights
            for i=1:count_ones(w_knights)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getKnightAttacks(index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #ROOK MOVES
        if(w_rooks != 0)
            temp = w_rooks
            for i=1:count_ones(w_rooks)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getRookAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #PAWN MOVES
        if(w_pawns != 0)
            temp = w_pawns
            for i=1:count_ones(w_pawns)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                black_occ = BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
                push!(moves, (least_bit, (white_pawn_attacks(index) & black_occ) | (w_pawns_shift(BITBOARDS) & FILES[8 - ((index - 1)% 8)])))
                temp &= ~least_bit
            end
        end

    else #BLACK turn

        enemyOrEmpty = ~(b_king | b_queens | b_bishops | b_knights | b_rooks | b_pawns)

        #KING MOVES
        if(b_king != 0)
            index = trailing_zeros(b_king) + 1
            push!(moves, (b_king, KING_MASKS_BY_ID[index] & enemyOrEmpty))
        end

        #QUEEN MOVES
        if(b_queens != 0)
            temp = b_queens
            for i=1:count_ones(b_queens)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getQueenAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #BISHOP MOVES
        if(b_bishops != 0)
            temp = b_bishops
            for i=1:count_ones(b_bishops)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getBishopAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #KNIGHT MOVES
        if(b_knights != 0)
            temp = b_knights
            for i=1:count_ones(b_knights)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getKnightAttacks(index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #ROOK MOVES
        if(b_rooks != 0)
            temp = b_rooks
            for i=1:count_ones(b_rooks)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                push!(moves, (least_bit, getRookAttacks(BITBOARDS, index) & enemyOrEmpty))
                temp &= ~least_bit
            end
        end

        #PAWN MOVES
        if(b_pawns != 0)
            temp = b_pawns
            for i=1:count_ones(b_pawns)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                white_occ = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6]
                push!(moves, (least_bit, (black_pawn_attacks(index) & white_occ) | (b_pawns_shift(BITBOARDS) & FILES[8 - ((index - 1)% 8)])))
                temp &= ~least_bit
            end
        end
    end
    return moves
end

#Every single Pseudo-move
#Moves will be listed in the following way: (source_square, target_square, piece_type, promotion, enpassant, castling, double push, capture)
#source_code as an id of the square, target square the same, piece_type from 1 to 12 as in the bitBoards (Color will be signed)
#four types of promotion in Q-R-N-B, enpassant true or false, 0 no castling, 1 castling kingside, 2 castling queenside, double push true or false, capture true or false
function goFullPseudo(BITBOARDS, GAMESTATE, BITTYBOARDS)
    moves = []
    #We name the variables for clarity of the code
    w_king = BITBOARDS[1]
    w_queens = BITBOARDS[2]
    w_bishops = BITBOARDS[3]
    w_knights = BITBOARDS[4]
    w_rooks = BITBOARDS[5]
    w_pawns = BITBOARDS[6]

    b_king = BITBOARDS[7]
    b_queens = BITBOARDS[8]
    b_bishops = BITBOARDS[9]
    b_knights = BITBOARDS[10]
    b_rooks = BITBOARDS[11]
    b_pawns = BITBOARDS[12]

    black_occ = b_king | b_queens | b_bishops | b_knights | b_rooks | b_pawns
    white_occ = w_king | w_queens | w_bishops | w_knights | w_rooks | w_pawns

    if(GAMESTATE[2] == WHITE)
        enemyOrEmpty = ~white_occ

        #KING MOVES
        if(w_king != 0)
            empty = ~(black_occ | white_occ)
            index = trailing_zeros(w_king) + 1
            attacks = getKingAttacks(index) & enemyOrEmpty
            captures = attacks & black_occ
            quiet_moves = attacks & ~black_occ
            if(captures != 0)
                temp2 = captures
                    for i=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 1, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
            end
            if(quiet_moves != 0)
                temp2 = quiet_moves
                        for j=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 1, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
            end
            if(GAMESTATE[5] == true) #check if pseudo-legal castling kingside is possible. (given or updated information about history moves of king and rooks)
                f1 = RANKS[1] & FILES[6]
                g1 = RANKS[1] & FILES[7]
                index_g1 = trailing_zeros(g1) + 1
                if(f1 & empty != 0)
                    if(g1 & empty != 0)
                        #Every square for castling kingside is empty
                        push!(moves, (index, index_g1, 1, 0, false, 1, false, false))
                    end
                end
            end
            if(GAMESTATE[6] == true)
                b1 = RANKS[1] & FILES[2]
                c1 = RANKS[1] & FILES[3]
                d1 = RANKS[1] & FILES[4]
                index_c1 = trailing_zeros(c1) + 1
                if(d1 & empty != 0)
                    if(c1 & empty != 0)
                        if(b1 & empty != 0)
                        #Every square for castling queenside is empty
                        push!(moves, (index, index_c1, 1, 0, false, 2, false, false))
                        end
                    end
                end
            end
        end
        #QUEEN MOVES
        if(w_queens != 0)
            temp = w_queens
            for i=1:count_ones(w_queens)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getQueenAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & black_occ
                quiet_moves = attacks & ~black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 2, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 2, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #BISHOP MOVES
        if(w_bishops != 0)
            temp = w_bishops
            for i=1:count_ones(w_bishops)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getBishopAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & black_occ
                quiet_moves = attacks & ~black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 3, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 3, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #KNIGHT MOVES
        if(w_knights != 0)
            temp = w_knights
            for i=1:count_ones(w_knights)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getKnightAttacks(index) & enemyOrEmpty
                captures = attacks & black_occ
                quiet_moves = attacks & ~black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 4, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 4, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #ROOK MOVES
        if(w_rooks != 0)
            temp = w_rooks
            for i=1:count_ones(w_rooks)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getRookAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & black_occ
                quiet_moves = attacks & ~black_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 5, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 5, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #PAWN MOVES
        if(w_pawns != 0)
            temp = w_pawns
            for i=1:count_ones(w_pawns)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                
                # Pawn attacks handling, promotion with capture is taken care
                attacks = white_pawn_attacks(index) & black_occ
                last_rank_attacks = attacks & RANKS[8]
                normal_attacks = attacks & ~RANKS[8]

                enpassant = white_pawn_attacks(index) & BITTYBOARDS[1]

                    if(enpassant != 0)
                        index2 = trailing_zeros(enpassant) + 1
                        push!(moves, (index, index2, 6, 0, true, 0, false, true))
                    end

                    if(last_rank_attacks != 0)
                    temp2 = last_rank_attacks
                        for j=1:count_ones(last_rank_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            push!(moves, (index, index2, 6, 2, false, 0, false, true))
                            push!(moves, (index, index2, 6, 3, false, 0, false, true))
                            push!(moves, (index, index2, 6, 4, false, 0, false, true))
                            push!(moves, (index, index2, 6, 5, false, 0, false, true))
                        end
                    end
                    if(normal_attacks != 0)
                        temp2 = normal_attacks
                        for k=1:count_ones(normal_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            push!(moves, (index, index2, 6, 0, false, 0, false, true))
                        end
                    end

                    #Pawn quiet moves
                    empty = ~(white_occ | black_occ)
                    pushes = (least_bit << 8 & empty) | (least_bit << 16 & empty & RANKS[4] & (empty << 8))
                    last_rank_push = RANKS[8] & pushes #only 1 bit or less
                    normal_push = ~RANKS[8] & pushes #only 2 bits or less
                    if(last_rank_push != 0)
                        index2 = trailing_zeros(last_rank_push) + 1
                        push!(moves, (index, index2, 6, 2, false, 0, false, false))
                        push!(moves, (index, index2, 6, 3, false, 0, false, false))
                        push!(moves, (index, index2, 6, 4, false, 0, false, false))
                        push!(moves, (index, index2, 6, 5, false, 0, false, false))
                    end
                    if(normal_push != 0)
                        temp2 = normal_push
                        for j=1:count_ones(normal_push)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            if(least_bit2 & RANKS[4] != 0) #Potential double push or push to rank 4
                                if(least_bit & RANKS[2] != 0) #Double Push
                                    push!(moves, (index, index2, 6, 0, false, 0, true, false))
                                else #single push to rank 4
                                    push!(moves, (index, index2, 6, 0, false, 0, false, false))
                                end
                            else #single push, not to rank 4, not to rank 8
                                push!(moves, (index, index2, 6, 0, false, 0, false, false))
                            end
                            temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

    else #BLACK turn

        
        enemyOrEmpty = ~black_occ

        #KING MOVES
        if(b_king != 0)
            empty = ~(black_occ | white_occ)
            index = trailing_zeros(b_king) + 1
            attacks = getKingAttacks(index) & enemyOrEmpty
            captures = attacks & white_occ
            quiet_moves = attacks & ~white_occ
            if(captures != 0)
                temp2 = captures
                    for i=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 7, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
            end
            if(quiet_moves != 0)
                temp2 = quiet_moves
                        for j=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 7, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
            end
            if(GAMESTATE[7] == true) #check if pseudo-legal castling kingside is possible. (given or updated information about history moves of king and rooks)
                f8 = RANKS[8] & FILES[6]
                g8 = RANKS[8] & FILES[7]
                index_g8 = trailing_zeros(g8) + 1
                if(f8 & empty != 0)
                    if(g8 & empty != 0)
                        #Every square for castling kingside is empty
                        push!(moves, (index, index_g8, 7, 0, false, 1, false, false))
                    end
                end
            end
            if(GAMESTATE[8] == true)
                b8 = RANKS[8] & FILES[2]
                c8 = RANKS[8] & FILES[3]
                d8 = RANKS[8] & FILES[4]
                index_c8 = trailing_zeros(c8) + 1
                if(d8 & empty != 0)
                    if(c8 & empty != 0)
                        if(b8 & empty != 0)
                        #Every square for castling queenside is empty
                        push!(moves, (index, index_c8, 7, 0, false, 2, false, false))
                        end
                    end
                end
            end
        end
        #QUEEN MOVES
        if(b_queens != 0)
            temp = b_queens
            for i=1:count_ones(b_queens)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getQueenAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & white_occ
                quiet_moves = attacks & ~white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 8, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 8, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #BISHOP MOVES
        if(b_bishops != 0)
            temp = b_bishops
            for i=1:count_ones(b_bishops)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getBishopAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & white_occ
                quiet_moves = attacks & ~white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 9, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 9, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #KNIGHT MOVES
        if(b_knights != 0)
            temp = b_knights
            for i=1:count_ones(b_knights)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getKnightAttacks(index) & enemyOrEmpty
                captures = attacks & white_occ
                quiet_moves = attacks & ~white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 10, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 10, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #ROOK MOVES
        if(b_rooks != 0)
            temp = b_rooks
            for i=1:count_ones(b_rooks)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                attacks = getRookAttacks(BITBOARDS, index) & enemyOrEmpty
                captures = attacks & white_occ
                quiet_moves = attacks & ~white_occ
                if(captures != 0)
                temp2 = captures
                    for j=1:count_ones(captures)
                    least_bit2 = leastSignificantBit(temp2)
                    index2 = trailing_zeros(least_bit2) + 1
                    push!(moves, (index, index2, 11, 0, false, 0, false, true))
                    temp2 &= ~least_bit2
                    end
                end
                if(quiet_moves != 0)
                    temp2 = quiet_moves
                        for k=1:count_ones(quiet_moves)
                        least_bit2 = leastSignificantBit(temp2)
                        index2 = trailing_zeros(least_bit2) + 1
                        push!(moves, (index, index2, 11, 0, false, 0, false, false))
                        temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end

        #PAWN MOVES
        if(b_pawns != 0)
            temp = b_pawns
            for i=1:count_ones(b_pawns)
                least_bit = leastSignificantBit(temp)
                index = trailing_zeros(least_bit) + 1
                
                # Pawn attacks handling, promotion with capture is taken care
                attacks = black_pawn_attacks(index) & white_occ
                last_rank_attacks = attacks & RANKS[1]
                normal_attacks = attacks & ~RANKS[1]

                enpassant = black_pawn_attacks(index) & BITTYBOARDS[1]

                    if(enpassant != 0)
                        index2 = trailing_zeros(enpassant) + 1
                        push!(moves, (index, index2, 12, 0, true, 0, false, true))
                    end

                    if(last_rank_attacks != 0)
                    temp2 = last_rank_attacks
                        for j=1:count_ones(last_rank_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            push!(moves, (index, index2, 12, 8, false, 0, false, true))
                            push!(moves, (index, index2, 12, 9, false, 0, false, true))
                            push!(moves, (index, index2, 12, 10, false, 0, false, true))
                            push!(moves, (index, index2, 12, 11, false, 0, false, true))
                        end
                    end
                    if(normal_attacks != 0)
                        temp2 = normal_attacks
                        for k=1:count_ones(normal_attacks)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            temp2 &= ~least_bit2
                            push!(moves, (index, index2, 12, 0, false, 0, false, true))
                        end
                    end

                    #Pawn quiet moves
                    empty = ~(white_occ | black_occ)
                    pushes = (least_bit >> 8 & empty) | (least_bit >> 16 & empty & RANKS[5] & (empty >> 8))
                    last_rank_push = RANKS[1] & pushes #only 1 bit or less
                    normal_push = ~RANKS[1] & pushes #only 2 bits or less
                    if(last_rank_push != 0)
                        index2 = trailing_zeros(last_rank_push) + 1
                        push!(moves, (index, index2, 12, 8, false, 0, false, false))
                        push!(moves, (index, index2, 12, 9, false, 0, false, false))
                        push!(moves, (index, index2, 12, 10, false, 0, false, false))
                        push!(moves, (index, index2, 12, 11, false, 0, false, false))
                    end
                    if(normal_push != 0)
                        temp2 = normal_push
                        for j=1:count_ones(normal_push)
                            least_bit2 = leastSignificantBit(temp2)
                            index2 = trailing_zeros(least_bit2) + 1
                            if(least_bit2 & RANKS[5] != 0) #Potential double push or push to rank 5
                                if(least_bit & RANKS[7] != 0) #Double Push
                                    push!(moves, (index, index2, 12, 0, false, 0, true, false))
                                else #single push to rank 5
                                    push!(moves, (index, index2, 12, 0, false, 0, false, false))
                                end
                            else #single push, not to rank 5, not to rank 1
                                push!(moves, (index, index2, 12, 0, false, 0, false, false))
                            end
                            temp2 &= ~least_bit2
                        end
                    end
                temp &= ~least_bit
            end
        end


    end
    return moves
end


# Makes a move on given bitboards, gamestate and move encoded and returns updated bitboards
function makeMove(BITBOARDS, GAMESTATE, BITTYBOARDS, MOVE)
        a1 = RANKS[1] & FILES[1]
        h1 = RANKS[1] & FILES[8] #for castling updates
        a8 = RANKS[8] & FILES[1]
        h8 = RANKS[8] & FILES[8]

        source = SQUARES_TO_BITBOARDS[MOVE[1]]
        target = SQUARES_TO_BITBOARDS[MOVE[2]]

    if (GAMESTATE[2] == WHITE)
        if(MOVE[3] == 1) # white king
                BITBOARDS[1] = target # king goes to target square, works also for castling
                GAMESTATE[5] = false #We moved the king so castling rights are lost
                GAMESTATE[6] = false
            if(MOVE[8] == true) # capture
                for i=7:12 # remove piece from black bitboards
                BITBOARDS[i] = BITBOARDS[i] & ~target
                end
            end
            if(MOVE[6] == 1)
                BITBOARDS[5] = (BITBOARDS[5] & (~h1)) | (RANKS[1] & FILES[6]) #Takes rook from h1 to f1
            end
            if(MOVE[6] == 2)
                BITBOARDS[5] = (BITBOARDS[5] & (~a1)) | (RANKS[1] & FILES[4]) #Takes rook from a1 to d1
            end
        end

        if(MOVE[3] == 2) # white queen
            BITBOARDS[2] = (BITBOARDS[2] | target) & ~source # queen goes from sourcesquare to targetsquare
        if(MOVE[8] == true) # capture
            for i=7:12 # remove piece from black bitboards
            BITBOARDS[i] = BITBOARDS[i] & ~target
            end
        end
        end

        if(MOVE[3] == 3) # white bishop
            BITBOARDS[3] = (BITBOARDS[3] | target) & ~source # bishop goes from sourcesquare to targetsquare
        if(MOVE[8] == true) # capture
            for i=7:12 # remove piece from black bitboards
            BITBOARDS[i] = BITBOARDS[i] & ~target
            end
        end
        end

        if(MOVE[3] == 4) # white knight
            BITBOARDS[4] = (BITBOARDS[4] | target) & ~source # knight goes from sourcesquare to targetsquare
        if(MOVE[8] == true) # capture
            for i=7:12 # remove piece from black bitboards
            BITBOARDS[i] = BITBOARDS[i] & ~target
            end
        end
        end

            if(MOVE[3] == 5) # white rook

                #castling update for white
                if(source & a1 != 0) #Queenside
                   GAMESTATE[6] = false
                end
                if(source & h1 != 0) #Kingside
                   GAMESTATE[5] = false
                end

            BITBOARDS[5] = (BITBOARDS[5] | target) & ~source # rook goes from sourcesquare to targetsquare
                if(MOVE[8] == true) # capture
                    for i=7:12 # remove piece from black bitboards
                    BITBOARDS[i] = BITBOARDS[i] & ~target
                    end
                end
            end


            if(MOVE[3] == 6) # white pawn

                BITBOARDS[6] = BITBOARDS[6] & ~source # pawn disappears from source square
                if(MOVE[8] == true) # capture
                    if(MOVE[5] == true)
                        enpassant = BITTYBOARDS[1]
                        for i=7:12 # remove piece from black bitboards ENPASSANT case
                        BITBOARDS[i] = BITBOARDS[i] & ~(enpassant >> 8)
                        end
                    else
                        for i=7:12 # remove piece from black bitboards normal case
                            BITBOARDS[i] = BITBOARDS[i] & ~target
                            end
                    end
                end
                if(MOVE[4] != 0)#PROMOTION, updates the relative bitboard with new piece
                    BITBOARDS[MOVE[4]] |= target
                else
                    BITBOARDS[6] = BITBOARDS[6] | target
                end

            end

            if(MOVE[7] == true)#double push case: we update enpassant bittyboard with the square behind the pawn
                BITTYBOARDS[1] = source << 8
            else# if not double push then set enpassant bitboard to zero
                BITTYBOARDS[1] = 0b0000000000000000000000000000000000000000000000000000000000000000
            end


            #Updates castling for black in case of h8 a8 invasion
            if(target & a8 != 0)#Queenside
                GAMESTATE[8] = false
            end
            if(target & h8 != 0)#Kingside
                GAMESTATE[7] = false
            end

            GAMESTATE[2] = BLACK

    else #BLACK TURN

        if(MOVE[3] == 7) # black king
            BITBOARDS[7] = target # king goes to target square, works also for castling
            GAMESTATE[7] = false #We moved the king so castling rights are lost
            GAMESTATE[8] = false
        if(MOVE[8] == true) # capture
            for i=1:6 # remove piece from black bitboards
            BITBOARDS[i] = BITBOARDS[i] & ~target
            end
        end
        if(MOVE[6] == 1)
            BITBOARDS[11] = (BITBOARDS[11] & (~h8)) | (RANKS[8] & FILES[6]) #Takes rook from h8 to f8
        end
        if(MOVE[6] == 2)
            BITBOARDS[11] = (BITBOARDS[11] & (~a8)) | (RANKS[8] & FILES[4]) #Takes rook from a8 to d8
        end
    end

    if(MOVE[3] == 8) # black queen
        BITBOARDS[8] = (BITBOARDS[8] | target) & ~source # queen goes from sourcesquare to targetsquare
    if(MOVE[8] == true) # capture
        for i=1:6 # remove piece from black bitboards
        BITBOARDS[i] = BITBOARDS[i] & ~target
        end
    end
    end

    if(MOVE[3] == 9) # black bishop
        BITBOARDS[9] = (BITBOARDS[9] | target) & ~source # bishop goes from sourcesquare to targetsquare
    if(MOVE[8] == true) # capture
        for i=1:6 # remove piece from black bitboards
        BITBOARDS[i] = BITBOARDS[i] & ~target
        end
    end
    end

    if(MOVE[3] == 10) # black knight
        BITBOARDS[10] = (BITBOARDS[10] | target) & ~source # knight goes from sourcesquare to targetsquare
    if(MOVE[8] == true) # capture
        for i=1:6 # remove piece from black bitboards
        BITBOARDS[i] = BITBOARDS[i] & ~target
        end
    end
    end

        if(MOVE[3] == 11) # black rook

            #castling update for black
            if(source & a8 != 0) #Queenside
               GAMESTATE[8] = false
            end
            if(source & h8 != 0) #Kingside
               GAMESTATE[7] = false
            end

        BITBOARDS[11] = (BITBOARDS[11] | target) & ~source # rook goes from sourcesquare to targetsquare
            if(MOVE[8] == true) # capture
                for i=1:6 # remove piece from black bitboards
                BITBOARDS[i] = BITBOARDS[i] & ~target
                end
            end
        end


        if(MOVE[3] == 12) # black pawn

            BITBOARDS[12] = BITBOARDS[12] & ~source # pawn disappears from source square
            if(MOVE[8] == true) # capture
                if(MOVE[5] == true)
                    enpassant = BITTYBOARDS[1]
                    for i=1:6 # remove piece from black bitboards ENPASSANT case
                    BITBOARDS[i] = BITBOARDS[i] & ~(enpassant << 8)
                    end
                else
                    for i=1:6 # remove piece from black bitboards normal case
                        BITBOARDS[i] = BITBOARDS[i] & ~target
                        end
                end
            end
            if(MOVE[4] != 0)#PROMOTION, updates the relative bitboard with new piece
                BITBOARDS[MOVE[4]] |= target
            else
                BITBOARDS[12] = BITBOARDS[12] | target
            end

        end

        if(MOVE[7] == true)#double push case: we update enpassant bittyboard with the square behind the pawn
            BITTYBOARDS[1] = target << 8
        else# if not double push then set enpassant bitboard to zero
            BITTYBOARDS[1] = 0b0000000000000000000000000000000000000000000000000000000000000000
        end


        #Updates castling for white in case of h8 a8 invasion
        if(target & a1 != 0)#Queenside
            GAMESTATE[6] = false
        end
        if(target & h1 != 0)#Kingside
            GAMESTATE[5] = false
        end

        GAMESTATE[2] = WHITE

    end
    return [BITBOARDS, GAMESTATE, BITTYBOARDS]
end


function doMove(MOVE)
    makeMove(getBitBoards(), getGameState(), getBittyBoards(), MOVE)
    printBoard()
end

#First legal moves generator.
function goFullLegal(BITBOARDS, GAMESTATE, BITTYBOARDS)
    legal_moves = []
    pseudo_moves = goFullPseudo(BITBOARDS, GAMESTATE, BITTYBOARDS)
    for i=1:length(pseudo_moves)
        var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), pseudo_moves[i])
        if(!isKingInCheck(var[1] , GAMESTATE[2]))
            if(pseudo_moves[i][6] != 0) #Castles
                if(pseudo_moves[i][3] == 1) #White king
                    if(pseudo_moves[i][6] == 1) #kingside white -> f1
                        if(!isSquareAttacked(BITBOARDS, RANKS[1] & FILES[6], WHITE))
                            if(!isSquareAttacked(BITBOARDS, BITBOARDS[1], WHITE))
                            push!(legal_moves, pseudo_moves[i])
                            end
                        end
                    else #queenside white -> d1
                        if(!isSquareAttacked(BITBOARDS, RANKS[1] & FILES[4], WHITE))
                            if(!isSquareAttacked(BITBOARDS, BITBOARDS[1], WHITE))
                            push!(legal_moves, pseudo_moves[i])
                            end
                        end
                    end
                else #Black King
                    if(pseudo_moves[i][6] == 1) #kingside black -> f8
                        if(!isSquareAttacked(BITBOARDS, RANKS[8] & FILES[6], BLACK))
                            if(!isSquareAttacked(BITBOARDS, BITBOARDS[7], BLACK))
                            push!(legal_moves, pseudo_moves[i])
                            end
                        end
                    else #queenside white -> d8
                        if(!isSquareAttacked(BITBOARDS, RANKS[8] & FILES[4], BLACK))
                            if(!isSquareAttacked(BITBOARDS, BITBOARDS[7], BLACK))
                            push!(legal_moves, pseudo_moves[i])
                            end
                        end
                    end
                end
            else
            push!(legal_moves, pseudo_moves[i])
            end
        end
    end
    return legal_moves
end

"""
    perft(bitboards, gamestate, bittyboards, depth)

Conta le posizioni raggiungibili fino a `depth` mosse legali.


RISULTATI OTTENUTI:
https://www.chessprogramming.org/Perft_Results
Per ora depth limitate perchè il generatore è lento, ma migliorabile...
Per ora MAX: 119 milioni di posizioni valutate
Starting Position: ok fino a depth 6
Kiwipete Position: ok fino a depth 5
Position 3: ok fino a depth 6
Position 4: ok fino a depth 5
Position 5: ok fino a depth 4
Position 6: 
"""
function perft(BITBOARDS, GAMESTATE, BITTYBOARDS, depth)
    depth == 0 && return 1
    nodes = 0
    legal_moves = goFullLegal(BITBOARDS, GAMESTATE, BITTYBOARDS)

    if(isempty(legal_moves))
        return 0
    end

    for move in legal_moves
        var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
        nodes += perft(var[1], var[2], var[3], depth - 1)
    end
    return nodes
end

"""
nuovi perft
"""
##################################################################


function divide_perft(BITBOARDS, GAMESTATE, BITTYBOARDS, depth)
    legal_moves = goFullLegal(BITBOARDS, GAMESTATE, BITTYBOARDS)
    total_nodes = 0

    for move in legal_moves
        var = makeMove(copy(BITBOARDS), copy(GAMESTATE), copy(BITTYBOARDS), move)
        nodes = perft(var[1], var[2], var[3], depth - 1)
        println(BITSQUARES_TO_NOTATION[SQUARES_TO_BITBOARDS[move[1]]], "-", BITSQUARES_TO_NOTATION[SQUARES_TO_BITBOARDS[move[2]]], "$move: $nodes")
        total_nodes += nodes
    end

    println("Total nodes: $total_nodes")
end


##################################################################




function isSquareAttacked(BITBOARDS, BITSQUARE, COLOR)
    if(COLOR == WHITE)
        index = trailing_zeros(BITSQUARE) + 1
        if(getKnightAttacks(index) & BITBOARDS[10] != 0)
            return true
        end
        if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[9]) != 0)
            return true
        end
        if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[11]) != 0)
            return true
        end
        if(white_pawn_attacks(index) & BITBOARDS[12] != 0)
            return true
        end
        if(getKingAttacks(index) & BITBOARDS[7] != 0)
            return true
        end
    else
        index = trailing_zeros(BITSQUARE) + 1
        if(getKnightAttacks(index) & BITBOARDS[4] != 0)
            return true
        end
        if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[3] | BITBOARDS[2]) != 0)
            return true
        end
        if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[5] | BITBOARDS[2]) != 0)
            return true
        end
        if(black_pawn_attacks(index) & BITBOARDS[6] != 0)
            return true
        end
        if(getKingAttacks(index) & BITBOARDS[1] != 0)
            return true
        end
    end
    return false
end

#Run only if exists a king. Determines if the king is in check. No other flags
function isKingInCheck(BITBOARDS, COLOR)
        if(COLOR == WHITE)
            index = trailing_zeros(BITBOARDS[1]) + 1
            if(getKnightAttacks(index) & BITBOARDS[10] != 0)
                return true
            end
            if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[9]) != 0)
                return true
            end
            if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[11]) != 0)
                return true
            end
            if(white_pawn_attacks(index) & BITBOARDS[12] != 0)
                return true
            end
            if(getKingAttacks(index) & BITBOARDS[7] != 0)
                return true
            end
        else
            index = trailing_zeros(BITBOARDS[7]) + 1
            if(getKnightAttacks(index) & BITBOARDS[4] != 0)
                return true
            end
            if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[3] | BITBOARDS[2]) != 0)
                return true
            end
            if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[5] | BITBOARDS[2]) != 0)
                return true
            end
            if(black_pawn_attacks(index) & BITBOARDS[6] != 0)
                return true
            end
            if(getKingAttacks(index) & BITBOARDS[1] != 0)
                return true
            end
        end
        return false
end

function checkersAmount(BITBOARDS, GAMESTATE)
    count = 0
        if(GAMESTATE[2] == WHITE)
            index = trailing_zeros(BITBOARDS[1]) + 1
            if(getKnightAttacks(index) & BITBOARDS[10] != 0)
                count += count_ones(getKnightAttacks(index) & BITBOARDS[10])
            end
            if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[9]) != 0)
                count += count_ones(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[9]))
            end
            if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[11]) != 0)
                count += count_ones(getRookAttacks(BITBOARDS, index) & (BITBOARDS[8] | BITBOARDS[11]))
            end
            if(white_pawn_attacks(index) & BITBOARDS[12] != 0)
                count += count_ones(white_pawn_attacks(index) & BITBOARDS[12])
            end
        else
            index = trailing_zeros(BITBOARDS[7]) + 1
            if(getKnightAttacks(index) & BITBOARDS[4] != 0)
                count += count_ones(getKnightAttacks(index) & BITBOARDS[4])
            end
            if(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[3] | BITBOARDS[2]) != 0)
                count += count_ones(getBishopAttacks(BITBOARDS, index) & (BITBOARDS[3] | BITBOARDS[2]))
            end
            if(getRookAttacks(BITBOARDS, index) & (BITBOARDS[5] | BITBOARDS[2]) != 0)
                count += count_ones(getRookAttacks(BITBOARDS, index) & (BITBOARDS[5] | BITBOARDS[2]))
            end
            if(black_pawn_attacks(index) & BITBOARDS[6] != 0)
                count += count_ones(black_pawn_attacks(index) & BITBOARDS[6])
            end 
        end
        return count
end

function getRookAttacks(BITBOARDS, id)::UInt64
    occ = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6] | BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
    relevant_occupancy = occ & ECO_ROOK_MASKS_BY_ID[id]
    magic_index = Int((relevant_occupancy * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
    return ROOK_ATTACKS[id][magic_index + 1]
end

# Functions that returns every possible pseudo-legal target square for a bishop
# It doesn't handle Allies and Pins
function getBishopAttacks(BITBOARDS, id)::UInt64
    occ = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6] | BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
    relevant_occupancy = occ & ECO_BISHOP_MASKS_BY_ID[id]
    magic_index = Int((relevant_occupancy * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
    return BISHOP_ATTACKS[id][magic_index + 1]
end

# Functions that returns every possible pseudo-legal target square for a queen
# It doesn't handle Allies and Pins
function getQueenAttacks(BITBOARDS, id)::UInt64
    return getBishopAttacks(BITBOARDS, id) | getRookAttacks(BITBOARDS, id)
end

# Functions that returns every possible pseudo-legal target square for a knight
# It doesn't handle Allies and Pins
function getKingAttacks(id)::UInt64
    return KING_MASKS_BY_ID[id]
end

# Functions that returns every possible pseudo-legal target square for the king
# It doesn't handle Allies and Safe Squares
function getKnightAttacks(id)::UInt64
    return KNIGHT_MASKS_BY_ID[id]
end

# Functions that returns attack pseudo-legal target square for the white pawn
# It doesn't handle Allies and Pins
# TODO: last rank captures (promotion)
function white_pawn_attacks(id)::UInt64
    return W_PAWN_ATTACKS_BY_ID[id]
end

# Functions that returns attack pseudo-legal target square for the black pawn
# It doesn't handle Allies and Pins
# TODO: last rank captures (promotion)
function black_pawn_attacks(id)::UInt64
    return B_PAWN_ATTACKS_BY_ID[id]
end

function w_pawns_shift(BITBOARDS)
    occ_black = BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
    occ_white = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6]
    empty = ~(occ_black | occ_white)
    return (BITBOARDS[6] << 8 & empty) | (BITBOARDS[6] << 16 & empty & RANKS[4] & (empty << 8))
end

function b_pawns_shift(BITBOARDS)
    occ_black = BITBOARDS[7] | BITBOARDS[8] | BITBOARDS[9] | BITBOARDS[10] | BITBOARDS[11] | BITBOARDS[12]
    occ_white = BITBOARDS[1] | BITBOARDS[2] | BITBOARDS[3] | BITBOARDS[4] | BITBOARDS[5] | BITBOARDS[6]
    empty = ~(occ_black | occ_white)
    return (BITBOARDS[12] >> 8 & empty) | (BITBOARDS[12] >> 16 & empty & RANKS[5] & (empty >> 8))
end


#############################################################################################################################################################
#############################################################################################################################################################
#############################################################################################################################################################


# This function was a test, but it is incomplete and contains bugs
# main function that generates and formats list of legal moves
# TODO: everything
function generateMoves()
    moves = []
    if(getTurnGameState() == WHITE)
        if(isSquareAttackedByBlack(getWhiteKing()) == true)
            #We are in check
            gameState[9] = true
            if(isWhiteInDoubleCheck() == true)
                possible_moves = getKingAttacks(getWhiteKing()) & ~getWhiteOccupancies()
                for i = 1:count_ones(possible_moves)
                    least_bitsquare = leastSignificantBit(possible_moves)
                    if(isSquareAttackedByBlack(least_bitsquare) == true)
                    possible_moves &= ~least_bitsquare
                    end
                end
                push!(moves, (getWhiteKing(), possible_moves))
                if(possible_moves == 0)
                    #Checkmate: black wins -> decisive == true and winner == BLACK
                    gameState[3] = true
                    gameState[4] = BLACK
                    println("Checkmate: Black wins!")
                end
            else
            println("scacco singolo")
            king_id = trailing_zeros(getWhiteKing()) + 1
            #Horse Attack on king: we can move the king or capture the knight. We CANNOT interpose a piece or pawn.
            enemies = getEnemyAttackersOnSquare(getWhiteKing(), BLACK)
                if(enemies & getBlackKnights() != 0)
                    pseudo_legal_king_moves = KING_MASKS_BY_ID[king_id]
                    legal_king_moves = 0x0000000000000000
                    count_to = count_ones(pseudo_legal_king_moves)
                    for i=1:count_to
                        least_bit = leastSignificantBit(pseudo_legal_king_moves)
                        if(!isSquareAttackedByBlack(least_bit))
                        legal_king_moves |= least_bit
                        end
                        pseudo_legal_king_moves &= ~least_bit
                    end
                push!(moves, (getWhiteKing(), legal_king_moves)) #mosse legali del re
                #We have to look for source of check to determine if we can or cannot capture
                white_capture_squad = getEnemyAttackersOnSquare(enemies, WHITE)
                    if(white_capture_squad != 0)
                    #Eventual pins. We handle them before everything else for now. Maybe we will change later




                    queen_att1 = getQueenAttacks(getWhiteKing())
                    pinned_candidates = queen_att1 & white_capture_squad & ~getWhiteKing()
                    pinned_pieces = 0x0000000000000000
                    enemy_peaceful = queen_att1 & getBlackOccupancies()
                        if(pinned_candidates != 0)
                        #We eliminate potential pinned pieces and generate again queen moves from the king position.
                        #Then we intersect with Enemy occupancies and with ~enemy_peaceful
                        id = trailing_zeros(getWhiteKing()) + 1
                        relevant_occ = getOccupancies() & ~getWhiteKing() & ~pinned_candidates
                        magicB_index = Int(((relevant_occ & ECO_BISHOP_MASKS_BY_ID[id]) * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
                        magicR_index = Int(((relevant_occ & ECO_ROOK_MASKS_BY_ID[id]) * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
                        dangerous_enemy = (~enemy_peaceful & (BISHOP_ATTACKS[id][magicB_index + 1] | ROOK_ATTACKS[id][magicR_index + 1]) & (getBlackBishops() | getBlackQueens() | getBlackRooks()))
                            if(dangerous_enemy != 0)
                                for i = 1:count_ones(dangerous_enemy)
                                printBitBoard(dangerous_enemy)
                                bitsquare = leastSignificantBit(dangerous_enemy)
                                kingDAD = BITSQUARES_TO_DAD[getWhiteKing()]
                                dangerDAD = BITSQUARES_TO_DAD[bitsquare]
                                    if(dangerDAD[1] == kingDAD[1])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = DIAGONALS[kingDAD[1]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (DIAGONALS[kingDAD[1]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        println("------------------------------")
                                        printBitBoard(pinned_piece)
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & enemies
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una diagonale")

                                        end
                                    end
                                    if(dangerDAD[2] == kingDAD[2])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = ANTI_DIAGONALS[kingDAD[2]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (ANTI_DIAGONALS[kingDAD[2]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & enemies
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una antidiagonale")
                                        end
                                    end
                                    kingCords = BITSQUARES_TO_COORDINATES[getWhiteKing()]
                                    dangerCords = BITSQUARES_TO_COORDINATES[bitsquare]
                                    if(dangerCords[1] == kingCords[1])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                        rook_ray = getRookAttacks(bitsquare)
                                        pinned_piece = RANKS[kingCords[1]] & pinned_candidates & rook_ray
                                        legal_mask_for_pinned_piece = (RANKS[kingCords[1]] & rook_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & enemies
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su un riga")
                                        end
                                    end
                                    if(dangerCords[2] == kingCords[2])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                            rook_ray = getRookAttacks(bitsquare)
                                            pinned_piece = RANKS[kingCords[2]] & pinned_candidates & rook_ray
                                            println(pinned_piece)
                                            legal_mask_for_pinned_piece = (RANKS[kingCords[2]] & rook_ray) | bitsquare
                                            pinned_pieces |= pinned_piece
                                            legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & enemies
                                            push!(moves, (pinned_piece, legal_moves))
                                            println("pin su un colonna")
                                        end
                                    end
                                end
                            end

                        end

                    enemyOrEmpty = ~getWhiteOccupancies()
                    occ = white_capture_squad & ~pinned_pieces
                    while(occ != 0b0)
                    piece = leastSignificantBit(occ)
                    id = trailing_zeros(piece) + 1
                    index = getBitBoardsIndex(piece)
                        if(index == 1)
                            push!(moves, (piece, KING_MASKS_BY_ID[id] & enemyOrEmpty & enemies))
                        elseif(index == 2)
                            push!(moves, (piece, getQueenAttacks(piece) & enemyOrEmpty & enemies))
                        elseif(index ==3)
                            push!(moves, (piece, getBishopAttacks(piece) & enemyOrEmpty & enemies))
                        elseif(index == 4)
                            push!(moves, (piece, KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty & enemies))
                        elseif(index == 5)
                            push!(moves, (piece, getRookAttacks(piece) & enemyOrEmpty & enemies))
                        elseif(index==6)
                            push!(moves, (piece, (W_PAWN_ATTACKS_BY_ID[id] & enemies)))
                        end
            occ &= ~piece
                    end
                    end   

                else #Single check and it is not a knight, so we have to identify the direction of check. Infact in this case we can block the check.
                    if(enemies & getBlackBishops() != 0)

                        pseudo_legal_king_moves = KING_MASKS_BY_ID[king_id]
                    legal_king_moves = 0x0000000000000000
                    count_to = count_ones(pseudo_legal_king_moves)
                    for i=1:count_to
                        least_bit = leastSignificantBit(pseudo_legal_king_moves)
                        if(!isSquareAttackedByBlack(least_bit))
                        legal_king_moves |= least_bit
                        end
                        pseudo_legal_king_moves &= ~least_bit
                    end
                push!(moves, (getWhiteKing(), legal_king_moves)) #mosse legali del re
                #We have to look for source of check to determine if we can or cannot capture
                squares_to_block = (getBishopAttacks(enemies) | enemies) & (DIAGONALS[BITSQUARES_TO_DAD[getWhiteKing()][1]] | ANTI_DIAGONALS[BITSQUARES_TO_DAD[getWhiteKing()][2]])
                squares_to_block_temp = squares_to_block
                    white_squad = 0x0000000000000000
                    count_to = count_ones(squares_to_block)
                    for i=1:count_to
                        least_bit = leastSignificantBit(squares_to_block_temp)
                        white_squad |= getEnemyAttackersOnSquare(least_bit, WHITE)
                        squares_to_block_temp &= ~least_bit
                    end
                    white_squad &= ~getWhiteKing()
                    if(white_squad != 0)
                    #Eventual pins. We handle them before everything else for now. Maybe we will change later
                    queen_att1 = getQueenAttacks(getWhiteKing())
                    pinned_candidates = queen_att1 & white_squad & ~getWhiteKing()
                    pinned_pieces = 0x0000000000000000
                    enemy_peaceful = queen_att1 & getBlackOccupancies()
                        if(pinned_candidates != 0)
                        #We eliminate potential pinned pieces and generate again queen moves from the king position.
                        #Then we intersect with Enemy occupancies and with ~enemy_peaceful
                        id = trailing_zeros(getWhiteKing()) + 1
                        relevant_occ = getOccupancies() & ~getWhiteKing() & ~pinned_candidates
                        magicB_index = Int(((relevant_occ & ECO_BISHOP_MASKS_BY_ID[id]) * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
                        magicR_index = Int(((relevant_occ & ECO_ROOK_MASKS_BY_ID[id]) * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
                        dangerous_enemy = (~enemy_peaceful & (BISHOP_ATTACKS[id][magicB_index + 1] | ROOK_ATTACKS[id][magicR_index + 1]) & (getBlackBishops() | getBlackQueens() | getBlackRooks()))
                            if(dangerous_enemy != 0)
                                for i = 1:count_ones(dangerous_enemy)
                                printBitBoard(dangerous_enemy)
                                bitsquare = leastSignificantBit(dangerous_enemy)
                                kingDAD = BITSQUARES_TO_DAD[getWhiteKing()]
                                dangerDAD = BITSQUARES_TO_DAD[bitsquare]
                                    if(dangerDAD[1] == kingDAD[1])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = DIAGONALS[kingDAD[1]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (DIAGONALS[kingDAD[1]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        println("------------------------------")
                                        printBitBoard(pinned_piece)
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una diagonale")

                                        end
                                    end
                                    if(dangerDAD[2] == kingDAD[2])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = ANTI_DIAGONALS[kingDAD[2]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (ANTI_DIAGONALS[kingDAD[2]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una antidiagonale")
                                        end
                                    end
                                    kingCords = BITSQUARES_TO_COORDINATES[getWhiteKing()]
                                    dangerCords = BITSQUARES_TO_COORDINATES[bitsquare]
                                    if(dangerCords[1] == kingCords[1])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                        rook_ray = getRookAttacks(bitsquare)
                                        pinned_piece = RANKS[kingCords[1]] & pinned_candidates & rook_ray
                                        legal_mask_for_pinned_piece = (RANKS[kingCords[1]] & rook_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su un riga")
                                        end
                                    end
                                    if(dangerCords[2] == kingCords[2])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                            rook_ray = getRookAttacks(bitsquare)
                                            pinned_piece = RANKS[kingCords[2]] & pinned_candidates & rook_ray
                                            println(pinned_piece)
                                            legal_mask_for_pinned_piece = (RANKS[kingCords[2]] & rook_ray) | bitsquare
                                            pinned_pieces |= pinned_piece
                                            legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                            push!(moves, (pinned_piece, legal_moves))
                                            println("pin su un colonna")
                                        end
                                    end
                                end
                            end

                        end

                    enemyOrEmpty = ~getWhiteOccupancies()
                    occ = white_squad & ~pinned_pieces
                    while(occ != 0b0)
                    piece = leastSignificantBit(occ)
                    id = trailing_zeros(piece) + 1
                    index = getBitBoardsIndex(piece)
                        if(index == 1)
                            push!(moves, (piece, KING_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 2)
                            push!(moves, (piece, getQueenAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index ==3)
                            push!(moves, (piece, getBishopAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index == 4)
                            push!(moves, (piece, KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 5)
                            push!(moves, (piece, getRookAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index==6)
                            push!(moves, (piece, (W_PAWN_ATTACKS_BY_ID[id] & getBlackOccupancies() | (w_pawns_forward() & FILES[8 - ((id - 1)% 8)])) & squares_to_block))
                        end
            occ &= ~piece
                    end
                    end


                    end
                    if(enemies & getBlackQueens() != 0)


                        pseudo_legal_king_moves = KING_MASKS_BY_ID[king_id]
                    legal_king_moves = 0x0000000000000000
                    count_to = count_ones(pseudo_legal_king_moves)
                    for i=1:count_to
                        least_bit = leastSignificantBit(pseudo_legal_king_moves)
                        if(!isSquareAttackedByBlack(least_bit))
                        legal_king_moves |= least_bit
                        end
                        pseudo_legal_king_moves &= ~least_bit
                    end
                push!(moves, (getWhiteKing(), legal_king_moves)) #mosse legali del re
                #We have to look for source of check to determine if we can or cannot capture
                squares_to_block = (getQueenAttacks(enemies) | enemies) & (RANKS[BITSQUARES_TO_COORDINATES[getWhiteKing()][1]] | FILES[BITSQUARES_TO_COORDINATES[getWhiteKing()][2]])
                squares_to_block_temp = squares_to_block
                    white_squad = 0x0000000000000000
                    count_to = count_ones(squares_to_block)
                    for i=1:count_to
                        least_bit = leastSignificantBit(squares_to_block_temp)
                        white_squad |= getEnemyAttackersOnSquare(least_bit, WHITE)
                        squares_to_block_temp &= ~least_bit
                    end
                    white_squad &= ~getWhiteKing()
                    if(white_squad != 0)
                    #Eventual pins. We handle them before everything else for now. Maybe we will change later
                    queen_att1 = getQueenAttacks(getWhiteKing())
                    pinned_candidates = queen_att1 & white_squad & ~getWhiteKing()
                    pinned_pieces = 0x0000000000000000
                    enemy_peaceful = queen_att1 & getBlackOccupancies()
                        if(pinned_candidates != 0)
                        #We eliminate potential pinned pieces and generate again queen moves from the king position.
                        #Then we intersect with Enemy occupancies and with ~enemy_peaceful
                        id = trailing_zeros(getWhiteKing()) + 1
                        relevant_occ = getOccupancies() & ~getWhiteKing() & ~pinned_candidates
                        magicB_index = Int(((relevant_occ & ECO_BISHOP_MASKS_BY_ID[id]) * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
                        magicR_index = Int(((relevant_occ & ECO_ROOK_MASKS_BY_ID[id]) * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
                        dangerous_enemy = (~enemy_peaceful & (BISHOP_ATTACKS[id][magicB_index + 1] | ROOK_ATTACKS[id][magicR_index + 1]) & (getBlackBishops() | getBlackQueens() | getBlackRooks()))
                            if(dangerous_enemy != 0)
                                for i = 1:count_ones(dangerous_enemy)
                                printBitBoard(dangerous_enemy)
                                bitsquare = leastSignificantBit(dangerous_enemy)
                                kingDAD = BITSQUARES_TO_DAD[getWhiteKing()]
                                dangerDAD = BITSQUARES_TO_DAD[bitsquare]
                                    if(dangerDAD[1] == kingDAD[1])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = DIAGONALS[kingDAD[1]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (DIAGONALS[kingDAD[1]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        println("------------------------------")
                                        printBitBoard(pinned_piece)
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una diagonale")

                                        end
                                    end
                                    if(dangerDAD[2] == kingDAD[2])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = ANTI_DIAGONALS[kingDAD[2]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (ANTI_DIAGONALS[kingDAD[2]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una antidiagonale")
                                        end
                                    end
                                    kingCords = BITSQUARES_TO_COORDINATES[getWhiteKing()]
                                    dangerCords = BITSQUARES_TO_COORDINATES[bitsquare]
                                    if(dangerCords[1] == kingCords[1])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                        rook_ray = getRookAttacks(bitsquare)
                                        pinned_piece = RANKS[kingCords[1]] & pinned_candidates & rook_ray
                                        legal_mask_for_pinned_piece = (RANKS[kingCords[1]] & rook_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su un riga")
                                        end
                                    end
                                    if(dangerCords[2] == kingCords[2])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                            rook_ray = getRookAttacks(bitsquare)
                                            pinned_piece = RANKS[kingCords[2]] & pinned_candidates & rook_ray
                                            println(pinned_piece)
                                            legal_mask_for_pinned_piece = (RANKS[kingCords[2]] & rook_ray) | bitsquare
                                            pinned_pieces |= pinned_piece
                                            legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                            push!(moves, (pinned_piece, legal_moves))
                                            println("pin su un colonna")
                                        end
                                    end
                                end
                            end

                        end

                    enemyOrEmpty = ~getWhiteOccupancies()
                    occ = white_squad & ~pinned_pieces
                    while(occ != 0b0)
                    piece = leastSignificantBit(occ)
                    id = trailing_zeros(piece) + 1
                    index = getBitBoardsIndex(piece)
                        if(index == 1)
                            push!(moves, (piece, KING_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 2)
                            push!(moves, (piece, getQueenAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index ==3)
                            push!(moves, (piece, getBishopAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index == 4)
                            push!(moves, (piece, KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 5)
                            push!(moves, (piece, getRookAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index==6)
                            push!(moves, (piece, (W_PAWN_ATTACKS_BY_ID[id] & getBlackOccupancies() | (w_pawns_forward() & FILES[8 - ((id - 1)% 8)])) & squares_to_block))
                        end
            occ &= ~piece
                    end
                    end

                    end
                    if(enemies & getBlackRooks() != 0)




                        pseudo_legal_king_moves = KING_MASKS_BY_ID[king_id]
                    legal_king_moves = 0x0000000000000000
                    count_to = count_ones(pseudo_legal_king_moves)
                    for i=1:count_to
                        least_bit = leastSignificantBit(pseudo_legal_king_moves)
                        if(isSquareAttackedByBlack(least_bit))
                            pseudo_legal_king_moves &= ~least_bit
                            continue;
                        else
                        legal_king_moves |= least_bit
                        end
                        pseudo_legal_king_moves &= ~least_bit
                    end
                push!(moves, (getWhiteKing(), legal_king_moves)) #mosse legali del re
                #We have to look for source of check to determine if we can or cannot capture
                squares_to_block = (getRookAttacks(enemies) | enemies) & (RANKS[BITSQUARES_TO_COORDINATES[getWhiteKing()][1]] | FILES[BITSQUARES_TO_COORDINATES[getWhiteKing()][2]])
                squares_to_block_temp = squares_to_block
                    white_squad = 0x0000000000000000
                    count_to = count_ones(squares_to_block)
                    for i=1:count_to
                        least_bit = leastSignificantBit(squares_to_block_temp)
                        white_squad |= getEnemyAttackersOnSquare(least_bit, WHITE)
                        squares_to_block_temp &= ~least_bit
                    end
                    white_squad &= ~getWhiteKing()
                    if(white_squad != 0)
                    #Eventual pins. We handle them before everything else for now. Maybe we will change later
                    queen_att1 = getQueenAttacks(getWhiteKing())
                    pinned_candidates = queen_att1 & white_squad & ~getWhiteKing()
                    pinned_pieces = 0x0000000000000000
                    enemy_peaceful = queen_att1 & getBlackOccupancies()
                        if(pinned_candidates != 0)
                        #We eliminate potential pinned pieces and generate again queen moves from the king position.
                        #Then we intersect with Enemy occupancies and with ~enemy_peaceful
                        id = trailing_zeros(getWhiteKing()) + 1
                        relevant_occ = getOccupancies() & ~getWhiteKing() & ~pinned_candidates
                        magicB_index = Int(((relevant_occ & ECO_BISHOP_MASKS_BY_ID[id]) * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
                        magicR_index = Int(((relevant_occ & ECO_ROOK_MASKS_BY_ID[id]) * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
                        dangerous_enemy = (~enemy_peaceful & (BISHOP_ATTACKS[id][magicB_index + 1] | ROOK_ATTACKS[id][magicR_index + 1]) & (getBlackBishops() | getBlackQueens() | getBlackRooks()))
                            if(dangerous_enemy != 0)
                                for i = 1:count_ones(dangerous_enemy)
                                printBitBoard(dangerous_enemy)
                                bitsquare = leastSignificantBit(dangerous_enemy)
                                kingDAD = BITSQUARES_TO_DAD[getWhiteKing()]
                                dangerDAD = BITSQUARES_TO_DAD[bitsquare]
                                    if(dangerDAD[1] == kingDAD[1])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = DIAGONALS[kingDAD[1]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (DIAGONALS[kingDAD[1]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        println("------------------------------")
                                        printBitBoard(pinned_piece)
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una diagonale")

                                        end
                                    end
                                    if(dangerDAD[2] == kingDAD[2])
                                        if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                        bishop_ray = getBishopAttacks(bitsquare)
                                        pinned_piece = ANTI_DIAGONALS[kingDAD[2]] & pinned_candidates & bishop_ray
                                        legal_mask_for_pinned_piece = (ANTI_DIAGONALS[kingDAD[2]] & bishop_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su una antidiagonale")
                                        end
                                    end
                                    kingCords = BITSQUARES_TO_COORDINATES[getWhiteKing()]
                                    dangerCords = BITSQUARES_TO_COORDINATES[bitsquare]
                                    if(dangerCords[1] == kingCords[1])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                        rook_ray = getRookAttacks(bitsquare)
                                        pinned_piece = RANKS[kingCords[1]] & pinned_candidates & rook_ray
                                        legal_mask_for_pinned_piece = (RANKS[kingCords[1]] & rook_ray) | bitsquare
                                        pinned_pieces |= pinned_piece
                                        legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                        push!(moves, (pinned_piece, legal_moves))
                                        println("pin su un riga")
                                        end
                                    end
                                    if(dangerCords[2] == kingCords[2])
                                        if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                            rook_ray = getRookAttacks(bitsquare)
                                            pinned_piece = RANKS[kingCords[2]] & pinned_candidates & rook_ray
                                            println(pinned_piece)
                                            legal_mask_for_pinned_piece = (RANKS[kingCords[2]] & rook_ray) | bitsquare
                                            pinned_pieces |= pinned_piece
                                            legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece & squares_to_block
                                            push!(moves, (pinned_piece, legal_moves))
                                            println("pin su un colonna")
                                        end
                                    end
                                end
                            end

                        end

                    enemyOrEmpty = ~getWhiteOccupancies()
                    occ = white_squad & ~pinned_pieces
                    while(occ != 0b0)
                    piece = leastSignificantBit(occ)
                    id = trailing_zeros(piece) + 1
                    index = getBitBoardsIndex(piece)
                        if(index == 1)
                            push!(moves, (piece, KING_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 2)
                            push!(moves, (piece, getQueenAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index ==3)
                            push!(moves, (piece, getBishopAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index == 4)
                            push!(moves, (piece, KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty & squares_to_block))
                        elseif(index == 5)
                            push!(moves, (piece, getRookAttacks(piece) & enemyOrEmpty & squares_to_block))
                        elseif(index==6)
                            push!(moves, (piece, (W_PAWN_ATTACKS_BY_ID[id] & getBlackOccupancies() | (w_pawns_forward() & FILES[8 - ((id - 1)% 8)])) & squares_to_block))
                        end
            occ &= ~piece
                    end
                    end




                    end
                end
            end
        else #If we are not in check

            println("NOT IN CHECK")

            #We are thinking about the king like a queen. We look after possible pinned candidates
            queen_att1 = getQueenAttacks(getWhiteKing())
            pinned_candidates = queen_att1 & getWhiteOccupancies() & ~getWhiteKing()
            pinned_pieces = 0x0000000000000000
            enemy_peaceful = queen_att1 & getBlackOccupancies()
            if(pinned_candidates != 0)
                #We eliminate potential pinned pieces and generate again queen moves from the king position.
                #Then we intersect with Enemy occupancies and with ~enemy_peaceful
                id = trailing_zeros(getWhiteKing()) + 1
                relevant_occ = getOccupancies() & ~getWhiteKing() & ~pinned_candidates
                magicB_index = Int(((relevant_occ & ECO_BISHOP_MASKS_BY_ID[id]) * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
                magicR_index = Int(((relevant_occ & ECO_ROOK_MASKS_BY_ID[id]) * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
                dangerous_enemy = (~enemy_peaceful & (BISHOP_ATTACKS[id][magicB_index + 1] | ROOK_ATTACKS[id][magicR_index + 1]) & (getBlackBishops() | getBlackQueens() | getBlackRooks()))
                if(dangerous_enemy != 0)
                    for i = 1:count_ones(dangerous_enemy)
                        printBitBoard(dangerous_enemy)
                        bitsquare = leastSignificantBit(dangerous_enemy)
                        index = trailing_zeros(bitsquare) + 1
                        kingDAD = BITSQUARES_TO_DAD[getWhiteKing()]
                        dangerDAD = BITSQUARES_TO_DAD[bitsquare]
                        if(dangerDAD[1] == kingDAD[1])
                            if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                bishop_ray = getBishopAttacks(bitsquare)
                                pinned_piece = DIAGONALS[kingDAD[1]] & pinned_candidates & bishop_ray
                                legal_mask_for_pinned_piece = (DIAGONALS[kingDAD[1]] & bishop_ray) | bitsquare
                                pinned_pieces |= pinned_piece
                                println("------------------------------")
                                printBitBoard(pinned_piece)
                                legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece
                                push!(moves, (pinned_piece, legal_moves))
                                println("pin su una diagonale")

                            end
                        end
                        if(dangerDAD[2] == kingDAD[2])
                            if((bitsquare & (getBlackBishops() | getBlackQueens())) != 0)
                                bishop_ray = getBishopAttacks(bitsquare)
                                pinned_piece = ANTI_DIAGONALS[kingDAD[2]] & pinned_candidates & bishop_ray
                                legal_mask_for_pinned_piece = (ANTI_DIAGONALS[kingDAD[2]] & bishop_ray) | bitsquare
                                pinned_pieces |= pinned_piece
                                legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece
                                push!(moves, (pinned_piece, legal_moves))
                                println("pin su una antidiagonale")
                            end
                        end
                        kingCords = BITSQUARES_TO_COORDINATES[getWhiteKing()]
                        dangerCords = BITSQUARES_TO_COORDINATES[bitsquare]
                        if(dangerCords[1] == kingCords[1])
                            if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                rook_ray = getRookAttacks(bitsquare)
                                pinned_piece = RANKS[kingCords[1]] & pinned_candidates & rook_ray
                                legal_mask_for_pinned_piece = (RANKS[kingCords[1]] & rook_ray) | bitsquare
                                pinned_pieces |= pinned_piece
                                legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece
                                push!(moves, (pinned_piece, legal_moves))
                                println("pin su un riga")
                            end
                        end
                        if(dangerCords[2] == kingCords[2])
                            if((bitsquare & (getBlackRooks() | getBlackQueens())) != 0)
                                rook_ray = getRookAttacks(bitsquare)
                                pinned_piece = RANKS[kingCords[2]] & pinned_candidates & rook_ray
                                println(pinned_piece)
                                legal_mask_for_pinned_piece = (RANKS[kingCords[2]] & rook_ray) | bitsquare
                                pinned_pieces |= pinned_piece
                                legal_moves = getPseudoLegalMoves(pinned_piece) & legal_mask_for_pinned_piece
                                push!(moves, (pinned_piece, legal_moves))
                                println("pin su un colonna")
                            end
                        end
                    end
                end

            end
            

        enemyOrEmpty = ~getWhiteOccupancies()
        occ = getWhiteOccupancies() & ~pinned_pieces
        while(occ != 0b0)
            piece = leastSignificantBit(occ)
            id = trailing_zeros(piece) + 1
            index = getBitBoardsIndex(piece)
            if(index == 1)
                pseudo_legal = KING_MASKS_BY_ID[id] & enemyOrEmpty
                legal_moves = 0x0000000000000000
                count_to = count_ones(pseudo_legal)
                for i=1:count_to
                    least_bit = leastSignificantBit(pseudo_legal)
                    if(!isSquareAttackedByBlack(least_bit))
                    legal_moves |= least_bit
                    end
                    pseudo_legal &= ~least_bit
                end
                push!(moves, (piece, legal_moves))
            elseif(index == 2)
                push!(moves, (piece, getQueenAttacks(piece) & enemyOrEmpty))
            elseif(index ==3)
                push!(moves, (piece, getBishopAttacks(piece) & enemyOrEmpty))
            elseif(index == 4)
                push!(moves, (piece, KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty))
            elseif(index == 5)
                push!(moves, (piece, getRookAttacks(piece) & enemyOrEmpty))
            elseif(index==6)
                push!(moves, (piece, (W_PAWN_ATTACKS_BY_ID[id] & getBlackOccupancies() | (w_pawns_forward() & FILES[8 - ((id - 1)% 8)]))))
            end
            occ &= ~piece
        end
        end
        return moves
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
end


function getPseudoLegalMoves(piece)
    if(getTurnGameState() == WHITE)
        enemyOrEmpty = ~getWhiteOccupancies()
        id = trailing_zeros(piece) + 1
        index = getBitBoardsIndex(piece)
        if(index == 1)
            return KING_MASKS_BY_ID[id] & enemyOrEmpty
        elseif(index == 2)
            return getQueenAttacks(piece) & enemyOrEmpty
        elseif(index ==3)
            return getBishopAttacks(piece) & enemyOrEmpty
        elseif(index == 4)
            return KNIGHT_MASKS_BY_ID[id] & enemyOrEmpty
        elseif(index == 5)
            return getRookAttacks(piece) & enemyOrEmpty
        elseif(index==6)
            return ((W_PAWN_ATTACKS_BY_ID[id] & getBlackOccupancies()) | (w_pawns_forward() & FILES[8 - ((id - 1)% 8)]))
        end
end
return 0x0000000000000000
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


"""
These functions that follows were used for generating Dictionaries in Move Data.
"""

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



"""
MOVE SECTION:
TODO: Everything
"""




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


"""
EVERYTHING IN NEED FOR MAGIC NUMBERS
"""

# returns index of bitBoards array that contains a bitsquare received as input: helper function
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

# Relevant bits only attack mask for the rook
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

    # Relevant bits only attack mask for the bishop
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

        #it checks only for least bit
        function getLeastBitfromBitboard(bitsquare)
            return trailing_zeros(bitsquare) + 1
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

# random UInt64 generator
function random_uint64()::UInt64
  u1::UInt64 = rand(UInt64) & 0x000000000000FFFF
  u2::UInt64 = rand(UInt64) & 0x000000000000FFFF
  u3::UInt64 = rand(UInt64) & 0x000000000000FFFF
  u4::UInt64 = rand(UInt64) & 0x000000000000FFFF
  return u1 | (u2 << 16) | (u3 << 32) | (u4 << 48)
end

# Few bits are better for finding magic numbers
function random_uint64_fewbits()::UInt64
  return random_uint64() & random_uint64() & random_uint64()
end

# Magic number generator for rooks
function magic_rooks(bitsquare::UInt64)
    fail::Bool = false
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

    for count=1:3000000
            magic_number::UInt64 = random_uint64_fewbits()
            
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
                println("0b" * bitstring(bitsquare) * " => 0b" * bitstring(magic_number) * ",")
                return
            end
        end
        println("fail")
end

# Magic number generator for bishops
function magic_bishops(bitsquare::UInt64)
    fail = false
    occupancies = []
    attacks = []
    used_attacks = Dict()
    attack_mask = get(ECO_BISHOP_MASKS, bitsquare, nothing)
    rl_bits = get(BISHOP_RLBITS_BY_BITSQUARE, bitsquare, nothing)
    occupancy_indicies = 0b0000000000000000000000000000000000000000000000000000000000000001 << rl_bits
    for i=0:(occupancy_indicies-1)
        push!(occupancies, setBlockersBishop(i, bitsquare))
        push!(attacks, bishop_attacks_run(occupancies[i + 1], bitsquare))
    end

    for count=1:100000
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
                    magic_number = 0
                end
            end
            if (!fail)
                println("0b" * bitstring(bitsquare) * " => 0b" * bitstring(magic_number) * ",")
                return
            end
        end
        println("fail")
end

# Initialize a big Dictionary for rook attacks
# magic numbers are being finally used
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

# Initialize a big Dictionary for bishop attacks
# magic numbers are being finally used
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


"""
The following functions are the final functions to get the piece movements easily

These functions in partical return a bitboard that contains every single attacked square:
1) they don't consider Allies
2) they don't consider Pins
3) they don't consider Safe Squares
"""

# Functions that returns every possible pseudo-legal target square for a rook
# It doesn't handle Allies and Pins
function getRookAttacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    relevant_occupancy = getOccupancies() & ECO_ROOK_MASKS_BY_ID[id]
    magic_index = Int((relevant_occupancy * MAGIC_ROOK_BY_ID[id]) >> (64 - ROOK_RLBITS_BY_ID[id]))
    return ROOK_ATTACKS[id][magic_index + 1]
end

# Functions that returns every possible pseudo-legal target square for a bishop
# It doesn't handle Allies and Pins
function getBishopAttacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    relevant_occupancy = getOccupancies() & ECO_BISHOP_MASKS_BY_ID[id]
    magic_index = Int((relevant_occupancy * MAGIC_BISHOP_BY_ID[id]) >> (64 - BISHOP_RLBITS_BY_ID[id]))
    return BISHOP_ATTACKS[id][magic_index + 1]
end

# Functions that returns every possible pseudo-legal target square for a queen
# It doesn't handle Allies and Pins
function getQueenAttacks(bitsquare::UInt64)::UInt64
    return getBishopAttacks(bitsquare) | getRookAttacks(bitsquare)
end

# Functions that returns every possible pseudo-legal target square for a knight
# It doesn't handle Allies and Pins
function getKingAttacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    return KING_MASKS_BY_ID[id]
end

# Functions that returns every possible pseudo-legal target square for the king
# It doesn't handle Allies and Safe Squares
function getKnightAttacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    return KNIGHT_MASKS_BY_ID[id]
end

# Functions that returns attack pseudo-legal target square for the white pawn
# It doesn't handle Allies and Pins
# TODO: last rank captures (promotion)
function white_pawn_attacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    return W_PAWN_ATTACKS_BY_ID[id]
end

# Functions that returns attack pseudo-legal target square for the black pawn
# It doesn't handle Allies and Pins
# TODO: last rank captures (promotion)
function black_pawn_attacks(bitsquare::UInt64)::UInt64
    id = getLeastBitfromBitboard(bitsquare)
    return B_PAWN_ATTACKS_BY_ID[id]
end

"""
Debug + have fun with magics functions
"""

# Sets random blockers (white pawns)
function setRandomOccupancy(bitsquare::UInt64)
    i = rand(0:4095)
    bitBoards[6] = setBlockersRook(i, bitsquare) | setBlockersBishop(i, bitsquare)
end

# sets only one rook on a random square
# if occ = true -> random blockers on the board
# if toPrint = true -> prints board and bitboards of possible rook attacks
# id debug = true -> debug mode
function alone_rook(occ::Bool, toPrint::Bool, debug::Bool)
    i = rand(1:64)
    cleanBitBoards()
    bitBoards[5] = setBitOn(getWhiteRooks(), i)
    occ && setRandomOccupancy(getWhiteRooks())
    if(toPrint)
    printBoard()
    println()
    printBitBoard(getRookAttacks(getWhiteRooks()))
    println()
    end
    if(debug)
    var1 = getRookAttacks(getWhiteRooks())
    var2 = rook_attacks_run(getOccupancies(), getWhiteRooks())
    # it's everything ok?
    if(var1 != var2)
        println("$var1 != $var2") # not okay if this line is reached
    end
    end
end

# sets only one bishop on a random square
# if occ = true -> random blockers on the board
# if toPrint = true -> prints board and bitboards of possible bishop attacks
# id debug = true -> debug mode
function alone_bishop(occ::Bool, toPrint::Bool, debug::Bool)
    i = rand(1:64)
    cleanBitBoards()
    bitBoards[3] = setBitOn(getWhiteBishops(), i)
    occ && setRandomOccupancy(getWhiteBishops())
    if(toPrint)
    printBoard()
    println()
    printBitBoard(getBishopAttacks(getWhiteBishops()))
    println()
    end
    if(debug)
    var1 = getBishopAttacks(getWhiteBishops())
    var2 = bishop_attacks_run(getOccupancies(), getWhiteBishops())
    # it's everything ok?
    if(var1 != var2)
        println("$var1 != $var2")
    end
    end
end

# sets only one queen on a random square
# if occ = true -> random blockers on the board
# if toPrint = true -> prints board and bitboards of possible queen attacks
function alone_queen(occ::Bool, toPrint::Bool)
    i = rand(1:64)
    cleanBitBoards()
    bitBoards[2] = setBitOn(getWhiteQueens(), i)
    occ && setRandomOccupancy(getWhiteQueens())
    if(toPrint)
    printBoard()
    println()
    printBitBoard(getQueenAttacks(getWhiteQueens()))
    println()
    end
end

function DebugForChecks()
    cleanBitBoards()
    bitBoards[7] = setBitOn(getBlackKing(), 1)
    bitBoards[1] = setBitOn(getWhiteKing(), rand(11:64))
    gameState[2] == WHITE
    i = rand(1:64)
    if(getOccupancies() & SQUARES_TO_BITBOARDS[i] == 0)
    bitBoards[11] = setBitOn(getBlackRooks(), i)
    end
    j = rand(1:64)
    if(getOccupancies() & SQUARES_TO_BITBOARDS[j] == 0)
    bitBoards[10] = setBitOn(getBlackKnights(), j)
    end
    k = rand(1:64)
    if(getOccupancies() & SQUARES_TO_BITBOARDS[k] == 0)
    bitBoards[8] = setBitOn(getBlackQueens(), k)
    end
    printBoard()
    if(isSquareAttackedByBlack(getWhiteKing()) == true)
        println("scacco")
    end
    if(isWhiteInDoubleCheck())
        println("doppio scacco")
    end

end

function DebugForPins()
    cleanBitBoards()
    bitBoards[1] = setBitOn(getWhiteKing(), 32)
    setRandomOccupancy(SQUARES_TO_BITBOARDS[32])
    gameState[2] = true
    printBoard()
    printState()
end

# other tests
function random_rook_and_pawns()
    cleanBitBoards()
    i = rand(1:64)
    bitBoards[5] = setBitOn(getWhiteRooks(), i)
    setRandomOccupancy(getWhiteRooks())
end

#fast print for debug purpose
function print_rook_pseudotargets()
    printBitBoard(getRookAttacks(getWhiteRooks()))
end

function DebugRandomFiveMoves()
    for i=1:5
        moves = goFullLegal(bitBoards, gameState, bittyBoards)
        doMove(moves[rand(1:length(moves))])
        printBoard()
        printState()
    end
end