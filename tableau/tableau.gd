@tool
class_name Tableau
extends Node2D

var normal_cells
var cards

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
	var mouse_event := event as InputEventMouse
	if event.is_pressed() and mouse_event != null: 
		var objects_clicked = get_world_2d().direct_space_state.intersect_point(x, 10)
		var cards_clicked = objects_clicked.map(area_to_card).filter(func(x): return x != null)
		var top_card = find_top_card(cards_clicked)
		if top_card != null:
			print(top_card.rank)
			
		#
		#for object in objects_clicked:
			#var card := object.get_parent() as Card
			#if card != null:
				#yield card
		#
		#if objects_clicked.size() > 0:
			#object = objects_clicked[-1].collider
			#
			#
			#var card := object.get_parent() as Card
			#if card != null:
				#var all_cards = $cards.get_children()
				#all_cards.reverse()
				#for c in all_cards:
					#
					#print(card.rank)


func _ready():
	var deck = []
	normal_cells = $normalCells.get_children()
	cards = $cards
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
		card.position = Vector2(cell.position.x, cell.position.y + row * 30)
		cards.move_child(card, i)
	
