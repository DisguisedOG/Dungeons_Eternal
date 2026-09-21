extends Node3D

var cell := Vector2i.ZERO


func _ready() -> void:
	_build()


func _build() -> void:
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.82, 0.62, 0.18)
	gold.emission_enabled = true
	gold.emission = Color(0.7, 0.45, 0.1)
	gold.emission_energy_multiplier = 1.4
	gold.roughness = 0.55

	var sack := StandardMaterial3D.new()
	sack.albedo_color = Color(0.32, 0.2, 0.12)
	sack.roughness = 1.0

	_box(sack, Vector3(0.42, 0.22, 0.32), Vector3(-0.12, 0.14, 0.08))
	_box(gold, Vector3(0.16, 0.1, 0.16), Vector3(0.16, 0.18, -0.06))
	_box(gold, Vector3(0.12, 0.08, 0.12), Vector3(0.02, 0.24, 0.12))

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.78, 0.32)
	glow.light_energy = 1.6
	glow.omni_range = 2.4
	glow.position = Vector3(0, 0.35, 0)
	add_child(glow)


func _box(material: Material, size: Vector3, pos: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	add_child(instance)
