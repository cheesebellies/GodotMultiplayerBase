extends Control

var load_client = preload("res://Client/client.tscn")
var load_server = preload("res://Server/server.tscn")


func _on_host_pressed():
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	get_parent().add_child(server_instance)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	get_parent().add_child(client_instance)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface())


func _on_join_pressed():
	pass # Replace with function body.
