extends RefCounted

const CREAM := Color("e8d9a0")
const CREAM_DIM := Color("8a7a58")
const INK := Color(0.05, 0.02, 0.08, 1)
const PANEL := Color(0.06, 0.03, 0.1, 0.92)
const PANEL_SOLID := Color(0.07, 0.04, 0.11, 1)
const BUTTON := Color(0.16, 0.1, 0.2, 1)
const BUTTON_HOVER := Color(0.28, 0.16, 0.32, 1)
const ACCENT := Color(0.72, 0.42, 0.22, 1)
const GOLD := Color(0.92, 0.78, 0.32)
const FRAME := Color(0.52, 0.38, 0.22, 1)
const HP_FILL := Color(0.74, 0.18, 0.24)
const MP_FILL := Color(0.22, 0.46, 0.86)
const XP_FILL := Color(0.82, 0.64, 0.22)
const STAMINA_FILL := Color(0.42, 0.78, 0.32)
const SLIME_FILL := Color(0.32, 0.86, 0.34)

const TEX_LEATHER := preload("res://UI/Theme/leather_panel.png")
const TEX_BANNER := preload("res://UI/Theme/banner.png")
const TEX_WELL := preload("res://UI/Theme/bar_well.png")
const TEX_COIN := preload("res://UI/Theme/coin.png")
const TEX_FLOURISH := preload("res://UI/Theme/flourish.png")
const TEX_SEAL_SWORD := preload("res://UI/Theme/seal_sword.png")
const TEX_SEAL_BAG := preload("res://UI/Theme/seal_bag.png")
const TEX_SEAL_CHAR := preload("res://UI/Theme/seal_char.png")
const TEX_SEAL_SKULL := preload("res://UI/Theme/seal_skull.png")
const FONT_UI := preload("res://UI/Theme/Cinzel-Regular.ttf")


static func style_label(label: Label, size: int = 16, color: Color = CREAM) -> void:
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 3)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func make_label(text: String, size: int = 16, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = text
	style_label(label, size, color)
	return label


static func make_button(text: String, width: int = 220) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 36)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = BUTTON
	normal.set_border_width_all(2)
	normal.border_color = GOLD
	normal.set_content_margin_all(8)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = BUTTON_HOVER
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.07, 0.14, 1)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.1, 0.08, 0.12, 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover)
	return button


static func make_line_edit(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(240, 34)
	edit.max_length = 16
	edit.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	edit.add_theme_font_override("font", FONT_UI)
	edit.add_theme_font_size_override("font_size", 16)
	edit.add_theme_color_override("font_color", CREAM)
	edit.add_theme_color_override("font_placeholder_color", CREAM_DIM)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.06, 0.14, 1)
	box.set_border_width_all(2)
	box.border_color = GOLD
	box.set_content_margin_all(8)
	box.set_corner_radius_all(6)
	edit.add_theme_stylebox_override("normal", box)
	edit.add_theme_stylebox_override("focus", box)
	return edit


static func frame_box(margin: int = 8, solid: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_SOLID if solid else PANEL
	box.set_border_width_all(1)
	box.border_color = FRAME
	box.set_content_margin_all(margin)
	return box


static func leather_box(margin: int = 14) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = TEX_LEATHER
	box.texture_margin_left = 20
	box.texture_margin_top = 20
	box.texture_margin_right = 20
	box.texture_margin_bottom = 20
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.set_content_margin_all(margin)
	return box


static func banner_box(margin: int = 12) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = TEX_BANNER
	box.texture_margin_left = 48
	box.texture_margin_top = 12
	box.texture_margin_right = 48
	box.texture_margin_bottom = 12
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.set_content_margin_all(margin)
	return box


static func well_box() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = TEX_WELL
	box.texture_margin_left = 4
	box.texture_margin_top = 4
	box.texture_margin_right = 4
	box.texture_margin_bottom = 4
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return box


static func make_leather_panel(margin: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.add_theme_stylebox_override("panel", leather_box(margin))
	return panel


static func make_banner_panel(margin: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.add_theme_stylebox_override("panel", banner_box(margin))
	return panel


static func make_panel(margin: int = 14) -> PanelContainer:
	return make_leather_panel(margin)


static func make_icon(tex: Texture2D, extent: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return icon


static func bar(value: float, max_value: float, width: int, height: int, fill: Color) -> Control:
	var wrap := ColorRect.new()
	wrap.custom_minimum_size = Vector2(width, height)
	wrap.color = Color(0.08, 0.05, 0.1, 1)
	var inner := ColorRect.new()
	inner.color = fill
	inner.position = Vector2(1, 1)
	var ratio := 0.0 if max_value <= 0.0 else clampf(value / max_value, 0.0, 1.0)
	inner.size = Vector2((width - 2) * ratio, height - 2)
	wrap.add_child(inner)
	return wrap
