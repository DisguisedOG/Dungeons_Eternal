extends Node

const Hero = preload("res://Data/Hero.gd")
const ClassData = preload("res://Data/ClassData.gd")
const ItemData = preload("res://Data/ItemData.gd")
const LootTable = preload("res://Data/LootTable.gd")
const SaveService = preload("res://Data/SaveService.gd")
const DungeonGen = preload("res://Data/DungeonGen.gd")
const MobData = preload("res://Data/MobData.gd")

signal player_hp_changed(hp: int, max_hp: int)
signal player_mp_changed(mp: int, max_mp: int)
signal monster_hp_changed(hp: int, max_hp: int)
signal message_changed(text: String)
signal player_attacked
signal monster_attacked
signal monster_died
signal encounter_hit(id: int)
signal encounter_died(id: int)
signal player_died
signal player_won
signal exit_unlocked
signal hero_changed
signal leveled_up(levels: int)
signal menu_changed
signal loot_changed
signal facing_changed(value: bool)
signal settings_changed

const GRID_SIZE = 2
const ATTACK_COOLDOWN := 0.55
const MENU_SCENE := "res://UI/MainMenu.tscn"
const WORLD_SCENE := "res://World/World.tscn"

var hero
var player_hp: int
var player_mp: int
var monster_hp: int
var monster_max_hp: int
var monster_attack: int
var monster_alive: bool
var exit_open: bool
var game_over: bool
var won: bool
var facing_monster: bool
var message: String
var monster_cell := Vector2i(7, 4)
var exit_cell := Vector2i(1, 4)
var spawn_cell := Vector2i.ZERO
var menu_open := false
var ward_bonus := 0
var saved_position := Vector3.ZERO
var saved_rotation := Vector3.ZERO
var restore_transform := false
var settings: Dictionary = {}
var ground_loot: Dictionary = {}
var dungeon_mode := "tutorial"
var dungeon_seed := 0
var dungeon_depth := 0
var dungeon_cells: Array = []
var encounters: Array = []
var facing_id := -1
var use_authored_map := true
var tutorial_active := false

var _cooldown := 0.0
var _attack_token := 0


func _ready() -> void:
	apply_settings()
	if hero == null:
		ensure_hero()
	reset_dungeon(false)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)


func apply_settings() -> void:
	settings = SaveService.load_settings()
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings.get("master", 1.0)), 0.001)))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	settings_changed.emit()


func hud_scale() -> float:
	return clampf(float(settings.get("hud_scale", 1.0)), 0.7, 1.25)


func ensure_hero() -> void:
	if hero != null:
		return
	hero = Hero.new()
	hero.setup("Adventurer", "warrior")
	hero.changed.connect(_on_hero_changed)


func start_new_game(new_hero, play_tutorial: bool = true) -> void:
	if hero != null and hero.changed.is_connected(_on_hero_changed):
		hero.changed.disconnect(_on_hero_changed)
	hero = new_hero
	hero.changed.connect(_on_hero_changed)
	hero.restore_full()
	if play_tutorial:
		_begin_tutorial()
	else:
		_begin_proc_run(1, true)
	save_game()
	hero_changed.emit()


func load_game() -> bool:
	var payload := SaveService.load_game()
	if payload.is_empty() or not payload.has("hero"):
		return false
	if hero != null and hero.changed.is_connected(_on_hero_changed):
		hero.changed.disconnect(_on_hero_changed)
	hero = Hero.from_dict(payload["hero"])
	hero.changed.connect(_on_hero_changed)
	var dungeon: Dictionary = payload.get("dungeon", {})
	if bool(dungeon.get("in_progress", false)):
		_apply_dungeon(dungeon)
	else:
		hero.restore_full()
		if str(dungeon.get("mode", "proc")) == "tutorial":
			_begin_tutorial()
		else:
			_begin_proc_run(maxi(int(dungeon.get("depth", 1)), 1), true)
	hero_changed.emit()
	_emit_vitals()
	return true


