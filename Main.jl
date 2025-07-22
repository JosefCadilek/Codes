include("Eval.jl")

"""
Game runs from here right now: sort of MAIN
"""

###################################################MAIN################################################################
# INITIALIZE magic bitboards
ROOK_ATTACKS = init_rook_attacks()
BISHOP_ATTACKS = init_bishop_attacks()

# Starting position and print by default
setStartingPosition()
printBoard()
printState()

# Tests
#########################################################################################################################