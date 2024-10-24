extends Node

@export var multiplayer_type: String = ""
@export var game_started: bool = false
var has_opponent = true
var last = 0
var ticks = 0
var tte = 0.0
var dmg_percent = 1.0
var player: CharacterBody3D = null
var opponent: CharacterBody3D = null

func debug(tprint):
	print("[Client] \t\t" + str(tprint))

func _ready() -> void:
	debug("Connected as " + multiplayer_type)
	if multiplayer_type != "admin":
		$Control.queue_free()

func _physics_process(delta: float) -> void:
	if game_started and has_opponent:
		get_node("../Server").send_positional(player)

func start_game(oppid: int):
	game_started = true
	var opp_spawn = get_node("World/Opponentspawn").position
	var player_spawn = get_node("World/Playerspawn").position
	if oppid < multiplayer.get_unique_id():
		var tmp = opp_spawn
		opp_spawn = player_spawn
		player_spawn = tmp
	var play = load("res://Client/player.tscn").instantiate()
	play.name = "Player"
	play.look_at_from_position(player_spawn,opp_spawn)
	add_child(play)
	var opp = load("res://Client/player.tscn").instantiate()
	opp.name = "Opponent"
	opp.is_auth = false
	opp.look_at_from_position(opp_spawn,player_spawn)
	add_child(opp)
	player = get_node("Player")
	opponent = get_node("Opponent")

func update_opponent_positional(data: Array):
	opponent.position = data[0]
	opponent.velocity = data[1]
	opponent.quaternion = data[2]

func apply_player_positional(impulse: Vector3):
	dmg_percent += 0.02
	player.velocity += impulse*dmg_percent
	player.just_hit = true

func remove_opponent():
	has_opponent = false
	opponent.queue_free()
	opponent = null
	var msg = TextEdit.new()
	msg.text = "Opponent disconnected"
	msg.editable = false
	msg.custom_minimum_size = Vector2(300,50)
	msg.add_theme_font_size_override("font_size",25)
	player.add_child(msg)
	await get_tree().create_timer(5.0).timeout
	msg.queue_free()

func hit_opponent(normal: Vector3):
	get_node("../Server").send_hit(normal*2.0)

func _on_start_pressed():
	get_node("../Server").event_start()
	get_node("Control").queue_free()
	if !get_node_or_null("root/Scanner"): return
	get_node("root/Scanner").clean_up()
	get_node("root/Scanner").queue_free()


#func _on_ping_pressed():
	#get_node("../Server").ping_server()
