extends Control

var load_client = preload("res://Client/client.tscn")
var load_server = preload("res://Server/server.tscn")

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _on_host_pressed():
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "host"
	get_parent().add_child(server_instance)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/Server")
	var endpoint_instance = load_server.instantiate()
	var container = Node.new()
	container.name = "clientroot"
	endpoint_instance.name = "Server"
	endpoint_instance.multiplayer_type = "endpoint"
	get_parent().add_child(container)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/clientroot")
	get_parent().get_node("clientroot").add_child(endpoint_instance)
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	client_instance.multiplayer_type = "admin"
	get_parent().get_node("clientroot").add_child(client_instance)
	print("Hosting")


func _on_join_pressed():
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "endpoint"
	get_parent().add_child(server_instance)
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	client_instance.multiplayer_type = "player"
	get_parent().add_child(client_instance)
	print("Joining")
