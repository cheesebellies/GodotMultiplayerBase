extends CharacterBody3D

@export var speed: float = 500.0
@export var direction: Vector3 = Vector3(0,0,0)
@export var expires: float = 1.0
@export var exclusions: Array
@export var mesh: Mesh
@export var homing: bool = false
@export var grenade: bool = false
@export var target: Node

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
	$Node3D.global_basis = Basis.looking_at(velocity)
	if grenade:
		$Node3D/CSGCylinder3D.visible = false
		$Node3D/CSGCylinder3D2.visible = true
		expires += 10.0
		

func _physics_process(delta):
	if tte >= expires:
		self.queue_free()
	tte += delta
	var res = move_and_collide(velocity*delta)
	if res:
		if (res.get_collider().name == target.name):
			if grenade:
				emit_signal("miss",res.get_position(),res.get_normal(),velocity,res.get_collider())
			else:
				emit_signal("hit",velocity.normalized(),res.get_collider())
			self.queue_free()
		else:
			emit_signal("miss",res.get_position(),res.get_normal(),velocity,res.get_collider())
			self.queue_free()
	if grenade:
		velocity.y -= 0.45
	if homing:
		if target:
			var opos = target.global_position
			var tvel = (opos - global_position)
			var tdir = tvel.normalized()
			var tlen = tvel.length()
			var adif = velocity.normalized().angle_to(tdir)
			if adif != 0:
				var dfac = clamp(tlen / 100, 0.1, 1.0)
				var tnrt = 180.0 if !grenade else 60.0
				var sctr = tnrt * 2.0 * dfac
				var cang = min(adif, deg_to_rad(sctr * delta))
				var fdir = velocity.normalized().slerp(tdir, cang / adif).normalized()
				velocity = fdir * speed
	$Node3D.global_basis = Basis.looking_at(velocity)
