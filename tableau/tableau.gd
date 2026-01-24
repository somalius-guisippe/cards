@tool
class_name Tableau
extends Node2D
# This script:
	#-models the game-state,
	#-defines legal moves,
	#-draws the board,
	#-recognizes inputs,

# List of the bases of piles in the main play area
var cascades

#list of foundation cells
var foundations

# List of places where we can place any single card
var cells: Array[Node2D]

#the card we're moving at the moment
var moving_cards: Array[Card] = []
#where the mouse is at the beggining of clicking the card
var movement_start
#movement start for the card
var card_start
#card under the moving card.
var drop_candidate: Node2D
#all possible highlights.
#var aph = []

var touched_cards = []

var deck = []


enum Mode {
	Gameplay,
	Fun,
}
var mode :Mode = Mode.Gameplay



	
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

	var keyEvent := event as InputEventKey

	var object
	var button_event := event as InputEventMouseButton
	var motion_event := event as InputEventMouseMotion
	
	if keyEvent != null:
		if event.pressed and event.keycode == KEY_APOSTROPHE:
			if keyEvent.ctrl_pressed && keyEvent.alt_pressed:
				Global.cheat()
		if event.pressed and event.keycode == KEY_Z:
			if keyEvent.ctrl_pressed:
				undo()
		if keyEvent.pressed and event.keycode == KEY_Y:
			if keyEvent.ctrl_pressed:
				Global.redo()
	if motion_event != null:
		if moving_cards != []:
			for c in moving_cards.size():
				moving_cards[c].position = card_start + ( event.position - movement_start )
				moving_cards[c].position.y += c*30
				moving_cards[c].z_index = 100+c
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
				if (Global.current().is_card_moveable(picked_card)):
					$Cards.move_child(picked_card, -1)
					
					# get_cards_under(c):
					#   If c is on a cell or foundation, return []
					#   If c is on a cascade, return c plus any cards under it 
					moving_cards = Global.current().get_cards_under(picked_card)
					
					moving_cards[0].set_moving(true)
					movement_start = event.position
					card_start = picked_card.position
					Global.change.emit()
		if event.is_released():
			if moving_cards != []:
				if drop_candidate != null:
					var drop_candidate_card := drop_candidate as Card
					if drop_candidate_card != null:
						Global.move_card(moving_cards, Global.current().getCardContext(drop_candidate))
					var i = cells.find(drop_candidate)
					if i != -1:
						Global.move_card(moving_cards, {"category": "cellCard", "index": i})

					# Handle dropping onto a foundation base
					var viable = foundations.find(drop_candidate)
					if viable != -1:
						Global.move_card(moving_cards, {"category": "foundationCard", "index": viable})
						# Global.current().foundation_cards[viable].append(moving_card)
					i = cascades.find(drop_candidate)
					if i != -1:
						Global.move_card(moving_cards, {"category": "cascadeCard", "index": i})
					while true:
						var cardToGoUp = Global.current().auto_go_up()
						if cardToGoUp != null:
							Global.move_card([cardToGoUp], Global.current().foundationStatus(cardToGoUp))
						else:
							break

				moving_cards[0].set_moving(false)
				moving_cards = []
				movement_start = null
				card_start = null
				drop_candidate = null
				touched_cards = []
				Global.change.emit()


func game_setup():
	Global.game_setup(deck)

func _ready():
	cells = [
		$Cells/cell1,
		$Cells/cell2,
		$Cells/cell3,
		$Cells/cell4]
	foundations = [
		$Foundations/foundation1,
		$Foundations/foundation2,
		$Foundations/foundation3,
		$Foundations/foundation4
	]
	
	$restart.pressed.connect(game_setup)
	$undo.pressed.connect(undo)
	
	Global.change.connect(updateView)
	deck = []
	cascades = $Cascades.get_children()
	
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
	game_setup()

func _on_card_exit(card: Node2D):
	if card in touched_cards:
		touched_cards.erase(card)
	Global.change.emit()

func _on_card_touch(node: Node2D):
	#In this instance, "node" is the card that is NOT moving.
	var card := node as Card
	if card != null:
		var top_cards = Global.current().get_top_cards()
		if node in top_cards:
			touched_cards.append(node)
	elif (node in cells) or (node in foundations) or (node in cascades):
		touched_cards.append(node)
	#elif node in foundations:
		#touched_cards.append(node)
	#elif node in cascades:
		#touched_cards.append(node)
	Global.change.emit()

func update_drop_candidate():
	if touched_cards.size() == 0:
		drop_candidate = null
	elif touched_cards.size() == 1:
		maybe_set_drop_candidate(touched_cards[0])
	else:
		var distance1 = touched_cards[1].position.distance_to(moving_cards[0].position)
		var distance2 = touched_cards[0].position.distance_to(moving_cards[0].position)
		if distance1 > distance2:
			maybe_set_drop_candidate(touched_cards[0])
		else:
			maybe_set_drop_candidate(touched_cards[1])
	Global.change.emit()