func save_game() -> void:
	ensure_hero()
	if hero:
		hero.hp = player_hp
		hero.mp = player_mp
	SaveService.save_game({
		"version": 2,
		"hero": hero.to_dict(),
		"dungeon": _dungeon_payload(),
	})


func _dungeon_payload() -> Dictionary:
	var packed_cells: Array = []
	for cell in dungeon_cells:
		packed_cells.append([int(cell.x), int(cell.y)])
	var packed_enc: Array = []
	for enc in encounters:
		var cell: Vector2i = enc["cell"]
		packed_enc.append({
			"id": int(enc["id"]),
			"kind": str(enc["kind"]),
			"name": str(enc["name"]),
			"x": cell.x,
			"y": cell.y,
			"hp": int(enc["hp"]),
			"max_hp": int(enc["max_hp"]),
			"attack": int(enc["attack"]),
			"xp": int(enc.get("xp", 24)),
			"alive": bool(enc["alive"]),
		})
	return {
		"in_progress": not game_over,
		"mode": dungeon_mode,
		"seed": dungeon_seed,
		"depth": dungeon_depth,
		"use_map": use_authored_map,
		"spawn_x": spawn_cell.x,
		"spawn_y": spawn_cell.y,
		"exit_x": exit_cell.x,
		"exit_y": exit_cell.y,
		"cells": packed_cells,
		"encounters": packed_enc,
		"exit_open": exit_open,
		"player_hp": player_hp,
		"player_mp": player_mp,
		"pos_x": saved_position.x,
		"pos_y": saved_position.y,
		"pos_z": saved_position.z,
		"rot_y": saved_rotation.y,
		"ground_loot": ground_loot.duplicate(true),
	}


func note_transform(pos: Vector3, rot: Vector3) -> void:
	saved_position = pos
	saved_rotation = rot


func setup(monster: Vector2i, stairs: Vector2i) -> void:
	monster_cell = monster
	exit_cell = stairs


func adopt_map_cells(tiles: Array) -> void:
	dungeon_cells.clear()
	for tile in tiles:
		dungeon_cells.append(Vector2i(tile))


func reset_dungeon(heal: bool) -> void:
	ensure_hero()
	if dungeon_mode == "tutorial":
		_apply_plan(DungeonGen.tutorial_plan(), heal)
	else:
		if dungeon_seed == 0:
			dungeon_seed = randi()
		if dungeon_depth <= 0:
			dungeon_depth = 1
		_apply_plan(DungeonGen.generate(dungeon_seed, dungeon_depth, hero.level), heal)


func start_new_run() -> void:
	if won:
		if tutorial_active:
			_begin_proc_run(1, true)
		else:
			_begin_proc_run(dungeon_depth + 1, true)
	elif tutorial_active:
		_begin_tutorial()
	else:
		_begin_proc_run(maxi(dungeon_depth, 1), true)
	save_game()
	get_tree().change_scene_to_file(WORLD_SCENE)


func go_to_menu() -> void:
	menu_open = false
	save_game()
	get_tree().change_scene_to_file(MENU_SCENE)


func restart() -> void:
	start_new_run()


func set_menu_open(value: bool) -> void:
	menu_open = value
	menu_changed.emit()


func is_busy() -> bool:
	return game_over or _cooldown > 0.0 or menu_open


func is_monster_cell(cell: Vector2i) -> bool:
	return _encounter_index_at(cell) >= 0


func is_exit_cell(cell: Vector2i) -> bool:
	return cell == exit_cell


func is_encounter_alive(id: int) -> bool:
	var enc := get_encounter(id)
	return not enc.is_empty() and bool(enc.get("alive", false))


func get_encounter(id: int) -> Dictionary:
	for enc in encounters:
		if int(enc["id"]) == id:
			return enc
	return {}


func facing_encounter() -> Dictionary:
	if facing_id < 0:
		return {}
	var enc := get_encounter(facing_id)
	if enc.is_empty() or not bool(enc.get("alive", false)):
		return {}
	return enc


