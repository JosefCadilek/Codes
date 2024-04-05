include("Chess.jl")

"""
Legal move generator step by step
"""


"""
Chess Rules:
documantion about the rules of chess are taken from FIDE: https://handbook.fide.com/chapter/E012023 
"""


function generateMoves()
    if(getTurnGameState() == WHITE)
        # as first we want to generate EnemyOrEmpty bitboard variable
        occupied = getOccupancies()
        empty = ~occupied
        enemyOrEmpty = ~getWhiteOccupancies()
        # 'check' to be defined
        if(CHECK)
            """
            Let's start from the position assuming that we are in check.
            There are fewer possibilities in this case.
            Our king is in check, we could do 3 things.
            1) Move our king to a 'safe' square, which means a 'not-attacked' square. (surely castling is impossible)
                an 'attacked' square is a square that is 'seen' by an indefinite number of enemies.
                I'm using 'seen', because as said in the rules of chess, a square is 'attacked' also if
                the piece that is attacking it is costreined to defend his king (ex: maybe pinned)
                For me, this isn't really 'attacking', it could not capture our piece for example if it was their turn.
                But it is an important aspect of the rules to consider so let's call that in some way.
                    Let every piece be removed from the board except for one piece,
                    this piece is 'seeing' a square if this one occurs in his movement Masks (only for the pawn it is different)

                This means that for generating king moves we have to consider:
                    kingMask = Lookup bitBoards for the king
                    & notSeenByEnemy = All squares not 'seen' by the enemy
                       & EnemyOrEmpty This means knowing the movement path for each piece is necessary.
                        
            2) We could block the check if there's a piece that could interpose between the king and enemy.
                        This is impossible if our king is in a double check for example.
                        In that case it is not possible to capture two pieces or block the checks.
                        Only king move is possible.

            3) We could capture the piece that is causing problems.
            """
        else
            """
            if we generate moves for each group for pieces, how can we tell which data is to attribute to a certain piece?
                This is one of the biggest problems.
                The simpliest way could be looping trough all the pieces, calculating the necessary data and then generate moves
                bitboards are so crazy that there could be a way of calculating everything without a looping.
                But let's tell we want to loop, what data should we calculate?
                
                    ...
                """

        end
    else # Black move generator
        occupied = getOccupancies()
        empty = ~occupied
        enemyOrEmpty = ~getBlackOccupancies()
    end
    return moves
end