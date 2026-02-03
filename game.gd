extends Node


var lobby_created:bool = false

var peer:SteamMultiplayerPeer = SteamMultiplayerPeer.new()

@export var checkpoints : Array[Marker3D] = []

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

#UI
@onready var main_menu: PanelContainer = $UI/MainMenu
@onready var lobbies: VBoxContainer = $UI/MainMenu/MarginContainer/LobbyList/lobbies/VBoxContainer
@onready var lobby_list_container: VBoxContainer = $UI/MainMenu/MarginContainer/LobbyList
@onready var main_menu_container: VBoxContainer = $UI/MainMenu/MarginContainer/MainMenu
@onready var filter_name: LineEdit = $UI/MainMenu/MarginContainer/LobbyList/filterName
@onready var hud: Control = $UI/HUD
@onready var names_box: VBoxContainer = $UI/LeaderBoard/MarginContainer/HBoxContainer/names/nameBox
@onready var kills_box: VBoxContainer = $UI/LeaderBoard/MarginContainer/HBoxContainer/kills/killbox
@onready var deaths_box: VBoxContainer = $UI/LeaderBoard/MarginContainer/HBoxContainer/deaths/deathBox
@onready var kda_box: VBoxContainer = $UI/LeaderBoard/MarginContainer/HBoxContainer/kda/kdabox
@onready var leader_board: PanelContainer = $UI/LeaderBoard
@onready var commands: LineEdit = $UI/HUD/commands


const PLAYER = preload("uid://cdne2banlrbwx")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined)
	Steam.lobby_match_list.connect(on_lobby_match_list)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# View params by looking at the signal in documentation
func on_lobby_created(connect: int, _lobby_id: int):
	if connect:
		Steam.setLobbyData(_lobby_id, "name", str(SteamManager.STEAM_USERNAME+"'s Lobby"))
		Steam.setLobbyJoinable(_lobby_id, true)
		peer.host_with_lobby(_lobby_id)
		#peer.create_host(0)
		multiplayer.multiplayer_peer = peer
		
		SteamManager.lobby_id = _lobby_id
		SteamManager.is_lobby_host = true

#Triggered whenever we join a lobby, connected to this via ready function
func on_lobby_joined(lobby: int, permissons:int, locked:bool, response:int):
	if Steam.getLobbyOwner(SteamManager.lobby_id) == Steam.getSteamID():
		return
	peer.connect_to_lobby(SteamManager.lobby_id)
	multiplayer.multiplayer_peer = peer


# Triggerd when Main Menu join is pressed
# Hides main menu and brings up lobby menu
func _on_join_button_pressed() -> void:
	main_menu_container.hide()
	lobby_list_container.show()
	#Clear any chuildren if there are any
	var lobby_btns = lobbies.get_children()
	for i in lobby_btns:
		i.queue_free()
	#Request lobby data from steam
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

#Triggered whebn we receive lobby list from steam, connected via ready function
#Parses lobbies into buttons that are added to list
func on_lobby_match_list(lobbies: Array):
	#Go through each lobby
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		var max_players = Steam.getLobbyMemberLimit(lobby)
		print(lobby_name)
		
		var but:Button = Button.new()
		but.text = "Name: {0} | Current: {1} | Max: {2}".format([lobby_name,member_count,max_players])
		
		but.pressed.connect(join_lobby.bind(lobby)) #lobby is the lobby id
		self.lobbies.add_child(but)

#This is connect to the lobby buttons, allows player to join a lobby
func join_lobby(_lobby_id):
	Steam.joinLobby(_lobby_id)
	SteamManager.lobby_id = _lobby_id
	main_menu.hide()
	hud.show()

# Adds a player with there ID
func add_player(peer_id):
	print(str(peer_id) + " Joined")
	var p = PLAYER.instantiate()
	p.name = str(peer_id)
	add_child(p)
	print("Connected")
func remove_player(peer_id):
	var p = get_node_or_null(str(peer_id))
	if p:
		p.queue_free()
#Triggered when pressing host from Main Menu
func _on_host_button_pressed() -> void:
	main_menu.hide()
	hud.show()
	if lobby_created:
		return
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC)
	multiplayer.peer_connected.connect(add_player) #when a player connects add them
	multiplayer.peer_disconnected.connect(remove_player) #when a player leaves remove them
	
	add_player(multiplayer.get_unique_id()) # add host

#Filters lobby names, triggers on text switch
func _on_filter_name_text_changed(new_text: String) -> void:
	for lobby in lobbies.get_children():
		if lobby is Button:
			if new_text == "":
				lobby.show()
			elif new_text in lobby.text.to_lower():
				lobby.show()
			else:
				lobby.hide()

func show_the_leadboard(value: bool):
	print("showing leaderboard: " + str(value))
	if value:
		reload_leaderboard()
		leader_board.show()
	else:
		leader_board.hide()
	
func reload_leaderboard():
	for l in kills_box.get_children():
		l.queue_free()
	for l in deaths_box.get_children():
		l.queue_free()
	for l in names_box.get_children():
		l.queue_free()
	for l in kda_box.get_children():
		l.queue_free()
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		var username: Label = Label.new()
		username.text = p.PLAYERNAME.text
		names_box.add_child(username)
		
		var kills: Label = Label.new()
		kills.text = str(p.kills)
		kills_box.add_child(kills)
		
		var deaths: Label = Label.new()
		deaths.text = str(p.deaths)
		deaths_box.add_child(deaths)
		
		var kda: Label = Label.new()
		kda.text = str(p.kda)
		kda_box.add_child(kda)

func get_spawn() -> Vector3:
	var index = randi() % 10
	return checkpoints[index].position
	
func show_console():
	if commands.visible:
		commands.hide()
		commands.release_focus()
	else:
		commands.show()
		commands.grab_focus()


func _on_commands_text_submitted(new_text: String) -> void:
	commands.hide()
	commands.release_focus()
	commands.text = ""
	if new_text == "give_hacks":
		for p in get_tree().get_nodes_in_group("players"):
			p.skin.material_override.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
		print("Wall Hacks On")
	if new_text == "no_hacks":
		for p in get_tree().get_nodes_in_group("players"):
			p.skin.material_override.stencil_mode = BaseMaterial3D.STENCIL_MODE_DISABLED
		print("Wall hacks off")
