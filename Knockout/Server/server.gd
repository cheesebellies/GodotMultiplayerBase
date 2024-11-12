extends Node



#Constants



#Enums



enum {PACKET_TYPE_PING, PACKET_TYPE_POSITIONAL, PACKET_TYPE_EVENT, PACKET_TYPE_IMPULSE, PACKET_TYPE_STATE, PACKET_TYPE_OTHER}
enum {EVENT_TYPE_GAME_START, EVENT_TYPE_PLAYER_LEAVE, EVENT_TYPE_GAME_END, EVENT_TYPE_PLAYER_DEATH, EVENT_TYPE_PICKUP, EVENT_TYPE_PICKUP_RESET, EVENT_TYPE_PICKUP_SPAWN}
enum {EVENT_INFO_MATCH_WON, EVENT_INFO_MATCH_LOST}



#Export vars



@export var multiplayer_type: String = ""
@export var multiplayer_ip: String = "localhost"
@export var multiplayer_port: int = 9999
@export var multiplayer_player_limit: int = 16



#Variables



var client: Node = null
var pairings: Dictionary = {}
var game_ids: Dictionary = {}
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var game_state_exclusives: Dictionary = {"pickups": {}}
var pid_counter: int = 0



#Utility functions



func debugs(tprint):
	print("[Server] \t\t" + str(tprint))

func debuge(tprint):
	print("[" + str(multiplayer.get_unique_id()) + "]   \t" + str(tprint))



#Built-in functions



func init():
	if multiplayer_type != "endpoint":
		enet_peer.create_server(multiplayer_port,multiplayer_player_limit)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.peer_packet.connect(_server_packet_received)
		debugs("Online")
	else:
		get_node("Timer").queue_free()
		enet_peer.create_client(multiplayer_ip, multiplayer_port)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_packet.connect(_endpoint_packet_received)
		multiplayer.server_disconnected.connect(_endpoint_server_disconnect)
		debuge("Connected")


func _ready():
	# Multiplayer functions get reset after added to tree, any changes in init
	pass



#Gameplay functions



func return_to_menu(code: int):
	print("[0]\t\t\t\tServer disconnected")
	if code == 1:
		pass
	if(multiplayer.is_server()): multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_node("../Client").queue_free()
	var menu = load("res://Menus/menu.tscn").instantiate()
	menu.name = "Menu"
	get_node("/root").add_child(menu)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.queue_free()

func make_pairings():
	var pl = multiplayer.get_peers()
	var fl = {}
	for i in range(0,len(pl),2):
		if (len(pl) - i) < 2:
			fl[pl[i]] = -1
			break
		fl[pl[i]] = pl[i+1]
		fl[pl[i+1]] = pl[i]
		game_ids[pl[i]] = i
		game_ids[pl[i+1]] = i
		game_state_exclusives["pickups"][i] = {0:true}
	pairings = fl

func update_position(packet: PackedByteArray):
	var data = unpack_positional(packet)
	client.update_opponent_positional(data)

func apply_impulse(packet: PackedByteArray):
	var impulse = Vector3()
	impulse.x = packet.decode_float(1)
	impulse.y = packet.decode_float(5)
	impulse.z = packet.decode_float(9)
	client.apply_player_positional(impulse)

func start_game(isPlaying: int, oppid: int):
	if isPlaying == 0:
		client.start_game(oppid)
	else:
		debuge("(insert spectation code here)")

func handle_player_disconnect():
	client.remove_opponent()
	debuge("Opponent disconnected")

func handle_player_death(wol: int):
	client.reset_world()
	debuge("Match won" if wol == EVENT_INFO_MATCH_WON else "Match lost")

func evaluate_pickup(id: int, packet: PackedByteArray):
	var pid = packet.decode_u16(2)
	if game_state_exclusives["pickups"][game_ids[id]][pid]:
		game_state_exclusives["pickups"][game_ids[id]][pid] = false
		echo_pickup_picked_up(id,pid)

func confirm_pickup(is_player: bool, pid: int):
	client.confirm_pickup_picked_up(is_player, pid)

func reset_pickups_server(id: int):
	game_state_exclusives["pickups"][game_ids[id]] = {0:true}

func spawn_pseudo_random_pickup(seed: int, pid: int):
	client.spawn_pickup_from_rand(seed, pid)



#Bit processing



func unpack_positional(packet: PackedByteArray) -> Array:
	var pos = Vector3()
	var vel = Vector3()
	var rot = Quaternion()
	pos.x = packet.decode_float(1)
	pos.y = packet.decode_float(5)
	pos.z = packet.decode_float(9)
	vel.x = packet.decode_float(13)
	vel.y = packet.decode_float(17)
	vel.z = packet.decode_float(21)
	rot.w = packet.decode_float(25)
	rot.x = packet.decode_float(29)
	rot.y = packet.decode_float(33)
	rot.z = packet.decode_float(37)
	return [pos,vel,rot]

func pack_positional(node: Node3D) -> PackedByteArray:
	#***********************************************************
	# Note that a normal float is 8 bytes, but for both Vector3
	# and Quaternion, they are reduced to 4 bytes for speed.
	# With PackedByteArray, 'double' is a normal float and
	# 'float' is the 32 bit version
	#
	# Position: Vector3: 3 floats (4, 4, 4) bytes
	# Velocity: Vector3: 3 floats (4, 4, 4) bytes
	# Rotation: Quaternion: 4 floats (4, 4, 4, 4) bytes
	#***********************************************************
	var pos = node.position
	var vel = node.velocity
	var rot = node.quaternion
	var packet = PackedByteArray()
	packet.resize(41)
	packet.encode_u8(0,PACKET_TYPE_POSITIONAL)
	packet.encode_float(1,pos.x)
	packet.encode_float(5,pos.y)
	packet.encode_float(9,pos.z)
	packet.encode_float(13,vel.x)
	packet.encode_float(17,vel.y)
	packet.encode_float(21,vel.z)
	packet.encode_float(25,rot.w)
	packet.encode_float(29,rot.x)
	packet.encode_float(33,rot.y)
	packet.encode_float(37,rot.z)
	return packet



