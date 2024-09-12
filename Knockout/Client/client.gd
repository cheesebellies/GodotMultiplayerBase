extends Node3D

@export var multiplayer_type: String = ""

func debug(tprint):
	print("[Client] " + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)


func _on_button_pressed():
	get_parent().get_node("Server").ping_server()
