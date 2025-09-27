@tool
class_name Tableau
extends Node2D
# This script:
	#-models the game-state,
	#-defines legal moves,
	#-draws the board,
	#-recognizes inputs,

# List of the bases of piles in the main play area
var cascades

#list of foundation cells
var foundations

# List of places where we can place any single card
var cells: Array[Node2D]

#the card we're moving at the moment
var moving_card: Card
#where the mouse is at the beggining of clicking the card
var movement_start
#movement start for the card
var card_start
#card under the moving card.
var drop_candidate: Node2D
#all possible highlights.
#var aph = []

var touched_cards = []

var deck = []




func get_top_cards() -> Array[Card]:
	var top_cards: Array[Card] = []
	for column in Global.columns:
		top_cards.append(column[-1])
	return top_cards
	
func intersect(array1, array2):
	var intersection = []
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	return intersection


func area_to_card(object: Dictionary) -> Card:
	var card := object.collider.get_parent() as Card
	return card

# Of the given list of cards, return the one with the highest z index
func find_top_card(cards) -> Card:
	var top: Card
	for card in cards:
		if top == null:
			top = card
		else:
			if (card.z_index > top.z_index):
				top = card
	return top

func _input(event):

	var object
	var button_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	if motion_event != null:
		if moving_card != null:
			moving_card.position = card_start + ( event.position - movement_start )
			update_drop_candidate()
	if button_event != null:
		var x = PhysicsPointQueryParameters2D.new()
		x.position = event.position
		x.collide_with_areas = true
		if event.is_pressed(): 
			var objects_clicked = get_world_2d().direct_space_state.intersect_point(x, 10)
			var cards_clicked = objects_clicked.map(area_to_card).filter(func(x): return x != null)
			var picked_card = find_top_card(cards_clicked)
			if picked_card != null:
				if (is_at_top_of_column(picked_card)) or (picked_card in Global.free_cell_cards):
					$Cards.move_child(picked_card, -1)
					moving_card = picked_card
					moving_card.set_moving(true)
					movement_start = event.position
					card_start = picked_card.position
					Global.change.emit()
		if event.is_released():
			if moving_card != null:
				if drop_candidate != null:
					Global.delete_card(moving_card)
					
					# Handle dropping onto a free cell
					var i = cells.find(drop_candidate)
					if i != -1:
						if Global.free_cell_cards[i] == null:
							Global.free_cell_cards[i] = moving_card

								
					
					# Handle dropping onto a foundation base
					var viable = foundations.find(drop_candidate)
					if viable != -1:
						Global.foundation_cards[viable].append(moving_card)

					# Handle dropping onto another card
					var card := drop_candidate as Card
					if card != null:
						var cardContext = Global.getCardContext(drop_candidate)
						if cardContext["category"] == "cascadeCard":
							for j in range(Global.columns.size()):
								var column = Global.columns[j]
								if j == cardContext["index"]:
									column.append(moving_card)
						elif cardContext["category"] == "foundationCard":
							var foundation = Global.foundation_cards[cardContext["index"]]
							foundation.append(moving_card)
							
							
				moving_card.set_moving(false)
				moving_card = null
				movement_start = null
				card_start = null
				drop_candidate = null
				touched_cards = []
				Global.change.emit()

func is_at_top_of_column(card):
	for column in Global.columns:
		if card == column[-1]:
			return true
	return false

func game_setup():
	Global.game_setup(deck)

func _ready():
	cells = [
		$Cells/cell1,
		$Cells/cell2,
		$Cells/cell3,
		$Cells/cell4]
	foundations = [
		$Foundations/foundation1,
		$Foundations/foundation2,
		$Foundations/foundation3,
		$Foundations/foundation4
	]
	
	$Button.pressed.connect(game_setup)
	
	Global.change.connect(updateView)
	deck = []
	cascades = $Cascades.get_children()
	
	for suit in range(0,4):
		for rank in range(1,13 + 1):
			var card = $FirstCard.duplicate()
			deck.append(card)
			$Cards.add_child(card)
			card.rank = rank
			card.suit = suit
			card.touched_card.connect(_on_card_touch)
			card.exited_card.connect(_on_card_exit)
			#card.position = Vector2(100 + 50 * rank, 100 + 30 * rank + 50 * suit)
	game_setup()

func _on_card_exit(card: Node2D):
	if card in touched_cards:
		touched_cards.erase(card)
	Global.change.emit()

func _on_card_touch(node: Node2D):
	#In this instance, "node" is the card that is NOT moving.
	var card := node as Card
	if card != null:
		var top_cards = get_top_cards()
		if node in top_cards:
			touched_cards.append(node)
	elif node in cells:
		touched_cards.append(node)
	elif node in foundations:
		touched_cards.append(node)
	Global.change.emit()

func update_drop_candidate():
	if touched_cards.size() == 0:
		drop_candidate = null
	elif touched_cards.size() == 1:
		maybe_set_drop_candidate(touched_cards[0])
	else:
		var distance1 = touched_cards[1].position.distance_to(moving_card.position)
		var distance2 = touched_cards[0].position.distance_to(moving_card.position)
		if distance1 > distance2:
			maybe_set_drop_candidate(touched_cards[0])
		else:
			maybe_set_drop_candidate(touched_cards[1])
	Global.change.emit()

func maybe_set_drop_candidate(x):
	if x in cells:
		var i = cells.find(x)
		var card = Global.free_cell_cards[i]
		if card == null:
			drop_candidate = x
	elif x in foundations:
		var i = foundations.find(x)
		if Global.foundation_cards[i] == []:
			if moving_card.rank == 1:
				drop_candidate = x
		else:
			var spec_Foundation = Global.foundation_cards[i]
			var foundation_top = spec_Foundation[-1]
			var foundation_rank = foundation_top.rank
			if moving_card.rank == foundation_rank + 1:
				if moving_card.suit == foundation_top.suit:
					drop_candidate = x
	else:
		var y = moving_card
		var can_place = (x.rank == y.rank+1) && different_color(x.suit, y.suit)
		if can_place:
			drop_candidate = x

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

func updateView():
	print(Global.free_cell_cards)
	for card in deck:
		var color
		if card == drop_candidate:
			color = Color(.8, .8, 1, 1)
		elif card == moving_card:
			color = Color(1, 1, 1, .8)
		else:
			color = Color(1, 1, 1, 1)
		card.modulate = color
	
	for i in range(4):
		var foundation = foundations[i]
		var color
		if foundation == drop_candidate:
			color = Color(.8, .8, 1, 1)
		elif foundation in touched_cards:
			color = Color(1, 0.8, 0.8, 1)
		else:
			color = Color(1, 1, 1, 1)
		for card in Global.foundation_cards[i]:
			card.position = foundation.position
		foundation.modulate = color
		
	for i in range(4):
		var cell = cells[i]
		var free_cell_card = Global.free_cell_cards[i]
		if free_cell_card != null:
			if free_cell_card != moving_card:
				free_cell_card.position = cell.position
		var color
		if cell == drop_candidate:
			color = Color(.8, .8, 1, 1)
		elif cell in touched_cards:
			color = Color(1, 0.8, 0.8, 1)
		else:
			color = Color(1, 1, 1, 1)
		cell.modulate = color
	for column_number in range(Global.columns.size()):
		var column = Global.columns[column_number]
		var cell = cascades[column_number]
		for row_number in range(column.size()):
			var card: Card = column[row_number]
			
			if (card != moving_card):
				card.position = Vector2(cell.position.x, cell.position.y + row_number * 30)
				card.z_index = row_number
			else:
				card.z_index = 100
