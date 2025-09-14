include("Eval.jl")

"""
File contenente tutto il necessario per una connessione rudimentale con un'interfaccia grafica locale tramite UCI.
Tutto senza eseguibili, direttamente dal codice.
"""

using Sockets

function handle_uci(io::TCPSocket, args::String)
    println("LOG: Ricevuto 'uci'. Invio l'identità.")
    write(io, "id name Jerry\n")
    write(io, "id author Josef Cadilek\n")
    write(io, "uciok\n")
end

function handle_isready(io::TCPSocket, args::String)
    println("LOG: Ricevuto 'isready'. Invio 'readyok'.")
    write(io, "readyok\n")
end

function handle_ucinewgame(io::TCPSocket, args::String)
    setStartingPosition(POSITION)
    println("LOG: Ricevuto 'ucinewgame'. Preparo per una nuova partita.")
end

function handle_position(io::TCPSocket, args::String)
    println("LOG: Ricevuto 'position' con dati: ", args)
    
    parts = split(args, " moves ")
    position_part = parts[1]
    
    # imposta la posizione iniziale o fen
    if startswith(position_part, "startpos")
        setStartingPosition(POSITION)
    elseif startswith(position_part, "fen")
        # estrazione stringa dopo "fen "
        fen_string = SubString(position_part, 5) 
        setPositionFromFEN(POSITION, String(fen_string))
    end

    # se è presente "moves" allora parts è più lungo di 1 e giochiamo le mosse segnalate
    if length(parts) > 1
        moves_str = parts[2]
        move_list_str = split(moves_str, " ")
        
        for move_algebra in move_list_str
            if !isempty(move_algebra)
                # è necessario generare le mosse legali per utilizzare algebra_to_move
                generate_legal_moves(POSITION, MOVE_LIST)
                
                # traduce la mossa e la applica con makeMove
                move_to_make = algebra_to_move(String(move_algebra), MOVE_LIST)
                makeMove!(POSITION, move_to_make)
            end
        end
    end
    println("LOG: Posizione impostata correttamente.")
end

function handle_go(io::TCPSocket, args::String)
    println("LOG: Ricevuto 'go' con parametri: ", args)

    search_depth = 7 # profondità "infinita"
    
    parts = split(args, " ")
    i = 1
    while i <= length(parts)
        if parts[i] == "depth" && i + 1 <= length(parts)
            search_depth = parse(Int64, parts[i+1])
            i += 2 # salta il valore della profondità
        elseif parts[i] == "infinite"
            search_depth = 7 # profondità massima
            i += 1
        else
            i += 1 # ignora per ora altri comandi non gestiti (wtime, btime etc.)
        end
    end

    println("LOG: Inizio la ricerca a profondità: ", search_depth)
    best_move_obj = bestMove(POSITION, search_depth)
    
    if best_move_obj.source != 0x00 #controllo mossa nulla
        best_move_string = move_to_algebra(best_move_obj)
        println("LOG: Ricerca completata. Invio bestmove $best_move_string")
        write(io, "bestmove $best_move_string\n")
    else
        println("LOG: Nessuna mossa legale trovata.")
        # mossa nulla secondo UCI
        write(io, "bestmove 0000\n")
    end
end

# LOOP PRINCIPALE
function main_loop()
    command_dispatcher = Dict(
        "uci" => handle_uci,
        "isready" => handle_isready,
        "ucinewgame" => handle_ucinewgame,
        "position" => handle_position,
        "go" => handle_go
    )

    port = 8888
    server = listen(port)
    println("Motore avviato. In attesa di connessione dalla GUI sulla porta $port...")

    try
        # accettazione collegamento gui
        io = accept(server)
        println("GUI connessa!")

        # loop comunicazione
        while isopen(io)
            line = readline(io)
            if isempty(line)
                println("LOG: La GUI ha chiuso la connessione.")
                break
            end

            parts = split(line, " ", limit=2)
            command = parts[1]
            args = length(parts) > 1 ? String(parts[2]) : ""

            if haskey(command_dispatcher, command)
                # scelta della funzione da chiamare
                handler_func = command_dispatcher[command]
                handler_func(io, args)
            elseif command == "quit"
                println("LOG: Ricevuto 'quit'. Arresto.")
                break
            else
                println("WARN: Comando non riconosciuto: ", command)
            end
        end
    catch e
        println("ERRORE: Si è verificato un errore nel loop principale: ", e)
    finally
        # chiusura server
        close(server)
        println("Server chiuso.")
    end
end