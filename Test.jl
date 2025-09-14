include("MoveGenerator.jl")

"""
File che contiene le funzioni per eseguire il performance test del generatore di mosse.
Si tratta di un metodo standard che consente di capire se tutto funziona correttamente.
"""

const MAX_DEPTH = 64
const MOVE_STACK = [MoveList() for _ in 1:MAX_DEPTH]
const COPY_STACK = [Position() for _ in 1:MAX_DEPTH]

#funzione che prende in ingresso move_stack e copy_stack per evitare allocazioni
function perft_worker(pos::Position, depth::Int, ply::Int, move_stack::Vector{MoveList}, copy_stack::Vector{Position})
    depth == 0 && return 1

    local_nodes = 0
    move_list = move_stack[ply]
    generate_legal_moves(pos, move_list)

    for i in 1:move_list.amount
        move = move_list.moves[i]
        
        copy_position!(copy_stack[ply], pos)
        makeMove!(copy_stack[ply], move)

        local_nodes += perft_worker(copy_stack[ply], depth - 1, ply + 1, move_stack, copy_stack)
    end

    return local_nodes
end


#testa il generatore di mosse legali e makemove contando il numero di nodi raggiunti a una data profondità
function perft(pos::Position, depth::Int)
    return perft_worker(pos, depth, 1, MOVE_STACK, COPY_STACK)
end


