extends Control

const UiKit = preload("res://Data/UiKit.gd")
const SaveService = preload("res://Data/SaveService.gd")

signal closed
signal changed(settings: Dictionary)

var settings: Dictionary = {}
var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _hud: HSlider
var _hud_caption: Label
var _fullscreen: CheckButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings = SaveService.load_settings()
	_build()
	Globals.apply_settings()


func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	add_child(dim)

	var panel := UiKit.make_leather_panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -200
	panel.offset_bottom = 200
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(UiKit.make_label("SETTINGS", 28, UiKit.GOLD))

	_master = _slider_row(col, "Master", float(settings["master"]), 0.0, 1.0, 0.05)
	_music = _slider_row(col, "Music", float(settings["music"]), 0.0, 1.0, 0.05)
	_sfx = _slider_row(col, "SFX", float(settings["sfx"]), 0.0, 1.0, 0.05)
	_hud_caption = UiKit.make_label(_hud_caption_text(float(settings.get("hud_scale", 1.0))), 14, UiKit.CREAM_DIM)
	col.add_child(_hud_caption)
	_hud = _slider(col, float(settings.get("hud_scale", 1.0)), 0.7, 1.25, 0.05)

	_fullscreen = CheckButton.new()
	_fullscreen.text = "Fullscreen"
	_fullscreen.button_pressed = bool(settings["fullscreen"])
	_fullscreen.add_theme_font_override("font", UiKit.FONT_UI)
	_fullscreen.add_theme_font_size_override("font_size", 16)
	_fullscreen.add_theme_color_override("font_color", UiKit.CREAM)
	_fullscreen.toggled.connect(func(_on: bool) -> void: _commit())
	col.add_child(_fullscreen)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var back := UiKit.make_button("Back", 140)
	back.pressed.connect(_on_back)
	row.add_child(back)


func _slider_row(parent: Control, caption: String, value: float, min_value: float, max_value: float, step: float) -> HSlider:
	parent.add_child(UiKit.make_label(caption, 14, UiKit.CREAM_DIM))
	return _slider(parent, value, min_value, max_value, step)


func _slider(parent: Control, value: float, min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(360, 18)
	slider.value_changed.connect(func(_v: float) -> void: _commit())
	parent.add_child(slider)
	return slider


func _hud_caption_text(value: float) -> String:
	return "HUD Scale  %.2f" % value


func _commit() -> void:
	settings["master"] = _master.value
	settings["music"] = _music.value
	settings["sfx"] = _sfx.value
	settings["hud_scale"] = _hud.value
	settings["fullscreen"] = _fullscreen.button_pressed
	_hud_caption.text = _hud_caption_text(float(_hud.value))
	SaveService.save_settings(settings)
	Globals.apply_settings()
	changed.emit(settings)


func _on_back() -> void:
	closed.emit()
	queue_free()
