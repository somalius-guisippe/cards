@tool
class_name Tableau
extends Node2D

var normal_cells
var cards

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
	
