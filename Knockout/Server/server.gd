extends Node

'''
High level networking in Godot is managed by the SceneTree.

Each node has a multiplayer property, which is a reference to the MultiplayerAPI instance configured for it by the scene tree.
Initially, every node is configured with the same default MultiplayerAPI object.

It is possible to create a new MultiplayerAPI object and assign it to a NodePath in the the scene tree, which will override multiplayer
for the node at that path and all of its descendants. This allows sibling nodes to be configured with different peers, which
makes it possible to run a server and a client simultaneously in one instance of Godot.
'''

'''
/root/
	Server/
		# All multiplayer things occur here, all RPC occurs between Server endpoints, etc.
	Client/
		# Sends and recieves information from the Server endpoint on the local tree. Only node with different code for each different player.
		# Updates Player, World, and other nodes based on information recieved.
		Player/
			# User control, rendering, etc.
		World/
			# Map, etc.
'''

const PORT: int = 9999
@export var multiplayer_type: String = ""
var enet_peer = ENetMultiplayerPeer.new()


func _ready() -> void:
	if multiplayer_type != "endpoint":
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		print("Multiplayer running")
		print(multiplayer.multiplayer_peer.get_connection_status())



func _peer_disconnected(id):
	print("Peer disconnected: " + id)

func _peer_connected(id):
	print("Peer connected: " + id)























#
