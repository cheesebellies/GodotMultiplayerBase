extends Node3D

var load_client = preload("res://Client/client.tscn")
var load_server = preload("res://Server/server.tscn")
var load_server_scanner = preload("res://Server/server_scanner.tscn")
var tick = 0
var scantick = 0
var servers = {}



func _ready():
	get_node("ServerScanner").setup_listener()

func _on_host_pressed():
	get_node("ServerScanner").clean_up()
	get_node("ServerScanner").queue_free()
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "host"
	var mpp = int($Control/HBoxContainer/Host/HBoxContainer/LineEdit.text)
	var mpl = int($Control/HBoxContainer/Host/HBoxContainer2/LineEdit.text)
	server_instance.multiplayer_port = mpp if mpp else 9999
	server_instance.multiplayer_player_limit = mpl if mpl else 16
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
	var scanner = load_server_scanner.instantiate()
	scanner.name = "Scanner"
	var hn = $Control/HBoxContainer/Host/HBoxContainer3/LineEdit.text
	scanner.host_name = hn if hn else "Untitled Game"
	get_parent().add_child(scanner)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/Scanner")
	get_node("../Scanner").setup_broadcast()
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

func update_server_list():
	for i in servers.keys():
		if servers[i]["scantick"] < scantick - 2:
			servers.erase(i)
	var normstyle = load("res://Assets/basic_button.tres")
	for i in get_node("Control/HBoxContainer/Join/HBoxContainer").get_children():
		i.queue_free()
	for server in servers.keys():
		var butt = Button.new()
		butt.toggle_mode = true
		butt.text = servers[server]["name"] + " @ " + str(servers[server]["players"]) + "/16\n" + str(server)
		butt.add_theme_stylebox_override("normal", normstyle)
		butt.add_theme_font_size_override("font_size",25)
		get_node("Control/HBoxContainer/Join/HBoxContainer").add_child(butt)

func _physics_process(_delta):
	var i = tick%720
	$Camera3D.position = Vector3(10.0*cos(deg_to_rad(float(i)*0.5)),10,10.0*sin(deg_to_rad(float(i)*0.5)))
	$Camera3D.look_at(Vector3(0,5,0))
	tick += 1

func _on_quit_pressed():
	get_tree().quit()

func _on_server_scanner_server_found(ip, player_count, server_name):
	scantick += 1
	print("\"" + str(server_name) + "\" [" + str(ip) + "] @ " + str(player_count) + "/16 Players")
	servers[ip] = {"scantick": scantick, "name": server_name, "players": player_count}
	update_server_list()
