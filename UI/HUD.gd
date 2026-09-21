extends CanvasLayer

const SkillTreeViewScript = preload("res://UI/SkillTreeView.gd")
const SettingsPanelScript = preload("res://UI/SettingsPanel.gd")
const UiKit = preload("res://Data/UiKit.gd")
const ItemData = preload("res://Data/ItemData.gd")
const StatBarScript = preload("res://UI/StatBar.gd")

var _vitals_group: Control
var _seals_group: Control
var _bottom_group: Control
var _name_label: Label
var _gold_label: Label
var _extra_skills: Label
var _hp_bar
var _mp_bar
var _xp_bar
var _msg_label: Label
var _enemy: PanelContainer
var _enemy_name: Label
var _enemy_bar
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_body: Label
var _pause: ColorRect
var _sheet: ColorRect
var _sheet_stats: Label
var _tree: VBoxContainer
var _bag: ColorRect
var _bag_gold: Label
var _gear_labels: Dictionary = {}
var _slot_buttons: Array = []
var _detail: Label
var _use_button: Button
var _selected := -1
var _settings_host: Control


func _ready() -> void:
	layer = 20
	_build()
	Globals.player_hp_changed.connect(_on_hp_changed)
	Globals.player_mp_changed.connect(_on_mp_changed)
	Globals.monster_hp_changed.connect(_on_monster_hp)
	Globals.message_changed.connect(_on_message_changed)
	Globals.hero_changed.connect(_refresh_identity)
	Globals.facing_changed.connect(_on_facing_changed)
	Globals.monster_died.connect(_refresh_enemy)
	Globals.settings_changed.connect(_apply_hud_scale)
	Globals.player_died.connect(_on_player_died)
	Globals.player_won.connect(_on_player_won)
	_refresh_identity()
	_on_hp_changed(Globals.player_hp, Globals.hero.max_hp())
	_on_mp_changed(Globals.player_mp, Globals.hero.max_mp())
	_on_message_changed(Globals.message)
	_refresh_enemy()
	_apply_hud_scale()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _bag.visible:
			_close_bag()
		elif _sheet.visible:
			_close_sheet()
		elif _pause.visible:
			_close_pause()
		elif not Globals.game_over:
			_open_pause()
		elif Globals.game_over:
			Globals.go_to_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and not Globals.game_over:
		if _bag.visible:
			_close_bag()
		else:
			_close_pause()
			_close_sheet()
			_open_bag()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("character_sheet") and not Globals.game_over:
		if _sheet.visible:
			_close_sheet()
		else:
			_close_pause()
			_close_bag()
			_open_sheet()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(root)

	_build_vitals(root)
	_build_seals(root)
	_build_bottom(root)

	_overlay = _make_dim(root)
	_overlay.visible = false
	var over_panel := UiKit.make_leather_panel(10)
	over_panel.set_anchors_preset(Control.PRESET_CENTER)
	over_panel.offset_left = -260
	over_panel.offset_right = 260
	over_panel.offset_top = -80
	over_panel.offset_bottom = 90
	_overlay.add_child(over_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	over_panel.add_child(column)
	_overlay_title = UiKit.make_label("", 32, UiKit.GOLD)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_overlay_title)
	_overlay_body = UiKit.make_label("", 18)
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_overlay_body)

	_pause = _make_dim(root)
	_pause.visible = false
	var pause_panel := UiKit.make_leather_panel(10)
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -160
	pause_panel.offset_right = 160
	pause_panel.offset_top = -210
	pause_panel.offset_bottom = 210
	_pause.add_child(pause_panel)
	var pause_col := VBoxContainer.new()
	pause_col.add_theme_constant_override("separation", 5)
	pause_panel.add_child(pause_col)
	var pause_title := UiKit.make_label("PAUSED", 28, UiKit.GOLD)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_col.add_child(pause_title)
	pause_col.add_child(_menu_button("Resume", _close_pause))
	pause_col.add_child(_menu_button("Inventory", func() -> void:
		_close_pause()
		_open_bag()
	))
	pause_col.add_child(_menu_button("Character", func() -> void:
		_close_pause()
		_open_sheet()
	))
	pause_col.add_child(_menu_button("Save Game", func() -> void:
		Globals.save_game()
		Globals.notify("The dark keeps your name.")
		_close_pause()
	))
	pause_col.add_child(_menu_button("Settings", _open_settings))
	pause_col.add_child(_menu_button("Main Menu", Globals.go_to_menu))

	_sheet = _make_dim(root)
	_sheet.visible = false
	var sheet_panel := UiKit.make_leather_panel(8)
	sheet_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet_panel.offset_left = 40
	sheet_panel.offset_right = -40
	sheet_panel.offset_top = 32
	sheet_panel.offset_bottom = -32
	_sheet.add_child(sheet_panel)
	var sheet_cols := HBoxContainer.new()
	sheet_cols.add_theme_constant_override("separation", 8)
	sheet_panel.add_child(sheet_cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 3)
	sheet_cols.add_child(left)
	left.add_child(UiKit.make_label("CHARACTER", 26, UiKit.GOLD))
	_sheet_stats = UiKit.make_label("", 18)
	left.add_child(_sheet_stats)
	left.add_child(UiKit.make_label("Spend stat points:", 14, UiKit.CREAM_DIM))
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 4)
	left.add_child(stat_row)
	for stat in ["str", "dex", "int", "luk"]:
		var plus := UiKit.make_button(stat.to_upper() + " +", 90)
		plus.pressed.connect(func() -> void:
			if Globals.hero.spend_stat(stat):
				_refresh_sheet()
		)
		stat_row.add_child(plus)
	var close := UiKit.make_button("Close  [C]", 160)
	close.pressed.connect(_close_sheet)
	left.add_child(close)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_cols.add_child(right)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(420, 360)
	right.add_child(scroll)
	_tree = SkillTreeViewScript.new()
	_tree.skill_chosen.connect(func(skill_id: String) -> void:
		if Globals.hero.learn(skill_id):
			_refresh_sheet()
	)
	scroll.add_child(_tree)

	_build_bag(root)

	_settings_host = Control.new()
	_settings_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_settings_host)