func alive_count() -> int:
	var n := 0
	for enc in encounters:
		if bool(enc.get("alive", false)):
			n += 1
	return n


func set_facing_monster(value: bool) -> void:
	if not value:
		_set_facing_id(-1)
		return
	if facing_id >= 0:
		_set_facing_id(facing_id)


func set_facing_cell(cell: Vector2i) -> void:
	_set_facing_id(_encounter_index_at(cell))


func can_attack() -> bool:
	return not game_over and not menu_open and facing_monster and _cooldown <= 0.0


func notify(text: String) -> void:
	_set_message(text)


func try_combat(skill_id: String = "") -> bool:
	if game_over or menu_open or _cooldown > 0.0:
		return false
	ensure_hero()
	var def := {}
	if skill_id != "":
		def = ClassData.get_skill(hero.class_id, skill_id)
		if def.is_empty() or hero.skill_rank(skill_id) <= 0:
			_set_message("You have not learned that skill.")
			return false
	var effects: Dictionary = def.get("effects", {})
	var support := effects.has("heal") or effects.has("ward")
	if not support and not can_attack():
		return false
	if skill_id != "":
		var cost := int(def.get("mp", 0))
		if not hero.spend_mp(cost):
			_set_message("Not enough MP.")
			return false
		player_mp = hero.mp
		player_mp_changed.emit(player_mp, hero.max_mp())
	_cooldown = ATTACK_COOLDOWN
	_attack_token += 1
	var token := _attack_token
	var did_damage := _resolve_action(def, skill_id)
	var enc := facing_encounter()
	if not enc.is_empty() and int(enc["hp"]) == 0:
		_defeat_monster(int(enc["id"]))
		return true
	if did_damage:
		_set_message("You strike.")
		get_tree().create_timer(0.32).timeout.connect(func() -> void: _monster_counter(token), CONNECT_ONE_SHOT)
	return true


func on_stepped_on(cell: Vector2i) -> void:
	if game_over:
		return
	pickup_at(cell)
	if not is_exit_cell(cell):
		save_game()
		return
	if exit_open:
		_win()
	else:
		var left := alive_count()
		if left <= 0:
			_set_message("The stairs are sealed.")
		elif left == 1:
			_set_message("The stairs are sealed. One guardian still lives.")
		else:
			_set_message("The stairs are sealed. %d guardians still live." % left)


func _begin_tutorial() -> void:
	tutorial_active = true
	dungeon_mode = "tutorial"
	dungeon_depth = 0
	dungeon_seed = 0
	use_authored_map = true
	_apply_plan(DungeonGen.tutorial_plan(), true)


func _begin_proc_run(depth: int, heal: bool) -> void:
	tutorial_active = false
	dungeon_mode = "proc"
	dungeon_depth = maxi(depth, 1)
	dungeon_seed = randi()
	use_authored_map = false
	ensure_hero()
	_apply_plan(DungeonGen.generate(dungeon_seed, dungeon_depth, hero.level), heal)


func _apply_plan(plan: Dictionary, heal: bool) -> void:
	ensure_hero()
	dungeon_mode = str(plan.get("mode", dungeon_mode))
	tutorial_active = dungeon_mode == "tutorial"
	dungeon_seed = int(plan.get("seed", dungeon_seed))
	dungeon_depth = int(plan.get("depth", dungeon_depth))
	use_authored_map = bool(plan.get("use_map", use_authored_map))
	spawn_cell = plan.get("spawn", Vector2i.ZERO)
	exit_cell = plan.get("exit", Vector2i(1, 4))
	dungeon_cells = []
	for cell in plan.get("cells", []):
		dungeon_cells.append(Vector2i(cell))
	encounters = []
	for enc in plan.get("encounters", []):
		encounters.append(enc.duplicate(true))
	_sync_legacy_monster()
	exit_open = alive_count() == 0
	game_over = false
	won = false
	facing_id = -1
	facing_monster = false
	facing_changed.emit(false)
	menu_open = false
	ward_bonus = 0
	_cooldown = 0.0
	_attack_token += 1
	restore_transform = false
	saved_position = Vector3(spawn_cell.x * GRID_SIZE, 0, spawn_cell.y * GRID_SIZE)
	saved_rotation = Vector3(0, -PI / 2.0, 0)
	ground_loot.clear()
	loot_changed.emit()
	if heal:
		hero.restore_full()
	player_hp = hero.hp
	player_mp = hero.mp
	_set_message(_start_message())
	_emit_vitals()
	monster_hp_changed.emit(monster_hp, monster_max_hp)


