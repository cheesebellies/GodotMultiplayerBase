class_name Weapon
extends Node

var type: int
var description: String
var is_auto: bool
var mag_size: int
var reload_time: float
var fire_rate: float
var KB_mult: float
var range: float
var model: Mesh

var last_shot: float = -99.0
var mag_count: int
var reload_start: float = -99.0

func _init(type: int, description: String, is_auto: bool, mag_size: int, reload_time: float, fire_rate: float, KB_mult: float, range: float, model: Mesh):
	self.type = type
	self.description = description
	self.is_auto = is_auto
	self.mag_size = mag_size
	self.mag_count = mag_size
	self.reload_time = reload_time
	self.KB_mult = KB_mult
	self.range = range
	self.model = model
