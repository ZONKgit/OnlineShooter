extends Panel

@onready var ui = $".."
@onready var addressLine = $addressLine
@onready var portLine = $portLine


const Player = preload("res://scenes/player.tscn")
const PORT = 9999					
var enet_peer = ENetMultiplayerPeer.new()

func _on_host_button_pressed():
	ui.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(addPlayer)
	multiplayer.peer_disconnected.connect(removePlayer)
	
	addPlayer(multiplayer.get_unique_id())
	
	UPnPSetup()


func _on_server_button_pressed():
	ui.hide()
	
	enet_peer.create_client(addressLine.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	

func addPlayer(peer_id) -> void:
	var player = Player.instantiate()
	player.name = str(peer_id)
	$"../../..".add_child(player)

func removePlayer(peer_id) -> void:
	var player = $"../../..".get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func UPnPSetup() -> void:
	var upnp = UPNP.new()
	
	var discoverResult = upnp.discover()
	assert(discoverResult == UPNP.UPNP_RESULT_SUCCESS, \
		"UPnP Discover Failed! Error %s" % discoverResult)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateaway!")
	
	var mapResult = upnp.add_port_mapping(PORT)
	assert(mapResult == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % mapResult)
	
	
	print(IP.get_local_addresses())
	print("Succes! Join Adress: %s" % upnp.query_external_address())
	

func _input(_e) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
