extends Node2D

var trail_scene = preload("res://scenes/trail.tscn")

onready var sprite = $Pivot/TileSprite
onready var pivot = $Pivot
onready var tween = $Tween
onready var label = $Label
onready var frame = $Pivot/TileSprite/Frame


var index : int
var initial_index : int
var initial_scale : Vector2
var size : int

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
	var w = image.region.size.x / grid_size
	var h = image.region.size.y / grid_size
	var stretch_ratio = 960.0 / image.region.size.x
	
	size = grid_size
	sprite.texture = image
	sprite.region_rect = Rect2(x * w, y * h, w, h)

	index = y * grid_size + x + 1
	if index == grid_size * grid_size:
		index = 0

	label.get("custom_fonts/font").set_size(clamp(96 / Globals.GRID_SIZE, 12, 24))
	call_deferred("set_label", str(index), w)

	sprite.scale *= stretch_ratio
	frame.scale *= w / 300
	initial_scale = sprite.scale

	w *= stretch_ratio
	h *= stretch_ratio

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
			t.emission_rect_extents = 0.8 * Vector2(960.0 / size * 0.5, 960.0 / size * 0.5)
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
