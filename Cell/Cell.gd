extends Node3D
class_name Cell

@onready var topFace: = $TopFace
@onready var northFace: = $NorthFace
@onready var eastFace: = $EastFace
@onready var southFace: = $SouthFace
@onready var westFace: = $WestFace
@onready var bottomFace: = $BottomFace

func update_faces(cell_list) -> void:
	var my_grid_position = Vector2i(roundi(position.x / Globals.GRID_SIZE), roundi(position.z / Globals.GRID_SIZE))
	if cell_list.has(my_grid_position + Vector2i.RIGHT):
		eastFace.queue_free()
	if cell_list.has(my_grid_position + Vector2i.LEFT):
		westFace.queue_free()
	if cell_list.has(my_grid_position + Vector2i.DOWN):
		southFace.queue_free()
	if cell_list.has(my_grid_position + Vector2i.UP):
		northFace.queue_free()


func apply_theme(wall_mat: Material, floor_mat: Material) -> void:
	for face in [northFace, eastFace, southFace, westFace, topFace]:
		if face != null and is_instance_valid(face):
			face.material_overlay = null
			face.material_override = wall_mat
	if bottomFace != null and is_instance_valid(bottomFace):
		bottomFace.material_overlay = null
		bottomFace.material_override = floor_mat
