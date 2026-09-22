extends Node3D

var sword: Node3D
var shield: Node3D

var _sword_rest_pos := Vector3(0.32, -0.3, -0.5)
var _sword_rest_rot := Vector3(16, 18, 14)
var _shield_rest_pos := Vector3(-0.3, -0.24, -0.48)
var _shield_rest_rot := Vector3(8, 22, -10)
var _sword_tween: Tween
var _shield_tween: Tween


func _ready() -> void:
	sword = _build_sword()
	shield = _build_shield()
	add_child(sword)
	add_child(shield)
	_snap_idle()


func set_equipped(has_sword: bool, has_shield: bool) -> void:
	if sword:
		sword.visible = has_sword
	if shield:
		shield.visible = has_shield


func snap_idle() -> void:
	_kill_tweens()
	_snap_idle()


func play_light(step: int) -> float:
	match clampi(step, 0, 2):
		0:
			return _slash(
				Vector3(0.42, -0.08, -0.4), Vector3(55, 48, 40),
				Vector3(0.08, -0.12, -0.55), Vector3(-8, -62, -18),
				0.28
			)
		1:
			return _slash(
				Vector3(0.02, 0.02, -0.42), Vector3(-30, -40, -24),
				Vector3(0.38, -0.18, -0.52), Vector3(28, 58, 22),
				0.3
			)
		_:
			return _slash(
				Vector3(0.18, 0.22, -0.38), Vector3(-70, 8, 12),
				Vector3(0.16, -0.32, -0.58), Vector3(48, 12, 8),
				0.4
			)


