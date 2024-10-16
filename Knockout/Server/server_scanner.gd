extends Node

var broadcast:PacketPeerUDP
var listen:PacketPeerUDP

var player_count: int = 1
@export var host_name: String = "Game"
@export var port: int = 9999

var connected_peers = []
signal server_found(ip,player_count,server_name, port)

func debug(msg):
	print("[Scanner] \t\t" + str(msg))

func _ready():
	$Timer.timeout.connect(_detection)

func setup_listener():
	listen = PacketPeerUDP.new()
	var res = listen.bind(9986)
	if res == OK:
		debug("Started listening")
		$Timer.start()
		return OK
	else:
		debug("Failed to start server scanner. Code " + str(res))
		return ERR_ALREADY_IN_USE

func setup_broadcast():
	broadcast = PacketPeerUDP.new()
	broadcast.set_broadcast_enabled(true)
	broadcast.set_dest_address('255.255.255.255',9986)
	var res = broadcast.bind(9989)
	if res == OK:
		debug("Started broadcasting")
		$Timer.start()
		return OK
	else:
		debug("Failed to start server status broadcast. Code " + str(res))
		return ERR_ALREADY_IN_USE

func _detection():
	if broadcast:
		if player_count > 15: return
		broadcast_status()
	elif listen:
		detect_server()

func broadcast_status():
	var packet = PackedByteArray()
	packet.resize(5)
	packet.encode_u8(0,player_count)
	packet.encode_u32(1,port)
	packet.append_array(host_name.to_ascii_buffer())
	broadcast.put_packet(packet)

func detect_server():
	if listen.get_available_packet_count() > 0:
		var ip = listen.get_packet_ip()
		var packet = listen.get_packet()
		var local_player_count = packet.decode_u8(0)
		var local_port = packet.decode_u32(1)
		var server_name = packet.slice(5).get_string_from_ascii()
		if ip != "":
			server_found.emit(ip,local_player_count,server_name,local_port)

func clean_up():
	if broadcast: broadcast.close()
	if listen: listen.close()
