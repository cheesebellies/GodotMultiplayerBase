extends Node

@export var multiplayer_type: String = ""
@export var game_started: bool = false
var has_opponent = true

func debug(tprint):
	print("[Client] \t\t" + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)
	if multiplayer_type != "admin":
		$Control.queue_free()

func _physics_process(_delta: float) -> void:
	if game_started and has_opponent:
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

func apply_player_positional(impulse: Vector3):
	get_node("Player").velocity += impulse
	get_node("Player").just_hit = true

func remove_opponent():
	has_opponent = false
	get_node("Opponent").queue_free()
	var msg = TextEdit.new()
	msg.text = "Opponent disconnected"
	msg.editable = false
	msg.custom_minimum_size = Vector2(300,50)
	msg.add_theme_font_size_override("font_size",25)
	get_node("Player").add_child(msg)
	await get_tree().create_timer(5.0).timeout
	msg.queue_free()

func hit_opponent(normal: Vector3):
	get_node("../Server").send_hit(normal*2.0)

func _on_start_pressed():
	get_node("../Server").event_start()
	get_node("Control").queue_free()


#func _on_ping_pressed():
	#get_node("../Server").ping_server()
