extends Node3D

const MobData = preload("res://Data/MobData.gd")
const MESH_PATH := "res://Monster/Oozey/Oozey.obj"
const DIFFUSE_PATH := "res://Monster/Oozey/oozey_diffuse.png"
const NORMAL_PATH := "res://Monster/Oozey/oozey_n.png"

var encounter_id: int = 0
var kind: String = "oozey"
var _body: Node3D
var _mesh: MeshInstance3D
var _glow: OmniLight3D
var _alive := true
var _idle := 0.0
var _hit_punch := 0.0
var _model_scale := 0.24


func _ready() -> void:
	_build()
	if not Globals.is_encounter_alive(encounter_id):
		_on_died()
		return
	Globals.encounter_hit.connect(_on_hit)
	Globals.encounter_died.connect(_on_died_id)


func _process(delta: float) -> void:
	if _body == null:
		return
	_idle += delta
	if not _alive:
		return
	var wobble := sin(_idle * 2.4)
	_body.position.y = wobble * 0.045
	var squash := 1.0 + wobble * 0.035
	var tall := 1.0 - wobble * 0.03
	if _hit_punch > 0.0:
		_hit_punch = maxf(_hit_punch - delta * 4.0, 0.0)
	_body.scale = Vector3(squash + _hit_punch * 0.12, tall - _hit_punch * 0.18, squash + _hit_punch * 0.12)


func _build() -> void:
	var data: Dictionary = MobData.def(kind)
	_model_scale = float(data.get("scale", 0.24))
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	_mesh = MeshInstance3D.new()
	_mesh.mesh = load(MESH_PATH)
	_mesh.position = Vector3(0, 0.02, 0)
	_mesh.scale = Vector3.ONE * _model_scale
	_mesh.rotation_degrees = Vector3(0, 180, 0)
	_mesh.material_override = _make_slime_material(data)
	_body.add_child(_mesh)

	_glow = OmniLight3D.new()
	_glow.light_color = data.get("glow", Color(0.28, 0.95, 0.22))
	_glow.light_energy = 2.1
	_glow.omni_range = 4.2
	_glow.omni_attenuation = 1.6
	_glow.position = Vector3(0, 0.85, 0)
	add_child(_glow)


func _make_slime_material(data: Dictionary) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(DIFFUSE_PATH)
	mat.albedo_color = data.get("tint", Color(0.85, 1.0, 0.7))
	mat.roughness = 0.28
	mat.metallic = 0.05
	mat.normal_enabled = true
	mat.normal_texture = load(NORMAL_PATH)
	mat.normal_scale = 0.85
	mat.emission_enabled = true
	mat.emission = data.get("glow", Color(0.08, 0.35, 0.04))
	mat.emission_energy_multiplier = 1.35
	mat.emission_texture = load(DIFFUSE_PATH)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return mat


func _on_hit(id: int) -> void:
	if id != encounter_id or not _alive:
		return
	_hit_punch = 1.0
	var tween := create_tween()
	tween.tween_property(_body, "position:z", 0.16, 0.07)
	tween.tween_property(_body, "position:z", 0.0, 0.14)
	if _glow:
		var energy := _glow.light_energy
		var flash := create_tween()
		flash.tween_property(_glow, "light_energy", energy * 2.4, 0.06)
		flash.tween_property(_glow, "light_energy", energy, 0.2)


func _on_died_id(id: int) -> void:
	if id == encounter_id:
		_on_died()


func _on_died() -> void:
	if not _alive:
		return
	_alive = false
	if Globals.encounter_hit.is_connected(_on_hit):
		Globals.encounter_hit.disconnect(_on_hit)
	if Globals.encounter_died.is_connected(_on_died_id):
		Globals.encounter_died.disconnect(_on_died_id)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_body, "scale", Vector3(1.55, 0.12, 1.55), 0.75)
	tween.tween_property(_body, "position", Vector3(0, 0.02, 0.12), 0.75)
	if _glow:
		tween.tween_property(_glow, "light_energy", 0.15, 0.6)
