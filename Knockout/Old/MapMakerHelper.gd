@tool
extends Node3D

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var children = get_children(true)
		for child in children:
			if child is CSGBox3D:
				if child.material: continue
				child.material = StandardMaterial3D.new()
				child.material.albedo_texture = load("res://Assets/PrototypeTextures/prototype_512x512_white.png")
				child.material.uv1_triplanar = true
				child.material.uv1_scale = Vector3(0.5,0.5,0.5)
				child.material.uv1_offset = Vector3(0,-0.5,0)
				child.use_collision = true
