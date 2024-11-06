extends Node3D

var atte: float = 0.0
var rtte: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	atte += delta*4
	rtte += delta/2
	$CSGSphere3D/MeshInstance3D.position.y = sin(atte)/20
	$CSGSphere3D.rotation_degrees.y = int(rtte*360)%360