extends Node
# This is just a information swapping area.

#### State of where the cards are
# Eight lists of cards, arranged from the bottom of the pile to the top
var columns
# Cards on free cells
var free_cell_cards
#Set of foundation sets
var foundation_cards

# When change is triggered, updateview in Tableau is called.
signal change

func game_setup(deck):
	columns = []
	for i in range(0,8):
		columns.append([])
	free_cell_cards = [null, null, null, null]
	foundation_cards = [[], [], [], []]
	deck.shuffle()
	for i in range(deck.size()):
		var row = i/8
		var column = i%8
		var card = deck[i]
		columns[column].append(card)
	change.emit()
