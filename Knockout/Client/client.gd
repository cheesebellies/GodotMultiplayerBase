extends Node

@export var multiplayer_type: String = ""
@export var game_started: bool = false

func debug(tprint):
	print("[Client] " + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)
	if multiplayer_type != "admin":
		$Control.queue_free()

func _process(_delta) -> void:
	if game_started:
		get_node("../Server").send_positional(get_node("Player"))

func start_game():
	game_started = true
	var opp = load("res://Client/player.tscn").instantiate()
	opp.name = "Opponent"
	opp.is_auth = false
	opp.position = Vector3(0,-9999,0)
	add_child(opp)

func update_opponent_positional(data: Array):
	var opp = get_node("Opponent")
	opp.position = data[0]
	opp.velocity = data[1]
	opp.quaternion = data[2]


func _on_start_pressed():
	get_node("../Server").event_start()
	get_node("Control").queue_free()


#func _on_ping_pressed():
	#get_node("../Server").ping_server()
