extends Node3D

const WeaponRigScript = preload("res://Player/WeaponRig.gd")

@onready var timerprocessor: = $Timer
@onready var forward: = $RayForward
@onready var back: = $RayBack
@onready var right: = $RayRight
@onready var left: = $RayLeft
@onready var camera: Camera3D = $Camera3D

var tween
var _rig
var _lmb_held := false
var _lmb_time := 0.0
var _charging := false
var _swinging := false
var _queued_light := false
var _blocking := false
var _combo := 0
var _combo_window := 0.0
var _want_block := false

const HOLD_POWER := 0.34
const MAX_CHARGE := 0.82
const COMBO_WINDOW := 0.4
const LIGHT_MULT := [1.0, 1.2, 1.55]
const POWER_MULT := 2.25
const HIT_DELAY := 0.11


func _ready() -> void:
	_rig = WeaponRigScript.new()
	_rig.name = "WeaponRig"
	camera.add_child(_rig)
	if not Globals.hero_changed.is_connected(_refresh_weapons):
		Globals.hero_changed.connect(_refresh_weapons)
	if not Globals.guard_broken.is_connected(_on_guard_broken):
		Globals.guard_broken.connect(_on_guard_broken)
	if not Globals.monster_attacked.is_connected(_on_monster_attacked):
		Globals.monster_attacked.connect(_on_monster_attacked)
	if not Globals.parry_succeeded.is_connected(_on_parry_succeeded):
		Globals.parry_succeeded.connect(_on_parry_succeeded)
	_refresh_weapons()


func _process(delta: float) -> void:
	if _combo_window > 0.0:
		_combo_window = maxf(_combo_window - delta, 0.0)
		if _combo_window <= 0.0 and not _swinging:
			_combo = 0
	if not Globals.uses_realtime_melee() or Globals.menu_open or Globals.game_over:
		if _blocking:
			_set_block_visual(false)
		_lmb_held = false
		_charging = false
		return
	_refresh_weapons()
	if _lmb_held and not _swinging and not _blocking:
		_lmb_time += delta
		if _lmb_time >= HOLD_POWER and not _charging:
			_charging = true
			_combo = 0
			_queued_light = false
			_rig.set_charging(true)
		if _charging and _lmb_time >= MAX_CHARGE:
			_lmb_held = false
			_fire_power()
	if _want_block and not _swinging and not _charging and not _blocking:
		_try_start_block()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and Globals.game_over:
		Globals.start_new_run()
		return
	if Globals.menu_open or Globals.game_over:
		return
	if Globals.uses_realtime_melee():
		if _is_attack_press(event):
			_on_attack_pressed()
			get_viewport().set_input_as_handled()
			return
		if _is_attack_release(event):
			_on_attack_released()
			get_viewport().set_input_as_handled()
			return
		if _is_block_press(event):
			_want_block = true
			_try_start_block()
			get_viewport().set_input_as_handled()
			return
		if _is_block_release(event):
			_want_block = false
			_set_block_visual(false)
			get_viewport().set_input_as_handled()
			return
		for i in 3:
			if event.is_action_pressed("skill_%d" % (i + 1)):
				var actives = Globals.hero.active_skills()
				if i < actives.size():
					Globals.try_combat(str(actives[i]["id"]))
				return
		return
	if event.is_action_pressed("attack"):
		if Globals.try_combat(""):
			_play_attack_lunge()
		return
	for i in 3:
		if event.is_action_pressed("skill_%d" % (i + 1)):
			var actives = Globals.hero.active_skills()
			if i < actives.size():
				if Globals.try_combat(str(actives[i]["id"])):
					_play_attack_lunge()
			return


func _is_attack_press(event: InputEvent) -> bool:
	if event.is_action_pressed("melee_attack") or event.is_action_pressed("attack"):
		return true
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT


func _is_attack_release(event: InputEvent) -> bool:
	if event.is_action_released("melee_attack") or event.is_action_released("attack"):
		return true
	return event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT


func _is_block_press(event: InputEvent) -> bool:
	if event.is_action_pressed("melee_block"):
		return true
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT


func _is_block_release(event: InputEvent) -> bool:
	if event.is_action_released("melee_block"):
		return true
	return event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT


func _on_attack_pressed() -> void:
	_want_block = false
	if _blocking:
		_set_block_visual(false)
	_lmb_held = true
	_lmb_time = 0.0
	_charging = false
	if _swinging:
		if _combo_window > 0.0 and _combo < 3:
			_queued_light = true


func _on_attack_released() -> void:
	if not _lmb_held and not _charging:
		return
	var held := _lmb_time
	_lmb_held = false
	if _swinging:
		return
	if _charging or held >= HOLD_POWER:
		_fire_power()
		return
	_fire_light()


func _fire_light() -> void:
	if _swinging:
		_queued_light = true
		return
	if _combo_window <= 0.0:
		_combo = 0
	var step := clampi(_combo, 0, 2)
	var cost := Globals.light_stamina_cost(step)
	if not Globals.spend_stamina(cost):
		Globals.notify("Too winded to cut.")
		_combo = 0
		return
	_swinging = true
	_queued_light = false
	_charging = false
	var duration := float(_rig.play_light(step))
	if step == 2:
		_play_attack_lunge()
	var hit_wait := minf(HIT_DELAY + step * 0.02, duration * 0.45)
	var label := "Slash"
	if step == 1:
		label = "Riposte"
	elif step == 2:
		label = "Cleave"
	var mult := float(LIGHT_MULT[step])
	get_tree().create_timer(hit_wait).timeout.connect(func() -> void:
		if Globals.game_over:
			return
		Globals.try_melee_hit(mult, label)
	, CONNECT_ONE_SHOT)
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		_swinging = false
		_combo = step + 1
		if _combo >= 3:
			_combo = 0
			_combo_window = 0.0
		else:
			_combo_window = COMBO_WINDOW
		if _queued_light:
			_queued_light = false
			_fire_light()
		elif _want_block:
			_try_start_block()
	, CONNECT_ONE_SHOT)


