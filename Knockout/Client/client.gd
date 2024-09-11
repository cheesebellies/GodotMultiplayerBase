extends Node

@export var multiplayer_type: String = ""




func _ready() -> void:
	var enet_peer = ENetMultiplayerPeer.new()
	enet_peer.create_client("10.60.21.137",9999)
	multiplayer.multiplayer_peer = enet_peer
