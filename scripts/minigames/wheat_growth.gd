extends Control
## Each new grain file is an instance of a small, replaceable icon scene.

const WHEAT_FILE: PackedScene = preload("res://scenes/minigames/wheat_file.tscn")
const GRID_SIZE := Vector2i(5, 4)

var filled_cells: int = 0


func reset() -> void:
	for patch in get_children():
		patch.queue_free()
	filled_cells = 0


func set_coverage(amount: float) -> void:
	var target_count := floori(clampf(amount, 0.0, 1.0) * GRID_SIZE.x * GRID_SIZE.y)
	var cell_size := size / Vector2(GRID_SIZE)
	while filled_cells < target_count:
		var column := filled_cells % GRID_SIZE.x
		var row := floori(float(filled_cells) / GRID_SIZE.x)
		var file: Control = WHEAT_FILE.instantiate()
		file.get_node("Name").text = "vili_%02d.png" % (filled_cells + 1)
		add_child(file)
		var cell_origin := Vector2(column, row) * cell_size
		file.position = cell_origin + (cell_size - file.size) * 0.5
		filled_cells += 1
	while filled_cells > target_count:
		var file := get_child(filled_cells - 1)
		remove_child(file)
		file.queue_free()
		filled_cells -= 1
