extends Node

var broadcast:PacketPeerUDP
var listen:PacketPeerUDP
@export var player_count: int = 0
signal received_server_ping(ip,player_count)

func setup_listener():
	listen = PacketPeerUDP.new()
	var res = listen.bind(9986)
	assert(res == OK, "Failed to start server scanner. Code " + str(res))
	$Timer.timeout.connect(_loop)
	$Timer.start()

func setup_broadcast():
	broadcast = PacketPeerUDP.new()
	broadcast.set_broadcast_enabled(true)
	broadcast.set_dest_address('10.60.255.255',9986)
	var res = broadcast.bind(9989)
	assert(res == OK, "Failed to start server status broadcast. Code " + str(res))
	$Timer.timeout.connect(_loop)
	$Timer.start()

func _loop():
	if broadcast:
		var packet = PackedByteArray()
		packet.resize(1)
		packet.encode_u8(0,player_count)
		broadcast.put_packet(packet)
	elif listen:
		if listen.get_available_packet_count() > 0:
			var ip = listen.get_packet_ip()
			var player_count = listen.get_packet().decode_u8(0)
			if ip != "":
				received_server_ping.emit(ip,player_count)

func clean_up():
	if broadcast: broadcast.close()
	if listen: listen.close()
