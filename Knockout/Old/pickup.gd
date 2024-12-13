extends Node3D

@export var ptype: int
@export var pvariation: int
@export var pid: int
var atte: float = 0.0
var rtte: float = 0.0

@warning_ignore("unused_signal")
signal pickup(pid: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	if ptype == 0:
		$CSGSphere3D/Label3D.text = ["REVOLVER","RIFLE","AUTO RIFLE","SHOTGUN","SMG","LAUNCHER"][pvariation]
	else:
		$CSGSphere3D/Label3D.text = ["REPEL","NULL","HOMING","OVERCLOCK","MOBILITY","NULL","NULL","NULL"][pvariation]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	atte += delta*4
	rtte += delta/2
	$CSGSphere3D/MeshInstance3D.position.y = sin(atte)/20
	$CSGSphere3D.rotation_degrees.y = int(rtte*360)%360


func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		emit_signal("pickup",pid)
