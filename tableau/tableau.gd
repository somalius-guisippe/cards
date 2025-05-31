@tool
class_name Tableau
extends Node2D

var normal_cells
var cards
#the card we're moving at the moment
var moving_card: Card
#where the mouse is at the beggining of clicking the card
var movement_start
#movement start for the card
var card_start
#card under the moving card.
var drop_candidate: Card
#all possible highlights.
#var aph = []

var touched_cards = []

signal change

func get_top_cards() -> Array[Card]:
	var top_cards: Array[Card] = []
	for column in columns:
		top_cards.append(column[-1])
	return top_cards
# Eight lists of cards, arranged from the bottom of the pile to the top
var columns
func intersect(array1, array2):
	var intersection = []
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	return intersection


func area_to_card(object: Dictionary) -> Card:
	var card := object.collider.get_parent() as Card
	return card

func find_top_card(cards_clicked):
	var all_cards = $cards.get_children()
	all_cards.reverse()
	for c in all_cards:
		if c in cards_clicked:
			return c

func _input(event):
	var x = PhysicsPointQueryParameters2D.new()
	x.position = event.position
	x.collide_with_areas = true

	var object
	var button_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	if motion_event != null:
		if moving_card != null:
			moving_card.position = card_start + ( event.position - movement_start )
			update_drop_candidate()
	if button_event != null:
		if event.is_pressed(): 
			var objects_clicked = get_world_2d().direct_space_state.intersect_point(x, 10)
			var cards_clicked = objects_clicked.map(area_to_card).filter(func(x): return x != null)
			var picked_card = find_top_card(cards_clicked)
			if picked_card != null:
				if (is_at_top_of_column(picked_card)):
					$cards.move_child(picked_card, -1)
					moving_card = picked_card
					moving_card.set_moving(true)
					movement_start = event.position
					card_start = picked_card.position
					change.emit()
		if event.is_released():
			if moving_card != null:
				#moving_card.position = card_start
				moving_card.set_moving(false)
				moving_card = null
				movement_start = null
				card_start = null
				drop_candidate = null
				change.emit()

func is_at_top_of_column(card):
	for column in columns:
		if card == column[-1]:
			return true
	return false

func _ready():
	change.connect(updateView)
	var deck = []
	normal_cells = $normalCells.get_children()
		
	columns = []
	for i in range(0,8):
		columns.append([])
	
	for suit in range(0,4):
		for rank in range(1,13 + 1):
			var card = $FirstCard.duplicate()
			deck.append(card)
			$cards.add_child(card)
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
		var cell = normal_cells[column]
		columns[column].append(card)
	change.emit()

func _on_card_exit(card: Card):
	if card in touched_cards:
		touched_cards.erase(card)

func _on_card_touch(card: Card):
	#In this instance, "card" is the card that is NOT moving.
	var top_cards = get_top_cards()
	if card in top_cards:
		touched_cards.append(card)
		
		#var should_change
		#if drop_candidate:
			#var distance1 = drop_candidate.position.distance_to(moving_card.position)
			#var distance2 = card.position.distance_to(moving_card.position)
			#should_change = distance1 > distance2
		#else:
			#should_change = true
		#if should_change:
			#drop_candidate = card
			#change.emit()\
func update_drop_candidate():
	if touched_cards.size() == 0:
		drop_candidate = null
	elif touched_cards.size() == 1:
		drop_candidate = touched_cards[0]
	else:
		var distance1 = touched_cards[1].position.distance_to(moving_card.position)
		var distance2 = touched_cards[0].position.distance_to(moving_card.position)
		if distance1 > distance2:
			drop_candidate = touched_cards[0]
		else:
			drop_candidate = touched_cards[1]
	change.emit()

func updateView():
	for column_number in range(columns.size()):
		var column = columns[column_number]
		var cell = normal_cells[column_number]
		for row_number in range(column.size()):
			var card = column[row_number]
			
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
				$cards.move_child(card, -1)
	$cards.move_child(moving_card, -1)
