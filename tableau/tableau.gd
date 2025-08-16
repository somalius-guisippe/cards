@tool
class_name Tableau
extends Node2D

# List of the bases of piles in the main play area
var cascades

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

#### State of where the cards are
# Eight lists of cards, arranged from the bottom of the pile to the top
var columns
# Cards on free cells
var free_cell_cards = [null, null, null, null]

signal change

func get_top_cards() -> Array[Card]:
	var top_cards: Array[Card] = []
	for column in columns:
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
				if (is_at_top_of_column(picked_card)) or (picked_card in free_cell_cards):
					$Cards.move_child(picked_card, -1)
					moving_card = picked_card
					moving_card.set_moving(true)
					movement_start = event.position
					card_start = picked_card.position
					change.emit()
		if event.is_released():
			if moving_card != null:
				if drop_candidate != null:
					var i = cells.find(drop_candidate)
					if i != -1:
						if free_cell_cards[i] == null:
							free_cell_cards[i] = moving_card
							for column in columns:
								column.erase(moving_card)
					var card := drop_candidate as Card
					if card !=null:
						for column in columns:
							if drop_candidate in column:
								column.append(moving_card)
							else:
								column.erase(moving_card)

				moving_card.set_moving(false)
				moving_card = null
				movement_start = null
				card_start = null
				drop_candidate = null
				touched_cards = []
				change.emit()

func is_at_top_of_column(card):
	for column in columns:
		if card == column[-1]:
			return true
	return false

func _ready():
	cells = [
		$Cells/cell1,
		$Cells/cell2,
		$Cells/cell3,
		$Cells/cell4]
	
	change.connect(updateView)
	var deck = []
	cascades = $Cascades.get_children()
		
	columns = []
	for i in range(0,8):
		columns.append([])
	
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
	
	deck.shuffle()
	for i in range(deck.size()):
		var row = i/8
		var column = i%8
		var card = deck[i]
		var cell = cascades[column]
		columns[column].append(card)
	change.emit()

func _on_card_exit(card: Node2D):
	if card in touched_cards:
		touched_cards.erase(card)
	change.emit()

func _on_card_touch(node: Node2D):
	#In this instance, "node" is the card that is NOT moving.
	var card := node as Card
	if card != null:
		var top_cards = get_top_cards()
		if node in top_cards:
			touched_cards.append(node)
	else:
		if node in cells:
			touched_cards.append(node)
	change.emit()

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
	change.emit()

func maybe_set_drop_candidate(x):
	if x in cells:
		var i = cells.find(x)
		var card = free_cell_cards[i]
		if card == null:
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

	for i in range(4):
		var cell = cells[i]
		var free_cell_card = free_cell_cards[i]
		if free_cell_card != null:
			if free_cell_card != moving_card:
				free_cell_card.position = cell.position
			var card_color = Color(1, 1, 1, 1)
			free_cell_card.modulate = card_color
		var color
		if cell == drop_candidate:
			color = Color(.8, .8, 1, 1)
		elif cell in touched_cards:
			color = Color(1, 0.8, 0.8, 1)
		else:
			color = Color(1, 1, 1, 1)
		cell.modulate = color
	for column_number in range(columns.size()):
		var column = columns[column_number]
		var cell = cascades[column_number]
		for row_number in range(column.size()):
			var card: Card = column[row_number]
			
			var color
			if card == drop_candidate:
				color = Color(.8, .8, 1, 1)
			elif card == moving_card:
				color = Color(1, 1, 1, .8)
			else:
				color = Color(1, 1, 1, 1)
			card.modulate = color
				
			if (card != moving_card):
				card.position = Vector2(cell.position.x, cell.position.y + row_number * 30)
				card.z_index = row_number
			else:
				card.z_index = 100
