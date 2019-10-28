extends Area2D

signal in_focus
signal play_effect
signal card_selected

export (int) var focus_move_on_y = 80
export (bool) var drag_and_drop #Used for drag and drop of cards.  If turned off interface is click to select.

var card : Resource
var card_name : String
var cost : int
var type : String
var power : int
var defense : int
var flavour_text : String
var health : int

var hand_location #modified on creation to store default location on Table node
var hand_rotation
var base_z
var focus_area

var dragMouse :  = false
var card_selected : = false
var can_move : = true
var focusCard :  = false
var card_in_play : = false

var deck_location : = Vector2.ZERO
var dealt : = false

var collision_startpos
var collision_focuspos


func _ready():
	pass


func _process(_delta): 
	#If drag and drop is being used, this is used to drage the card.
	if drag_and_drop:
		if(dragMouse):
			set_position(get_viewport().get_mouse_position()+ Vector2(-40, -80))


#Used to tweed card from it's position to a destination.
func move_card(dest, rotate = null):
		$Tween.interpolate_property(self, "position" , position, dest, 0.3, Tween.TRANS_BACK, Tween.EASE_OUT)
		if rotate != null:
			$Tween.interpolate_property(self, "rotation", rotation, rotate, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()

#Sets variables when the card is created based on the card resource attached to it.
#Please see instructions (when they are written lol) if you don't understand how to create resources with custom template (Cardtypes.gd).	
func card_initialize(path, type):
	card = load(path + type)
	card_name = card.card_name
	$name.text = card_name
	cost = card.cost
	$Cost.text = str(cost)
	type = card.type
	power = card.power
	$power.text = str(power)
	defense = card.defense
	$defense.text = str(defense)
	flavour_text = card.flavour_text
	$flavour.text = flavour_text
	health = card.health
	if card.sprite != null:
		$Sprite2.texture = card.sprite
	hand_location = position
	collision_startpos = $CollisionShape2D.position.y 
	collision_focuspos = $CollisionShape2D.position.y +80

func card_selection(val):
	card_selected = val
	print ("Card_selected value change: " + str(card_selected))
	emit_signal("card_selected", val, z_index)

#Make card focus, which allows it to be clicked or dragged for an effect
func make_focus():
	if can_move:
		var position_shift = position
		position_shift.y -= focus_move_on_y
		z_index += 10
		emit_signal("in_focus", z_index)
		focusCard = true
		if position == hand_location:
	#		rotation = 0.0
			move_card(position_shift, 0.0)
			if focus_area != null:
				move_card(focus_area, 0.0)
	#		position.y -= focus_move_on_y
			$CollisionShape2D.scale.y = 1.5
			$CollisionShape2D.position.y = collision_focuspos

#Removes focus from card.
func off_focus(z):
	if can_move:
		if z != z_index && !card_in_play:
			focusCard = false
			move_card(hand_location, hand_rotation)
			yield(get_tree().create_timer(0.3), "timeout")
			z_index = base_z
			$CollisionShape2D.scale.y = 1.0
			$CollisionShape2D.position.y = collision_startpos
		else:
			focusCard = true

func _lock_movement(card, sel):
	if sel:
		if card == z_index:
			can_move = true
		else: 
			move_card(hand_location)
			can_move = false
	else: 
		can_move = true

# called when over a valid play area
func set_play_area():
	card_in_play = true

# called when no longer over a valid play area if not played.
func unset_play_area():
	card_in_play = false

# stops mouse drag if left button is no longer held
func _unhandled_input(event):
	if event is InputEventMouseButton and not event.is_action_pressed("left_click"):
		dragMouse = false
		card_selection(false)
		pass

# used to enable mouse drag and effects target play_effect if dropped on a valid target
func _on_Card_input_event(_viewport, event, shape_idx):
	if event is InputEventMouseButton and drag_and_drop:
		if event.is_action_pressed("left_click") and focusCard:
			print("leftclick")
			dragMouse = true
			card_selection(true)
		if event.is_action_released("left_click") and card_in_play:
			emit_signal("play_effect", self.get_path())

# makes card focus when mouse entered.
func _on_Card_mouse_entered():
	make_focus()

# can be used to make the card return to it's default position on mouse exit.
func _on_Card_mouse_exited():
#	position = hand_location
# OR YOU CAN USE (not both)
#	move_card(hand_location)
	pass

# Timer used to make the card dance a bit when it gets into position
func _on_Timer_timeout():
	#Checks to see if there is a deck location. If there isn't, first if statment runs.
	if deck_location != Vector2.ZERO and !dealt:
		move_card(hand_location, hand_rotation)
		dealt = true
	else:
		position = hand_location

	#Jiggle effect  Card dips down and then up. Stays slightly above so it's easy to identify new drawn cards.
	move_card(Vector2(hand_location.x, hand_location.y + 40))
	yield(get_tree().create_timer(0.3), "timeout")
	move_card(Vector2(hand_location.x, hand_location.y - 60))
	pass