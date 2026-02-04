extends Control

@onready var console: RichTextLabel = $MarginContainer/HBoxContainer/RichTextLabel
@onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit
@onready var color_rect: ColorRect = $MarginContainer/ColorRect

signal exit_chat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()
	console.clear()
	color_rect.hide()
	line_edit.hide()
	console.hide()
	release_focus()


func log_local(text: String):
	console.add_text("\n" + text)
	
func log_global(text:String):
	global_system.rpc(text, SteamManager.STEAM_USERNAME)

@rpc("any_peer", "reliable", "call_local")
func global_chat(text:String, player:String):
	console.add_text("\n"+ player + ": " + text)

@rpc("any_peer", "reliable", "call_local")
func global_system(text:String):
	console.add_text("\n"+ text)

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.begins_with("/"):
		if new_text == "rep-me":
			self.log_global(SteamManager.STEAM_USERNAME + " IS HACKING")
			return
		if new_text == "/hack":
			for p in get_tree().get_nodes_in_group("players"):
				p.skin.material_override.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
				p.skin.material_override.stencil_color = Color("B266FF")
				self.log_local("Wall hacks are on")
				print("Wall Hacks On")
				return
		if new_text == "/hack-off":
			for p in get_tree().get_nodes_in_group("players"):
				p.skin.material_override.stencil_mode = BaseMaterial3D.STENCIL_MODE_DISABLED
				self.log_local("Wall hacks are off")
				print("Wall hacks off")
				return
		self.log_local("Invalid command")
		return
	
	if not new_text.is_empty():
		#console.add_text("\n"+ SteamManager.STEAM_USERNAME + ": " +new_text)
		self.global_chat.rpc(new_text, SteamManager.STEAM_USERNAME)
	line_edit.clear()

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	get_tree().create_timer(3).timeout.connect(fade_console)
	if not toggled_on:
		release_focus()
		line_edit.hide()
		exit_chat.emit()

func enable():
	console.show()
	line_edit.show()
	color_rect.show()
	line_edit.grab_focus()
	line_edit.edit(true)

func disable():
	line_edit.hide()
	line_edit.release_focus()
	
func fade_console():
	if line_edit.has_focus():
		return
	console.hide()
	color_rect.hide()
