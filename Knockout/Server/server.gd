extends Node



#Constants



#Enums



enum {PACKET_TYPE_PING, PACKET_TYPE_POSITIONAL, PACKET_TYPE_EVENT, PACKET_TYPE_IMPULSE, PACKET_TYPE_STATE, PACKET_TYPE_OTHER}
enum {EVENT_TYPE_GAME_START, EVENT_TYPE_PLAYER_LEAVE, EVENT_TYPE_GAME_END, EVENT_TYPE_PLAYER_DEATH}
enum {EVENT_INFO_MATCH_WON, EVENT_INFO_MATCH_LOST}



#Export vars



@export var multiplayer_type: String = ""
@export var multiplayer_ip: String = "localhost"
@export var multiplayer_port: int = 9999
@export var multiplayer_player_limit: int = 16



#Variables



var tte: float = 0.0
var client: Node = null
var pairings = {}
var enet_peer = ENetMultiplayerPeer.new()



#Utility functions



func debugs(tprint):
	print("[Server] \t\t" + str(tprint))

func debuge(tprint):
	print("[" + str(multiplayer.get_unique_id()) + "]   \t" + str(tprint))



#Built-in functions



func _physics_process(delta):
	tte += delta
	

func init():
	if multiplayer_type != "endpoint":
		enet_peer.create_server(multiplayer_port,multiplayer_player_limit)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.peer_packet.connect(_server_packet_received)
		debugs("Online")
	else:
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
	if multiplayer.is_server(): multiplayer.multiplayer_peer.close()
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



func echo_pickup_picked_up():
	pass

func pickup_picked_up(pid: int, time: float):
	pass

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
			if packet.decode_u8(1) == EVENT_TYPE_GAME_START:
				start_game(packet.decode_u8(2),packet.decode_u32(3))
			if packet.decode_u8(1) == EVENT_TYPE_PLAYER_LEAVE:
				handle_player_disconnect()
			if packet.decode_u8(1) == EVENT_TYPE_PLAYER_DEATH:
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
			if packet.decode_u8(1) == EVENT_TYPE_PLAYER_DEATH:
				# Matchmaking code here
				player_death_echo(id, packet)
			elif packet.decode_u8(1) == EVENT_TYPE_GAME_START:
				multiplayer.multiplayer_peer.refuse_new_connections = true
				make_pairings()
				event_start_echo()
		PACKET_TYPE_IMPULSE:
			echo_hit(id,packet)
