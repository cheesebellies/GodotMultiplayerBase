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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
