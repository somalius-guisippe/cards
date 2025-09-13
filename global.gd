extends Node
# This is just a information swapping area.
var columns
# Cards on free cells
var free_cell_cards = [null, null, null, null]

#Set of foundation sets
#### State of where the cards are
# Eight lists of cards, arranged from the bottom of the pile to the top
var foundation_cards = [[], [], [], []]
