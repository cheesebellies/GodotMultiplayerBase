extends CharacterBody3D

var ticks = 0
var lastshot = -20
const SPEED = 11.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 0.15
@export var just_hit: bool = false
@export var is_auth: bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Camera3D/RayCast3D.add_exception(self)
	if name == "Opponent":
		$Camera3D/Gun.queue_free()
	else:
		$Showgun.queue_free()

func shoot():
	if ticks-lastshot > 2:
		lastshot = ticks
		var coll = $Camera3D/RayCast3D.get_collider()
		if coll and coll.name == "Opponent":
			get_parent().hit_opponent(($Camera3D/RayCast3D.get_collision_point() - $Camera3D.global_position).normalized() + Vector3(0,0.65,0))
		var anim = $Camera3D/Gun.get_node("AnimationPlayer")
		anim.current_animation = "recoil"

func _input(event):
	if !is_auth: return
	var ncams = 0.0008
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * ncams)
		$Camera3D.rotate_x(-event.relative.y * ncams)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	ticks += 1
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
		var xyvel = Vector3(velocity.x,0.0,velocity.z)
		if xyvel.length() > SPEED:
			var modxyvel = xyvel.normalized()*SPEED
			velocity.x = modxyvel.x
			velocity.z = modxyvel.z
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shoot()
	move_and_slide()
	just_hit = false
