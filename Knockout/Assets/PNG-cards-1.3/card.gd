@tool
extends Node3D

@export var texture: Texture:
	set(value):
		_set_card_texture(value)
		texture = value

var card: Card:
	set(value):
		_get_card_texture(value)
		card = value

func _set_card_texture(tex):
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	$MeshInstance3D.set_surface_override_material(0,mat)

func _get_card_texture(card: Card):
	var key = ""
	var is2 = false
	if card.number < 8:
		key += str(card.number+2) + "_of_"
	else:
		match card.number:
			Global.numbers.JACK:
				key += "jack_of_"
				is2 = true
			Global.numbers.QUEEN:
				key += "queen_of_"
				is2 = true
			Global.numbers.KING:
				key += "queen_of_"
				is2 = true
			Global.numbers.ACE:
				key += "ace_of_"
				is2 = card.suit == Global.suits.SPADES
	match card.suit:
		Global.suits.SPADES:
			key += "spades"
		Global.suits.HEARTS:
			key += "hearts"
		Global.suits.DIAMONDS:
			key += "diamonds"
		Global.suits.CLUBS:
			key += "clubs"
	if is2:
		key += "2"
	key += ".png"
	texture = load("res://Assets/PNG-cards-1.3/" + key)