func _build_vitals(root: Control) -> void:
	_vitals_group = UiKit.make_leather_panel(14)
	_vitals_group.position = Vector2(24, 20)
	_vitals_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitals_group.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(_vitals_group)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitals_group.add_child(col)

	_name_label = UiKit.make_label("", 26)
	col.add_child(_name_label)

	_hp_bar = StatBarScript.new()
	_hp_bar.configure(400, 26, UiKit.HP_FILL)
	col.add_child(_hp_bar)
	_mp_bar = StatBarScript.new()
	_mp_bar.configure(400, 26, UiKit.MP_FILL)
	col.add_child(_mp_bar)
	_xp_bar = StatBarScript.new()
	_xp_bar.configure(400, 20, UiKit.XP_FILL)
	col.add_child(_xp_bar)


func _build_seals(root: Control) -> void:
	_seals_group = VBoxContainer.new()
	_seals_group.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_seals_group.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_seals_group.offset_right = -24
	_seals_group.offset_top = 20
	_seals_group.add_theme_constant_override("separation", 4)
	_seals_group.alignment = BoxContainer.ALIGNMENT_END
	_seals_group.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(_seals_group)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	_seals_group.add_child(row)

	var coin_wrap := Control.new()
	coin_wrap.custom_minimum_size = Vector2(92, 118)
	row.add_child(coin_wrap)
	var coin := UiKit.make_icon(UiKit.TEX_COIN, 92)
	coin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	coin.offset_bottom = 92
	coin_wrap.add_child(coin)
	_gold_label = UiKit.make_label("0", 20, Color(0.16, 0.08, 0.02))
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_gold_label.offset_top = 30
	_gold_label.offset_bottom = 62
	coin_wrap.add_child(_gold_label)

	row.add_child(_seal_button(UiKit.TEX_SEAL_SWORD, "[1]", _on_seal_skill))
	row.add_child(_seal_button(UiKit.TEX_SEAL_BAG, "[I]", func() -> void:
		if Globals.game_over:
			return
		if _bag.visible:
			_close_bag()
		else:
			_close_pause()
			_close_sheet()
			_open_bag()
	))
	row.add_child(_seal_button(UiKit.TEX_SEAL_CHAR, "[C]", func() -> void:
		if Globals.game_over:
			return
		if _sheet.visible:
			_close_sheet()
		else:
			_close_pause()
			_close_bag()
			_open_sheet()
	))
	row.add_child(_seal_button(UiKit.TEX_SEAL_SKULL, "[Esc]", func() -> void:
		if _bag.visible:
			_close_bag()
		elif _sheet.visible:
			_close_sheet()
		elif _pause.visible:
			_close_pause()
		elif not Globals.game_over:
			_open_pause()
	))

	_extra_skills = UiKit.make_label("", 14, UiKit.CREAM_DIM)
	_extra_skills.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_extra_skills.visible = false
	_seals_group.add_child(_extra_skills)
	_seals_group.resized.connect(_sync_hud_pivots)


