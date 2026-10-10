extends CharacterBody2D
## A simple patrol for testing movement and contact damage before the encounter is designed.

signal touched_player

@export var movement_speed: float = 65.0
@export var patrol_points: Node2D

var next_point: int = 0
var contact_cooldown: float = 0.0


func reset() -> void:
	position = patrol_points.get_child(0).position
	next_point = 1
	contact_cooldown = 2.0
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	var target: Vector2 = patrol_points.get_child(next_point).global_position
	if global_position.distance_to(target) < 8.0:
		next_point = (next_point + 1) % patrol_points.get_child_count()
	velocity = global_position.direction_to(target) * movement_speed
	move_and_slide()


func _on_contact_body_entered(_body: Node2D) -> void:
	if contact_cooldown > 0.0:
		return
	contact_cooldown = 2.0
	touched_player.emit()
