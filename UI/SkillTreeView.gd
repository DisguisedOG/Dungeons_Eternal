extends VBoxContainer

const UiKit = preload("res://Data/UiKit.gd")
const ClassData = preload("res://Data/ClassData.gd")

signal skill_chosen(skill_id: String)

var _hero
var _editable := true
var _buttons: Dictionary = {}


func setup(hero, editable: bool = true) -> void:
	_hero = hero
	_editable = editable
	refresh()


func refresh() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	if _hero == null:
		return
	add_theme_constant_override("separation", 3)
	var header := UiKit.make_label("%s Tree  SP %d" % [_hero.class_name_pretty(), _hero.skill_points], 16)
	add_child(header)
	for def in ClassData.get_skills(_hero.class_id):
		add_child(_make_row(def))


func _make_row(def: Dictionary) -> Control:
	var skill_id := str(def["id"])
	var rank: int = int(_hero.skill_rank(skill_id))
	var max_rank := int(def["max_rank"])
	var req_text := _req_text(def)
	var label := "T%d  %s  %d/%d" % [int(def["tier"]), def["name"], rank, max_rank]
	if str(def["kind"]) == "active":
		label += "  MP%d" % int(def["mp"])
	var button := UiKit.make_button(label, 480)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = "%s\n%s" % [def["desc"], req_text]
	var unlocked: bool = rank > 0
	var can: bool = _editable and bool(_hero.can_learn(skill_id))
	button.disabled = not can and not unlocked
	if unlocked:
		button.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	if can:
		button.add_theme_color_override("font_color", Color(0.7, 0.95, 0.55))
	button.pressed.connect(func() -> void:
		skill_chosen.emit(skill_id)
	)
	_buttons[skill_id] = button
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(button)
	var detail := UiKit.make_label(str(def["desc"]), 14, UiKit.CREAM_DIM)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wrap.add_child(detail)
	return wrap


func _req_text(def: Dictionary) -> String:
	if (def["reqs"] as Array).is_empty():
		return "No requirement."
	var parts: PackedStringArray = PackedStringArray()
	for req in def["reqs"]:
		var other := ClassData.get_skill(_hero.class_id, str(req["id"]))
		parts.append("%s %d" % [other.get("name", req["id"]), int(req["rank"])])
	return "Needs: " + ", ".join(parts)
