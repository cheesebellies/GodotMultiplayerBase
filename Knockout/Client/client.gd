extends Node

@export var multiplayer_type: String = ""

var enet_peer = ENetMultiplayerPeer.new()



func _ready() -> void:
	print("[Peer] Starting peer")
	enet_peer.create_client("10.60.21.137",9999)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(_connected_to_server)
	print(multiplayer.multiplayer_peer.get_connection_status())



func _connected_to_server():
	print("[Peer] Connected to server")
