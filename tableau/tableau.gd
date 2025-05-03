@tool
class_name Tableau
extends Node2D

func _ready():
	var deck = []
	for suit in range(0,4):
		for rank in range(1,13 + 1):
			var card = $FirstCard.duplicate()
			deck.append(card)
			add_child(card)
			card.rank = rank
			card.suit = suit
			#card.position = Vector2(100 + 50 * rank, 100 + 30 * rank + 50 * suit)
	deck.shuffle()
	for i in range(deck.size()):
		var card = deck[i]
		card.position = Vector2(100 + 50 * i, 100 + 30 * i + 50 * i)
		move_child(card, i)
	
