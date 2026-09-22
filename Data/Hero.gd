extends RefCounted

const ClassData = preload("res://Data/ClassData.gd")
const ItemData = preload("res://Data/ItemData.gd")

signal changed

var hero_name: String = "Adventurer"
var class_id: String = "warrior"
var level: int = 1
var xp: int = 0
var strength: int = 8
var dexterity: int = 4
var intellect: int = 2
var luck: int = 2
var hp: int = 1
var mp: int = 1
var stat_points: int = 0
var skill_points: int = 1
var skills: Dictionary = {}
var gold: int = 0
var inventory: Array = []
var equipped: Dictionary = {"weapon": "", "offhand": "", "armor": "", "accessory": ""}


func setup(p_name: String, p_class: String) -> void:
	hero_name = p_name.strip_edges()
	if hero_name.is_empty():
		hero_name = "Adventurer"
	class_id = p_class if ClassData.CLASSES.has(p_class) else "warrior"
	var data: Dictionary = ClassData.class_def(class_id)
	level = 1
	xp = 0
	strength = int(data["str"])
	dexterity = int(data["dex"])
	intellect = int(data["int"])
	luck = int(data["luk"])
	stat_points = 0
	skill_points = 1
	skills.clear()
	_grant_starter()
	hp = max_hp()
	mp = max_mp()
	changed.emit()


func _grant_starter() -> void:
	gold = 15
	inventory = [{"id": "healing_vial", "count": 2}]
	equipped = {"weapon": "", "offhand": "", "armor": "", "accessory": ""}
	if class_id == "warrior":
		equipped["weapon"] = "iron_sword"
		equipped["offhand"] = "oak_shield"


func class_name_pretty() -> String:
	return str(ClassData.class_def(class_id)["name"])


func xp_to_next() -> int:
	return 20 * level


func add_xp(amount: int) -> int:
	var gained := 0
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		stat_points += 2
		skill_points += 1
		gained += 1
		hp = max_hp()
		mp = max_mp()
	changed.emit()
	return gained


func spend_stat(stat: String) -> bool:
	if stat_points <= 0:
		return false
	match stat:
		"str":
			strength += 1
		"dex":
			dexterity += 1
		"int":
			intellect += 1
		"luk":
			luck += 1
		_:
			return false
	stat_points -= 1
	hp = mini(hp + 2, max_hp()) if stat == "str" else mini(hp, max_hp())
	mp = mini(mp + 2, max_mp()) if stat == "int" else mini(mp, max_mp())
	changed.emit()
	return true


func skill_rank(skill_id: String) -> int:
	return int(skills.get(skill_id, 0))


func can_learn(skill_id: String) -> bool:
	if skill_points <= 0:
		return false
	var def := ClassData.get_skill(class_id, skill_id)
	if def.is_empty():
		return false
	if skill_rank(skill_id) >= int(def["max_rank"]):
		return false
	for req in def["reqs"]:
		if skill_rank(str(req["id"])) < int(req["rank"]):
			return false
	return true


func learn(skill_id: String) -> bool:
	if not can_learn(skill_id):
		return false
	skills[skill_id] = skill_rank(skill_id) + 1
	skill_points -= 1
	hp = mini(hp, max_hp())
	mp = maxi(mp, 0)
	mp = mini(mp, max_mp())
	changed.emit()
	return true


func bonus(key: String) -> int:
	var total := 0
	for skill_id in skills.keys():
		var def := ClassData.get_skill(class_id, str(skill_id))
		if def.is_empty():
			continue
		var effects: Dictionary = def.get("effects", {})
		if effects.has(key):
			total += int(effects[key]) * skill_rank(str(skill_id))
	return total


func gear_bonus(key: String) -> int:
	var total := 0
	for slot in equipped.keys():
		var item_id := str(equipped[slot])
		if item_id.is_empty():
			continue
		var effects: Dictionary = ItemData.def(item_id).get("effects", {})
		total += int(effects.get(key, 0))
	return total


func total_str() -> int:
	return strength + bonus("str") + gear_bonus("str")


