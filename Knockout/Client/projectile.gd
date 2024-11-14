extends CharacterBody3D

@export var speed: float = 500.0
@export var direction: Vector3 = Vector3(0,0,0)
@export var expires: float = 2.0
@export var exclusions: Array
@export var mesh: Mesh

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
	var res = move_and_collide(velocity*delta)
	if res:
		if (res.get_collider().name == "Opponent"):
			emit_signal("hit",velocity.normalized(),res.get_collider())
			self.queue_free()
		else:
			emit_signal("miss",res.get_position(),res.get_normal(),velocity,res.get_collider())
			self.queue_free()
