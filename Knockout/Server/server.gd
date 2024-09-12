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
