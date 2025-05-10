@tool
class_name Tableau
extends Node2D

var normal_cells
var cards
#the card we're moving at the moment
var moving_card
#where the mouse is at the beggining of clicking the card
var movement_start
#movement start for the card
var card_start

# Eight lists of cards, arranged from the bottom of the pile to the top
var columns

func area_to_card(object):
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
	if button_event != null:
		if event.is_pressed(): 
			var objects_clicked = get_world_2d().direct_space_state.intersect_point(x, 10)
			var cards_clicked = objects_clicked.map(area_to_card).filter(func(x): return x != null)
			var picked_card = find_top_card(cards_clicked)
			if picked_card != null:
				if (is_at_top_of_column(picked_card)):
					moving_card = picked_card
					movement_start = event.position
					card_start = picked_card.position
		if event.is_released():
			print(event)
			if moving_card != null:
				moving_card.position = card_start
				moving_card = null
				movement_start = null
				card_start = null

func is_at_top_of_column(card):
	for column in columns:
		if card == column[-1]:
			return true
	return false

func _ready():
	var deck = []
	normal_cells = $normalCells.get_children()
	cards = $cards
	
	columns = []
	for i in range(0,8):
		columns.append([])
	
	for suit in range(0,4):
		for rank in range(1,13 + 1):
			var card = $FirstCard.duplicate()
			deck.append(card)
			cards.add_child(card)
			card.rank = rank
			card.suit = suit
			#card.position = Vector2(100 + 50 * rank, 100 + 30 * rank + 50 * suit)
	deck.shuffle()
	for i in range(deck.size()):
		var row = i/8
		var column = i%8
		var card = deck[i]
		var cell = normal_cells[column]
		columns[column].append(card)
		card.position = Vector2(cell.position.x, cell.position.y + row * 30)
		cards.move_child(card, i)
	
