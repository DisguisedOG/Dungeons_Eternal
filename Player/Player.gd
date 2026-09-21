extends Node3D

@onready var timerprocessor: = $Timer
@onready var forward: = $RayForward
@onready var back: = $RayBack
@onready var right: = $RayRight
@onready var left: = $RayLeft
@onready var camera: Camera3D = $Camera3D

var tween


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and Globals.game_over:
		Globals.start_new_run()
		return
	if Globals.menu_open or Globals.game_over:
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
