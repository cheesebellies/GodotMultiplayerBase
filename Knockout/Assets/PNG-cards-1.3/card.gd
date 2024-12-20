@tool
extends Node3D

@export var texture: Texture:
	set(value):
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = value
		$MeshInstance3D.set_surface_override_material(0,mat)
		texture = value
