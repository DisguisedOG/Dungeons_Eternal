extends RefCounted
# RPG class and skill definitions

const IDS := ["warrior", "mage", "rogue", "priest"]

const CLASSES := {
	"warrior": {
		"id": "warrior",
		"name": "Warrior",
		"blurb": "Front-line steel. Starts with sword and shield. LMB slash, hold for a power cut, RMB block, tap RMB to parry.",
		"str": 8, "dex": 4, "int": 2, "luk": 2,
		"base_hp": 22, "base_mp": 6, "base_atk": 3, "base_def": 1,
		"atk_stat": "str",
		"skills": [
			{"id": "power_strike", "name": "Power Strike", "tier": 1, "max_rank": 3, "kind": "active", "mp": 0, "reqs": [], "desc": "A crushing blow. +2 damage per rank.", "effects": {"damage": 2}},
			{"id": "iron_skin", "name": "Iron Skin", "tier": 1, "max_rank": 3, "kind": "passive", "mp": 0, "reqs": [], "desc": "Harden the body. +4 Max HP per rank.", "effects": {"max_hp": 4}},
			{"id": "cleave", "name": "Cleave", "tier": 2, "max_rank": 2, "kind": "active", "mp": 2, "reqs": [{"id": "power_strike", "rank": 1}], "desc": "Wide cut. +5 damage per rank.", "effects": {"damage": 5}},
			{"id": "second_wind", "name": "Second Wind", "tier": 2, "max_rank": 2, "kind": "active", "mp": 4, "reqs": [{"id": "iron_skin", "rank": 1}], "desc": "Recover 6 HP + STR per rank.", "effects": {"heal": 6, "heal_str": 1}},
			{"id": "warlord", "name": "Warlord", "tier": 3, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "power_strike", "rank": 2}], "desc": "Battle instinct. +2 STR per rank.", "effects": {"str": 2}},
			{"id": "fortress", "name": "Fortress", "tier": 3, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "iron_skin", "rank": 2}], "desc": "Immovable. +2 DEF per rank.", "effects": {"defense": 2}},
		],
	},
	"mage": {
		"id": "mage",
		"name": "Mage",
		"blurb": "Arcane fire. High INT and MP. Fragile, but spells end fights.",
		"str": 2, "dex": 4, "int": 8, "luk": 2,
		"base_hp": 12, "base_mp": 20, "base_atk": 1, "base_def": 0,
		"atk_stat": "int",
		"skills": [
			{"id": "spark", "name": "Spark", "tier": 1, "max_rank": 3, "kind": "active", "mp": 3, "reqs": [], "desc": "Arcane dart. +3 spell damage per rank.", "effects": {"damage": 3, "spell": 1}},
			{"id": "mana_well", "name": "Mana Well", "tier": 1, "max_rank": 3, "kind": "passive", "mp": 0, "reqs": [], "desc": "Deeper reserves. +5 Max MP per rank.", "effects": {"max_mp": 5}},
			{"id": "frost_ward", "name": "Frost Ward", "tier": 2, "max_rank": 2, "kind": "active", "mp": 4, "reqs": [{"id": "spark", "rank": 1}], "desc": "Ice shield. +3 DEF this fight per rank.", "effects": {"ward": 3}},
			{"id": "fireball", "name": "Fireball", "tier": 2, "max_rank": 2, "kind": "active", "mp": 6, "reqs": [{"id": "spark", "rank": 2}], "desc": "A roaring sphere. +8 damage per rank.", "effects": {"damage": 8, "spell": 1}},
			{"id": "arcane_mind", "name": "Arcane Mind", "tier": 3, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "mana_well", "rank": 2}], "desc": "Clear thought. +2 INT per rank.", "effects": {"int": 2}},
			{"id": "meteor", "name": "Meteor", "tier": 3, "max_rank": 1, "kind": "active", "mp": 10, "reqs": [{"id": "fireball", "rank": 1}], "desc": "Call a star down. +16 damage.", "effects": {"damage": 16, "spell": 1}},
		],
	},
	"rogue": {
		"id": "rogue",
		"name": "Rogue",
		"blurb": "Knives in the dark. High DEX and LUK. Dodges, then cuts deep.",
		"str": 3, "dex": 8, "int": 2, "luk": 5,
		"base_hp": 14, "base_mp": 10, "base_atk": 2, "base_def": 0,
		"atk_stat": "dex",
		"skills": [
			{"id": "quick_cut", "name": "Quick Cut", "tier": 1, "max_rank": 3, "kind": "active", "mp": 1, "reqs": [], "desc": "A darting blade. +2 damage per rank.", "effects": {"damage": 2}},
			{"id": "lucky_feet", "name": "Lucky Feet", "tier": 1, "max_rank": 3, "kind": "passive", "mp": 0, "reqs": [], "desc": "Slip the counter. +8% dodge per rank.", "effects": {"dodge": 8}},
			{"id": "venom", "name": "Venom", "tier": 2, "max_rank": 2, "kind": "active", "mp": 3, "reqs": [{"id": "quick_cut", "rank": 1}], "desc": "Tainted edge. +6 damage per rank.", "effects": {"damage": 6}},
			{"id": "leech", "name": "Leech", "tier": 2, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "lucky_feet", "rank": 1}], "desc": "Bleed them. Heal 2 HP on hit per rank.", "effects": {"lifesteal": 2}},
			{"id": "assassin", "name": "Assassin", "tier": 3, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "venom", "rank": 1}], "desc": "Killers' grace. +2 DEX per rank.", "effects": {"dex": 2}},
			{"id": "deathblow", "name": "Deathblow", "tier": 3, "max_rank": 1, "kind": "active", "mp": 5, "reqs": [{"id": "venom", "rank": 2}], "desc": "If Oozey is below half, +12 damage.", "effects": {"damage": 4, "execute": 12}},
		],
	},
	"priest": {
		"id": "priest",
		"name": "Priest",
		"blurb": "Light against the dark. INT and LUK. Heals, smites, endures.",
		"str": 3, "dex": 3, "int": 6, "luk": 6,
		"base_hp": 16, "base_mp": 16, "base_atk": 1, "base_def": 1,
		"atk_stat": "int",
		"skills": [
			{"id": "mend", "name": "Mend", "tier": 1, "max_rank": 3, "kind": "active", "mp": 4, "reqs": [], "desc": "Close wounds. Heal 5 + INT per rank.", "effects": {"heal": 5, "heal_int": 1}},
			{"id": "smite", "name": "Smite", "tier": 1, "max_rank": 3, "kind": "active", "mp": 3, "reqs": [], "desc": "Holy fire. +3 damage per rank.", "effects": {"damage": 3, "spell": 1}},
			{"id": "bless", "name": "Bless", "tier": 2, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "smite", "rank": 1}], "desc": "Favored. +1 LUK and +1 ATK per rank.", "effects": {"luk": 1, "attack": 1}},
			{"id": "aegis", "name": "Aegis", "tier": 2, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "mend", "rank": 1}], "desc": "Sacred guard. +3 Max HP and +1 DEF per rank.", "effects": {"max_hp": 3, "defense": 1}},
			{"id": "divinity", "name": "Divinity", "tier": 3, "max_rank": 2, "kind": "passive", "mp": 0, "reqs": [{"id": "bless", "rank": 1}], "desc": "Closer to the light. +1 INT and +1 LUK per rank.", "effects": {"int": 1, "luk": 1}},
			{"id": "miracle", "name": "Miracle", "tier": 3, "max_rank": 1, "kind": "active", "mp": 8, "reqs": [{"id": "aegis", "rank": 1}], "desc": "A flood of light. Heal 18 + INT.", "effects": {"heal": 18, "heal_int": 1}},
		],
	},
}


static func class_def(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, CLASSES["warrior"])


static func get_skills(class_id: String) -> Array:
	return class_def(class_id).get("skills", [])


static func get_skill(class_id: String, skill_id: String) -> Dictionary:
	for skill in get_skills(class_id):
		if skill["id"] == skill_id:
			return skill
	return {}
