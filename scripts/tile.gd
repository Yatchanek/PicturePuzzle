extends Node2D

onready var sprite = $Pivot/Sprite
onready var pivot = $Pivot
onready var tween = $Tween
onready var label = $Label
onready var frame = $Pivot/Sprite/Frame

var index : int
var initial_index : int
var initial_scale : Vector2

signal rotation_finished
signal move_finished

func _ready():
	pass

func align():
	pass

func set_label(value: String) -> void:
	if value != "0":
		label.text = value
	label.rect_position = Vector2(5,5)
	label.rect_size += Vector2(25,5)
	label.visible = Globals.display_hints

func setup(image : Texture, grid_size: int, x: int, y: int) -> int:
	var w = image.get_width() / grid_size
	var h = image.get_height() / grid_size
	
	sprite.texture = image
	sprite.region_rect = Rect2(x * w, y * h, w, h)
	index = y * grid_size + x + 1
	if index == grid_size * grid_size:
		index = 0
	w *= 600.0 / image.get_width()
	h *= 600.0 / image.get_width()
	
	sprite.scale *= 600.0 / image.get_width()
	initial_scale = sprite.scale
	frame.scale *= w / 300.0 / sprite.scale.x
	
	set_label(str(index))
	pivot.position = Vector2(w / 2 + Globals.GAP, h / 2 + Globals.GAP)
	position = Vector2(x * (w + Globals.GAP), y * (h + Globals.GAP))
	initial_index = index
	return index

func move(pos, speed):
	if speed > 0:
		tween.interpolate_property(self, "position", position, pos, speed, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		tween.start()
	else:
		position = pos

func rotate_self(speed : float = 0.25):
	if index != 0:
		if speed > 0:
			get_parent().call_deferred("move_child", self, Globals.GRID_SIZE * Globals.GRID_SIZE - 1)
			tween.interpolate_property(sprite, "scale", initial_scale, initial_scale * 1.25, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.interpolate_property(pivot, "rotation_degrees", pivot.rotation_degrees, pivot.rotation_degrees + 90, speed * 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.interpolate_property(sprite, "scale", initial_scale * 1.25, initial_scale, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, speed)
			tween.start()
		else:
			pivot.rotation_degrees += 90
			_on_Tween_tween_completed(pivot, ":rotation_degrees")


func _on_Tween_tween_completed(_object, key):
	if key == ":position":

		emit_signal("move_finished")

	if key == ":rotation_degrees":
		if int(pivot.rotation_degrees) % 360 == 0:
			pivot.rotation_degrees = 0
		index = initial_index + (int(pivot.rotation_degrees) % 360)
		emit_signal("rotation_finished")