func _start_message() -> String:
	if tutorial_active:
		return "Tutorial: WASD to step, Q/E to turn, Space to attack. [I] bag  [C] character  [Esc] pause. Oozey waits in one hall."
	var n := alive_count()
	var beast := "beast hunts" if n == 1 else "beasts hunt"
	return "Depth %d. %d %s these shifting halls. The stairs stay sealed until they fall." % [dungeon_depth, n, beast]


func _sync_legacy_monster() -> void:
	monster_alive = alive_count() > 0
	if encounters.is_empty():
		monster_hp = 0
		monster_max_hp = 1
		monster_attack = 1
		monster_cell = Vector2i(-99, -99)
		return
	var enc: Dictionary = encounters[0]
	for row in encounters:
		if bool(row.get("alive", false)):
			enc = row
			break
	monster_cell = enc.get("cell", Vector2i.ZERO)
	monster_hp = int(enc.get("hp", 0))
	monster_max_hp = int(enc.get("max_hp", 1))
	monster_attack = int(enc.get("attack", 1))
	monster_alive = bool(enc.get("alive", false)) and alive_count() > 0


func _encounter_index_at(cell: Vector2i) -> int:
	for enc in encounters:
		if bool(enc.get("alive", false)) and Vector2i(enc["cell"]) == cell:
			return int(enc["id"])
	return -1


func _set_facing_id(id: int) -> void:
	var next_id := id
	if next_id >= 0 and not is_encounter_alive(next_id):
		next_id = -1
	var next_facing := next_id >= 0
	if facing_id == next_id and facing_monster == next_facing:
		return
	facing_id = next_id
	facing_monster = next_facing
	facing_changed.emit(facing_monster)
	_refresh_facing_vitals()
	if game_over or menu_open:
		return
	if facing_monster:
		_set_message(_combat_prompt())
	elif not exit_open:
		if tutorial_active:
			_set_message("Oozey waits in one hall. The stairs in the other are sealed.")
		else:
			var left := alive_count()
			_set_message("%d beast(s) still hunt these halls." % left)


func _refresh_facing_vitals() -> void:
	var enc := facing_encounter()
	if enc.is_empty():
		_sync_legacy_monster()
		monster_hp_changed.emit(monster_hp, monster_max_hp)
		return
	monster_hp = int(enc["hp"])
	monster_max_hp = int(enc["max_hp"])
	monster_attack = int(enc["attack"])
	monster_cell = enc["cell"]
	monster_alive = true
	monster_hp_changed.emit(monster_hp, monster_max_hp)


func _resolve_action(def: Dictionary, skill_id: String) -> bool:
	var rank: int = hero.skill_rank(skill_id) if skill_id != "" else 1
	var effects: Dictionary = def.get("effects", {})
	if effects.has("ward"):
		ward_bonus = mini(ward_bonus + int(effects["ward"]) * rank, 8)
		_set_message("Frost gathers around you.")
		return false
	if effects.has("heal") and not effects.has("damage"):
		var amount: int = int(effects.get("heal", 0)) * rank
		amount += int(effects.get("heal_str", 0)) * rank * int(hero.total_str())
		amount += int(effects.get("heal_int", 0)) * rank * int(hero.total_int())
		var healed: int = _heal_player(amount)
		_set_message("You mend %d wounds." % healed)
		return false
	var enc := facing_encounter()
	if enc.is_empty():
		return false
	var damage: int = int(hero.attack_power())
	if effects.has("damage"):
		damage += int(effects["damage"]) * rank
	if effects.has("execute") and int(enc["hp"]) <= int(int(enc["max_hp"]) / 2.0):
		damage += int(effects["execute"])
	enc["hp"] = maxi(int(enc["hp"]) - damage, 0)
	_write_encounter(enc)
	monster_hp = int(enc["hp"])
	monster_max_hp = int(enc["max_hp"])
	player_attacked.emit()
	encounter_hit.emit(int(enc["id"]))
	monster_hp_changed.emit(monster_hp, monster_max_hp)
	var leech: int = int(hero.bonus("lifesteal"))
	if leech > 0:
		_heal_player(leech)
	return true


