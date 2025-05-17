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

func get_card_intersections() -> Array[Card]:
	var p = PhysicsShapeQueryParameters2D.new()
	p.collide_with_areas = true
	p.collide_with_bodies = true
	p.shape = $Area2D/CollisionShape2D
	var os: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(p)
	print("os", os)
	var xs: Array[Card] = []
	for o in os:
		var x := o.collider.get_parent().get_parent() as Card
		if (x != null):
			xs.append(x)
	return xs
