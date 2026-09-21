extends Node3D

const Cell = preload("res://Cell/Cell.tscn")
const MonsterScene = preload("res://Monster/Monster.tscn")
const ExitScene = preload("res://Exit/Exit.tscn")
const HUDScene = preload("res://UI/HUD.tscn")
const LootPileScene = preload("res://Loot/LootPile.tscn")
const DungeonGen = preload("res://Data/DungeonGen.gd")

@export var Map: PackedScene
@onready var worldEnvironment: = $WorldEnvironment
@onready var player: = $Player

var cells = []
var _loot_piles: Dictionary = {}


func _ready():
	var environment = get_tree().root.world_3d.fallback_environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_color = Color("432d6d")
	add_child(HUDScene.instantiate())
	if not Globals.loot_changed.is_connected(_refresh_loot):
		Globals.loot_changed.connect(_refresh_loot)
	generate_map()


func generate_map():
	var tiles: Array = []
	if Globals.use_authored_map:
		tiles = _tiles_from_map()
		Globals.adopt_map_cells(tiles)
		if Globals.encounters.is_empty():
			Globals.setup(DungeonGen.TUTORIAL_MONSTER, DungeonGen.TUTORIAL_EXIT)
	else:
		for cell in Globals.dungeon_cells:
			tiles.append(Vector2i(cell))
	if tiles.is_empty():
		push_warning("Dungeon has no tiles.")
		return
	var seed := Globals.dungeon_seed if not Globals.use_authored_map else 11
	for tile in tiles:
		var cell = Cell.instantiate()
		add_child(cell)
		cell.position = Vector3(tile.x * Globals.GRID_SIZE, 0, tile.y * Globals.GRID_SIZE)
		cell.apply_theme(DungeonGen.wall_material(seed, tile), DungeonGen.floor_material(seed, tile))
		cells.append(cell)
	for cell in cells:
		cell.update_faces(tiles)
	_place_player()
	_spawn_props(tiles)


func _tiles_from_map() -> Array:
	if not Map is PackedScene:
		return []
	var map = Map.instantiate()
	var tile_map = map.get_tilemap()
	var used = tile_map.get_used_cells(0)
	map.free()
	var tiles: Array = []
	for tile in used:
		tiles.append(Vector2i(tile))
	return tiles


func _place_player() -> void:
	if Globals.restore_transform:
		player.global_position = Globals.saved_position
		player.rotation = Globals.saved_rotation
		Globals.restore_transform = false
		Globals.note_transform(player.global_position, player.rotation)
		return
	var spawn: Vector2i = Globals.spawn_cell
	player.global_position = Vector3(spawn.x * Globals.GRID_SIZE, 0, spawn.y * Globals.GRID_SIZE)
	if Globals.use_authored_map:
		player.rotation = Vector3(0, -PI / 2.0, 0)
	else:
		var look := _walkable_dir(spawn)
		if look == Vector2i.ZERO:
			player.rotation = Vector3(0, -PI / 2.0, 0)
		else:
			player.look_at(player.global_position + Vector3(look.x, 0, look.y), Vector3.UP)
	Globals.note_transform(player.global_position, player.rotation)


func _walkable_dir(from: Vector2i) -> Vector2i:
	var cells_set: Dictionary = {}
	for cell in Globals.dungeon_cells:
		cells_set[Vector2i(cell)] = true
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if cells_set.has(from + dir) and not Globals.is_monster_cell(from + dir) and from + dir != Globals.exit_cell:
			return dir
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if cells_set.has(from + dir):
			return dir
	return Vector2i.ZERO


func _spawn_props(_used_tiles: Array) -> void:
	for enc in Globals.encounters:
		var monster = MonsterScene.instantiate()
		monster.encounter_id = int(enc["id"])
		monster.kind = str(enc["kind"])
		add_child(monster)
		var live_cell: Vector2i = enc["cell"]
		monster.position = Vector3(live_cell.x * Globals.GRID_SIZE, 0, live_cell.y * Globals.GRID_SIZE)
	var stairs = ExitScene.instantiate()
	add_child(stairs)
	stairs.position = Vector3(Globals.exit_cell.x * Globals.GRID_SIZE, 0, Globals.exit_cell.y * Globals.GRID_SIZE)
	_refresh_loot()


func _refresh_loot() -> void:
	var live: Dictionary = {}
	for key in Globals.ground_loot.keys():
		var pile_data: Array = Globals.ground_loot[key]
		if pile_data.is_empty():
			continue
		live[str(key)] = true
		if _loot_piles.has(key):
			continue
		var pile = LootPileScene.instantiate()
		var cell: Vector2i = Globals.loot_cell(str(key))
		add_child(pile)
		pile.position = Vector3(cell.x * Globals.GRID_SIZE + 0.35, 0, cell.y * Globals.GRID_SIZE + 0.3)
		_loot_piles[str(key)] = pile
	var stale: Array = []
	for key in _loot_piles.keys():
		if not live.has(str(key)):
			stale.append(key)
	for key in stale:
		if is_instance_valid(_loot_piles[key]):
			_loot_piles[key].queue_free()
		_loot_piles.erase(key)
