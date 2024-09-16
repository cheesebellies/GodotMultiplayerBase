extends Node3D

var load_client = preload("res://Client/client.tscn")
var load_server = preload("res://Server/server.tscn")
var tick = 0

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _on_host_pressed():
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "host"
	get_parent().add_child(server_instance)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/Server")
	get_parent().get_node("Server").init()
	var endpoint_instance = load_server.instantiate()
	var container = Node.new()
	container.name = "clientroot"
	endpoint_instance.name = "Server"
	endpoint_instance.multiplayer_type = "endpoint"
	get_parent().add_child(container)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/clientroot")
	get_parent().get_node("clientroot").add_child(endpoint_instance)
	get_parent().get_node("clientroot/Server").init()
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	client_instance.multiplayer_type = "admin"
	get_parent().get_node("clientroot").add_child(client_instance)
	self.queue_free()

func _on_join_pressed():
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "endpoint"
	get_parent().add_child(server_instance)
	get_parent().get_node("Server").init()
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	client_instance.multiplayer_type = "player"
	get_parent().add_child(client_instance)
	self.queue_free()



func _physics_process(_delta):
	var i = tick%720
	$Camera3D.position = Vector3(10.0*cos(deg_to_rad(float(i)*0.5)),10,10.0*sin(deg_to_rad(float(i)*0.5)))
	$Camera3D.look_at(Vector3(0,5,0))
	tick += 1


func _on_quit_pressed():
	get_tree().quit()



func _on_server_scanner_received_server_ping(ip, player_count):
	print(str(ip) + " @ " + str(player_count) + "/16 Players")


func _on_button_pressed() -> void:
	$ServerScanner.setup_listener()


func _on_button_2_pressed() -> void:
	$ServerScanner.setup_broadcast()
