extends CharacterBody3D


const SPEED = 11.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 0.15
@export var just_hit: bool = false
@export var is_auth: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if !is_auth: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if $Camera3D/RayCast3D.is_colliding():
				get_parent().hit_opponent((get_node("../Opponent").position - self.position).normalized() + Vector3(0,1.5,0))
	var ncams = 0.001
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * ncams)
		$Camera3D.rotate_x(-event.relative.y * ncams)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if is_auth:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = abs(Input.mouse_mode - 2)
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			just_hit = true
		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if !is_on_floor():
			velocity += direction * 0.35
			var vel_mod = 0.995
			velocity.x *= vel_mod
			velocity.z *= vel_mod
		elif direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x *= 0.675
			velocity.z *= 0.675
		velocity.y -= GRAVITY
		velocity.x = clamp(velocity.x,-SPEED, SPEED)
		velocity.z = clamp(velocity.z,-SPEED, SPEED)
	move_and_slide()
	just_hit = false
