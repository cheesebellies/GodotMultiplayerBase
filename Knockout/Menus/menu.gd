extends Node3D

var load_client = preload("res://Client/client.tscn")
var load_server = preload("res://Server/server.tscn")
var load_server_scanner = preload("res://Server/server_scanner.tscn")
var tick = 0
var tte = 0.0
var servers = {}

func debug(msg):
	print("[Menu] \t\t" + str(msg))

func _ready():
	var res = get_node("ServerScanner").setup_listener()
	$Control/LineEdit.text = "Scanning ON" if res != ERR_ALREADY_IN_USE else "Scanning ERROR"

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
	get_parent().get_node("clientroot/Server").client = get_parent().get_node("clientroot/Client")
	var scanner = load_server_scanner.instantiate()
	scanner.name = "Scanner"
	var hn = $Control/HBoxContainer/Host/HBoxContainer3/LineEdit.text
	scanner.host_name = hn if hn else "Untitled Game"
	scanner.port = mpp if mpp else 9999
	get_parent().add_child(scanner)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(),"/root/Scanner")
	get_node("../Scanner").setup_broadcast()
	self.queue_free()

func join_server(ip, port):
	get_node("ServerScanner").clean_up()
	get_node("ServerScanner").queue_free()
	var server_instance = load_server.instantiate()
	server_instance.name = "Server"
	server_instance.multiplayer_type = "endpoint"
	server_instance.multiplayer_ip = ip
	server_instance.multiplayer_port = port
	get_parent().add_child(server_instance)
	get_parent().get_node("Server").init()
	var client_instance = load_client.instantiate()
	client_instance.name = "Client"
	client_instance.multiplayer_type = "player"
	get_parent().add_child(client_instance)
	get_parent().get_node("Server").client = get_parent().get_node("Client")
	self.queue_free()

func update_server_list():
	for i in servers.keys():
		if servers[i]["tte"] < tte - 1.0:
			servers.erase(i)
			get_node("Control/HBoxContainer/Join/" + i).queue_free()
	var normstyle = load("res://Assets/basic_button.tres")
	for server in servers.keys():
		if !get_node_or_null("Control/HBoxContainer/Join/" + server):
			var butt = Button.new()
			butt.add_theme_font_size_override("font_size",30)
			butt.text = servers[server]["name"] + " @ " + str(servers[server]["players"]) + "/16\n" + str(server)
			butt.name = server
			butt.pressed.connect(_join_server_info.bind(butt))
			butt.add_theme_stylebox_override("normal", normstyle)
			butt.add_theme_font_size_override("font_size",25)
			get_node("Control/HBoxContainer/Join").add_child(butt)

func _join_server_info(button):
	var binfo = button.name.split("_")
	var ip = ".".join(binfo.slice(0,-1))
	var port = int(binfo[-1])
	join_server(ip,port)

func _physics_process(delta):
	var i = tick%720
	$Camera3D.position = Vector3(10.0*cos(deg_to_rad(float(i)*0.5)),10,10.0*sin(deg_to_rad(float(i)*0.5)))
	$Camera3D.look_at(Vector3(0,5,0))
	tick += 1
	tte += delta
	update_server_list()

func _on_quit_pressed():
	get_tree().quit()

func _on_server_scanner_server_found(ip, player_count, server_name, port):
	#print("\"" + str(server_name) + "\" [" + str(ip) + ":" + str(port) + "] @ " + str(player_count) + "/16 Players")
	servers[(ip + "_" + str(port)).replace(".","_")] = {"tte": tte, "name": server_name, "players": player_count}


func _on_fjl_pressed() -> void:
	join_server("localhost",9999)