func _write_encounter(updated: Dictionary) -> void:
	for i in encounters.size():
		if int(encounters[i]["id"]) == int(updated["id"]):
			encounters[i] = updated
			return


func _heal_player(amount: int) -> int:
	var healed: int = int(hero.heal(amount))
	player_hp = hero.hp
	player_hp_changed.emit(player_hp, hero.max_hp())
	return healed


func _monster_counter(token: int) -> void:
	if token != _attack_token or game_over:
		return
	var enc := facing_encounter()
	if enc.is_empty():
		return
	if randi() % 100 < hero.dodge_chance():
		_set_message("You slip aside. " + _combat_prompt())
		return
	var incoming := maxi(1, int(enc["attack"]) - hero.defense() - ward_bonus)
	player_hp = maxi(player_hp - incoming, 0)
	hero.hp = player_hp
	monster_attacked.emit()
	player_hp_changed.emit(player_hp, hero.max_hp())
	if player_hp == 0:
		_die()
	else:
		var data: Dictionary = MobData.def(str(enc["kind"]))
		_set_message(str(data.get("hit", "It strikes back.")) + " " + _combat_prompt())


func _defeat_monster(id: int) -> void:
	var enc := get_encounter(id)
	if enc.is_empty():
		return
	enc["alive"] = false
	enc["hp"] = 0
	_write_encounter(enc)
	var cell: Vector2i = enc["cell"]
	var xp_gain: int = int(enc.get("xp", 24 + hero.level * 12))
	var levels: int = int(hero.add_xp(xp_gain))
	player_hp = hero.hp
	player_mp = hero.mp
	var drops: Array = LootTable.roll_beast(int(hero.total_luk()))
	_add_to_ground(cell, drops)
	var data: Dictionary = MobData.def(str(enc["kind"]))
	var text := "%s +%d XP." % [str(data.get("death", "It falls.")), xp_gain]
	if levels > 0:
		text += " You reach level %d." % hero.level
		leveled_up.emit(levels)
	text += " " + _loot_summary(drops)
	if alive_count() == 0:
		exit_open = true
		text += " The seal on the stairs lifts."
		exit_unlocked.emit()
	else:
		text += " %d remain." % alive_count()
	_set_message(text)
	loot_changed.emit()
	_emit_vitals()
	_set_facing_id(-1)
	_sync_legacy_monster()
	monster_died.emit()
	encounter_died.emit(id)
	save_game()


func _die() -> void:
	game_over = true
	won = false
	hero.hp = player_hp
	_set_message("The dark takes you.")
	player_died.emit()
	save_game()


func _win() -> void:
	game_over = true
	won = true
	hero.hp = player_hp
	hero.mp = player_mp
	if tutorial_active:
		_set_message("Lesson done. The next descent will never look the same.")
	else:
		_set_message("You find the stairs. The dungeon rearranges below.")
	player_won.emit()
	save_game()


func win_overlay_body() -> String:
	if tutorial_active:
		return "You finish the lesson.\n[R] Enter the shifting dungeon   [Esc] Menu"
	return "The stairs lead deeper.\n[R] New descent   [Esc] Menu"


