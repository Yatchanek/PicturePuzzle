extends Node2D

var firework_scene = preload("res://scenes/fireworks.tscn")

onready var picture_container : Node = $PictureContainer
onready var time_label : Node = $CanvasLayer/MarginContainer/TimeLabel
onready var reference : Node = $HUD/Reference/VBoxContainer/TextureRect
onready var reference_container : Node = $HUD/Reference
onready var tween = $Tween
onready var next_quit_buttons = $HUD/NextQuitButtons

var tile_scene : PackedScene = preload("res://scenes/tile.tscn")

signal game_ended
signal game_started

var grid
var can_move : bool
var game_won : bool
var current_picture : int
var previous_default_picture : int
var previous_custom_picture : int
var start_time : int
var current_time : int
var paused_time : int
var restart_time : int

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.scancode == KEY_P:
				paused_time = current_time
				set_process(false)
				$HUD/TitleScreen/Settings.popup()
			if event.scancode == KEY_ESCAPE:
				if $HUD/TitleScreen.visible:
					get_tree().quit()
				else:
					$HUD/TitleScreen.show()
					clear_board()
								
	elif event is InputEventMouseButton:
		if event.is_pressed() and can_move:
			if event.button_index == BUTTON_LEFT:
				if !game_won:
					var mouse_pos : Vector2 = picture_container.to_local(get_global_mouse_position())
					var cell : Vector2 = grid.world_to_map(mouse_pos)
					var blank = grid.find_blank_neighbour(cell)
					if blank != null:
						can_move = false
						grid.switch(cell, blank)

			if event.button_index == BUTTON_RIGHT and Globals.enable_rotations:
				if !game_won:
					var mouse_pos : Vector2 = picture_container.to_local(get_global_mouse_position())
					var cell : Vector2 = grid.world_to_map(mouse_pos)
					can_move = false
					grid.rotate(cell)
	
func _ready():
	Globals.connect("start_game", self, "load_picture")
	Globals.connect("reference_display_toggled", self, "toggle_reference_display")
	connect("game_started", Globals, "_on_Game_started")
	connect("game_ended", Globals, "_on_Game_ended")
	can_move = false
	game_won = false
	set_process(false)

func _process(_delta):
	update_time_label()
	
func update_time_label():
	current_time = paused_time + OS.get_unix_time() - restart_time
	var minutes = floor(current_time / 60.0)
	var seconds = current_time % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	
func load_picture():
	for tile in $PictureContainer.get_children():
		tile.queue_free()
		
	randomize()
	var img
	if Globals.use_custom_pictures and Globals.custom_pictures.size() > 0:	
		if randf() < 0.000005:
			img = load_default_image()
		else:
			img = load_custom_image()
	else:
		img = load_default_image()
		
	var w : int = clamp(img.get_width(), 0, 600)
	var h : int = clamp(img.get_height(), 0, 600)
	
	create_tiles(img, Globals.GRID_SIZE)
	picture_container.position = Vector2((1200 - w - Globals.GRID_SIZE * Globals.GAP) / 2.0,  (720 - h - Globals.GRID_SIZE * Globals.GAP) / 2.0)
	emit_signal("game_started")
	game_won = false
	next_quit_buttons.hide()
	time_label.text = "00:00"
	if Globals.display_reference:
		picture_container.position.x += 200
		reference.texture = img
		reference_container.show()
	
func load_default_image():
	randomize()
	current_picture = randi() % Globals.default_pictures.size()
	while current_picture == previous_default_picture:
		current_picture = randi() % Globals.default_pictures.size()
	previous_default_picture = current_picture
	var img = load(Globals.default_pictures[current_picture])
	return img
	
func load_custom_image():
	randomize()
	current_picture = randi() % Globals.custom_pictures.size()
	while current_picture == previous_default_picture:
		current_picture = randi() % Globals.custom_pictures.size()
	
	var img = Image.new()
	img.load(Globals.custom_pictures[current_picture])
	
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	var min_size = min(tex.get_width(), tex.get_height())
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2(0, 0, min_size, min_size)
	
	return atlas_tex
	
func create_tiles(image : Texture, grid_size : int):
	var tile_width = floor(clamp(image.get_width(), 0, 600) / grid_size)
	var tile_height = floor(clamp(image.get_height(), 0, 600) / grid_size)
	
	grid = Grid.new(grid_size)
	grid.set_cell_size(Vector2(tile_width + 5, tile_height + 5))
	grid.connect("shuffle_completed", self, "_on_Shuffle_completed")

	for i in range(grid_size):
		for j in range(grid_size):
			var tile = tile_scene.instance()
			picture_container.add_child(tile)
			var index = tile.setup(image, grid_size, i, j)
			if index == 0:
				tile.connect("move_finished", self, "_on_Tile_move_finished")
			else:
				tile.connect("rotation_finished", self, "_on_Tile_move_finished")
			grid.set_cell(i, j, tile.index)
			grid.map_cell(Vector2(i, j), tile)
			
	picture_container.get_child(picture_container.get_children().size() - 1).hide()
	grid.shuffle()

func clear_board():
	for tile in $PictureContainer.get_children():
		tile.queue_free()	

func toggle_reference_display():
	if Globals.display_reference:
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x + 200, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		tween.start()
		reference_container.show()
		if Globals.game_in_progress:
			reference.texture = picture_container.get_child(0).sprite.texture
	else:
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x - 200, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		tween.start()
		reference_container.hide()
	
func _on_Tile_move_finished():
	var win = grid.check_for_win()
	if !win:
		can_move = true
	else:
		game_won = true
		for _i in range (10 + randi() % 5):
			var firework = firework_scene.instance()
			add_child(firework)
			firework.position.x = rand_range(100, get_viewport().size.x - 100)
			firework.position.y = rand_range(100, get_viewport().size.y - 100)
			firework.emitting = true
			yield(get_tree().create_timer(0.15), "timeout")
		emit_signal("game_ended")
		
		next_quit_buttons.show()
		for button in get_tree().get_nodes_in_group("NextQuitButtons"):
			button.disabled = false
			
		can_move = true
		set_process(false)
	
	
func _on_Shuffle_completed():
	start_time = OS.get_unix_time()
	restart_time = start_time
	paused_time = 0
	set_process(true)
	can_move = true
	

func _on_Settings_popup_hide():
	if Globals.game_in_progress:
		restart_time = OS.get_unix_time()
		set_process(true)


func _on_NextPictureButton_pressed():
	for button in get_tree().get_nodes_in_group("NextQuitButtons"):
		button.disabled = true
	clear_board()
	load_picture()


func _on_QuitButton_pressed():
	for button in get_tree().get_nodes_in_group("NextQuitButtons"):
		button.disabled = true
	clear_board()
	$HUD/TitleScreen.show()
