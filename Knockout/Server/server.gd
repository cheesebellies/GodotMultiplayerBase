extends Node

#Constants

const PORT: int = 9999
const MAX_CLIENTS: int = 16

#Enums

enum {PACKET_TYPE_PING, PACKET_TYPE_POSITIONAL, PACKET_TYPE_EVENT, PACKET_TYPE_OTHER}

#Export vars

@export var multiplayer_type: String = ""

#Variables

var pairings = {}

#Utility functions

func debugs(tprint):
	print("[Server] " + str(tprint))
func debuge(tprint):
	print("[Endpoint] " + str(tprint))

#Built-in functions

func _ready() -> void:
	if multiplayer_type != "endpoint":
		var enet_peer = ENetMultiplayerPeer.new()
		enet_peer.create_server(PORT,MAX_CLIENTS)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.peer_packet.connect(_server_packet_received)
		debugs("Online")
	else:
		var enet_peer = ENetMultiplayerPeer.new()
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_packet.connect(_endpoint_packet_received)
		debuge("Connected to server")

#Gameplay functions

func start_game():
	print("AHHH WHY WAS THIS RUNNING")
	#multiplayer.multiplayer_peer.refuse_new_connections = true

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

func ping_response(id):
	var packet = PackedByteArray()
	packet.resize(1)
	packet.encode_u8(0,PACKET_TYPE_PING)
	debugs(multiplayer.get_peers())
	multiplayer.send_bytes(packet,0,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

func ping_server():
	var packet = PackedByteArray()
	packet.resize(1)
	packet.encode_u8(0,PACKET_TYPE_PING)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

#Signals

func _peer_disconnected(id):
	debugs("Peer disconnected: " + (id))

func _peer_connected(id):
	print(multiplayer.get_peers())
	debugs("Peer connected: " + str(id))

func _endpoint_packet_received(id: int, packet: PackedByteArray):
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_PING:
			debuge("Ping Successful")
	debuge("Received packet from " + str(id))

func _server_packet_received(id: int, packet: PackedByteArray):
	print(multiplayer.multiplayer_peer)
	print(multiplayer.multiplayer_peer.get_peer(id))
	var packet_type = packet.decode_u8(0)
	match packet_type:
		PACKET_TYPE_PING:
			ping_response(id)
	debugs("Received packet from " + str(id))



















#
