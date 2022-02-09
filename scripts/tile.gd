extends Node2D

var trail_scene = preload("res://scenes/trail.tscn")

onready var sprite = $Pivot/TileSprite
onready var pivot = $Pivot
onready var tween = $Tween
onready var label = $Label
onready var frame = $Pivot/TileSprite/Frame
onready var border = $Pivot/TileSprite/Border

var index : int
var initial_index : int
var initial_scale : Vector2

signal rotation_finished
signal move_finished

func _ready():
	pass

func align():
	pass

func set_label(value: String, w : int) -> void:
	if value != "0":
		label.text = value
	label.rect_position = Vector2(w * 0.05 ,w * 0.05)
	label.visible = Globals.display_hints

	label.rect_size.x = label.rect_size.y
	
func setup(image : Texture, grid_size: int, x: int, y: int) -> int:
	var w = image.get_width() / grid_size
	var h = image.get_height() / grid_size
	
	sprite.texture = image
	sprite.region_rect = Rect2(x * w, y * h, w, h)
	index = y * grid_size + x + 1
	if index == grid_size * grid_size:
		index = 0
	w *= 960.0 / image.get_width()
	h *= 960.0 / image.get_width()
	
	label.get("custom_fonts/font").set_size(clamp(96 / Globals.GRID_SIZE, 12, 24))
	call_deferred("set_label", str(index), w)
	
	sprite.scale *= 960.0 / image.get_width()
	initial_scale = sprite.scale
	frame.scale *= w / 300.0 / sprite.scale.x
	border.scale = frame.scale

	pivot.position = Vector2(w / 2 + Globals.GAP, h / 2 + Globals.GAP)
	position = Vector2(x * (w + Globals.GAP), y * (h + Globals.GAP))
	initial_index = index
	return index

func move(pos, speed, trail : bool = false):
	if speed > 0:
		tween.interpolate_property(self, "position", position, pos, speed, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		tween.start()
		if trail:
			var t = trail_scene.instance()
			add_child(t)
			move_child(t, 0)
			t.direction = (position - pos).normalized()
			t.position = pivot.position
			t.emission_rect_extents = 0.8 * Vector2(sprite.region_rect.size.x * 0.5 * sprite.scale.x, sprite.region_rect.size.x * 0.5 * sprite.scale.x)
			t.scale_amount = 0.03 - 0.0025 * Globals.GRID_SIZE
			t.amount -= Globals.GRID_SIZE
			t.emitting = true
		Sounds.play_effect(Sounds.SLIDE)
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
