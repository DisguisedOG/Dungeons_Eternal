extends Node3D

var _seal: MeshInstance3D
var _glow: OmniLight3D


func _ready() -> void:
	_build()
	Globals.exit_unlocked.connect(_unlock)
	if Globals.exit_open:
		_unlock()


func _build() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.28, 0.22, 0.2)
	stone.roughness = 1.0

	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.72, 0.55, 0.22)
	gold.emission_enabled = true
	gold.emission = Color(0.85, 0.55, 0.15)
	gold.emission_energy_multiplier = 1.6

	_add_box(stone, Vector3(1.4, 0.16, 0.7), Vector3(0, 0.08, 0.35))
	_add_box(stone, Vector3(1.15, 0.16, 0.55), Vector3(0, 0.24, 0.18))
	_add_box(stone, Vector3(0.9, 0.16, 0.4), Vector3(0, 0.4, 0.02))
	_add_box(stone, Vector3(0.18, 1.7, 0.18), Vector3(-0.7, 0.85, -0.55))
	_add_box(stone, Vector3(0.18, 1.7, 0.18), Vector3(0.7, 0.85, -0.55))
	_add_box(gold, Vector3(1.55, 0.12, 0.12), Vector3(0, 1.62, -0.55))

	var seal_mat := StandardMaterial3D.new()
	seal_mat.albedo_color = Color(0.18, 0.1, 0.22)
	seal_mat.roughness = 0.85
	var seal_mesh := BoxMesh.new()
	seal_mesh.size = Vector3(1.35, 1.35, 0.12)
	seal_mesh.material = seal_mat
	_seal = MeshInstance3D.new()
	_seal.mesh = seal_mesh
	_seal.position = Vector3(0, 0.78, -0.42)
	add_child(_seal)

	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.78, 0.35)
	_glow.light_energy = 0.0
	_glow.omni_range = 3.5
	_glow.position = Vector3(0, 1.1, 0)
	add_child(_glow)


func _add_box(material: Material, size: Vector3, pos: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	add_child(instance)


func _unlock() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	if _seal:
		tween.tween_property(_seal, "position", _seal.position + Vector3(0, -1.6, 0), 0.8)
		tween.tween_property(_seal, "rotation", Vector3(0.15, 0, 0), 0.8)
	if _glow:
		tween.tween_property(_glow, "light_energy", 2.8, 0.6)