func total_dex() -> int:
	return dexterity + bonus("dex") + gear_bonus("dex")


func total_int() -> int:
	return intellect + bonus("int") + gear_bonus("int")


func total_luk() -> int:
	return luck + bonus("luk") + gear_bonus("luk")


func max_hp() -> int:
	var data := ClassData.class_def(class_id)
	return int(data["base_hp"]) + total_str() * 2 + bonus("max_hp") + gear_bonus("max_hp")


func max_mp() -> int:
	var data := ClassData.class_def(class_id)
	var extra := total_luk() if class_id == "priest" else 0
	return int(data["base_mp"]) + total_int() * 2 + extra + bonus("max_mp") + gear_bonus("max_mp")


func attack_power() -> int:
	var data := ClassData.class_def(class_id)
	var stat_value := total_str()
	match str(data["atk_stat"]):
		"dex":
			stat_value = total_dex()
		"int":
			stat_value = total_int()
	return int(data["base_atk"]) + int(stat_value / 2.0) + bonus("attack") + gear_bonus("attack")


func defense() -> int:
	var data := ClassData.class_def(class_id)
	return int(data["base_def"]) + int(total_str() / 4.0) + bonus("defense") + gear_bonus("defense")


func dodge_chance() -> int:
	return clampi(total_luk() * 2 + bonus("dodge"), 0, 65)


func max_stamina() -> int:
	return 40 + total_str() * 3 + bonus("stamina") + gear_bonus("stamina")


func block_power() -> int:
	return 4 + gear_bonus("block") + int(total_str() / 4.0)


func has_weapon() -> bool:
	return str(equipped.get("weapon", "")) != ""


func has_shield() -> bool:
	return str(equipped.get("offhand", "")) != ""


func active_skills() -> Array:
	var result: Array = []
	for def in ClassData.get_skills(class_id):
		if str(def["kind"]) != "active":
			continue
		if skill_rank(str(def["id"])) > 0:
			result.append(def)
	return result


func heal(amount: int) -> int:
	var before := hp
	hp = mini(hp + amount, max_hp())
	changed.emit()
	return hp - before


func spend_mp(cost: int) -> bool:
	if mp < cost:
		return false
	mp -= cost
	changed.emit()
	return true


func restore_full() -> void:
	hp = max_hp()
	mp = max_mp()
	changed.emit()


func add_item(item_id: String, count: int) -> int:
	if count <= 0:
		return 0
	if item_id == "gold":
		gold += count
		changed.emit()
		return 0
	var data: Dictionary = ItemData.def(item_id)
	if data.is_empty():
		return count
	var max_stack: int = int(data.get("stack", 1))
	for i in inventory.size():
		var stack: Dictionary = inventory[i]
		if str(stack["id"]) != item_id:
			continue
		var space: int = max_stack - int(stack["count"])
		if space <= 0:
			continue
		var add: int = mini(space, count)
		stack["count"] = int(stack["count"]) + add
		inventory[i] = stack
		count -= add
		if count <= 0:
			changed.emit()
			return 0
	while count > 0 and inventory.size() < ItemData.MAX_SLOTS:
		var add: int = mini(max_stack, count)
		inventory.append({"id": item_id, "count": add})
		count -= add
	changed.emit()
	return count


func use_item(index: int) -> String:
	if index < 0 or index >= inventory.size():
		return ""
	var stack: Dictionary = inventory[index]
	var item_id := str(stack["id"])
	var data: Dictionary = ItemData.def(item_id)
	if data.is_empty():
		return ""
	var kind := str(data.get("kind", ""))
	if kind == "consumable":
		var effects: Dictionary = data.get("effects", {})
		if effects.has("heal"):
			hp = mini(hp + int(effects["heal"]), max_hp())
		if effects.has("mana"):
			mp = mini(mp + int(effects["mana"]), max_mp())
		_remove_count(index, 1)
		changed.emit()
		return "You use the %s." % str(data["name"])
	if kind == "equipment":
		return equip_from(index)
	return "You cannot use the %s." % str(data["name"])


