extends CharacterBody3D

@export var speed: float = 500.0
@export var direction: Vector3 = Vector3(0,0,0)
@export var exclusions: Array

var tte = 0.0

signal hit(normal: Vector3, target: Node)

func _ready():
	velocity = direction*speed
	for e in exclusions:
		self.add_collision_exception_with(e)

func _physics_process(delta):
	if tte >= 2.0:
		self.queue_free()
	tte += delta
	var res = move_and_collide(velocity*delta)
	if res:
		if (res.get_collider().name == "Opponent"):
			emit_signal("hit",velocity.normalized(),res.get_collider())
			self.queue_free()
		else:
			var spark = load("res://Assets/Particles/bullet_wall.tscn").instantiate()
			var hitpos = res.get_position()
			spark.look_at_from_position(hitpos,hitpos + res.get_normal())
			get_parent().add_child(spark)
			spark.get_node("GPUParticles3D").emitting = true
			self.queue_free()
