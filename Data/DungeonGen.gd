extends RefCounted

const MobData = preload("res://Data/MobData.gd")

const WALL_TEX := preload("res://Resources/Wall.png")
const WALL_N := preload("res://Resources/WallNormals.png")
const FLOOR_TEX := preload("res://Resources/Floor.png")
const FLOOR_N := preload("res://Resources/FloorNormals.png")

const TUTORIAL_MONSTER := Vector2i(7, 4)
const TUTORIAL_EXIT := Vector2i(1, 4)

const WALL_TINTS := [
	Color(1.0, 0.95, 0.88),
	Color(0.78, 0.86, 0.72),
	Color(0.72, 0.7, 0.68),
	Color(0.92, 0.82, 0.7),
	Color(0.7, 0.76, 0.86),
	Color(0.86, 0.74, 0.7),
]

const FLOOR_TINTS := [
	Color(1.0, 0.96, 0.9),
	Color(0.82, 0.88, 0.78),
	Color(0.7, 0.68, 0.66),
	Color(0.9, 0.8, 0.68),
	Color(0.74, 0.78, 0.88),
]


static func tutorial_plan() -> Dictionary:
	return {
		"mode": "tutorial",
		"seed": 0,
		"depth": 0,
		"cells": [],
		"spawn": Vector2i.ZERO,
		"exit": TUTORIAL_EXIT,
		"encounters": [_make_encounter(0, "oozey", TUTORIAL_MONSTER, 1, 1)],
		"use_map": true,
	}


