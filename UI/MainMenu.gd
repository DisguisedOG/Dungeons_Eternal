extends Control

const SkillTreeViewScript = preload("res://UI/SkillTreeView.gd")
const SettingsPanelScript = preload("res://UI/SettingsPanel.gd")
const UiKit = preload("res://Data/UiKit.gd")
const SaveService = preload("res://Data/SaveService.gd")

var _load_button: Button
var _settings_host: Control


func _ready() -> void:
	Globals.apply_settings()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	_refresh_load()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.07, 1)
	add_child(bg)

	var panel := UiKit.make_leather_panel(10)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -200
	panel.offset_bottom = 220
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)

	var title := UiKit.make_label("DUNGEONS ETERNAL", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiKit.make_label("Choose your fate in the dark.", 16, UiKit.CREAM_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	col.add_child(spacer)

	var new_game := UiKit.make_button("New Game")
	new_game.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://UI/CharacterCreate.tscn")
	)
	col.add_child(new_game)

	_load_button = UiKit.make_button("Load Game")
	_load_button.pressed.connect(_on_load)
	col.add_child(_load_button)

	var settings := UiKit.make_button("Settings")
	settings.pressed.connect(_on_settings)
	col.add_child(settings)

	var quit := UiKit.make_button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(quit)

	_settings_host = Control.new()
	_settings_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_settings_host)


func _refresh_load() -> void:
	_load_button.disabled = not SaveService.has_save()
	if _load_button.disabled:
		_load_button.text = "Load Game  (empty)"
	else:
		_load_button.text = "Load Game"


func _on_load() -> void:
	if Globals.load_game():
		get_tree().change_scene_to_file("res://World/World.tscn")


func _on_settings() -> void:
	if _settings_host.get_child_count() > 0:
		return
	var panel = SettingsPanelScript.new()
	_settings_host.add_child(panel)
	panel.closed.connect(_refresh_load)
