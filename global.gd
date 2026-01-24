extends Node

func current():
	return history[historyPosition]

# This is just a information swapping area.

# card - What card we're moving
# to - card context
func move_card(cards: Array[Card], to):
	var newGS = current().duplicate()
	history.resize(historyPosition+1)
	
	newGS.move_card(cards, to)
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
		
func different_color(s1, s2):
	return (color_of(s1) != color_of(s2))

func color_of(s):
	if s == 0:
		return ("black")
	if s == 1:
		return ("red")
	if s == 2:
		return ("red")
	if s == 3:
		return ("black")

func opposite_color(x):
	if x == 'red':
		return 'black'
	else:
		return 'red'

func cheat():
	print("cheatermgj")
	var newGS = current().duplicate()
	history.resize(historyPosition+1)
	
	newGS.secretColumn.append_array(newGS.columns[0])
	newGS.columns[0] = []
	historyPosition += 1
	history.append(newGS)

	change.emit()

func is_organized_sequence(cards: Array[Card]):
	for c in range(cards.size()-1):
		var numberHere = cards[c].rank
		var suitHere = cards[c].suit
		var numberNext = cards[c + 1].rank
		var suitNext = cards[c + 1].suit
		if numberHere == numberNext + 1 && Global.different_color(suitHere, suitNext):
			pass
		else:
			return false
	return true

#### State of where the cards are
class GameState:
	# Eight lists of cards, arranged from the bottom of the pile to the top
	var columns
	# Cards on free cells
	var free_cell_cards
	#Set of foundation sets
	var foundation_cards
	
	var secretColumn = []
	
	# Given a card, determine whether it is possible to place it onto a foundation.
	# If so, return a card context describing where it may be placed.
	# Otherwise, return null.
	func foundationStatus(card):
		var foundations = foundation_cards
		for i in range(4):
			var foundationPile = foundation_cards[i]
			if foundationPile == []:
				if card.rank == 1:
					return {"category": "foundationCard", "index": i}
			else:
				var top = foundationPile[-1]
				# compare 'top' and 'card' 
				if card.rank == top.rank+1 && card.suit == top.suit:
					return {"category": "foundationCard", "index": i}
		pass
	
	func get_top_cards() -> Array[Card]:
		var top_cards: Array[Card] = []
		for column in columns:
			if column.size() != 0:
				top_cards.append(column[-1])
		for Foundation in foundation_cards:
			if Foundation.size() != 0:
				top_cards.append(Foundation[-1])
		return top_cards
	
	func is_card_moveable(card):
		if getCardContext(card)["category"] ==  "cellCard":
			return true
		if getCardContext(card)["category"] ==  "cascadeCard":
			var cards_under = get_cards_under(card)
			return Global.is_organized_sequence(cards_under)
		return false
	
	# Determine whether a stack of cards (described by the top card of the stack) is allowed to move onto a particular cascade
	#   card: The card that is being moved (potentially the top of an organized stack)
	#   i: number 0-7 indicating the index of the cascade being moved onto
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
		if context["category"] == "cascadeCard":
			var whereCard = columnContents.find(card)
			return columnContents.size() - whereCard
		elif context["category"] == "cellCard":
			return(1)
		
		
	func get_cards_under(card: Card) -> Array[Card]:
		var result: Array[Card] = []
		
		var cardContext = getCardContext(card)
		if cardContext["category"] == "cascadeCard":
			var columnI = cardContext["index"]
			var column = columns[columnI]
			var cardI = column.find(card)
			
			for x in column.slice(cardI):
				var y := x as Card
				result.append(y)
			
		if cardContext["category"] == "cellCard":
			result.append(card)
		
		return result
			
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
	func move_card(cards: Array[Card], to):
		for card in cards:
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
		
	# 
	func auto_go_up():
		var topCards = get_top_cards()
		topCards.append_array(free_cell_cards)
		for card in topCards:
			if card != null:
				if can_auto_go_up(card):
					return card

	
	func can_auto_go_up(card:Card):
		if getCardContext(card) ["category"] == "foundationCard":
			return false
		if card.rank == 1:
			return true
			
		else:
			if foundationStatus(card) != null:
				var rank = card.rank
				var color = Global.color_of(card.suit)
				if card.rank == 2:
					return true
				else:
					
					return !are_there_any_still_out(rank - 1, Global.opposite_color(color))
				
	func are_there_any_still_out(rank, color):
		for card in free_cell_cards:
			if card != null:
				if card.rank == rank && Global.color_of(card.suit) == color:
					return true
		for column in columns:
			for card in column:
				if card != null:
					if card.rank == rank && Global.color_of(card.suit) == color:
						return true

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
	history.append(gs)
	historyPosition = history.size()-1
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
	
