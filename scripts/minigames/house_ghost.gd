extends CharacterBody2D
## Patrol the house, then follow the player through doorways when they come close.

signal touched_player

@export var movement_speed: float = 85.0
@export var chase_distance: float = 280.0
@export var patrol_points: Node2D
@export var player: CharacterBody2D
@export var house: Node2D

var active: bool = false
var next_point: int = 1
var contact_cooldown: float = 0.0
var route: PackedVector2Array
var route_index: int = 0
var route_delay: float = 0.0


func reset() -> void:
	active = false
	position = patrol_points.get_child(0).position
	next_point = 1
	contact_cooldown = 2.0
	route_delay = 0.0
	velocity = Vector2.ZERO
	modulate.a = 1.0
	show()


func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	route_delay -= delta
	if route_delay <= 0.0:
		var target: Vector2 = patrol_points.get_child(next_point).position
		if position.distance_to(player.position) < chase_distance:
			target = player.position
		elif position.distance_to(target) < 24.0:
			next_point = (next_point + 1) % patrol_points.get_child_count()
			target = patrol_points.get_child(next_point).position
		route = house.walking_path(position, target)
		route_index = 0
		route_delay = 0.3
	while route_index < route.size() and position.distance_to(route[route_index]) < 8.0:
		route_index += 1
	velocity = Vector2.ZERO
	if route_index < route.size():
		velocity = position.direction_to(route[route_index]) * movement_speed
	move_and_slide()
	# Staying in contact also counts, but there is time to escape after each hit.
	if contact_cooldown <= 0.0 and $Contact.has_overlapping_bodies():
		contact_cooldown = 2.0
		touched_player.emit()