func maybe_set_drop_candidate(x):
	if x in cells:
		var i = cells.find(x)
		var card = Global.current().free_cell_cards[i]
		if card == null:
			drop_candidate = x
			return
	elif x in foundations:
		print("b")
		var i = foundations.find(x)
		if Global.current().foundation_cards[i] == [] and moving_cards.size() == 1:
			if moving_cards[0].rank == 1:
				drop_candidate = x
				return
			else:
				var spec_Foundation = Global.current().foundation_cards[i]
				#Bug!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				if spec_Foundation != []:
					var foundation_top = spec_Foundation[-1]
					var foundation_rank = foundation_top.rank
					if moving_cards[0].rank == foundation_rank + 1:
						if moving_cards[0].suit == foundation_top.suit:
							drop_candidate = x
							return
	elif x in cascades:
		#RETURN HERE IN THE FUTURE FOR MATH.
		var i = cascades.find(x)
		if Global.current().can_move_to_cascade(moving_cards[0], i) && Global.current().columns[i] == []:
			drop_candidate = x
			return
		
	else:
		print("a")
		var cascade_position = Global.current().findCardColumn(x)
		var can_place = (x.rank == moving_cards[0].rank+1) && Global.different_color(x.suit, moving_cards[0].suit) && Global.current().can_move_to_cascade(moving_cards[0], cascade_position)
		if can_place:
			drop_candidate = x
			return
		var CardContext = Global.current().getCardContext(x)
		#"category": "foundationCard"
		if CardContext ["category"] == "foundationCard":
			print("A")
			if moving_cards.size() < 2:
				print("AA")
				if moving_cards[0].rank == x.rank+1 && moving_cards[0].suit == x.suit:
					print("AAA")
					drop_candidate = x
					return
	drop_candidate = null


func updateView():
	if mode != Mode.Gameplay:
		return
	
	if Global.current().hasWon():
		mode = Mode.Fun
		win()
		
	# Set the transparency/tint of every card
	for card in deck:
		var color
		if card == drop_candidate:
			color = Color(.8, .8, 1, 1)
		elif moving_cards.has(card):
			color = Color(1, 1, 1, .8)
		else:
			color = Color(1, 1, 1, 1)
		card.modulate = color
	
	# Color the foundation bases
	# Position cards on the foundations
	for i in range(4):
		var foundation = foundations[i]
		var color
		if foundation == drop_candidate:
			color = Color(.8, .8, 1, 1)
		else:
			color = Color(1, 1, 1, 1)
		for card in Global.current().foundation_cards[i]:
			card.position = foundation.position
		foundation.modulate = color
		
	# Color the free cells
	# Position cards on free cells
	for i in range(4):
		var cell = cells[i]
		var free_cell_card = Global.current().free_cell_cards[i]
		if free_cell_card != null:
			if not moving_cards.has(free_cell_card):
				free_cell_card.position = cell.position
		var color
		if cell == drop_candidate:
			color = Color(.8, .8, 1, 1)
		else:
			color = Color(1, 1, 1, 1)
		cell.modulate = color
	
	# Color the cascade bases
	# Position cards onto cascade columns
	for column_number in range(8):
		var column = Global.current().columns[column_number]
		var cell = cascades[column_number]
		var color
		if cell == drop_candidate:
			color = Color(.8, .8, 1, 1)
		else:
			color = Color(1, 1 , 1, 1)
		cell.modulate = color
		
		for row_number in range(column.size()):
			var card: Card = column[row_number]
			
			if not moving_cards.has(card):
				card.position = Vector2(cell.position.x, cell.position.y + row_number * 30)
				card.z_index = row_number
	
	for card in Global.current().secretColumn:
		card.position = $Cascades/SecretCascade.position
		
func undo():
	Global.undo()
func win():
	print("you won with ",Global.history.size()," moves!")

func _physics_process(delta: float) -> void:
	#print("We are processing physics.", mode)
	if mode != Mode.Fun:
		return

	if animated_cards.is_empty():
		for foundation in Global.current().foundation_cards:
			animated_cards.append(foundation[-1])

	var cards_copied_0 = int(cards_per_second * animation_time)
	
	animation_time += delta

	var cards_copied_1 = int(cards_per_second * animation_time)
	
	
	#print(str(animation_time) + " | " + str(cards_copied_0) + " | " + str(cards_copied_1))
	for t in range(cards_copied_0, cards_copied_1):
		for animated_card in animated_cards:
			var duplicate: Card = animated_card.duplicate()
			$FunCards.add_child(duplicate)
			var a = -1
			var b = 2
			var x = t * 10
			var y = (a * (t ** 2)) + (b * t)
			if (t < 15):
				print(t," ", x," ", y)
			duplicate.position.y = animated_card.position.y - 10 * y
			duplicate.position.x = animated_card.position.x - x
			
# seconds
var animation_time = 0

var animated_cards: Array[Card]

var cards_per_second = 8
