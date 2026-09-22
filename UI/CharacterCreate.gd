extends Control

const SkillTreeViewScript = preload("res://UI/SkillTreeView.gd")
const ConfirmPromptScript = preload("res://UI/ConfirmPrompt.gd")
const Hero = preload("res://Data/Hero.gd")
const ClassData = preload("res://Data/ClassData.gd")
const UiKit = preload("res://Data/UiKit.gd")

var _hero = Hero.new()
var _name_edit: LineEdit
var _blurb: Label
var _stats: Label
var _tree: VBoxContainer
var _class_buttons: Dictionary = {}
var _want_tutorial := true
var _prompt_busy := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hero.setup("Adventurer", "warrior")
	_build()
	_select_class("warrior")


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.07, 1)
	add_child(bg)

	var panel := UiKit.make_leather_panel(16)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 18
	panel.offset_bottom = -18
	add_child(panel)

	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 4)
	root.add_theme_constant_override("margin_right", 4)
	root.add_theme_constant_override("margin_top", 2)
	root.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(root)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	root.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	cols.add_child(left)

	left.add_child(UiKit.make_label("NEW GAME", 28))
	left.add_child(UiKit.make_label("Name", 14, UiKit.CREAM_DIM))
	_name_edit = UiKit.make_line_edit("Adventurer")
	_name_edit.text = "Adventurer"
	_name_edit.text_changed.connect(func(value: String) -> void:
		_hero.hero_name = value
	)
	left.add_child(_name_edit)
	left.add_child(UiKit.make_label("Class", 14, UiKit.CREAM_DIM))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	left.add_child(grid)
	for class_id in ClassData.IDS:
		var data := ClassData.class_def(class_id)
		var button := UiKit.make_button(str(data["name"]), 180)
		button.pressed.connect(_select_class.bind(class_id))
		_class_buttons[class_id] = button
		grid.add_child(button)

	_blurb = UiKit.make_label("", 14, UiKit.CREAM_DIM)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(360, 48)
	left.add_child(_blurb)

	_stats = UiKit.make_label("", 16)
	left.add_child(_stats)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	left.add_child(nav)
	var back := UiKit.make_button("Back", 140)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
	)
	nav.add_child(back)
	var start := UiKit.make_button("Enter Dungeon", 220)
	start.pressed.connect(_start)
	nav.add_child(start)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	cols.add_child(right)
	right.add_child(UiKit.make_label("Skill Tree  (click to spend SP)", 16, UiKit.CREAM_DIM))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(420, 360)
	right.add_child(scroll)
	_tree = SkillTreeViewScript.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.skill_chosen.connect(_on_skill)
	scroll.add_child(_tree)


func _select_class(class_id: String) -> void:
	var spent_name: String = _name_edit.text if _name_edit else _hero.hero_name
	_hero.setup(spent_name, class_id)
	for id in _class_buttons.keys():
		var button: Button = _class_buttons[id]
		button.modulate = Color(1, 1, 1, 1) if id == class_id else Color(0.7, 0.7, 0.7, 1)
	_refresh()


func _on_skill(skill_id: String) -> void:
	if _hero.learn(skill_id):
		_refresh()


func _refresh() -> void:
	var data := ClassData.class_def(_hero.class_id)
	_blurb.text = str(data["blurb"])
	_stats.text = "STR %d   DEX %d   INT %d   LUK %d\nHP %d   MP %d   STA %d   ATK %d   DEF %d" % [
		_hero.total_str(), _hero.total_dex(), _hero.total_int(), _hero.total_luk(),
		_hero.max_hp(), _hero.max_mp(), _hero.max_stamina(), _hero.attack_power(), _hero.defense()
	]
	_tree.setup(_hero, true)


func _start() -> void:
	if _prompt_busy:
		return
	_hero.hero_name = _name_edit.text.strip_edges()
	if _hero.hero_name.is_empty():
		_hero.hero_name = "Adventurer"
	_hero.restore_full()
	_ask_tutorial()


func _ask_tutorial() -> void:
	_prompt_busy = true
	var prompt = ConfirmPromptScript.new()
	add_child(prompt)
	prompt.setup("Tutorial", "Would you like to play the tutorial?", "Yes", "No")
	prompt.chosen.connect(_on_tutorial_choice)


func _on_tutorial_choice(yes: bool) -> void:
	_want_tutorial = yes
	var prompt = ConfirmPromptScript.new()
	add_child(prompt)
	var body := "Are you sure you want to play the tutorial?" if yes else "Are you sure you want to skip the tutorial?"
	prompt.setup("Are you sure?", body, "Yes", "No")
	prompt.chosen.connect(_on_sure)


func _on_sure(yes: bool) -> void:
	if not yes:
		_prompt_busy = false
		_ask_tutorial()
		return
	Globals.start_new_game(_hero, _want_tutorial)
	get_tree().change_scene_to_file("res://World/World.tscn")