func _fire_power() -> void:
	_charging = false
	_queued_light = false
	_combo = 0
	_combo_window = 0.0
	if _swinging:
		return
	if not Globals.spend_stamina(Globals.POWER_STAMINA):
		Globals.notify("Too winded for a power cut.")
		_rig.snap_idle()
		return
	_swinging = true
	_play_attack_lunge()
	var duration := float(_rig.play_power())
	get_tree().create_timer(0.28).timeout.connect(func() -> void:
		if Globals.game_over:
			return
		Globals.try_melee_hit(POWER_MULT, "Power cut")
	, CONNECT_ONE_SHOT)
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		_swinging = false
		if _want_block:
			_try_start_block()
	, CONNECT_ONE_SHOT)


func _try_start_block() -> void:
	if _swinging or _charging or Globals.game_over or Globals.menu_open:
		return
	if Globals.hero == null or not Globals.hero.has_shield():
		Globals.notify("You have no shield.")
		_want_block = false
		return
	if Globals.player_stamina < 6.0:
		Globals.notify("Too winded to raise the shield.")
		return
	Globals.set_blocking(true)
	if not Globals.is_blocking:
		return
	Globals.begin_parry()
	_set_block_visual(true)


func _set_block_visual(on: bool) -> void:
	if _blocking == on:
		if not on:
			Globals.set_blocking(false)
		return
	_blocking = on
	Globals.set_blocking(on)
	if _rig:
		_rig.set_blocking(on)


func _on_guard_broken() -> void:
	_want_block = false
	_blocking = false
	if _rig:
		_rig.set_blocking(false)
		_rig.snap_idle()


func _on_monster_attacked() -> void:
	if _blocking and _rig:
		_rig.play_block_hit()


func _on_parry_succeeded(_id: int) -> void:
	_want_block = false
	_blocking = false
	Globals.set_blocking(false)
	if _rig:
		_rig.play_parry()
	_play_attack_lunge()


func _refresh_weapons() -> void:
	if _rig == null or Globals.hero == null:
		return
	var melee := Globals.uses_realtime_melee()
	_rig.visible = melee
	if melee:
		_rig.set_equipped(Globals.hero.has_weapon(), Globals.hero.has_shield())


func collision_check(direction):
	if direction != null:
		return direction.is_colliding()
	else:
		return false

func get_direction(direction):
	if not direction is RayCast3D: return
	return direction.get_collider().global_transform.origin - global_transform.origin

func tween_translation(change):
	$AnimationPlayer.play("Step")
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", position + change, 0.5)
	tween.play()
	await tween.finished

func tween_rotation(change):
	tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", rotation + Vector3(0, change, 0), 0.5)
	tween.play()
	await tween.finished


func get_grid_pos() -> Vector2i:
	return Vector2i(
		roundi(global_position.x / Globals.GRID_SIZE),
		roundi(global_position.z / Globals.GRID_SIZE)
	)


func get_forward_grid() -> Vector2i:
	var fwd := -global_transform.basis.z
	return get_grid_pos() + Vector2i(roundi(fwd.x), roundi(fwd.z))


func _destination_grid(change: Vector3) -> Vector2i:
	var dest := global_position + change
	return Vector2i(
		roundi(dest.x / Globals.GRID_SIZE),
		roundi(dest.z / Globals.GRID_SIZE)
	)


func _refresh_facing() -> void:
	Globals.set_facing_cell(get_forward_grid())


func _play_attack_lunge() -> void:
	var origin: Vector3 = camera.position
	var punch := create_tween()
	punch.tween_property(camera, "position", origin + Vector3(0, 0, -0.14), 0.08)
	punch.tween_property(camera, "position", origin, 0.14)


func _on_Timer_timeout() -> void:
	_refresh_facing()
	if Globals.is_busy():
		return

	var GO_W := Input.is_action_pressed("forward")
	var GO_S := Input.is_action_pressed("back")
	var GO_A := Input.is_action_pressed("strafe_left")
	var GO_D := Input.is_action_pressed("strafe_right")
	var TURN_Q := Input.is_action_pressed("turn_left")
	var TURN_E := Input.is_action_pressed("turn_right")

	var ray_dir
	var turn_dir = int(TURN_Q) - int(TURN_E)


	if GO_W: 
		ray_dir = forward
	elif GO_S: 
		ray_dir = back
	elif GO_A: 
		ray_dir = left
	elif GO_D: 
		ray_dir = right
	elif turn_dir:
		timerprocessor.stop()
		await tween_rotation(PI/2 * turn_dir)
		_refresh_facing()
		Globals.note_transform(global_position, rotation)
		timerprocessor.start()

	if collision_check(ray_dir):
		var change = get_direction(ray_dir)
		if Globals.is_monster_cell(_destination_grid(change)):
			_refresh_facing()
			return
		timerprocessor.stop()
		await tween_translation(change)
		Globals.note_transform(global_position, rotation)
		Globals.on_stepped_on(get_grid_pos())
		_refresh_facing()
		timerprocessor.start()
