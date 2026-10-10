extends CharacterBody2D

signal interacted

@export var movement_speed: float = 150.0

var controls_enabled: bool = false
var held_keys: Array[int] = []


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	held_keys.clear()
	velocity = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not controls_enabled or not event is InputEventKey or event.echo:
		return
	var key: int = event.physical_keycode
	if key == 0:
		key = event.keycode
	if key == KEY_SPACE:
		if event.pressed:
			interacted.emit()
		get_viewport().set_input_as_handled()
		return
	if key not in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]:
		return
	if event.pressed:
		if key not in held_keys:
			held_keys.append(key)
	else:
		held_keys.erase(key)
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if KEY_A in held_keys or KEY_LEFT in held_keys:
		direction.x -= 1.0
	if KEY_D in held_keys or KEY_RIGHT in held_keys:
		direction.x += 1.0
	if KEY_W in held_keys or KEY_UP in held_keys:
		direction.y -= 1.0
	if KEY_S in held_keys or KEY_DOWN in held_keys:
		direction.y += 1.0
	velocity = direction.normalized() * movement_speed
	move_and_slide()
