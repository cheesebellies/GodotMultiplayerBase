extends CharacterBody3D

@export var speed: float = 500.0
@export var direction: Vector3 = Vector3(0,0,0)
@export var expires: float = 1.0
@export var exclusions: Array
@export var mesh: Mesh
@export var homing: bool = false

var sdif = null
var tte = 0.0

@warning_ignore("unused_signal")
signal hit(normal: Vector3, target: Node)
@warning_ignore("unused_signal")
signal miss(position: Vector3, normal: Vector3, velocity: Vector3, target: Node)

func _ready():
	velocity = direction*speed
	for e in exclusions:
		self.add_collision_exception_with(e)
	if mesh: $MeshInstance3D.mesh=mesh

func _physics_process(delta):
	if tte >= expires:
		self.queue_free()
	tte += delta
	if homing:
		var opos = get_node("../../Opponent").global_position
		var tvel = (opos - global_position)
		var tdir = tvel.normalized()
		var tlen = tvel.length()
		var adif = velocity.normalized().angle_to(tdir)
		if !sdif: sdif = adif
		if sdif < 30.0:
			var dfac = clamp(tlen / 100, 0.1, 1.0)
			var sctr = 180.0 * 2.0 * dfac
			var cang = min(adif, deg_to_rad(sctr * delta))
			var fdir = velocity.normalized().slerp(tdir, cang / adif).normalized()
			velocity = fdir * speed
	var res = move_and_collide(velocity*delta)
	if res:
		if (res.get_collider().name == "Opponent"):
			emit_signal("hit",velocity.normalized(),res.get_collider())
			self.queue_free()
		else:
			emit_signal("miss",res.get_position(),res.get_normal(),velocity,res.get_collider())
			self.queue_free()