func _seal_button(tex: Texture2D, caption: String, callback: Callable) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := UiKit.make_icon(tex, 92)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
				callback.call()
	)
	col.add_child(icon)
	var cap := UiKit.make_label(caption, 15, UiKit.GOLD)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)
	return col


func _build_bottom(root: Control) -> void:
	_bottom_group = Control.new()
	_bottom_group.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_group.offset_left = 180
	_bottom_group.offset_right = -180
	_bottom_group.offset_top = -150
	_bottom_group.offset_bottom = -24
	_bottom_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_group.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(_bottom_group)
	_bottom_group.resized.connect(_sync_hud_pivots)

	_enemy = UiKit.make_leather_panel(10)
	_enemy.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_enemy.offset_left = -180
	_enemy.offset_right = 180
	_enemy.offset_top = -120
	_enemy.offset_bottom = -72
	_enemy.visible = false
	_enemy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_group.add_child(_enemy)
	var enemy_col := VBoxContainer.new()
	enemy_col.add_theme_constant_override("separation", 4)
	enemy_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy.add_child(enemy_col)
	_enemy_name = UiKit.make_label("OOZEY", 16, UiKit.SLIME_FILL)
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_col.add_child(_enemy_name)
	_enemy_bar = StatBarScript.new()
	_enemy_bar.configure(300, 16, UiKit.SLIME_FILL)
	enemy_col.add_child(_enemy_bar)

	var msg := UiKit.make_banner_panel(12)
	msg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	msg.offset_left = 0
	msg.offset_right = 0
	msg.offset_top = -64
	msg.offset_bottom = 0
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_group.add_child(msg)
	var msg_row := HBoxContainer.new()
	msg_row.add_theme_constant_override("separation", 12)
	msg_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg.add_child(msg_row)
	var flourish := TextureRect.new()
	flourish.texture = UiKit.TEX_FLOURISH
	flourish.custom_minimum_size = Vector2(120, 24)
	flourish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flourish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flourish.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	flourish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_row.add_child(flourish)
	_msg_label = UiKit.make_label("", 20)
	_msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_row.add_child(_msg_label)
	var flourish_b := TextureRect.new()
	flourish_b.texture = UiKit.TEX_FLOURISH
	flourish_b.custom_minimum_size = Vector2(120, 24)
	flourish_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flourish_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flourish_b.flip_h = true
	flourish_b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	flourish_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_row.add_child(flourish_b)


