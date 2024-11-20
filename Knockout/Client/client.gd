extends Node



#Export
@export var multiplayer_type: String = ""
@export var game_started: bool = false

#Preloads
var world_pre = preload("res://Client/world.tscn")
var player_pre = preload("res://Client/player.tscn")
var pickup_pre = preload("res://Client/pickup.tscn")

#Local
var ticks: int = 0
var tte: float = 0.0
var resetting: bool = false

#Multiplayer
var server: Node
var player: CharacterBody3D
var opponent: CharacterBody3D
var has_opponent: bool = true
var opponent_id: int
var pickups: Dictionary = {0:{"ptype":0,"pvariation":4,"location_index":1}}



#UTILITY



func debug(tprint):
	print("[Client] \t\t" + str(tprint))



#BUILTINS



func _ready() -> void:
	debug("Connected as " + multiplayer_type)
	server = get_node("../Server")
	if multiplayer_type != "admin":
		$Control.queue_free()

func _physics_process(_delta: float) -> void:
	if game_started and has_opponent and !resetting:
		server.send_positional(player)



#WORLD



func setup_world():
	var world = world_pre.instantiate()
	world.name = "World"
	add_child(world)
	var opponent_spawn = get_node("World/Opponentspawn").position
	var player_spawn = get_node("World/Playerspawn").position
	if opponent_id < multiplayer.get_unique_id():
		var tmp = opponent_spawn
		opponent_spawn = player_spawn
		player_spawn = tmp
	var player = player_pre.instantiate()
	player.name = "Player"
	player.look_at_from_position(player_spawn,opponent_spawn)
	add_child(player)
	var opponent = player_pre.instantiate()
	opponent.name = "Opponent"
	opponent.is_auth = false
	opponent.look_at_from_position(opponent_spawn,player_spawn)
	add_child(opponent)
	self.player = get_node("Player")
	self.opponent = get_node("Opponent")
	get_node("World/Killbox/Area3D").connect("body_entered", _on_killbox_body_entered)
	get_node("World/pickup_0").connect("pickup",_on_pickup_picked_up)

func reset_world():
	if !has_opponent: return
	get_node("Player").free()
	get_node("Opponent").free()
	get_node("World").free()
	reset_pickups()
	setup_world()
	resetting = false

func reset_pickups():
	server.reset_pickups()
	pickups = {}
	pickups[0] = {"ptype": 0, "pvariation": 4, "location_index": 1}



#EVENTS



func force_spawn_pickup(pid: int, type: int, variation: int, location: int):
	spawn_pickup(pid,type,variation,location)

func start_game(opponent_id: int):
	self.opponent_id = opponent_id
	setup_world()
	game_started = true

func spawn_pickup(pid: int, ptype: int, pvariation: int, location_index: int):
	if !game_started or resetting: return
	#var location_options = get_node("World/PickupSpawns").get_children()
	#if used_locations.size() == location_options.size(): return
	#var count: int = 0
	#while true:
		#if count > location_options.size(): return
		#if used_locations.has((location_index+count)%location_options.size()):
			#count += 1
		#else:
			#location_index = ((location_index+count)%location_options.size())
			#break
	var pup = pickup_pre.instantiate()
	pup.ptype = ptype
	pup.pvariation = pvariation
	pup.position = get_node("World/PickupSpawns").get_children()[location_index].position
	pup.pid = pid
	pup.name = "pickup_" + str(pid)
	pickups[pid] = {"ptype": ptype, "pvariation": pvariation, "location_index": location_index}
	pup.connect("pickup",_on_pickup_picked_up)
	get_node("World").add_child(pup)

func remove_pickup(pid: int):
	if resetting: return
	pickups.erase(pid)
	get_node("World/pickup_" + str(pid)).queue_free()



#MULTIPLAYER



func confirm_pickup_picked_up(is_player: bool, pid: int):
	if resetting: return
	if !is_player: 
		remove_pickup(pid)
		return
	var ptype = pickups[pid]["ptype"]
	var pvariation = pickups[pid]["pvariation"]
	if ptype == 0:
		player.change_gun(pvariation)
	else:
		player.current_powerup = pvariation
	remove_pickup(pid)

func pickup_picked_up(pid: int):
	if resetting: return
	server.pickup_picked_up(pid)

func apply_player_positional(impulse: Vector3):
	if resetting: return
	impulse.y *= 0 if impulse.y < 0.0 else 1.0
	player.impulse(impulse + Vector3(0,1.5,0))

func update_opponent_positional(data: Array):
	if resetting: return
	opponent.position = data[0]
	opponent.velocity = data[1]
	opponent.quaternion = data[2]

func hit_opponent(normal: Vector3, weapon: Weapon):
	if resetting: return
	server.send_hit(normal*17.5*weapon.KB_mult)

func remove_opponent():
	if resetting: return
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



#SIGNALS



func _on_pickup_picked_up(pid: int):
	pickup_picked_up(pid)

func _on_killbox_body_entered(body: Node3D):
	if body == player:
		resetting = true
		server.player_death()

func _on_start_pressed():
	server.event_start()
	get_node("Control").queue_free()
	if !get_node_or_null("root/Scanner"): return
	get_node("root/Scanner").clean_up()
	get_node("root/Scanner").queue_free()