static func generate(seed: int, depth: int, hero_level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var width := 17
	var height := 13
	var carved: Dictionary = {}
	var rooms: Array = []
	var room_count := rng.randi_range(6, 9)
	for _i in 48:
		var rw := rng.randi_range(3, 5)
		var rh := rng.randi_range(3, 5)
		var rx := rng.randi_range(1, width - rw - 2)
		var ry := rng.randi_range(1, height - rh - 2)
		var room := Rect2i(rx, ry, rw, rh)
		var overlaps := false
		for other in rooms:
			if room.intersects(other):
				overlaps = true
				break
		if overlaps:
			continue
		rooms.append(room)
		_carve_rect(carved, room)
		if rooms.size() >= room_count:
			break
	if rooms.size() < 4:
		return generate(seed + 17, depth, hero_level)
	for i in range(1, rooms.size()):
		var a: Vector2i = _center(rooms[i - 1])
		var b: Vector2i = _center(rooms[i])
		_carve_corridor(carved, a, b, rng)
	var spawn: Vector2i = _center(rooms[0])
	var exit_cell: Vector2i = _center(rooms[rooms.size() - 1])
	if spawn == exit_cell:
		exit_cell = Vector2i(rooms[rooms.size() - 1].end.x - 1, rooms[rooms.size() - 1].end.y - 1)
		carved[exit_cell] = true
	_ensure_path(carved, spawn, exit_cell)
	var cells: Array = carved.keys()
	var encounters: Array = []
	var mob_count := clampi(3 + depth, 3, 8)
	var used: Dictionary = {spawn: true, exit_cell: true}
	var next_id := 0
	for i in range(1, rooms.size()):
		if encounters.size() >= mob_count:
			break
		var cell: Vector2i = _center(rooms[i])
		if used.has(cell):
			cell = _pick_in_room(rooms[i], used, rng)
		if cell.x == -999:
			continue
		used[cell] = true
		var kind := MobData.pick(rng, depth)
		encounters.append(_make_encounter(next_id, kind, cell, depth, hero_level))
		next_id += 1
	while encounters.size() < mob_count:
		var extra: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		if used.has(extra):
			continue
		used[extra] = true
		encounters.append(_make_encounter(next_id, MobData.pick(rng, depth), extra, depth, hero_level))
		next_id += 1
		if next_id > 24:
			break
	return {
		"mode": "proc",
		"seed": seed,
		"depth": depth,
		"cells": cells,
		"spawn": spawn,
		"exit": exit_cell,
		"encounters": encounters,
		"use_map": false,
	}


static func _make_encounter(id: int, kind: String, cell: Vector2i, depth: int, hero_level: int) -> Dictionary:
	var data: Dictionary = MobData.def(kind)
	var hp: int = MobData.scaled_hp(kind, maxi(depth, 1), hero_level)
	return {
		"id": id,
		"kind": kind,
		"name": str(data["name"]),
		"cell": cell,
		"hp": hp,
		"max_hp": hp,
		"attack": MobData.scaled_attack(kind, maxi(depth, 1), hero_level),
		"xp": int(data["xp"]) + depth * 6,
		"alive": true,
	}


static func _carve_rect(carved: Dictionary, room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			carved[Vector2i(x, y)] = true


static func _carve_corridor(carved: Dictionary, a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var cursor := a
	if rng.randf() < 0.5:
		_carve_line_x(carved, cursor, b.x)
		cursor.x = b.x
		_carve_line_y(carved, cursor, b.y)
	else:
		_carve_line_y(carved, cursor, b.y)
		cursor.y = b.y
		_carve_line_x(carved, cursor, b.x)


static func _carve_line_x(carved: Dictionary, from: Vector2i, x_to: int) -> void:
	var step := 1 if x_to >= from.x else -1
	var x := from.x
	while true:
		carved[Vector2i(x, from.y)] = true
		if x == x_to:
			break
		x += step


static func _carve_line_y(carved: Dictionary, from: Vector2i, y_to: int) -> void:
	var step := 1 if y_to >= from.y else -1
	var y := from.y
	while true:
		carved[Vector2i(from.x, y)] = true
		if y == y_to:
			break
		y += step


static func _center(room: Rect2i) -> Vector2i:
	return Vector2i(room.position.x + int(room.size.x / 2.0), room.position.y + int(room.size.y / 2.0))


static func _pick_in_room(room: Rect2i, used: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	for _i in 12:
		var cell := Vector2i(
			rng.randi_range(room.position.x, room.end.x - 1),
			rng.randi_range(room.position.y, room.end.y - 1)
		)
		if not used.has(cell):
			return cell
	return Vector2i(-999, -999)


static func _ensure_path(carved: Dictionary, spawn: Vector2i, exit_cell: Vector2i) -> void:
	if _reachable(carved, spawn, exit_cell):
		return
	_carve_corridor(carved, spawn, exit_cell, RandomNumberGenerator.new())


static func _reachable(carved: Dictionary, start: Vector2i, goal: Vector2i) -> bool:
	var seen: Dictionary = {start: true}
	var q: Array = [start]
	while not q.is_empty():
		var cell: Vector2i = q.pop_front()
		if cell == goal:
			return true
		for n in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + n
			if carved.has(next) and not seen.has(next):
				seen[next] = true
				q.append(next)
	return false


static func wall_material(seed: int, cell: Vector2i) -> StandardMaterial3D:
	var h := _hash(seed, cell.x, cell.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = WALL_TEX
	mat.albedo_color = WALL_TINTS[h % WALL_TINTS.size()]
	mat.normal_enabled = true
	mat.normal_texture = WALL_N
	mat.uv1_offset = Vector3((h % 4) * 0.25, ((h / 4) % 4) * 0.25, 0)
	mat.roughness = 0.85
	return mat


static func floor_material(seed: int, cell: Vector2i) -> StandardMaterial3D:
	var h := _hash(seed + 91, cell.x * 3, cell.y * 7)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = FLOOR_TEX
	mat.albedo_color = FLOOR_TINTS[h % FLOOR_TINTS.size()]
	mat.normal_enabled = true
	mat.normal_texture = FLOOR_N
	mat.uv1_offset = Vector3((h % 3) * 0.33, ((h / 3) % 3) * 0.33, 0)
	mat.uv1_scale = Vector3(1, 1, 1) if h % 2 == 0 else Vector3(-1, 1, 1)
	mat.roughness = 0.9
	return mat


static func _hash(seed: int, x: int, y: int) -> int:
	var n := seed * 374761393 + x * 668265263 + y * 1274126177
	n = (n ^ (n >> 13)) * 1274126177
	return abs(n)
