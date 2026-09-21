extends Control

const UiKit = preload("res://Data/UiKit.gd")

var _fill: ColorRect
var _glow: ColorRect
var _label: Label
var _color: Color = Color.WHITE
var _pad := 4
var _inner_w := 1
var _inner_h := 1


func configure(width: int, height: int, color: Color) -> void:
	custom_minimum_size = Vector2(width, height)
	size = Vector2(width, height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true
	_color = color
	_inner_w = maxi(width - _pad * 2, 1)
	_inner_h = maxi(height - _pad * 2, 1)

	var well := Panel.new()
	well.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	well.add_theme_stylebox_override("panel", UiKit.well_box())
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(well)

	_fill = ColorRect.new()
	_fill.position = Vector2(_pad, _pad)
	_fill.size = Vector2(_inner_w, _inner_h)
	_fill.color = color
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	_glow = ColorRect.new()
	_glow.position = Vector2(_pad, _pad)
	_glow.size = Vector2(_inner_w, 2)
	_glow.color = Color(1, 1, 1, 0.28)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 5
	_label.offset_right = -4
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.style_label(_label, 16, Color(1, 0.96, 0.88))
	add_child(_label)


func set_amount(value: float, max_value: float, caption: String) -> void:
	var ratio := 0.0 if max_value <= 0.0 else clampf(value / max_value, 0.0, 1.0)
	var w: int = maxi(int(round(float(_inner_w) * ratio)), 0 if ratio <= 0.0 else 1)
	_fill.size = Vector2(w, _inner_h)
	_glow.size = Vector2(w, 2)
	_glow.visible = w > 0
	var tint := _color
	if ratio <= 0.28:
		tint = _color.lerp(Color(1.0, 0.28, 0.18), 0.55)
	_fill.color = tint
	_label.text = caption