func equip_from(index: int) -> String:
	if index < 0 or index >= inventory.size():
		return ""
	var stack: Dictionary = inventory[index]
	var item_id := str(stack["id"])
	var data: Dictionary = ItemData.def(item_id)
	var slot := str(data.get("slot", ""))
	if str(data.get("kind", "")) != "equipment" or slot.is_empty():
		return "You cannot wear that."
	_remove_count(index, 1)
	var previous := str(equipped.get(slot, ""))
	equipped[slot] = item_id
	if previous != "":
		add_item(previous, 1)
	hp = mini(hp, max_hp())
	mp = mini(mp, max_mp())
	changed.emit()
	return "You equip the %s." % str(data["name"])


func unequip(slot: String) -> String:
	var item_id := str(equipped.get(slot, ""))
	if item_id.is_empty():
		return ""
	if inventory.size() >= ItemData.MAX_SLOTS:
		return "Your bag is full."
	equipped[slot] = ""
	add_item(item_id, 1)
	hp = mini(hp, max_hp())
	mp = mini(mp, max_mp())
	changed.emit()
	return "You remove the %s." % ItemData.display_name(item_id)


func equipped_name(slot: String) -> String:
	var item_id := str(equipped.get(slot, ""))
	if item_id.is_empty():
		return "—"
	return ItemData.display_name(item_id)


func _remove_count(index: int, amount: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var stack: Dictionary = inventory[index]
	stack["count"] = int(stack["count"]) - amount
	if int(stack["count"]) <= 0:
		inventory.remove_at(index)
	else:
		inventory[index] = stack


func to_dict() -> Dictionary:
	return {
		"name": hero_name,
		"class_id": class_id,
		"level": level,
		"xp": xp,
		"str": strength,
		"dex": dexterity,
		"int": intellect,
		"luk": luck,
		"hp": hp,
		"mp": mp,
		"stat_points": stat_points,
		"skill_points": skill_points,
		"skills": skills.duplicate(),
		"gold": gold,
		"inventory": inventory.duplicate(true),
		"equipped": equipped.duplicate(),
	}


static func from_dict(data: Dictionary):
	var hero = load("res://Data/Hero.gd").new()
	hero.hero_name = str(data.get("name", "Adventurer"))
	hero.class_id = str(data.get("class_id", "warrior"))
	hero.level = int(data.get("level", 1))
	hero.xp = int(data.get("xp", 0))
	hero.strength = int(data.get("str", 8))
	hero.dexterity = int(data.get("dex", 4))
	hero.intellect = int(data.get("int", 2))
	hero.luck = int(data.get("luk", 2))
	hero.stat_points = int(data.get("stat_points", 0))
	hero.skill_points = int(data.get("skill_points", 0))
	hero.skills = data.get("skills", {}).duplicate()
	if data.has("inventory"):
		hero.gold = int(data.get("gold", 0))
		hero.inventory = []
		for row in data.get("inventory", []):
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var item_id := str(row.get("id", ""))
			if item_id.is_empty():
				continue
			hero.inventory.append({"id": item_id, "count": int(row.get("count", 1))})
		var eq: Dictionary = data.get("equipped", {})
		hero.equipped = {
			"weapon": str(eq.get("weapon", "")),
			"offhand": str(eq.get("offhand", "")),
			"armor": str(eq.get("armor", "")),
			"accessory": str(eq.get("accessory", "")),
		}
		if hero.class_id == "warrior":
			if str(hero.equipped.get("weapon", "")) == "":
				hero.equipped["weapon"] = "iron_sword"
			if str(hero.equipped.get("offhand", "")) == "":
				hero.equipped["offhand"] = "oak_shield"
	else:
		hero._grant_starter()
	hero.hp = int(data.get("hp", hero.max_hp()))
	hero.mp = int(data.get("mp", hero.max_mp()))
	hero.hp = mini(hero.hp, hero.max_hp())
	hero.mp = mini(hero.mp, hero.max_mp())
	return hero
