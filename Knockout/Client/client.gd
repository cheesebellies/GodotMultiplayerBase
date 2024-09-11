extends Node

@export var multiplayer_type: String = ""

func debug(tprint):
	print("[Client] " + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)