func play_power() -> float:
	_kill_tweens()
	_sword_tween = create_tween()
	_sword_tween.tween_property(sword, "position", Vector3(0.28, 0.16, -0.32), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", Vector3(-82, 16, 10), 0.12)
	_sword_tween.tween_property(sword, "position", Vector3(0.12, -0.36, -0.62), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", Vector3(62, 8, 6), 0.22)
	_sword_tween.tween_property(sword, "position", _sword_rest_pos, 0.28).set_trans(Tween.TRANS_SINE)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", _sword_rest_rot, 0.28)
	return 0.62


func set_charging(on: bool) -> void:
	if not on:
		return
	_kill_sword_tween()
	_sword_tween = create_tween()
	_sword_tween.tween_property(sword, "position", Vector3(0.3, 0.1, -0.34), 0.18).set_trans(Tween.TRANS_SINE)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", Vector3(-74, 18, 12), 0.18)


func set_blocking(on: bool) -> void:
	_kill_shield_tween()
	_shield_tween = create_tween()
	if on:
		_shield_tween.tween_property(shield, "position", Vector3(-0.12, -0.1, -0.42), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_shield_tween.parallel().tween_property(shield, "rotation_degrees", Vector3(2, 8, -4), 0.12)
		_kill_sword_tween()
		_sword_tween = create_tween()
		_sword_tween.tween_property(sword, "position", Vector3(0.4, -0.22, -0.4), 0.12)
		_sword_tween.parallel().tween_property(sword, "rotation_degrees", Vector3(8, 40, 28), 0.12)
	else:
		_shield_tween.tween_property(shield, "position", _shield_rest_pos, 0.16).set_trans(Tween.TRANS_SINE)
		_shield_tween.parallel().tween_property(shield, "rotation_degrees", _shield_rest_rot, 0.16)
		_kill_sword_tween()
		_sword_tween = create_tween()
		_sword_tween.tween_property(sword, "position", _sword_rest_pos, 0.16)
		_sword_tween.parallel().tween_property(sword, "rotation_degrees", _sword_rest_rot, 0.16)


func play_block_hit() -> void:
	if shield == null or not shield.visible:
		return
	_kill_shield_tween()
	var raised := Vector3(-0.12, -0.1, -0.42)
	_shield_tween = create_tween()
	_shield_tween.tween_property(shield, "position", raised + Vector3(0, 0, 0.08), 0.05)
	_shield_tween.tween_property(shield, "position", raised, 0.12)


func play_parry() -> void:
	if shield == null:
		return
	_kill_tweens()
	_shield_tween = create_tween()
	_shield_tween.tween_property(shield, "position", Vector3(-0.04, -0.04, -0.52), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shield_tween.parallel().tween_property(shield, "rotation_degrees", Vector3(12, -8, 18), 0.05)
	_shield_tween.tween_property(shield, "position", _shield_rest_pos, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shield_tween.parallel().tween_property(shield, "rotation_degrees", _shield_rest_rot, 0.22)
	_sword_tween = create_tween()
	_sword_tween.tween_property(sword, "position", Vector3(0.22, -0.12, -0.58), 0.08)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", Vector3(28, -10, 8), 0.08)
	_sword_tween.tween_property(sword, "position", _sword_rest_pos, 0.2)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", _sword_rest_rot, 0.2)


func _slash(windup_pos: Vector3, windup_rot: Vector3, hit_pos: Vector3, hit_rot: Vector3, duration: float) -> float:
	_kill_sword_tween()
	var wind := minf(0.08, duration * 0.22)
	var cut := duration * 0.42
	var recover := maxf(duration - wind - cut, 0.1)
	_sword_tween = create_tween()
	_sword_tween.tween_property(sword, "position", windup_pos, wind).set_trans(Tween.TRANS_SINE)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", windup_rot, wind)
	_sword_tween.tween_property(sword, "position", hit_pos, cut).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", hit_rot, cut)
	_sword_tween.tween_property(sword, "position", _sword_rest_pos, recover).set_trans(Tween.TRANS_SINE)
	_sword_tween.parallel().tween_property(sword, "rotation_degrees", _sword_rest_rot, recover)
	return duration


func _snap_idle() -> void:
	if sword:
		sword.position = _sword_rest_pos
		sword.rotation_degrees = _sword_rest_rot
	if shield:
		shield.position = _shield_rest_pos
		shield.rotation_degrees = _shield_rest_rot


func _kill_tweens() -> void:
	_kill_sword_tween()
	_kill_shield_tween()


func _kill_sword_tween() -> void:
	if _sword_tween and _sword_tween.is_valid():
		_sword_tween.kill()
	_sword_tween = null


func _kill_shield_tween() -> void:
	if _shield_tween and _shield_tween.is_valid():
		_shield_tween.kill()
	_shield_tween = null


func _build_sword() -> Node3D:
	var root := Node3D.new()
	root.name = "Sword"
	root.add_child(_mesh(Vector3(0.028, 0.028, 0.14), Vector3(0, 0, 0.08), Color(0.28, 0.16, 0.08), 0.0, 0.7))
	root.add_child(_mesh(Vector3(0.13, 0.03, 0.024), Vector3(0, 0, 0.0), Color(0.78, 0.62, 0.22), 0.7, 0.35))
	root.add_child(_mesh(Vector3(0.032, 0.012, 0.48), Vector3(0, 0, -0.25), Color(0.72, 0.76, 0.82), 0.88, 0.22))
	root.add_child(_mesh(Vector3(0.018, 0.018, 0.05), Vector3(0, 0, 0.14), Color(0.55, 0.45, 0.2), 0.65, 0.4))
	return root


func _build_shield() -> Node3D:
	var root := Node3D.new()
	root.name = "Shield"
	root.add_child(_mesh(Vector3(0.2, 0.26, 0.03), Vector3.ZERO, Color(0.32, 0.16, 0.08), 0.05, 0.62))
	root.add_child(_mesh(Vector3(0.22, 0.28, 0.018), Vector3(0, 0, 0.01), Color(0.5, 0.42, 0.26), 0.55, 0.4))
	root.add_child(_mesh(Vector3(0.05, 0.05, 0.04), Vector3(0, 0, -0.012), Color(0.7, 0.58, 0.22), 0.8, 0.3))
	return root


func _mesh(size: Vector3, pos: Vector3, color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
