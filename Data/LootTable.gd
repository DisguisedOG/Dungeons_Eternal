extends RefCounted

const BEAST_DROPS := [
	{"id": "gold", "weight": 28, "min": 3, "max": 9},
	{"id": "healing_vial", "weight": 18, "min": 1, "max": 2},
	{"id": "mana_vial", "weight": 14, "min": 1, "max": 2},
	{"id": "rations", "weight": 16, "min": 1, "max": 3},
	{"id": "beast_fang", "weight": 20, "min": 1, "max": 3},
	{"id": "shadow_hide", "weight": 8, "min": 1, "max": 1},
	{"id": "greater_vial", "weight": 6, "min": 1, "max": 1},
	{"id": "rusty_blade", "weight": 7, "min": 1, "max": 1},
	{"id": "hide_wrap", "weight": 6, "min": 1, "max": 1},
	{"id": "lucky_tooth", "weight": 5, "min": 1, "max": 1},
	{"id": "ash_cloak", "weight": 3, "min": 1, "max": 1},
	{"id": "bone_club", "weight": 3, "min": 1, "max": 1},
	{"id": "ember_charm", "weight": 2, "min": 1, "max": 1},
	{"id": "heart_shard", "weight": 2, "min": 1, "max": 1},
]


static func roll_beast(luck: int = 0) -> Array:
	var rolls: int = 2
	if randi() % 100 < 35 + clampi(luck, 0, 20):
		rolls += 1
	if randi() % 100 < luck * 2:
		rolls += 1
	var stacks: Dictionary = {}
	for _i in rolls:
		var picked: Dictionary = _pick(BEAST_DROPS)
		if picked.is_empty():
			continue
		var item_id := str(picked["id"])
		var amount: int = randi_range(int(picked["min"]), int(picked["max"]))
		stacks[item_id] = int(stacks.get(item_id, 0)) + amount
	var result: Array = []
	for item_id in stacks.keys():
		result.append({"id": str(item_id), "count": int(stacks[item_id])})
	if result.is_empty():
		result.append({"id": "gold", "count": randi_range(2, 5)})
	return result


static func _pick(table: Array) -> Dictionary:
	var total := 0
	for row in table:
		total += int(row["weight"])
	if total <= 0:
		return {}
	var roll := randi() % total
	var cursor := 0
	for row in table:
		cursor += int(row["weight"])
		if roll < cursor:
			return row
	return table[table.size() - 1]
