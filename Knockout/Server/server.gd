extends Node

#Constants

const PORT: int = 9999
const MAX_CLIENTS: int = 16

#Export vars

@export var multiplayer_type: String = ""

#Variables

var enet_peer = ENetMultiplayerPeer.new()

#Utility functions

func debugs(tprint):
	print("[Server] " + str(tprint))
func debuge(tprint):
	print("[Endpoint] " + str(tprint))

#Built-in functions

func _ready() -> void:
	if multiplayer_type != "endpoint":
		enet_peer.create_server(PORT,MAX_CLIENTS)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.peer_packet.connect(_server_packet_received)
		debugs("Online")
	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_packet.connect(_endpoint_packet_received)
		debuge("Connected to server")

#Bit processing

func unpack_positional(packet: PackedByteArray):
	pass

func pack_positional(node: Node3D):
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
	packet.resize(40)
	packet.encode_float(0,pos.x)
	packet.encode_float(4,pos.y)
	packet.encode_float(8,pos.z)
	packet.encode_float(12,vel.x)
	packet.encode_float(16,vel.y)
	packet.encode_float(20,vel.z)
	packet.encode_float(24,rot.w)
	packet.encode_float(28,rot.x)
	packet.encode_float(32,rot.y)
	packet.encode_float(36,rot.z)
	return packet

#Processing functions

func ping_server():
	var packet = PackedByteArray()
	packet.resize(4)
	packet.encode_float(0,3.234234)
	multiplayer.send_bytes(packet,1,MultiplayerPeer.TRANSFER_MODE_RELIABLE,0)

#Signals

func _peer_disconnected(id):
	debugs("Peer disconnected: " + (id))

func _peer_connected(id):
	debugs("Peer connected: " + str(id))

func _endpoint_packet_received(id: int, packet: PackedByteArray):
	debuge("Received packet from " + str(id))

func _server_packet_received(id: int, packet: PackedByteArray):
	var data = packet.decode_float(0)
	print(data)
	print(type_string(typeof(data)))
	debugs("Received packet from " + str(id))



















#
