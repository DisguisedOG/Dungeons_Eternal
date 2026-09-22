extends RefCounted

const MAX_SLOTS := 16

const ITEMS := {
	"gold": {
		"name": "Gold", "kind": "currency", "slot": "", "stack": 999, "rarity": "common",
		"desc": "Coin of the deep halls.", "effects": {},
	},
	"healing_vial": {
		"name": "Healing Vial", "kind": "consumable", "slot": "", "stack": 8, "rarity": "common",
		"desc": "Bitter red draught. Restore 12 HP.", "effects": {"heal": 12},
	},
	"mana_vial": {
		"name": "Mana Vial", "kind": "consumable", "slot": "", "stack": 8, "rarity": "common",
		"desc": "Blue glass, cold to the touch. Restore 10 MP.", "effects": {"mana": 10},
	},
	"rations": {
		"name": "Rations", "kind": "consumable", "slot": "", "stack": 12, "rarity": "common",
		"desc": "Hard bread and salt. Restore 6 HP.", "effects": {"heal": 6},
	},
	"greater_vial": {
		"name": "Greater Vial", "kind": "consumable", "slot": "", "stack": 4, "rarity": "uncommon",
		"desc": "A fat potion. Restore 22 HP.", "effects": {"heal": 22},
	},
	"beast_fang": {
		"name": "Beast Fang", "kind": "loot", "slot": "", "stack": 20, "rarity": "common",
		"desc": "A yellowed tooth. Proof you killed something.", "effects": {},
	},
	"shadow_hide": {
		"name": "Shadow Hide", "kind": "loot", "slot": "", "stack": 10, "rarity": "uncommon",
		"desc": "Still-warm pelt from the beast.", "effects": {},
	},
	"iron_sword": {
		"name": "Iron Sword", "kind": "equipment", "slot": "weapon", "stack": 1, "rarity": "common",
		"desc": "A straight blade. Warrior's starting steel. +2 ATK.", "effects": {"attack": 2},
	},
	"oak_shield": {
		"name": "Oak Shield", "kind": "equipment", "slot": "offhand", "stack": 1, "rarity": "common",
		"desc": "Bossed oak and iron. Hold RMB to block, tap as a blow lands to parry. +1 DEF, +8 Stamina.", "effects": {"defense": 1, "stamina": 8, "block": 6},
	},
	"rusty_blade": {
		"name": "Rusty Blade", "kind": "equipment", "slot": "weapon", "stack": 1, "rarity": "uncommon",
		"desc": "Notched iron. +2 ATK.", "effects": {"attack": 2},
	},
	"bone_club": {
		"name": "Bone Club", "kind": "equipment", "slot": "weapon", "stack": 1, "rarity": "rare",
		"desc": "A femur wrapped in hide. +3 ATK, +1 STR.", "effects": {"attack": 3, "str": 1},
	},
	"hide_wrap": {
		"name": "Hide Wrap", "kind": "equipment", "slot": "armor", "stack": 1, "rarity": "uncommon",
		"desc": "Stitched beast skin. +2 DEF, +4 Max HP.", "effects": {"defense": 2, "max_hp": 4},
	},
	"ash_cloak": {
		"name": "Ash Cloak", "kind": "equipment", "slot": "armor", "stack": 1, "rarity": "rare",
		"desc": "Smells of old fires. +1 DEX, +1 DEF.", "effects": {"dex": 1, "defense": 1},
	},
	"ember_charm": {
		"name": "Ember Charm", "kind": "equipment", "slot": "accessory", "stack": 1, "rarity": "rare",
		"desc": "A coal that never dies. +2 INT, +4 Max MP.", "effects": {"int": 2, "max_mp": 4},
	},
	"lucky_tooth": {
		"name": "Lucky Tooth", "kind": "equipment", "slot": "accessory", "stack": 1, "rarity": "uncommon",
		"desc": "Drilled and strung. +2 LUK.", "effects": {"luk": 2},
	},
	"heart_shard": {
		"name": "Heart Shard", "kind": "equipment", "slot": "accessory", "stack": 1, "rarity": "rare",
		"desc": "A crystal that beats. +8 Max HP.", "effects": {"max_hp": 8},
	},
}


static func def(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func display_name(item_id: String) -> String:
	var data: Dictionary = def(item_id)
	if data.is_empty():
		return item_id
	return str(data["name"])


static func is_stackable(item_id: String) -> bool:
	return int(def(item_id).get("stack", 1)) > 1


static func rarity_color(item_id: String) -> Color:
	match str(def(item_id).get("rarity", "common")):
		"uncommon":
			return Color(0.55, 0.85, 0.45)
		"rare":
			return Color(0.45, 0.7, 1.0)
		"epic":
			return Color(0.78, 0.45, 1.0)
		_:
			return Color("e8d9a0")
