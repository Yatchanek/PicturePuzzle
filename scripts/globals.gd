extends Node

var GRID_SIZE = 4
var GAP = 4
var default_pictures =[
"res://assets/pictures/picture_01.jpg", "res://assets/pictures/picture_02.jpg",
"res://assets/pictures/picture_03.jpg", "res://assets/pictures/picture_04.jpg",
"res://assets/pictures/picture_05.jpg", "res://assets/pictures/picture_06.jpg", 
"res://assets/pictures/picture_07.jpg", "res://assets/pictures/picture_08.jpg",
"res://assets/pictures/picture_09.jpg", "res://assets/pictures/picture_10.jpg",
"res://assets/pictures/picture_11.jpg", "res://assets/pictures/picture_12.jpg",
]
var custom_pictures = []

var display_hints = true
var display_reference = true
var enable_rotations = false
var game_in_progress = false
var grid_size_changed = false
var use_custom_pictures = false

signal start_game
signal reference_display_toggled
signal toggle_labels

func _ready():
	var f = File.new()
	if f.file_exists("user://custom_pictures.dat"):
		f.open("user://custom_pictures.dat", File.READ)
		custom_pictures = f.get_var()
		f.close()

func set_grid_size(value):
	GRID_SIZE = value
	
func set_hints_display(value):
	display_hints = value
	emit_signal("toggle_labels")
			
	
func set_reference_display(value):
	if value != display_reference:
		display_reference = value
		emit_signal("reference_display_toggled")
		

func set_rotations(value):
	enable_rotations = value

func start():
	emit_signal("start_game")

func _on_Game_started():
	game_in_progress = true

func _on_Game_ended():
	game_in_progress = false

func save_custom_pictures():
	var f = File.new()
	f.open("user://custom_pictures.dat", File.WRITE)
	f.store_var(custom_pictures)
	f.close()
