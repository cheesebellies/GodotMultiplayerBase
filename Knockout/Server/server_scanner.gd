extends Node

var broadcast:PacketPeerUDP
var listen:PacketPeerUDP

var player_count: int = 1
@export var host_name: String = "Game"
var broadcast_type_switch = 1

var connected_peers = []
signal server_found(ip,player_count,server_name)

func _ready():
	$Timer.timeout.connect(_detection)

func setup_listener():
	listen = PacketPeerUDP.new()
	var res = listen.bind(9986)
	assert(res == OK, "Failed to start server scanner. Code " + str(res))
	$Timer.start()

func setup_broadcast():
	broadcast = PacketPeerUDP.new()
	broadcast.set_broadcast_enabled(true)
	broadcast.set_dest_address('255.255.255.255',9986)
	var res = broadcast.bind(9989)
	assert(res == OK, "Failed to start server status broadcast. Code " + str(res))
	$Timer.start()

func _detection():
	if broadcast:
		if player_count > 15: return
		if broadcast_type_switch == 1:
			broadcast_status()
			broadcast_type_switch = 0
		else:
			checkup()
			broadcast_type_switch = 1
	elif listen:
		detect_server()

func checkup():
	for peer in connected_peers:
		broadcast.set_dest_address(peer,9986)
		var packet = PackedByteArray()
		packet.resize(2)
		packet.encode_u8(0,player_count)
		packet.encode_u8(0,0)
		broadcast.put_packet(packet)

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
		var player_count = packet.decode_u8(0)
		var server_name = packet.slice(1).get_string_from_ascii()
		if ip != "":
			server_found.emit(ip,player_count,server_name)


func clean_up():
	if broadcast: broadcast.close()
	if listen: listen.close()