func death_overlay_body() -> String:
	if tutorial_active:
		return "Oozey drags you into the dark.\n[R] Retry the lesson   [Esc] Menu"
	return "The beasts drag you into the dark.\n[R] New run   [Esc] Menu"


func _combat_prompt() -> String:
	var parts: PackedStringArray = PackedStringArray()
	var enc := facing_encounter()
	if not enc.is_empty():
		parts.append(str(enc.get("name", "Beast")) + ".")
	parts.append("[Space] Attack")
	var actives: Array = hero.active_skills()
	for i in mini(actives.size(), 3):
		var skill: Dictionary = actives[i]
		parts.append("[%d] %s" % [i + 1, skill["name"]])
	return " ".join(parts)


func _apply_dungeon(dungeon: Dictionary) -> void:
	dungeon_mode = str(dungeon.get("mode", "proc"))
	dungeon_seed = int(dungeon.get("seed", 0))
	dungeon_depth = int(dungeon.get("depth", 1 if dungeon_mode == "proc" else 0))
	use_authored_map = bool(dungeon.get("use_map", dungeon_mode == "tutorial"))
	tutorial_active = dungeon_mode == "tutorial"
	spawn_cell = Vector2i(int(dungeon.get("spawn_x", 0)), int(dungeon.get("spawn_y", 0)))
	exit_cell = Vector2i(int(dungeon.get("exit_x", 1)), int(dungeon.get("exit_y", 4)))
	dungeon_cells.clear()
	for row in dungeon.get("cells", []):
		if typeof(row) == TYPE_ARRAY and row.size() >= 2:
			dungeon_cells.append(Vector2i(int(row[0]), int(row[1])))
	encounters.clear()
	if dungeon.has("encounters"):
		for row in dungeon.get("encounters", []):
			if typeof(row) != TYPE_DICTIONARY:
				continue
			encounters.append({
				"id": int(row.get("id", 0)),
				"kind": str(row.get("kind", "oozey")),
				"name": str(row.get("name", "Oozey")),
				"cell": Vector2i(int(row.get("x", 0)), int(row.get("y", 0))),
				"hp": int(row.get("hp", 8)),
				"max_hp": int(row.get("max_hp", 8)),
				"attack": int(row.get("attack", 2)),
				"xp": int(row.get("xp", 24)),
				"alive": bool(row.get("alive", true)),
			})
	else:
		encounters.append({
			"id": 0,
			"kind": "oozey",
			"name": "Oozey",
			"cell": Vector2i(int(dungeon.get("monster_x", 7)), int(dungeon.get("monster_y", 4))),
			"hp": int(dungeon.get("monster_hp", 8)),
			"max_hp": int(dungeon.get("monster_max_hp", 8)),
			"attack": 2 + int(hero.level / 2.0),
			"xp": 24,
			"alive": bool(dungeon.get("monster_alive", true)),
		})
	_sync_legacy_monster()
	exit_open = bool(dungeon.get("exit_open", alive_count() == 0))
	game_over = false
	won = false
	facing_id = -1
	facing_monster = false
	facing_changed.emit(false)
	menu_open = false
	ward_bonus = 0
	player_hp = int(dungeon.get("player_hp", hero.hp))
	player_mp = int(dungeon.get("player_mp", hero.mp))
	hero.hp = player_hp
	hero.mp = player_mp
	saved_position = Vector3(float(dungeon.get("pos_x", spawn_cell.x * GRID_SIZE)), float(dungeon.get("pos_y", 0)), float(dungeon.get("pos_z", spawn_cell.y * GRID_SIZE)))
	saved_rotation = Vector3(0, float(dungeon.get("rot_y", -PI / 2.0)), 0)
	restore_transform = true
	_load_ground_loot(dungeon.get("ground_loot", {}))
	_set_message("The dark remembers you.")
	monster_hp_changed.emit(monster_hp, monster_max_hp)
	loot_changed.emit()


func _on_hero_changed() -> void:
	if hero == null:
		return
	player_hp = hero.hp
	player_mp = hero.mp
	hero_changed.emit()
	_emit_vitals()


