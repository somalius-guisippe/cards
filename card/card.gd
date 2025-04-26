@tool
class_name Card
extends Node2D

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

@onready var _sprite: AnimatedSprite2D = $Sprite

signal change

func _ready():
	change.connect(_on_change)
	_pick_animation_frame()

func _pick_animation_frame():
	_sprite.frame = suit * 13 + rank - 1

func _on_change():
	if is_node_ready():
		_pick_animation_frame()

func _set_suit(x: Suit):
	suit = x
	change.emit()

func _set_rank(x: int):
	rank = x
	change.emit()
