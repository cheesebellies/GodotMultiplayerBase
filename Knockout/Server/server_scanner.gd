extends Node

var broadcast:PacketPeerUDP
var listen:PacketPeerUDP

var player_count: int = 1
@export var host_name: String = "Game"

var connected_peers = []
signal server_found(ip,player_count,server_name)

func _ready():
	$Timer.timeout.connect(_detection)

func setup_listener():
	listen = PacketPeerUDP.new()
	var res = listen.bind(9986)
	if res == OK:
		print("Started listening")
		$Timer.start()
	else:
		print("Failed to start server scanner. Code " + str(res))

func setup_broadcast():
	broadcast = PacketPeerUDP.new()
	broadcast.set_broadcast_enabled(true)
	broadcast.set_dest_address('255.255.255.255',9986)
	var res = broadcast.bind(9989)
	print(("Failed to start server status broadcast. Code " + str(res)) if res != OK else "Started broadcasting")
	$Timer.start()

func _detection():
	if broadcast:
		if player_count > 15: return
		broadcast_status()
	elif listen:
		detect_server()

func broadcast_status():
	var packet = PackedByteArray()
	packet.resize(1)
	packet.encode_u8(0,player_count)
	packet.append_array(host_name.to_ascii_buffer())
	broadcast.put_packet(packet)

func detect_server():
	if listen.get_available_packet_count() > 0:
		var ip = listen.get_packet_ip()
		var packet = listen.get_packet()
		var local_player_count = packet.decode_u8(0)
		var server_name = packet.slice(1).get_string_from_ascii()
		if ip != "":
			server_found.emit(ip,local_player_count,server_name)

func clean_up():
	if broadcast: broadcast.close()
	if listen: listen.close()