func _build_bag(root: Control) -> void:
	_bag = _make_dim(root)
	_bag.visible = false
	var panel := UiKit.make_leather_panel(8)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 18
	panel.offset_bottom = -18
	_bag.add_child(panel)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	panel.add_child(cols)

	var gear := VBoxContainer.new()
	gear.custom_minimum_size = Vector2(280, 0)
	gear.add_theme_constant_override("separation", 4)
	cols.add_child(gear)
	gear.add_child(UiKit.make_label("BAG", 26, UiKit.GOLD))
	_bag_gold = UiKit.make_label("", 16, UiKit.GOLD)
	gear.add_child(_bag_gold)
	for slot in ["weapon", "armor", "accessory"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		gear.add_child(row)
		var label := UiKit.make_label("", 14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(180, 28)
		row.add_child(label)
		_gear_labels[slot] = label
		var off := UiKit.make_button("Off", 70)
		off.pressed.connect(func() -> void:
			Globals.try_unequip(slot)
			_refresh_bag()
		)
		row.add_child(off)
	gear.add_child(UiKit.make_label("Click a slot, then Use.", 14, UiKit.CREAM_DIM))
	_detail = UiKit.make_label("Select an item.", 14)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(240, 80)
	gear.add_child(_detail)
	_use_button = UiKit.make_button("Use / Equip", 200)
	_use_button.pressed.connect(_use_selected)
	gear.add_child(_use_button)
	var bag_close := UiKit.make_button("Close  [I]", 200)
	bag_close.pressed.connect(_close_bag)
	gear.add_child(bag_close)

	var grid_wrap := VBoxContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(grid_wrap)
	grid_wrap.add_child(UiKit.make_label("SLOTS", 16, UiKit.CREAM_DIM))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid_wrap.add_child(grid)
	for i in ItemData.MAX_SLOTS:
		var slot_i := i
		var button := UiKit.make_button("", 140)
		button.custom_minimum_size = Vector2(140, 44)
		button.pressed.connect(func() -> void:
			_select_slot(slot_i)
		)
		grid.add_child(button)
		_slot_buttons.append(button)


func _menu_button(text: String, callback: Callable) -> Button:
	var button := UiKit.make_button(text, 240)
	button.pressed.connect(callback)
	return button


func _make_dim(parent: Control) -> ColorRect:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.04, 0.82)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	return dim


func _apply_hud_scale() -> void:
	var s := Globals.hud_scale()
	var vs := Vector2(s, s)
	_vitals_group.scale = vs
	_vitals_group.pivot_offset = Vector2.ZERO
	_seals_group.scale = vs
	_bottom_group.scale = vs
	_sync_hud_pivots()
	call_deferred("_sync_hud_pivots")


func _sync_hud_pivots() -> void:
	if _seals_group == null or _bottom_group == null:
		return
	_seals_group.pivot_offset = Vector2(_seals_group.size.x, 0.0)
	_bottom_group.pivot_offset = Vector2(_bottom_group.size.x * 0.5, _bottom_group.size.y)


func _on_seal_skill() -> void:
	if Globals.game_over or Globals.menu_open:
		return
	var actives = Globals.hero.active_skills()
	if actives.is_empty():
		return
	Globals.try_combat(str(actives[0]["id"]))


func _open_pause() -> void:
	_pause.visible = true
	Globals.set_menu_open(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause() -> void:
	_pause.visible = false
	if not _sheet.visible and not _bag.visible:
		Globals.set_menu_open(false)


func _open_sheet() -> void:
	_sheet.visible = true
	Globals.set_menu_open(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_sheet()


func _close_sheet() -> void:
	_sheet.visible = false
	if not _pause.visible and not _bag.visible:
		Globals.set_menu_open(false)


func _open_bag() -> void:
	_bag.visible = true
	Globals.set_menu_open(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_bag()


func _close_bag() -> void:
	_bag.visible = false
	if not _pause.visible and not _sheet.visible:
		Globals.set_menu_open(false)


func _open_settings() -> void:
	var panel = SettingsPanelScript.new()
	_settings_host.add_child(panel)
	panel.closed.connect(func() -> void: Globals.apply_settings())


func _select_slot(index: int) -> void:
	_selected = index
	_refresh_bag()


func _use_selected() -> void:
	if _selected < 0:
		return
	Globals.try_use_item(_selected)
	if Globals.hero != null and _selected >= Globals.hero.inventory.size():
		_selected = -1
	_refresh_bag()
	_refresh_identity()


func _refresh_bag() -> void:
	var h = Globals.hero
	if h == null:
		return
	_bag_gold.text = "Gold  %d" % h.gold
	for slot in ["weapon", "armor", "accessory"]:
		var label: Label = _gear_labels[slot]
		label.text = "%s: %s" % [slot.capitalize(), h.equipped_name(slot)]
	for i in _slot_buttons.size():
		var button: Button = _slot_buttons[i]
		if i < h.inventory.size():
			var stack: Dictionary = h.inventory[i]
			var item_id := str(stack["id"])
			var count: int = int(stack["count"])
			var mark := ">" if i == _selected else ""
			button.text = "%s%s x%d" % [mark, ItemData.display_name(item_id), count]
			button.add_theme_color_override("font_color", ItemData.rarity_color(item_id))
			button.disabled = false
		else:
			button.text = "—"
			button.add_theme_color_override("font_color", UiKit.CREAM_DIM)
			button.disabled = false
	_detail.text = "Select an item."
	_use_button.disabled = true
	if _selected >= 0 and _selected < h.inventory.size():
		var stack: Dictionary = h.inventory[_selected]
		var item_id := str(stack["id"])
		var data: Dictionary = ItemData.def(item_id)
		_detail.text = "%s\n%s" % [str(data.get("name", item_id)), str(data.get("desc", ""))]
		_use_button.disabled = false
		var kind := str(data.get("kind", ""))
		_use_button.text = "Equip" if kind == "equipment" else "Use"


func _refresh_sheet() -> void:
	var h = Globals.hero
	_sheet_stats.text = "%s  %s  Lv %d\nSTR %d  DEX %d  INT %d  LUK %d\nHP %d/%d  MP %d/%d\nATK %d  DEF %d  Dodge %d%%\nStat pts %d   Skill pts %d" % [
		h.hero_name, h.class_name_pretty(), h.level,
		h.total_str(), h.total_dex(), h.total_int(), h.total_luk(),
		h.hp, h.max_hp(), h.mp, h.max_mp(),
		h.attack_power(), h.defense(), h.dodge_chance(),
		h.stat_points, h.skill_points
	]
	_tree.setup(h, true)
	_refresh_identity()


func _refresh_identity() -> void:
	var h = Globals.hero
	if h == null:
		return
	_name_label.text = "%s  ·  %s  ·  Lv %d" % [h.hero_name, h.class_name_pretty(), h.level]
	_gold_label.text = str(h.gold)
	_xp_bar.set_amount(float(h.xp), float(h.xp_to_next()), "XP %d/%d" % [h.xp, h.xp_to_next()])
	_refresh_extra_skills(h)
	_on_hp_changed(Globals.player_hp, h.max_hp())
	_on_mp_changed(Globals.player_mp, h.max_mp())
	_refresh_enemy()
	if _bag.visible:
		_refresh_bag()


func _refresh_extra_skills(h) -> void:
	var actives = h.active_skills()
	var parts: PackedStringArray = PackedStringArray()
	for i in range(1, mini(actives.size(), 3)):
		parts.append("[%d] %s" % [i + 1, actives[i]["name"]])
	_extra_skills.text = "  ".join(parts)
	_extra_skills.visible = parts.size() > 0


func _on_hp_changed(hp: int, max_hp: int) -> void:
	_hp_bar.set_amount(float(hp), float(max_hp), "HP  %d/%d" % [hp, max_hp])


func _on_mp_changed(mp: int, max_mp: int) -> void:
	_mp_bar.set_amount(float(mp), float(max_mp), "MP  %d/%d" % [mp, max_mp])


func _on_monster_hp(_hp: int, _max_hp: int) -> void:
	_refresh_enemy()


func _on_facing_changed(_value: bool) -> void:
	_refresh_enemy()


func _refresh_enemy() -> void:
	var enc: Dictionary = Globals.facing_encounter()
	var show_enemy := not enc.is_empty() and not Globals.game_over
	_enemy.visible = show_enemy
	if not show_enemy:
		return
	_enemy_name.text = str(enc.get("name", "Beast")).to_upper()
	_enemy_bar.set_amount(float(int(enc["hp"])), float(int(enc["max_hp"])), "%d/%d" % [int(enc["hp"]), int(enc["max_hp"])])


func _on_message_changed(text: String) -> void:
	_msg_label.text = text


func _on_player_died() -> void:
	_show_overlay("YOU DIED", Globals.death_overlay_body())


func _on_player_won() -> void:
	var title := "LESSON COMPLETE" if Globals.tutorial_active else "YOU DESCEND"
	_show_overlay(title, Globals.win_overlay_body())


func _show_overlay(title: String, body: String) -> void:
	_close_pause()
	_close_sheet()
	_close_bag()
	_overlay_title.text = title
	_overlay_body.text = body
	_overlay.visible = true
	_refresh_enemy()
