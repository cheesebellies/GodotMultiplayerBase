extends CharacterBody3D

var ticks = 0
var tte = 0.0
const SPEED = 8.0
const JUMP_VELOCITY = 6.5
const GRAVITY = 0.25
const preproj = preload("res://Client/projectile.tscn")
@export var just_hit: bool = false
@export var is_auth: bool = true

#****************************************************
#						To-do:
#
#3	- Add a slight aim assist option
#6	- Implement powerup selection
#
#
#
#****************************************************

enum {WEAPON_REVOLVER,WEAPON_RIFLE,WEAPON_AUTO_RIFLE,WEAPON_SHOTGUN,WEAPON_SMG,WEAPON_LAUNCHER}
enum {POWERUP_REPEL,POWERUP_GRAPPLE,POWERUP_HOMING,POWERUP_OVERCLOCK,POWERUP_MOBILITY,POWERUP_TANK,POWERUP_SHRINK,POWERUP_SAVIOR}

#type: int, description: String, is_auto: bool, mag_size: int, reload_time: float, fire_rate: float, KB_mult: float, range: float, model: Mesh

var weapons: Dictionary = {
	WEAPON_REVOLVER: Weapon.new(
		WEAPON_REVOLVER,
		"e",
		false,
		6,				#mag_size
		1.0,			#reload_time
		0.3,			#fire_rate
		1.45,			#KB_mult
		1.0,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_RIFLE: Weapon.new(
		WEAPON_RIFLE,
		"e",
		false,
		1,				#mag_size
		0.8,			#reload_time
		0.2,			#fire_rate
		2.5,			#KB_mult
		2.0,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_AUTO_RIFLE: Weapon.new(
		WEAPON_AUTO_RIFLE,
		"e",
		true,
		18,				#mag_size
		2.0,			#reload_time
		0.2,			#fire_rate
		0.55,			#KB_mult
		1.0,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_SHOTGUN: Weapon.new(
		WEAPON_SHOTGUN,
		"e",
		false,
		2,				#mag_size
		2.0,			#reload_time
		0.8,			#fire_rate
		4.5,			#KB_mult
		0.1,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_SMG: Weapon.new(
		WEAPON_SMG,
		"e",
		true,
		36,				#mag_size
		3.5,			#reload_time
		0.075,			#fire_rate
		0.25,			#KB_mult
		0.8,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_LAUNCHER: Weapon.new(
		WEAPON_LAUNCHER,
		"e",
		false,
		3,				#mag_size
		1.0,			#reload_time
		0.8,			#fire_rate
		5.0,			#KB_mult
		0.5,			#range
		load("res://Assets/gun_new.obj")
	)
}

@export var has_powerup: Dictionary = {
	"repel": false,		# Instant that repels the opponent based on distance, but also repels the player a smaller amount in the inverse direction
	"grapple": false,	# Instant (cancelable) that grapples player towards whatever it is fired at. If it hits the opponent, they are grappled to each other
	"homing": false,	# Short (3 seconds) that gives all shots fired a minor homing ability
	"overclock": false,	# Medium (9 seconds) that increases weapon fire rate
	"mobility": false,	# Long (15 seconds) that improves all movement: speed, air maneuverability, jump, etc.
	"tank": false,		# Long (15 seconds) that reduces knockback, but also increases size
	"shrink": false,	# Long (15 seconds) that reduces player size, but also increases knockback
	"savior": false		# Passive (activates on death) that teleports the player back to spawn, saving them, at a cost of +200% knockback
}

var current_weapon: Weapon = weapons[WEAPON_REVOLVER]



# GAMEPLAY FUNCS



func shoot():
	if tte <= current_weapon.reload_start+current_weapon.reload_time: return
	if current_weapon.mag_count <= 0:
		reload()
		return
	if (current_weapon.last_shot + current_weapon.fire_rate) < tte:
		current_weapon.last_shot = tte
		var anim = $Camera3D/Gun.get_node("AnimationPlayer")
		anim.current_animation = "recoil"
		anim.speed_scale = 1
		var fface = $Camera3D.global_basis.z
		var proj = preproj.instantiate()
		proj.position = global_position - fface + Vector3(0,0.731,0)
		proj.speed = 100
		var randface = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*(1/current_weapon.range)*0.02
		proj.direction = -fface + randface
		proj.exclusions = [self]
		var part = proj.duplicate()
		var spt = $Camera3D/Gun/Node3D.global_position
		var rct = $Camera3D/RayCast3D
		rct.look_at_from_position(proj.position,-(proj.direction*proj.speed))
		var hpt = $Camera3D/RayCast3D.get_collision_point()
		part.look_at_from_position(spt,hpt)
		part.direction = (hpt-spt).normalized()
		part.get_node("Node3D")
		part.get_node("Node3D").visible = true
		proj.connect("hit",_projectile_hit)
		proj.connect("miss",_projectile_miss)
		get_node("../World").add_child(proj)
		get_node("../World").add_child(part)
		current_weapon.mag_count -= 1

func reload():
	if tte <= current_weapon.reload_start+current_weapon.reload_time: return
	if current_weapon.mag_count >= current_weapon.mag_size: return
	current_weapon.reload_start = tte
	$Camera3D/Gun/ReloadTimer.wait_time = current_weapon.reload_time
	$Camera3D/Gun/ReloadTimer.start()
	$Camera3D/Gun/AnimationPlayer.current_animation = "reload"
	$Camera3D/Gun/AnimationPlayer.speed_scale = 1/current_weapon.reload_time

func impulse(impulse: Vector3):
	velocity += impulse
	just_hit = true
	move_and_slide()

func change_gun(type: int):
	current_weapon = weapons[type]



#BUILTINS



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Camera3D/RayCast3D.add_exception(self)
	if name == "Opponent":
		$Camera3D/Gun.queue_free()
	else:
		$Showgun.queue_free()
	$Camera3D/Gun/ReloadTimer.connect("timeout",_reload_complete)

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
				# In the air, just hit. Move at 35% speed so long as it slows you down
				var nvel = velocity + direction * 0.35
				var nxyvel = Vector3(velocity.x,0.0,velocity.z)
				if nxyvel.length() > SPEED:
					if nvel.length() < velocity.length():
						velocity = nvel
			else:
				# In the air, not just hit. Move at 55% speed
				velocity += direction * 0.55
			# Air damping
			velocity.x *= 0.995
			velocity.z *= 0.995
		else:
			# If on floor and moving
			velocity.x += direction.x * 1.5 * (1/0.8)
			velocity.z += direction.z * 1.5 * (1/0.8)
			velocity.x *= 0.8
			velocity.z *= 0.8
		#else:
			## If on floor and not moving
			#velocity.x *= 0.8
			#velocity.z *= 0.8
		velocity.y -= GRAVITY
		var xyvel = Vector3(velocity.x,0.0,velocity.z)
		if !just_hit && (xyvel.length() > SPEED):
			var modxyvel = xyvel.normalized()*SPEED
			velocity.x = modxyvel.x
			velocity.z = modxyvel.z
		if current_weapon.is_auto:
			if Input.is_action_pressed("m1"):
				shoot()
		else:
			if Input.is_action_just_pressed("m1"):
				shoot()
		if Input.is_action_just_pressed("r"):
			reload()
		$Camera3D/HUD/Label.text = str(current_weapon.mag_count) + " Ammo"
	move_and_slide()
	ticks += 1
	tte += delta



# SIGNALS

func _projectile_miss(pos: Vector3, normal: Vector3, vel: Vector3, target: Node):
	pass
	#this shit is cursed
	#var spark = load("res://Assets/Particles/bullet_wall.tscn").instantiate()
	#var lookat = vel.normalized().bounce(normal)
	#var lookat = normal
	#get_node("../World").add_child(spark)
	#spark.position = pos
	#spark.look_at(pos+lookat)
	#spark.get_node("GPUParticles3D").emitting = true

func _projectile_hit(normal: Vector3, target: Node3D):
	if target.name == "Opponent":
		get_parent().hit_opponent(normal,current_weapon)
		$Camera3D/HUD/CenterContainer/Sprite2D.position = get_viewport().size/2
		$Camera3D/HUD/CenterContainer/Sprite2D.visible = true
		$Camera3D/HUD/CenterContainer/Sprite2D.rotation = randi_range(0,90)
		$Camera3D/HUD/CenterContainer/Sprite2D/Timer.start()

func _on_hitmarker_timeout() -> void:
	$Camera3D/HUD/CenterContainer/Sprite2D.visible = false

func _reload_complete():
	current_weapon.mag_count = current_weapon.mag_size
