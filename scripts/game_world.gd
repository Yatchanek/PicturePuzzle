extends Node2D

var firework_scene = preload("res://scenes/fireworks.tscn")
var tile_scene : PackedScene = preload("res://scenes/tile.tscn")

onready var picture_container : Node = $PictureContainer
onready var reference : Node = $HUD/UIControl/ReferenceContainer/ReferenceControl/Reference
onready var reference_container : Node = $HUD/UIControl/ReferenceContainer
onready var tween : Node = $Tween
onready var next_quit_buttons : Node = $HUD/UIControl/NextQuitButtonContainer
onready var hud : Node = $HUD/UIControl
onready var grid = $Grid
onready var info_label = $HUD/UIControl/ReferenceContainer/ReferenceControl/InfoLabel
onready var firework_layer = $FireworkLayer


signal game_ended
signal game_started


var can_move : bool
var game_won : bool
var current_picture : int
var previous_pictures : Array
var previous_custom_picture : int
var start_time : int
var current_time : int
var paused_time : int
var restart_time : int

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.scancode == KEY_P:
				if !hud.settings_panel.visible:
					paused_time = current_time
					set_process(false)
					hud.settings_panel.popup()
				else:
					hud.settings_panel.hide()
					restart_time = OS.get_unix_time()
					set_process(true)			
			if event.scancode == KEY_ESCAPE and can_move:
				if hud.title_screen.visible:
					get_tree().quit()
				else:
					hud.return_to_menu()
					set_process(false)
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
						grid.switch(cell, blank, 0.25, true)

			if event.button_index == BUTTON_RIGHT and Globals.enable_rotations:
				if !game_won:
					var mouse_pos : Vector2 = picture_container.to_local(get_global_mouse_position())
					var cell : Vector2 = grid.world_to_map(mouse_pos)
					can_move = false
					grid.rotate(cell)
	
func _ready():
	Globals.connect("start_game", self, "load_picture")
	Globals.connect("reference_display_toggled", self, "toggle_reference_display")
	Globals.connect("toggle_labels", self, "toggle_label_hints")
	hud.connect("next_picture", self, "_on_NextPictureButton_pressed")
	hud.connect("quit_to_menu", self, "_on_QuitButton_pressed")
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
	hud.update_time_label(minutes, seconds)
	
	
func load_picture():
	for tile in picture_container.get_children():
		tile.queue_free()
		
	randomize()
	var img = load_default_image()
#	if Globals.use_custom_pictures and Globals.custom_pictures.size() > 0:	
#		if randf() < 0.000005:
#			img = load_default_image()
#		else:
#			img = load_custom_image()
#		pass
#	else:
		
	var w : int = clamp(img.get_width(), 0, 768)
	var h : int = clamp(img.get_height(), 0, 768)
	
	create_tiles(img, Globals.GRID_SIZE)
	picture_container.position = Vector2((1600 - w - Globals.GRID_SIZE * Globals.GAP) / 2.0,  (900 - h - Globals.GRID_SIZE * Globals.GAP) / 2.0)

	emit_signal("game_started")
	game_won = false
	next_quit_buttons.hide()
	hud.reset_time_label()
	
	if Globals.display_reference:
		picture_container.position.x += 280
		reference.texture = img
		reference_container.show()
	
func load_default_image():
	randomize()
	current_picture = randi() % Globals.default_pictures.size()
	while previous_pictures.has(current_picture):
		current_picture = randi() % Globals.default_pictures.size()
	previous_pictures.push_back(current_picture)
	if previous_pictures.size() > 5:
		previous_pictures.pop_front()
	var img = load(Globals.default_pictures[current_picture])
	info_label.text = Globals.captions[current_picture]
	return img
	
#func load_custom_image():
#	randomize()
#	current_picture = randi() % Globals.custom_pictures.size()
#	while current_picture == previous_default_picture:
#		current_picture = randi() % Globals.custom_pictures.size()
#
#	var img = Image.new()
#	img.load(Globals.custom_pictures[current_picture])
#
#	var tex = ImageTexture.new()
#	tex.create_from_image(img)
#	var min_size = min(tex.get_width(), tex.get_height())
#
#	var atlas_tex = AtlasTexture.new()
#	atlas_tex.atlas = tex
#	atlas_tex.region = Rect2(0, 0, min_size, min_size)
#
#	return atlas_tex
	
func create_tiles(image : Texture, grid_size : int):
	var tile_width = floor(clamp(image.get_width(), 0, 768) / grid_size)
	var tile_height = floor(clamp(image.get_height(), 0, 768) / grid_size)

	grid.init(grid_size)
	grid.set_cell_size(Vector2(tile_width + 5, tile_height + 5))

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
	yield(get_tree().create_timer(0.5), "timeout")
	grid.shuffle()

func clear_board():
	for tile in picture_container.get_children():
		tile.queue_free()	

func toggle_reference_display():
	if Globals.display_reference:
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x + 280, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		tween.start()
		if Globals.game_in_progress:
			reference_container.show()
		if Globals.game_in_progress:
			reference.texture = picture_container.get_child(0).sprite.texture
	else:
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x - 280, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		tween.start()
		reference_container.hide()

func toggle_label_hints():
	for tile in picture_container.get_children():
		tile.label.visible = Globals.display_hints

func launch_fireworks():
	for _i in range (10 + randi() % 5):
		var firework = firework_scene.instance()
		firework_layer.add_child(firework)
		firework.global_position.x = rand_range(100, get_viewport().size.x - 100)
		firework.global_position.y = rand_range(100, get_viewport().size.y - 100)
		firework.emitting = true
		yield(get_tree().create_timer(0.15), "timeout")
	
	next_quit_buttons.show()
	for button in get_tree().get_nodes_in_group("NextQuitButtons"):
		button.disabled = false
	
func _on_Tile_move_finished():
	var win = grid.check_for_win()
	if !win:
		can_move = true
	else:
		game_won = true

		launch_fireworks()
		
		emit_signal("game_ended")
	
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
