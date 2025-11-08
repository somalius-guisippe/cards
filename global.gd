extends Node

func current():
	return history[historyPosition]

# This is just a information swapping area.

# card - What card we're moving
# to - card context
func move_card(card, to):
	var newGS = current().duplicate()
	history.resize(historyPosition+1)
	
	newGS.move_card(card, to)
	historyPosition += 1
	history.append(newGS)

	change.emit()

func undo():
	if historyPosition != 0:
		historyPosition -= 1
		change.emit()

func atEndOfHistory():
	return historyPosition == history.size() - 1

func redo():
	if not atEndOfHistory():
		historyPosition += 1
		change.emit()

func cheat():
	print("cheatermgj")
	var newGS = current().duplicate()
	history.resize(historyPosition+1)
	
	newGS.secretColumn.append_array(newGS.columns[0])
	newGS.columns[0] = []
	historyPosition += 1
	history.append(newGS)

	change.emit()

#### State of where the cards are
class GameState:
	# Eight lists of cards, arranged from the bottom of the pile to the top
	var columns
	# Cards on free cells
	var free_cell_cards
	#Set of foundation sets
	var foundation_cards
	
	var secretColumn = []
	
	func is_card_moveable(card):
		if getCardContext(card)["category"] ==  "cellCard":
			return true
		if getCardContext(card)["category"] ==  "cascadeCard":
			return true
		return false
	
	func can_move_to_cascade(card, i):
		var amount_moving = cascade_Depth(card)
		var openCells = 0
		for x in free_cell_cards:
			if x == null:
				openCells += 1
		var openCascades = 0
		for x in columns:
			if x == []:
				openCascades += 1
		if columns[i] == []:
			openCascades -= 1
		var amount_moveable = (1+openCells)*pow(2, openCascades)
		return amount_moving <= amount_moveable
		
	func cascade_Depth(card):
		var context = getCardContext(card)
		var columnContents = columns[context["index"]]
		var whereCard = columnContents.find(card)
		return columnContents.size() - whereCard
		
	func get_cards_under(card):
		var cardContext = getCardContext(card)
		if cardContext["category"] == "cellCard":
			return []
		if cardContext["category"] == "foundationCard":
			return []
		if cardContext["category"] == "cascadeCard":
			var columnI = cardContext["index"]
			var cardI = columns[columnI].find(card)
			return columns[columnI].slice(cardI+1)
	# Returns a new copy of this game state
	func duplicate():
		var newGS = GameState.new()
		newGS.columns = []
		newGS.foundation_cards = []
		
		newGS.secretColumn = secretColumn.duplicate()
		for c in columns:
			newGS.columns.append(c.duplicate())
		for f in foundation_cards:
			newGS.foundation_cards.append(f.duplicate())
		newGS.free_cell_cards = free_cell_cards.duplicate()

		return newGS
	
	func hasWon():
		for pile in foundation_cards:
			if pile.size() < 13:
				return false
		return true

	# card - What card we're moving
	# to - card context
	func move_card(card, to):
		delete_card(card)
		if to['category'] == 'cascadeCard':
			columns[to['index']].append(card)
		elif to['category'] == 'cellCard':
			free_cell_cards[to['index']] = card
		else:
			foundation_cards[to['index']].append(card)
	
	func delete_card(card):
		var context = getCardContext(card)
		if context['category'] == 'cascadeCard':
			columns[context['index']].erase(card)
		elif context['category'] == 'cellCard':
			free_cell_cards[context['index']] = null
		elif context['category'] == 'foundationCard':
			foundation_cards[context['index']].erase(card)

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

	func is_at_top_of_column(card):
		for column in columns:
			if column.size() != 0:
				if card == column[-1]:
					return true
		return false

#moves made
var history: Array[GameState] = []

#position in history
var historyPosition = -1

# When change is triggered, updateview in Tableau is called.
signal change
	
func game_setup(deck):
	var gs = GameState.new()
	gs.columns = []
	for i in range(0,8):
		gs.columns.append([])
	gs.free_cell_cards = [null, null, null, null]
	gs.foundation_cards = [[], [], [], []]
	deck.shuffle()
	for i in range(deck.size()):
		var row = i/8
		var column = i%8
		var card = deck[i]
		gs.columns[column].append(card)
	historyPosition += 1
	history.append(gs)
	change.emit()
	
func winAtReady(deck):
	var gs = GameState.new()
	gs.columns = []
	for i in range(0,8):
		gs.columns.append([])
	gs.free_cell_cards = [null, null, null, null]
	gs.foundation_cards = [[], [], [], []]
	for card in deck:
		gs.foundation_cards[card.suit].append(card)
	historyPosition += 1
	history.append(gs)
	change.emit()
	
