extends CharacterBody3D

var ticks = 0
var tte = 0.0
var lastshot = -2.0
const SPEED = 11.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 0.15
@export var just_hit: bool = false
@export var is_auth: bool = true

#*********************************************************
# To-do:
#	- Make shooting a projectile system
#	- 
#
#*********************************************************

@export var powerups: Dictionary = {
	"repel": false		# Instant that repels the opponent based on distance, but also repels the player a smaller amount in the inverse direction
	"grapple": false	# Instant (cancelable) that grapples player towards whatever it is fired at. If it hits the opponent, they are grappled to each other
	"homing": false		# Short (3 seconds) that gives all shots fired a minor homing ability
	"overclock": false	# Medium (9 seconds) that increases weapon fire rate
	"mobility": false	# Long (15 seconds) that improves all movement: speed, air maneuverability, jump, etc.
	"tank": false		# Long (15 seconds) that reduces knockback, but also increases size
	"shrink": false		# Long (15 seconds) that reduces player size, but also increases knockback
	"savior": false		# Passive (activates on death) that teleports the player back to spawn, saving them, at a cost of +200% knockback
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Camera3D/RayCast3D.add_exception(self)
	if name == "Opponent":
		$Camera3D/Gun.queue_free()
	else:
		$Showgun.queue_free()

func shoot():
	if tte-lastshot >= 0.1333:
		lastshot = tte
		var coll = $Camera3D/RayCast3D.get_collider()
		if coll and coll.name == "Opponent":
			get_parent().hit_opponent(($Camera3D/RayCast3D.get_collision_point() - $Camera3D.global_position).normalized())
			$Camera3D/Crosshair/CenterContainer/Sprite2D.position = get_viewport().size/2
			$Camera3D/Crosshair/CenterContainer/Sprite2D.visible = true
			$Camera3D/Crosshair/CenterContainer/Sprite2D.rotation = randi_range(0,90)
			$Camera3D/Crosshair/CenterContainer/Sprite2D/Timer.start()
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
	if is_auth:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = abs(Input.mouse_mode - 2)
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if just_hit && is_on_floor():
			just_hit = false
		if !is_on_floor():
			if just_hit:
				var nvel = velocity + direction * 0.35
				var nxyvel = Vector3(velocity.x,0.0,velocity.z)
				if nxyvel.length() > SPEED:
					if nvel.length() < velocity.length():
						velocity = nvel
			else:
				velocity += direction * 0.35
			velocity.x *= 0.995
			velocity.z *= 0.995
		elif direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x *= 0.675
			velocity.z *= 0.675
		velocity.y -= GRAVITY
		var xyvel = Vector3(velocity.x,0.0,velocity.z)
		if !just_hit && (xyvel.length() > SPEED):
			var modxyvel = xyvel.normalized()*SPEED
			velocity.x = modxyvel.x
			velocity.z = modxyvel.z
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			shoot()
	move_and_slide()
	ticks += 1
	tte += delta


func _on_hitmarker_timeout() -> void:
	$Camera3D/Crosshair/CenterContainer/Sprite2D.visible = false
