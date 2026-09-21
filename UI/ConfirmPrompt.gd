extends Control

const UiKit = preload("res://Data/UiKit.gd")

signal chosen(yes: bool)


func setup(title: String, body: String, yes_text: String = "Yes", no_text: String = "No") -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.04, 0.78)
	add_child(dim)
	var panel := UiKit.make_leather_panel(18)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = -140
	panel.offset_bottom = 140
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var title_label := UiKit.make_label(title, 28, UiKit.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title_label)
	var body_label := UiKit.make_label(body, 18)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(480, 48)
	col.add_child(body_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var yes := UiKit.make_button(yes_text, 160)
	yes.pressed.connect(func() -> void:
		chosen.emit(true)
		queue_free()
	)
	row.add_child(yes)
	var no := UiKit.make_button(no_text, 160)
	no.pressed.connect(func() -> void:
		chosen.emit(false)
		queue_free()
	)
	row.add_child(no)
