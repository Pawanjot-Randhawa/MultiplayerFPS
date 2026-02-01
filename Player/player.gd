extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 10
var has_focus: bool = true
var SENSITVITY: float = 0.005


@onready var camera: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle_flash: GPUParticles3D = $Camera3D/gun/muzzle_flash
@onready var gunshot_sound: AudioStreamPlayer3D = $gunshot_sound
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var name_label: Label3D = $nameLabel

var health:int = 2

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): 
		return
	if event.is_action_pressed("ui_cancel"):
		has_focus = !has_focus
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if has_focus else Input.MOUSE_MODE_VISIBLE
	if has_focus:
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
	if not is_multiplayer_authority():
		print("non")
		return
	has_focus = true
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): 
		return
	if not has_focus:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta *2.0

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
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

@rpc("call_local")
func shoot_effect():
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	gunshot_sound.play()

@rpc("any_peer")
func receive_dmg():
	health -= 1
	if health <= 0:
		#RESPAWN LOGIC HERE
		health = 2
		position = Vector3(0.0, 10.0, 0.0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		animation_player.play("idle")
