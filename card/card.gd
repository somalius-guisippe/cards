@tool
class_name Card
extends StaticBody2D

var is_moving = false
signal touched_card(card:Node2D)
signal exited_card(card:Node2D)

func set_moving(x: bool) -> void:
	is_moving = x

enum Suit {
  Spade, # 0
  Heart, # 1
  Diamond, # 2
  Club # 3
}

@export_group("Card")

@export var suit: Suit = Suit.Spade:
	set = _set_suit
	
@export_range(1, 13) var rank: int = 1:
	set = _set_rank

var _sprite: AnimatedSprite2D

signal change

func _ready():
	_sprite = $Sprite
	change.connect(_on_change)
	_pick_animation_frame()

func _on_change():
	if is_node_ready():
		_pick_animation_frame()

func _pick_animation_frame():
	_sprite.frame = suit * 13 + rank - 1

func _set_suit(x: Suit):
	suit = x
	change.emit()

func _set_rank(x: int):
	rank = x
	change.emit()

func _on_body_body_entered(body: Node2D) -> void:
	if is_moving:
		touched_card.emit(body)

func _on_body_body_exited(body: Node2D) -> void:
	exited_card.emit(body)

func _to_string():
	return (str(suit) + " " + str(rank))
