extends Node



#Constants



#



#Enums



enum {PACKET_TYPE_PING, PACKET_TYPE_POSITIONAL, PACKET_TYPE_EVENT, PACKET_TYPE_IMPULSE, PACKET_TYPE_STATE, PACKET_TYPE_OTHER}
enum {EVENT_TYPE_GAME_START, EVENT_TYPE_PLAYER_LEAVE, EVENT_TYPE_GAME_END, EVENT_TYPE_PLAYER_DEATH, EVENT_TYPE_TRACER, EVENT_TYPE_HAND_CARDS_UPDATE}
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
var player_ids: Dictionary = {}
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var game_state: Dictionary = {}



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
	var default_cards = []
	for s in range(4):
		for n in range(13):
			default_cards.append(Card.new(n,s))
	for i in range(0,len(pl),2):
		if (len(pl) - i) < 2:
			fl[pl[i]] = -1
			break
		fl[pl[i]] = pl[i+1]
		fl[pl[i+1]] = pl[i]
		game_ids[pl[i]] = i
		game_ids[pl[i+1]] = i
		player_ids[i] = [pl[i],pl[i+1]]
		game_state[i] = {'deck' = default_cards.duplicate()}
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

func spawn_client_tracer(packet: PackedByteArray):
	var data = unpack_tracer(packet)
	var direction = data[0]
	var speed = data[1]
	var homing = data[2]
	var grenade = data[3]
	client.spawn_tracer(direction,speed,homing,grenade)

func set_game_hands_random(game_id: int):
	var card_options: Array = game_state[game_id]["deck"]
	var choices = []
	for i in range(4):
		var c = card_options.pick_random()
		choices.append(c)
		card_options.erase(c)
	game_state[game_id]["deck"] = card_options
	var c = 0
	for player_id in player_ids[game_id]:
		update_client_cards(player_id, choices[c], choices[c+1])
		c += 2




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

func pack_tracer(direction: Vector3, speed: float, homing: bool, grenade: bool) -> PackedByteArray:
	var packet = PackedByteArray()
	packet.resize(24)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_TRACER)
	packet.encode_float(2,direction.x)
	packet.encode_float(6,direction.y)
	packet.encode_float(10,direction.z)
	packet.encode_double(14,speed)
	packet.encode_u8(22,0 if homing else 1)
	packet.encode_u8(23,0 if grenade else 1)
	return packet

func unpack_tracer(packet: PackedByteArray) -> Array:
	var direction: Vector3 = Vector3(0,0,0)
	var speed: float = 0.0
	var homing: bool = false
	var grenade: bool = false
	direction.x = packet.decode_float(2)
	direction.y = packet.decode_float(6)
	direction.z = packet.decode_float(10)
	speed = packet.decode_double(14)
	homing = packet.decode_u8(22) == 0
	grenade = packet.decode_u8(23) == 0
	return [direction,speed,homing,grenade]



#Packet functions



func update_client_cards(id: int, card_one: Card, card_two: Card):
	var packet = PackedByteArray()
	packet.resize(6)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,EVENT_TYPE_HAND_CARDS_UPDATE)
	packet.encode_u8(2,card_one.suit)
	packet.encode_u8(3,card_one.number)
	packet.encode_u8(4,card_two.suit)
	packet.encode_u8(5,card_two.number)
	multiplayer.send_bytes(packet,id,MultiplayerPeer.TRANSFER_MODE_RELIABLE,2)

func echo_tracer(packet: PackedByteArray, id: int):
	multiplayer.send_bytes(packet,pairings[id],MultiplayerPeer.TRANSFER_MODE_UNRELIABLE,2)

func send_tracer(direction: Vector3, speed: float, homing: bool, grenade: bool):
	var packet = pack_tracer(direction,speed,homing,grenade)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_UNRELIABLE,2)

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
			if type == EVENT_TYPE_TRACER:
				spawn_client_tracer(packet)
			if type == EVENT_TYPE_GAME_START:
				start_game(packet.decode_u8(2),packet.decode_u32(3))
			elif type == EVENT_TYPE_PLAYER_LEAVE:
				handle_player_disconnect()
			elif type == EVENT_TYPE_PLAYER_DEATH:
				handle_player_death(packet.decode_u8(2))
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
			if type == EVENT_TYPE_TRACER:
				echo_tracer(packet,id)
			elif type == EVENT_TYPE_PLAYER_DEATH:
				# Matchmaking code here
				player_death_echo(id, packet)
			elif type == EVENT_TYPE_GAME_START:
				multiplayer.multiplayer_peer.refuse_new_connections = true
				make_pairings()
				event_start_echo()
		PACKET_TYPE_IMPULSE:
			echo_hit(id,packet)
