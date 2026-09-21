extends RefCounted

const KINDS := ["oozey", "blood_ooze", "night_ooze", "ash_ooze", "gold_ooze"]


static func def(kind: String) -> Dictionary:
	match kind:
		"blood_ooze":
			return {
				"id": "blood_ooze",
				"name": "Blood Ooze",
				"hp": 12,
				"attack": 3,
				"xp": 30,
				"tint": Color(0.95, 0.28, 0.22),
				"glow": Color(0.95, 0.18, 0.12),
				"scale": 0.26,
				"hit": "The blood ooze spatters back.",
				"death": "The blood ooze bursts.",
			}
		"night_ooze":
			return {
				"id": "night_ooze",
				"name": "Night Ooze",
				"hp": 10,
				"attack": 4,
				"xp": 32,
				"tint": Color(0.45, 0.28, 0.85),
				"glow": Color(0.42, 0.22, 0.9),
				"scale": 0.22,
				"hit": "The night ooze lashes out.",
				"death": "The night ooze fades to smoke.",
			}
		"ash_ooze":
			return {
				"id": "ash_ooze",
				"name": "Ash Ooze",
				"hp": 16,
				"attack": 2,
				"xp": 28,
				"tint": Color(0.55, 0.52, 0.48),
				"glow": Color(0.7, 0.62, 0.4),
				"scale": 0.3,
				"hit": "The ash ooze rumbles.",
				"death": "The ash ooze collapses into dust.",
			}
		"gold_ooze":
			return {
				"id": "gold_ooze",
				"name": "Gold Ooze",
				"hp": 14,
				"attack": 3,
				"xp": 48,
				"tint": Color(0.95, 0.78, 0.28),
				"glow": Color(1.0, 0.82, 0.25),
				"scale": 0.23,
				"hit": "The gold ooze rings as it strikes.",
				"death": "The gold ooze splits into coins of slime.",
			}
		_:
			return {
				"id": "oozey",
				"name": "Oozey",
				"hp": 8,
				"attack": 2,
				"xp": 24,
				"tint": Color(0.85, 1.0, 0.7),
				"glow": Color(0.28, 0.95, 0.22),
				"scale": 0.24,
				"hit": "Oozey sloshes back.",
				"death": "Oozey collapses.",
			}


static func pick(rng: RandomNumberGenerator, depth: int) -> String:
	var roll := rng.randi_range(0, 99)
	if depth >= 3 and roll < 8:
		return "gold_ooze"
	if roll < 28:
		return "oozey"
	if roll < 52:
		return "blood_ooze"
	if roll < 74:
		return "night_ooze"
	return "ash_ooze"


static func scaled_hp(kind: String, depth: int, hero_level: int) -> int:
	var base: int = int(def(kind)["hp"])
	return base + (depth - 1) * 3 + hero_level * 2


static func scaled_attack(kind: String, depth: int, hero_level: int) -> int:
	var base: int = int(def(kind)["attack"])
	return maxi(1, base + int(depth / 2.0) + int(hero_level / 2.0) - 1)
