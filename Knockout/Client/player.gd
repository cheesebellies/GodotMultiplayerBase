extends CharacterBody3D

var ticks = 0
var tte = 0.0
var SPEED = 8.0
var JUMP_VELOCITY = 6.5
const GRAVITY = 0.25
const preproj = preload("res://Client/projectile.tscn")
@export var just_hit: bool = false
@export var is_auth: bool = true

#****************************************************
#						To-do:
#
# Cleanup deprecated code (specifically, server.gd, client.gd, player.gd, and all mentions of pickups.) Make sure to save all the code in res://Old/
# Let's go gambling!
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
		1.25,			#KB_mult
		2.0,			#range
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
		3.0,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_AUTO_RIFLE: Weapon.new(
		WEAPON_AUTO_RIFLE,
		"e",
		true,
		18,				#mag_size
		2.0,			#reload_time
		0.2,			#fire_rate
		0.85,			#KB_mult
		2.2,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_SHOTGUN: Weapon.new(
		WEAPON_SHOTGUN,
		"e",
		false,
		2,				#mag_size
		2.0,			#reload_time
		0.8,			#fire_rate
		0.35,			#KB_mult (PER PROJECTILE)
		0.3,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_SMG: Weapon.new(
		WEAPON_SMG,
		"e",
		true,
		36,				#mag_size
		3.5,			#reload_time
		0.075,			#fire_rate
		0.3,			#KB_mult
		0.65,			#range
		load("res://Assets/gun_new.obj")
	),
	WEAPON_LAUNCHER: Weapon.new(
		WEAPON_LAUNCHER,
		"e",
		false,
		3,				#mag_size
		1.0,			#reload_time
		0.8,			#fire_rate
		3.3,			#KB_mult
		0.35,			#range
		load("res://Assets/gun_new.obj")
	)
}

@export var has_powerup: Dictionary = {
	POWERUP_REPEL: false,		# Instant that repels the opponent based on distance, but also repels the player a smaller amount in the inverse direction
	POWERUP_GRAPPLE: false,		# Instant (cancelable) that grapples player towards whatever it is fired at. If it hits the opponent, they are grappled to each other
	POWERUP_HOMING: false,		# Short (3 seconds) that gives all shots fired a minor homing ability
	POWERUP_OVERCLOCK: false,	# Medium (9 seconds) that increases weapon fire rate
	POWERUP_MOBILITY: false,	# Long (15 seconds) that improves all movement: speed, air maneuverability, jump, etc.
	POWERUP_TANK: false,		# Long (15 seconds) that reduces knockback, but also increases size
	POWERUP_SHRINK: false,		# Long (15 seconds) that reduces player size, but also increases knockback
	POWERUP_SAVIOR: false		# Passive (activates on death) that teleports the player back to spawn, saving them, at a cost of +200% knockback
}

var current_weapon: Weapon = weapons[WEAPON_REVOLVER]
var current_powerup = null
var fire_rate_mod: float = 1.0
var has_homing: bool = false



# GAMEPLAY FUNCS



func powerup_timeout(time: float, type: int):
	var htimer = get_node_or_null("../powerup_" + str(type))
	if htimer:
		htimer.wait_time += time
		return
	var timer = Timer.new()
	timer.wait_time = time
	timer.name = "powerup_" + str(type)
	timer.autostart = true
	timer.one_shot = true
	timer.connect("timeout",_powerup_timeout.bind(type))
	get_parent().add_child(timer)

func use_powerup():
	if !current_powerup: return
	match current_powerup:
		POWERUP_REPEL:
			var diff = (get_node("../Opponent").global_position-global_position)
			var dist = diff.length()
			var mdir = diff/((dist/1.5)**2)
			get_parent().hit_opponent(mdir,weapons[WEAPON_RIFLE])
		POWERUP_GRAPPLE:
			pass
		POWERUP_HOMING:
			powerup_timeout(3,POWERUP_HOMING)
			has_homing = true
		POWERUP_OVERCLOCK:
			powerup_timeout(9,POWERUP_OVERCLOCK)
			fire_rate_mod = 1.5
		POWERUP_MOBILITY:
			powerup_timeout(15,POWERUP_MOBILITY)
			SPEED = 10.0
			JUMP_VELOCITY = 10.0
		POWERUP_TANK:
			pass
		POWERUP_SHRINK:
			pass
	current_powerup = null

func shoot():
	if tte <= current_weapon.reload_start+current_weapon.reload_time: return
	if current_weapon.mag_count <= 0:
		reload()
		return
	if (current_weapon.last_shot + (current_weapon.fire_rate * (2-fire_rate_mod))) < tte:
		current_weapon.last_shot = tte
		current_weapon.mag_count -= 1
		var anim = $Camera3D/Gun.get_node("AnimationPlayer")
		anim.current_animation = "recoil"
		anim.speed_scale = 1
		if current_weapon.type == WEAPON_LAUNCHER:
			var fface = $Camera3D.global_basis.z
			var part = preproj.instantiate()
			part.homing = has_homing
			part.target = get_node("../Opponent")
			part.grenade = true
			part.speed = 50
			var randface = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*(1/current_weapon.range)*0.012
			part.exclusions = [self]
			var spt = $Camera3D/Gun/Node3D.global_position
			$Camera3D/RayCast3D.global_basis = Basis.looking_at((-fface + randface).normalized())
			$Camera3D/RayCast3D.rotation_degrees.x += 90
			$Camera3D/RayCast3D.force_raycast_update()
			var hpt = $Camera3D/RayCast3D.get_collision_point()
			part.look_at_from_position(spt,hpt)
			part.direction = (hpt-spt).normalized()
			part.get_node("Node3D").visible = true
			part.connect("hit",_grenade_hit)
			part.connect("miss",_grenade_hit)
			get_node("../World").add_child(part)
			get_parent().send_tracer(part.direction, 50.0, part.homing, part.grenade)
			return
		for parnum in range(1 if current_weapon.type != WEAPON_SHOTGUN else 8):
			var fface = $Camera3D.global_basis.z
			var proj = preproj.instantiate()
			proj.homing = has_homing
			proj.target = get_node("../Opponent")
			proj.position = global_position - fface + Vector3(0,0.731,0)
			proj.speed = 1000.0
			var randface = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*(1/current_weapon.range)*0.012
			proj.direction = (-fface + randface).normalized()
			proj.exclusions = [self]
			var part = proj.duplicate()
			var spt = $Camera3D/Gun/Node3D.global_position
			$Camera3D/RayCast3D.global_basis = Basis.looking_at(proj.direction)
			$Camera3D/RayCast3D.rotation_degrees.x += 90
			$Camera3D/RayCast3D.force_raycast_update()
			var hpt = $Camera3D/RayCast3D.get_collision_point()
			part.look_at_from_position(spt,hpt)
			part.direction = (hpt-spt).normalized()
			part.get_node("Node3D").visible = true
			proj.connect("hit",_projectile_hit)
			proj.connect("miss",_projectile_miss)
			get_node("../World").add_child(proj)
			get_node("../World").add_child(part)
			get_parent().send_tracer(part.direction, 1000.0, part.homing, part.grenade)

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
		$Camera3D/Gun.visible = false
	else:
		$Showgun.visible = false
	$Camera3D/Gun/ReloadTimer.connect("timeout",_reload_complete)
	current_weapon = weapons[randi_range(0,5)]

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
				var nvel = velocity
				nvel.x += direction.x * 1.5 * (2/0.8)
				nvel.z += direction.z * 1.5 * (2/0.8)
				var vxylen = Vector3(velocity.x,0,velocity.y)
				if vxylen.length() > SPEED:
					var nxylen = Vector3(nvel.x,0,nvel.y)
					if (vxylen.length() + nxylen.length()) < vxylen.length():
						velocity = nvel
				else:
					velocity = nvel
			velocity += direction * 0.45
			# Air damping
			velocity.x *= 0.995
			velocity.z *= 0.995
		else:
			# If on floor and moving
			velocity.x += direction.x * 1.5 * (2/0.8)
			velocity.z += direction.z * 1.5 * (2/0.8)
			velocity.x *= 0.8
			velocity.z *= 0.8
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
		if Input.is_action_just_pressed("q"):
			use_powerup()
		$Camera3D/HUD/Label.text = str(current_weapon.mag_count) + " Ammo"
		if current_powerup:
			$Camera3D/HUD/Label2.text = "[Q]" + str(["REPEL","NULL","HOMING","OVERCLOCK","MOBILITY","NULL","NULL","NULL"][current_powerup])
		else:
			$Camera3D/HUD/Label2.text = ""
	move_and_slide()
	ticks += 1
	tte += delta



# SIGNALS 



@warning_ignore("unused_parameter")
func _grenade_hit(pos: Vector3, normal: Vector3, vel: Vector3, target: Node):
	var opos = get_node("../Opponent").global_position
	var dist = (opos-pos)
	var sdist = 6.0
	if dist.length() < sdist:
		get_parent().hit_opponent(dist.normalized()*((sdist-dist.length())/sdist),current_weapon)
		$Camera3D/HUD/CenterContainer/Sprite2D.position = get_viewport().size/2
		$Camera3D/HUD/CenterContainer/Sprite2D.visible = true
		$Camera3D/HUD/CenterContainer/Sprite2D.rotation = randi_range(0,90)
		$Camera3D/HUD/CenterContainer/Sprite2D/Timer.start()

func _powerup_timeout(type: int):
	match current_powerup:
		POWERUP_REPEL:
			pass
		POWERUP_GRAPPLE:
			pass
		POWERUP_HOMING:
			has_homing = false
			get_node("../powerup_" + str(type)).queue_free()
		POWERUP_OVERCLOCK:
			fire_rate_mod = 1.0
			get_node("../powerup_" + str(type)).queue_free()
		POWERUP_MOBILITY:
			SPEED = 8.0
			JUMP_VELOCITY = 6.5
			get_node("../powerup_" + str(type)).queue_free()
		POWERUP_TANK:
			pass
		POWERUP_SHRINK:
			pass

@warning_ignore("unused_parameter")
func _projectile_miss(pos: Vector3, normal: Vector3, vel: Vector3, target: Node):
	var spark = load("res://Assets/Particles/bullet_wall.tscn").instantiate()
	get_node("../World").add_child(spark)
	spark.position = pos
	spark.get_node("GPUParticles3D").emitting = true

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