#Packet functions



func request_random_pickup_spawn(seed: int, pid: int):
	debugs("Spawning pickup")
	var packet = PackedByteArray()
	packet.resize(5)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PICKUP_SPAWN)
	packet.encode_u8(2,seed)
	packet.encode_u16(3,pid)
	multiplayer.send_bytes(packet,0,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func reset_pickups():
	var packet = PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PICKUP_RESET)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func echo_pickup_picked_up(id: int, pid: int):
	var packet = PackedByteArray()
	packet.resize(5)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PICKUP)
	packet.encode_u8(2,0)
	packet.encode_u16(3,pid)
	multiplayer.send_bytes(packet,id,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)
	packet.encode_u8(2,1)
	multiplayer.send_bytes(packet,pairings[id],MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func pickup_picked_up(pid: int):
	var packet = PackedByteArray()
	packet.resize(4)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PICKUP)
	packet.encode_u16(2,pid)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func player_death():
	var packet = PackedByteArray()
	packet.resize(3)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PLAYER_DEATH)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func player_death_echo(id: int, packet: PackedByteArray):
	packet.encode_u8(2,EVENT_INFO_MATCH_LOST)
	multiplayer.send_bytes(packet, id, MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)
	packet.encode_u8(2,EVENT_INFO_MATCH_WON)
	multiplayer.send_bytes(packet, pairings[id], MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func alert_player_leave(id: int):
	var packet = PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_PLAYER_LEAVE)
	multiplayer.send_bytes(packet,pairings[id],MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func send_hit(vel: Vector3):
	var packet = PackedByteArray()
	packet.resize(13)
	packet.encode_u8(0,PACKET_TYPE_IMPULSE)
	packet.encode_float(1,vel.x)
	packet.encode_float(5,vel.y)
	packet.encode_float(9,vel.z)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func echo_hit(id: int, packet: PackedByteArray):
	multiplayer.send_bytes(packet,pairings[id],MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func send_positional(node: Node3D):
	var packet = pack_positional(node)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED,1)

func echo_positional(id: int, packet: PackedByteArray):
	multiplayer.send_bytes(packet,pairings[id],MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED,1)

func event_start_echo():
	var packet = PackedByteArray()
	packet.resize(7)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_GAME_START)
	for peer in multiplayer.get_peers():
		if pairings[peer] != -1:
			packet.encode_u8(2,0)
		else:
			packet.encode_u8(2,1)
		packet.encode_u32(3,pairings[peer])
		multiplayer.send_bytes(packet,peer,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func event_start():
	var packet = PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_GAME_START)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func ping_response(id):
	var packet = PackedByteArray()
	packet.resize(1)
	packet.encode_u8(0,PACKET_TYPE_PING)
	multiplayer.send_bytes(packet,id,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func ping_server():
	var packet = PackedByteArray()
	packet.resize(1)
	packet.encode_u8(0,PACKET_TYPE_PING)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)



#Signals



func _pickup_spawn_timer_timeout():
	pid_counter += 1
	for i in game_state_exclusives["pickups"].keys():
		game_state_exclusives["pickups"][i][pid_counter] = true
	request_random_pickup_spawn(randi_range(0,128), pid_counter)

func _endpoint_server_disconnect():
	return_to_menu(1)

func _peer_disconnected(id):
	alert_player_leave(id)
	debugs("Peer disconnected: " + str(id))

func _peer_connected(id):
	debugs("Peer connected: " + str(id))

func _endpoint_packet_received(_id: int, packet: PackedByteArray):
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_POSITIONAL:
			update_position(packet)
		PACKET_TYPE_PING:
			debuge("Ping Successful")
		PACKET_TYPE_EVENT:
			var type = packet.decode_u8(1)
			if type == EVENT_TYPE_GAME_START:
				start_game(packet.decode_u8(2),packet.decode_u32(3))
			elif type == EVENT_TYPE_PLAYER_LEAVE:
				handle_player_disconnect()
			elif type == EVENT_TYPE_PLAYER_DEATH:
				handle_player_death(packet.decode_u8(2))
			elif type == EVENT_TYPE_PICKUP:
				confirm_pickup(packet.decode_u8(2) == 0,packet.decode_u16(3)) 
			elif type == EVENT_TYPE_PICKUP_SPAWN:
				spawn_pseudo_random_pickup(packet.decode_u8(2),packet.decode_u16(3))
		PACKET_TYPE_IMPULSE:
			apply_impulse(packet)


func _server_packet_received(id: int, packet: PackedByteArray):
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_POSITIONAL:
			echo_positional(id, packet)
		PACKET_TYPE_PING:
			ping_response(id)
		PACKET_TYPE_EVENT:
			var type = packet.decode_u8(1)
			if type == EVENT_TYPE_PLAYER_DEATH:
				# Matchmaking code here
				player_death_echo(id, packet)
			elif type == EVENT_TYPE_GAME_START:
				multiplayer.multiplayer_peer.refuse_new_connections = true
				make_pairings()
				event_start_echo()
			elif type == EVENT_TYPE_PICKUP:
				evaluate_pickup(id,packet)
			elif type == EVENT_TYPE_PICKUP_RESET:
				reset_pickups_server(id)
		PACKET_TYPE_IMPULSE:
			echo_hit(id,packet)
