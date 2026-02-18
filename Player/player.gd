extends CharacterBody3D

const SPEED = 10
const JUMP_VELOCITY = 10
var has_focus: bool = true
var SENSITVITY: float = 0.005
var player_name:String

@onready var skin: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = $Camera3D/gun/muzzle_flash
@onready var gunshot_sound: AudioStreamPlayer3D = $gunshot_sound
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var name_label: Label3D = $nameLabel
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var color_rect: ColorRect = $ColorRect
@onready var PLAYERNAME: Label = $PLAYERNAME
@onready var progress_bar: ProgressBar = $MarginContainer/ProgressBar
var game

var health:int = 5

var kills: int = 0:
	set(value):
		stat_change.emit()
		kills = value

var deaths:int = 0:
	set(value):
		stat_change.emit()
		deaths = value

var kda:float = 0:
	set(value):
		stat_change.emit()
		kda = value

var showing_leaderboard:bool = false
signal show_leaderboard(value:bool)
signal stat_change
signal commands

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): 
		return
	if event.is_action_pressed("ui_cancel"):
		has_focus = !has_focus
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if has_focus else Input.MOUSE_MODE_VISIBLE
	if has_focus:
		if Input.is_action_just_pressed("tab"):
			print("Show leadaerboard signal sent")
			showing_leaderboard = !showing_leaderboard
			show_leaderboard.emit(showing_leaderboard)
		if Input.is_action_just_pressed("commands") and not showing_leaderboard:
			Console.enable()
			has_focus = false
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * SENSITVITY)
			camera.rotate_x(-event.relative.y * SENSITVITY)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "shoot":
			shoot_effect.rpc()
			if raycast.is_colliding():
				var target = raycast.get_collider()
				target.receive_dmg.rpc_id(str(target.name).to_int())
func _ready() -> void:
	add_to_group("players")
	if not is_multiplayer_authority():
		return
	
	has_focus = true
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	progress_bar.show()
	PLAYERNAME.text = SteamManager.STEAM_USERNAME
	name_label.text = PLAYERNAME.text + " : "+ str(health)
	
	Console.exit_chat.connect(func(): has_focus = true)
	
	game = get_parent()
	if game:
		self.show_leaderboard.connect(game.show_the_leadboard)
		self.stat_change.connect(game.reload_leaderboard)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): 
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta *2.0
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and has_focus:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	if not has_focus:
		input_dir = Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if animation_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("move")
	else:
		animation_player.play("idle")
	move_and_slide()

@rpc("call_local") #this animation is called on all peers as well as the local machine so that the player can see it
func shoot_effect():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	gunshot_sound.play()

@rpc("any_peer","reliable", "call_local")
func add_kill():
	print("player " + str(multiplayer.get_unique_id()) + "got the kill")
	print("valid kill peer")
	self.kills += 1
	if self.deaths < 1:
		self.kda = kills
	else:
		self.kda = float(kills) / deaths

@rpc("any_peer","reliable", "call_local")
func add_death():
	self.deaths += 1
	if self.kills < 1:
		self.kda = 0
	else:
		self.kda = float(kills) / deaths

@rpc("any_peer", "reliable")
func receive_dmg(): #receives damage and trigger a GUI red flash
	#Damage flash
	print("Flash occured")
	color_rect.color = Color(1.0, 0.0, 0.0, 0.753)
	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	#Reduce health
	health -= 1
	
	if health <= 0:
		health = 5
		position = game.get_spawn() #THIS works as postion is being synced, get spawn returns vector3
		inform_shooter(multiplayer.get_remote_sender_id())
		add_death.rpc() # call death on this node for all
	#Update label of this node
	name_label.text = PLAYERNAME.text + " : "+ str(health) # NOTE this only works because name label is synced, normally its only updating for this caller
	progress_bar.value = float(health)
	#Play hit effect on all clients except local as we cant see ourselves
	hit_animation.rpc()

@rpc("call_remote") #Plays the flashing red capsule animation, call remote will bnot call it on this pc
func hit_animation():
	mesh_instance_3d.material_override.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
	var tween = get_tree().create_tween()
	tween.tween_property(mesh_instance_3d.material_override, "albedo_color", Color(1.0, 1.0, 1.0, 1.0), 0.4)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		animation_player.play("idle")

func inform_shooter(peer_id: int): #Find the correct player node that got the kill and trigger the rpc
	for p in get_tree().get_nodes_in_group("players"):
		if p.name == str(peer_id):
			print("Player " + p.PLAYERNAME.text + "got the kill, id :" + str(peer_id))
			p.add_kill.rpc()
