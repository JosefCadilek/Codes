include("DataManager.jl")

"""
File contenente la rappresentazione della scacchiera tramite bitboards e alcune funzioni utili come la traduzione FEN
"""

mutable struct Position
    pawns::UInt64
    knights::UInt64
    bishops::UInt64
    rooks::UInt64
    queens::UInt64
    kings::UInt64
    black_occ::UInt64 #pezzi neri
    white_occ::UInt64 #pezzi bianchi
    enpassant::UInt64 #casa enpassant
    turn::Bool #turn = true se tocca al bianco, mentre è false se tocca il nero
    w_kingside::Bool #arrocco corto bianco
    w_queenside::Bool #arrocco lungo bianco
    b_kingside::Bool #arrocco corto nero
    b_queenside::Bool #arrocco lungo nero
end

POSITION = Position(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, true, true, true, true, true)

#imposta la posizione iniziale
function setStartingPosition(p::Position)
    pawns = 0x00FF00000000FF00
    knights = 0x0000000000000042 | 0x4200000000000000
    bishops = 0x0000000000000024 | 0x2400000000000000
    rooks = 0x0000000000000081 | 0x8100000000000000
    queens = 0x0000000000000010 | 0x1000000000000000
    kings = 0x0000000000000008 | 0x0800000000000000

    white_occ = 0x000000000000FF00 | 0x0000000000000042 | 0x0000000000000024 | 0x0000000000000081 | 0x0000000000000010 | 0x0000000000000008
    black_occ = 0x00FF000000000000 | 0x4200000000000000 | 0x2400000000000000 | 0x8100000000000000 | 0x1000000000000000 | 0x0800000000000000

    p.pawns = pawns
    p.knights = knights
    p.bishops = bishops
    p.rooks = rooks
    p.queens = queens
    p.kings = kings
    p.white_occ = white_occ
    p.black_occ = black_occ
    p.enpassant = 0x0
    p.turn = true
    p.w_kingside = true
    p.w_queenside = true
    p.b_kingside = true
    p.b_queenside = true
end

#Stampa una bitboard nel terminale
function printBitBoard(bitboard::UInt64)
    for i=1:8:64
        println(SubString(bitstring(bitboard), i:(i+7)))
    end
end

#Prende in input una bitboard e restituisce una bitboard contenente
#esclusivamente il bit acceso meno rilevante
@inline
function leastSignificantBit(bitboard::UInt64)
    bitboard & ~(bitboard - 1)
end

#Funzione che cambia la posizione data una stringa FEN
function setPositionFromFEN(p::Position, fen::String)
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
    # split FEN
    fenPieces = split(fen, r"\s+");
    count = 0;

    #riempiamo le bitboards
    for letter in fenPieces[1]
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

    p.pawns = white_pawns | black_pawns
    p.knights = white_knights | black_knights
    p.bishops = white_bishops | black_bishops
    p.rooks = white_rooks | black_rooks
    p.queens = white_queens | black_queens
    p.kings = white_king | black_king
    p.white_occ = white_pawns | white_knights | white_bishops | white_rooks | white_queens | white_king
    p.black_occ = black_pawns | black_knights | black_bishops | black_rooks | black_queens | black_king
    p.enpassant = EP
    p.turn = playing_turn
    p.w_kingside = w_cast_king
    p.w_queenside = w_cast_queen
    p.b_kingside = b_cast_king
    p.b_queenside = b_cast_queen
end

#Stampa la scacchiera e lo stato nel terminale
function printBoard(p::Position)
    A=Matrix{Char}(undef, 8, 8) # matrice da stampare
for i=0:63
    square=0b1000000000000000000000000000000000000000000000000000000000000000 >> i # shift della casa a8
    v = divrem(i, 8); # divisione con resto
    if((square & p.black_occ) == square)
        if ((p.kings & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='k';
            continue;
        end
        if ((p.queens & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='q';
            continue;
        end
        if ((p.bishops & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='b';
            continue;
        end
        if ((p.knights & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='n';
            continue;
        end
        if ((p.rooks & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='r';
            continue;
        end
        if ((p.pawns & p.black_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='p';
            continue;
        end
    elseif((square & p.white_occ) == square)
        if ((p.kings & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='K';
            continue;
        end
        if ((p.queens & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='Q';
            continue;
        end
        if ((p.bishops & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='B';
            continue;
        end
        if ((p.knights & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='N';
            continue;
        end
        if ((p.rooks & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='R';
            continue;
        end
        if ((p.pawns & p.white_occ & square) != 0b0)
            A[v[1] + 1, v[2] + 1]='P';
            continue;
        end
    else
        A[v[1] + 1, v[2] + 1]='-';
    end

end
display("text/plain", A)
println()
println("-------------STATO--------------")
println("turno: ", (p.turn ? "BIANCO" : "NERO"))
println("enpassant: ", (p.enpassant != 0 ? BITSQUARES_TO_NOTATION[p.enpassant] : "-"))
println("arrocchi: ", (p.w_kingside ? "K" : "-"), (p.w_queenside ? "Q" : "-"), (p.b_kingside ? "k" : "-"), (p.b_queenside ? "q" : "-"))
end

