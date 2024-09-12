extends Node

@export var multiplayer_type: String = ""
@export var game_started: bool = false

func debug(tprint):
	print("[Client] " + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)

func _process(_delta) -> void:
	if !game_started: return
	get_node("../Server").send_positional(get_node("Player"))

func start_game():
	game_started = true
	var opp = load("res://Client/player.tscn").instantiate()
	opp.name = "Opponent"
	opp.is_auth = false
	add_child(opp)

func update_opponent_positional(data: Array):
	var opp = get_node("Opponent")
	opp.position = data[0]
	opp.velocity = data[1]
	opp.quaternion = data[2]

func _on_button_pressed():
	get_node("../Server").ping_server()


func _on_button_2_pressed():
	get_node("../Server").event_start()
