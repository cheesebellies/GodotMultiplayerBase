extends CharacterBody3D

var ticks = 0
var tte = 0.0
var lastshot = -2.0
var puid: int = -1
const SPEED = 11.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 0.15
const preproj = preload("res://Client/projectile.tscn")
@export var just_hit: bool = false
@export var is_auth: bool = true

#****************************************************
#						To-do:
#3	- Add a slight aim assist option
#4	- Implement pickup system (powerups/guns)
#6	- Implement powerup selection
#
#
#
#****************************************************

enum {WEAPON_REVOLVER,WEAPON_RIFLE,WEAPON_AUTO_RIFLE,WEAPON_SHOTGUN,WEAPON_SMG,WEAPON_LAUNCHER}
enum {POWERUP_REPEL,POWERUP_GRAPPLE,POWERUP_HOMING,POWERUP_OVERCLOCK,POWERUP_MOBILITY,POWERUP_TANK,POWERUP_SHRINK,POWERUP_SAVIOR}

var weapons: Dictionary = {
	WEAPON_REVOLVER: Weapon.new(WEAPON_REVOLVER,"Simple revolver, the starting weapon.", false, 6, 0.1, 0.5, 30, load("res://Assets/gun_new.obj")),
	WEAPON_RIFLE: Weapon.new(WEAPON_RIFLE,"Simple revolver, the starting weapon.", false, 1, 0.2, 0.5, 30, load("res://Assets/gun_new.obj")),
	WEAPON_AUTO_RIFLE: Weapon.new(WEAPON_AUTO_RIFLE,"Simple revolver, the starting weapon.", true, 18, 0.2, 0.5, 30, load("res://Assets/gun_new.obj")),
	WEAPON_SHOTGUN: Weapon.new(WEAPON_SHOTGUN,"Simple revolver, the starting weapon.", false, 2, 0.2, 0.5, 30, load("res://Assets/gun_new.obj")),
	WEAPON_SMG: Weapon.new(WEAPON_SMG,"Simple revolver, the starting weapon.", true, 35, 0.05, 0.5, 30, load("res://Assets/gun_new.obj")),
	WEAPON_LAUNCHER: Weapon.new(WEAPON_LAUNCHER,"Simple revolver, the starting weapon.", false, 3, 0.2, 0.5, 30, load("res://Assets/gun_new.obj"))
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
var current_weapon: Weapon = weapons.WEAPON_REVOLVER


class Weapon:
	var type: int
	var description: String
	var is_auto: bool
	var mag_size: int
	var reload_time: float
	var KB_mult: float
	var range: float
	var model: Mesh
	
	func _init(type: int, description: String, is_auto: bool, mag_size: int, reload_time: float, KB_mult: float, range: float, model: Mesh):
		self.type = type
		self.description = description
		self.is_auto = is_auto
		self.mag_size = mag_size
		self.reload_time = reload_time
		self.KB_mult = KB_mult
		self.range = range
		self.model = model


# GAMEPLAY FUNCS



func shoot():
	if tte-lastshot >= 0.1333:
		lastshot = tte
		var anim = $Camera3D/Gun.get_node("AnimationPlayer")
		anim.current_animation = "recoil"
		var fface = $Camera3D.global_basis.z
		var proj = preproj.instantiate()
		proj.position = global_position - fface + Vector3(0,0.731,0)
		proj.speed = 1000
		proj.direction = -fface
		proj.exclusions = [self]
		proj.connect("hit",_projectile_hit)
		proj.connect("miss",_projectile_miss)
		get_node("../World").add_child(proj)



#BUILTINS



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Camera3D/RayCast3D.add_exception(self)
	if name == "Opponent":
		$Camera3D/Gun.queue_free()
	else:
		$Showgun.queue_free()

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



# SIGNALS

func _projectile_miss(pos: Vector3, normal: Vector3, vel: Vector3, target: Node):
	pass
	#this shit is cursed
	#var spark = load("res://Assets/Particles/bullet_wall.tscn").instantiate()
	##var lookat = vel.normalized().bounce(normal)
	#var lookat = normal
	#get_node("../World").add_child(spark)
	#spark.position = pos
	#spark.look_at(pos+lookat)
	#spark.get_node("GPUParticles3D").emitting = true

func _projectile_hit(normal: Vector3, target: Node3D):
	if target.name == "Opponent":
		get_parent().hit_opponent(normal)
		$Camera3D/Crosshair/CenterContainer/Sprite2D.position = get_viewport().size/2
		$Camera3D/Crosshair/CenterContainer/Sprite2D.visible = true
		$Camera3D/Crosshair/CenterContainer/Sprite2D.rotation = randi_range(0,90)
		$Camera3D/Crosshair/CenterContainer/Sprite2D/Timer.start()

func _on_hitmarker_timeout() -> void:
	$Camera3D/Crosshair/CenterContainer/Sprite2D.visible = false