func _emit_vitals() -> void:
	if hero == null:
		return
	player_hp_changed.emit(player_hp, hero.max_hp())
	player_mp_changed.emit(player_mp, hero.max_mp())


func _set_message(text: String) -> void:
	message = text
	message_changed.emit(message)


func loot_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func loot_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func has_loot(cell: Vector2i) -> bool:
	var pile: Array = ground_loot.get(loot_key(cell), [])
	return not pile.is_empty()


func pickup_at(cell: Vector2i) -> void:
	var key := loot_key(cell)
	if not ground_loot.has(key):
		return
	ensure_hero()
	var pile: Array = ground_loot[key]
	var leftover: Array = []
	var names: PackedStringArray = PackedStringArray()
	var bag_full := false
	for stack in pile:
		if typeof(stack) != TYPE_DICTIONARY:
			continue
		var item_id := str(stack.get("id", ""))
		var count: int = int(stack.get("count", 1))
		if item_id.is_empty() or count <= 0:
			continue
		var remain: int = int(hero.add_item(item_id, count))
		var taken: int = count - remain
		if taken > 0:
			if item_id == "gold":
				names.append("%d gold" % taken)
			else:
				names.append("%s x%d" % [ItemData.display_name(item_id), taken])
		if remain > 0:
			leftover.append({"id": item_id, "count": remain})
			bag_full = true
	if leftover.is_empty():
		ground_loot.erase(key)
	else:
		ground_loot[key] = leftover
	if names.size() > 0:
		var text := "You pick up " + ", ".join(names) + "."
		if bag_full:
			text += " Your bag cannot hold the rest."
		_set_message(text)
	elif bag_full:
		_set_message("Your bag is full.")
	loot_changed.emit()


func try_use_item(index: int) -> bool:
	ensure_hero()
	var msg: String = str(hero.use_item(index))
	player_hp = hero.hp
	player_mp = hero.mp
	_emit_vitals()
	if msg != "":
		_set_message(msg)
		save_game()
	return msg != ""


func try_unequip(slot: String) -> bool:
	ensure_hero()
	var msg: String = str(hero.unequip(slot))
	player_hp = hero.hp
	player_mp = hero.mp
	_emit_vitals()
	if msg != "":
		_set_message(msg)
		save_game()
	return msg != "" and not msg.begins_with("Your bag")


func _add_to_ground(cell: Vector2i, drops: Array) -> void:
	var key := loot_key(cell)
	var pile: Array = ground_loot.get(key, [])
	for drop in drops:
		if typeof(drop) != TYPE_DICTIONARY:
			continue
		var item_id := str(drop.get("id", ""))
		var count: int = int(drop.get("count", 1))
		if item_id.is_empty() or count <= 0:
			continue
		var merged := false
		for i in pile.size():
			var stack: Dictionary = pile[i]
			if str(stack["id"]) != item_id:
				continue
			stack["count"] = int(stack["count"]) + count
			pile[i] = stack
			merged = true
			break
		if not merged:
			pile.append({"id": item_id, "count": count})
	ground_loot[key] = pile


func _load_ground_loot(raw: Variant) -> void:
	ground_loot.clear()
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var data: Dictionary = raw
	for key in data.keys():
		var piles: Array = []
		for row in data[key]:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var item_id := str(row.get("id", ""))
			if item_id.is_empty():
				continue
			piles.append({"id": item_id, "count": int(row.get("count", 1))})
		if not piles.is_empty():
			ground_loot[str(key)] = piles


func _loot_summary(drops: Array) -> String:
	if drops.is_empty():
		return "It leaves nothing."
	var names: PackedStringArray = PackedStringArray()
	for drop in drops:
		if typeof(drop) != TYPE_DICTIONARY:
			continue
		names.append("%s x%d" % [ItemData.display_name(str(drop["id"])), int(drop["count"])])
	if names.is_empty():
		return "It leaves nothing."
	return "Loot: " + ", ".join(names) + "."
