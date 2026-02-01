extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 10
var has_focus: bool = true
var SENSITVITY: float = 0.005

@onready var camera: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		has_focus = !has_focus
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if has_focus else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and has_focus:
		rotate_y(-event.relative.x * SENSITVITY)
		camera.rotate_x(-event.relative.y * SENSITVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	has_focus = true
	
func _physics_process(delta: float) -> void:
	if not has_focus:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

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

	move_and_slide()
