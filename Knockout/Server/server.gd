extends Node



#Constants



#



#Enums



enum {PACKET_TYPE_PING, PACKET_TYPE_POSITIONAL, PACKET_TYPE_EVENT, PACKET_TYPE_IMPULSE, PACKET_TYPE_STATE, PACKET_TYPE_OTHER}



#Export vars



@export var multiplayer_type: String = ""
@export var multiplayer_ip: String = "localhost"
@export var multiplayer_port: int = 9999
@export var multiplayer_player_limit: int = 16



#Variables



var pairings = {}
var enet_peer = ENetMultiplayerPeer.new()



#Utility functions



func debugs(tprint):
	print("[Server] " + str(tprint))
func debuge(tprint):
	print("[Endpoint #-" + str(multiplayer.get_unique_id()) + "] " + str(tprint))



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
		enet_peer.create_client(multiplayer_ip, multiplayer_port)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_packet.connect(_endpoint_packet_received)
		debuge("Connected to server")


func _ready():
	# Multiplayer functions get reset after added to tree, any changes in init
	pass

func _process(_delta):
	pass



#Gameplay functions



func update_position(packet: PackedByteArray):
	var data = unpack_positional(packet)
	get_node("../Client").update_opponent_positional(data)

func apply_impulse(packet: PackedByteArray):
	var impulse = Vector3()
	impulse.x = packet.decode_float(1)
	impulse.y = packet.decode_float(5)
	impulse.z = packet.decode_float(9)
	get_node("../Client").apply_player_positional(impulse)

func start_game():
	get_node("../Client").start_game()



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
	# Position: Vector3: 3 floats (4, 4, 4 bytes)
	# Velocity: Vector3: 3 floats (4, 4, 4 bytes)
	# Rotation: Quaternion: 4 floats (4, 4, 4, 4 bytes)
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
	packet.resize(2)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,0)
	multiplayer.send_bytes(packet,0,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func event_start():
	var packet = PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0,PACKET_TYPE_EVENT)
	packet.encode_u8(1,0)
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



func _peer_disconnected(id):
	debugs("Peer disconnected: " + str(id))

func _peer_connected(id):
	debugs("Peer connected: " + str(id))

func _endpoint_packet_received(id: int, packet: PackedByteArray):
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_POSITIONAL:
			update_position(packet)
		PACKET_TYPE_PING:
			debuge("Ping Successful")
		PACKET_TYPE_EVENT:
			if packet.decode_u8(1) == 0:
				start_game()
		PACKET_TYPE_IMPULSE:
			apply_impulse(packet)
	#debuge("Received packet from #-" + str(id))

func _server_packet_received(id: int, packet: PackedByteArray):
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_POSITIONAL:
			echo_positional(id, packet)
		PACKET_TYPE_PING:
			ping_response(id)
		PACKET_TYPE_EVENT:
			if packet.decode_u8(1) == 0:
				multiplayer.multiplayer_peer.refuse_new_connections = true
				var peers = multiplayer.get_peers()
				pairings[peers[0]] = peers[1]
				pairings[peers[1]] = peers[0]
				event_start_echo()
		PACKET_TYPE_IMPULSE:
			echo_hit(id,packet)
	#debugs("Received packet from #-" + str(id))
