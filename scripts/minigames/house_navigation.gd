extends Node2D
## Build walking routes from the walls and furniture already placed in the scene.

const CELL_SIZE: int = 20
const PLAYER_CLEARANCE: float = 18.0
var grid := AStarGrid2D.new()


func _ready() -> void:
	grid.region = Rect2i(0, 0, 45, 50)
	grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	grid.offset = grid.cell_size * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for shape: CollisionPolygon2D in find_children("*", "CollisionPolygon2D", true, false):
		var bounds := Rect2(to_local(shape.to_global(shape.polygon[0])), Vector2.ZERO)
		for point in shape.polygon:
			bounds = bounds.expand(to_local(shape.to_global(point)))
		bounds = bounds.grow(PLAYER_CLEARANCE)
		for y in range(grid.region.size.y):
			for x in range(grid.region.size.x):
				var cell := Vector2i(x, y)
				if bounds.has_point(grid.get_point_position(cell)):
					grid.set_point_solid(cell)


func walking_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return grid.get_point_path(_nearest_open_cell(from), _nearest_open_cell(to))


func _nearest_open_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i((point / CELL_SIZE).floor())
	cell = cell.clamp(Vector2i.ZERO, grid.region.size - Vector2i.ONE)
	if not grid.is_point_solid(cell):
		return cell
	# A player beside a wall can stand between the navigation grid's cell centres.
	var closest := cell
	var closest_distance := INF
	for y in range(maxi(0, cell.y - 2), mini(grid.region.size.y, cell.y + 3)):
		for x in range(maxi(0, cell.x - 2), mini(grid.region.size.x, cell.x + 3)):
			var candidate := Vector2i(x, y)
			if grid.is_point_solid(candidate):
				continue
			var distance := point.distance_squared_to(grid.get_point_position(candidate))
			if distance < closest_distance:
				closest = candidate
				closest_distance = distance
	return closest
