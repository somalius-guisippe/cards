@tool
class_name Tableau
extends Node2D

func _ready():
	for suit in range(0,4):
		for rank in range(1,13 + 1):
			var card = $FirstCard.duplicate()
			add_child(card)
			card.rank = rank
			card.suit = suit
			card.position = Vector2(100 + 50 * rank, 100 + 30 * rank + 50 * suit)
	
