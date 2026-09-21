extends RefCounted

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func save_game(payload: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


static func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func load_settings() -> Dictionary:
	var cfg := ConfigFile.new()
	var data := {
		"master": 1.0,
		"music": 0.8,
		"sfx": 1.0,
		"fullscreen": false,
		"hud_scale": 1.0,
	}
	if cfg.load(SETTINGS_PATH) != OK:
		return data
	data["master"] = float(cfg.get_value("audio", "master", 1.0))
	data["music"] = float(cfg.get_value("audio", "music", 0.8))
	data["sfx"] = float(cfg.get_value("audio", "sfx", 1.0))
	data["fullscreen"] = bool(cfg.get_value("video", "fullscreen", false))
	data["hud_scale"] = clampf(float(cfg.get_value("video", "hud_scale", 1.0)), 0.7, 1.25)
	return data


static func save_settings(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", float(data.get("master", 1.0)))
	cfg.set_value("audio", "music", float(data.get("music", 0.8)))
	cfg.set_value("audio", "sfx", float(data.get("sfx", 1.0)))
	cfg.set_value("video", "fullscreen", bool(data.get("fullscreen", false)))
	cfg.set_value("video", "hud_scale", clampf(float(data.get("hud_scale", 1.0)), 0.7, 1.25))
	cfg.save(SETTINGS_PATH)
