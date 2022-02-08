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

var captions = [
	"Statue of Nio, Japan", "Waterfall in Japan", "\"Mona Lisa\" by Leonardo da Vinci, ca. 1503-1506",
	"City Hall in Poznan, Poland", "Pansy flower", "\"Great Wave off Kanagawa\" \nby Katsushika Hokusai, ca. 1830",
	"Fokker Dr.I", "Freshwater fish tank", "Pearl gourami", "Ancistrus fish",
	"\"Union of Lublin\" by Jan Matejko, 1869 ", "\"Battle of Grunwald\" by Jan Matejko, 1878",
	"\"The Scream\" by Edvard Munch, 1893"
]

var display_hints = true
var display_reference = true
var enable_rotations = false
var rotations_enabled = false
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


func _on_Game_started():
	rotations_enabled = enable_rotations
	game_in_progress = true
	emit_signal("start_game")

func _on_Game_ended():
	game_in_progress = false

func save_custom_pictures():
	var f = File.new()
	f.open("user://custom_pictures.dat", File.WRITE)
	f.store_var(custom_pictures)
	f.close()
