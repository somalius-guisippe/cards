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

func delete_card(card):
	var context = getCardContext(card)
	if context['category'] == 'cascadeCard':
		columns[context['index']].erase(card)
	elif context['category'] == 'cellCard':
		free_cell_cards[context['index']] = null
	elif context['category'] == 'foundationCard':
		foundation_cards[context['index']].erase(card)
	
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

func getCardContext(card):
	var column = findCardColumn(card)
	var freecell = findCardFreecell(card)
	var foundation = findCardFoundation(card)
	if column != null:
		return {"category": "cascadeCard", "index": column}
	if freecell != null:
		return {"category": "cellCard", "index": freecell}
	if foundation != null:
		return {"category": "foundationCard", "index": foundation}
		
func findCardColumn(card):
	for i in range(columns.size()):
		if card in columns[i]:
			return i

func findCardFreecell(card):
	var i = free_cell_cards.find(card)
	if i == -1:
		return null
	else:
		return i

func findCardFoundation(card):
	for i in range(4):
		if card in foundation_cards[i]:
			return i
