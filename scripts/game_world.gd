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
onready var click_timer = $ClickTimer

signal game_ended
signal game_started


var can_move : bool
var game_won : bool
var can_drag : bool
var press_and_hold : bool
var current_picture : String
var previous_pictures : Array
var start_time : int
var current_time : int
var paused_time : int
var restart_time : int
var last_clicked_tile
var blank = Vector2.ZERO
var dupa = "aaa"
var click_pos

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
			if event.scancode == KEY_ESCAPE:
				if hud.title_screen.visible:
					get_tree().quit()
				elif can_move:
					hud.return_to_menu()
					set_process(false)
					clear_board()
		
	if event is InputEventScreenTouch:
		if event.is_pressed():
			if !can_move:
				return
				
			var pos = picture_container.to_local(event.position)
			last_clicked_tile = grid.world_to_map(pos)

			if last_clicked_tile == null or !grid.get_used_cells().has(last_clicked_tile):
				return
			blank = grid.find_blank_neighbour(last_clicked_tile)
			press_and_hold = false

			click_timer.start()
		else:
			if !can_move:
				return
			click_timer.stop()
			if !press_and_hold and last_clicked_tile != null and blank != null:
				can_move = false
				grid.switch(last_clicked_tile, blank)

	if event is InputEventScreenDrag:
		if !can_move or !can_drag:
			return
		if event.relative.length() < 10:
			return
		var blank_tile = grid.find_blank_tile()
		var neighbours = grid.get_valid_neighbours(blank_tile)
		last_clicked_tile = null
		blank = null
		for neighbour in neighbours:
			if event.relative.normalized().dot(grid.find_direction(blank_tile, neighbour)) > 0.5:
				can_move = false
				can_drag = false
				grid.switch(neighbour, blank_tile)
				return


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
	can_drag = false
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
#		if randf() < 0.5:
#			img = load_default_image()
#		else:
#			img = load_custom_image()
#		pass
#	else:
		
	var w : int = clamp(img.get_width(), 0, 960)
	var h : int = clamp(img.get_height(), 0, 960)
	
	create_tiles(img, Globals.GRID_SIZE)
	picture_container.position = Vector2((1920 - w - Globals.GRID_SIZE * Globals.GAP) / 2.0,  (1080 - h - Globals.GRID_SIZE * Globals.GAP) / 2.0)

	next_quit_buttons.hide()
	hud.reset_time_label()
	
	if Globals.display_reference:
		picture_container.position.x += 350
		reference.texture = img
		reference_container.show()
	
func load_default_image():
	randomize()
	current_picture = Globals.default_pictures[randi() % Globals.default_pictures.size()]
	while previous_pictures.has(current_picture):
		current_picture = Globals.default_pictures[randi() % Globals.default_pictures.size()]
	previous_pictures.push_back(current_picture)
	if previous_pictures.size() > 5:
		previous_pictures.pop_front()
	var img = load(current_picture)
	info_label.text = Globals.captions[Globals.default_pictures.find(current_picture)]
	return img
	
func load_custom_image():
	if Globals.custom_pictures.size() == 0:
		load_default_image()
		return

	randomize()
	current_picture = Globals.custom_pictures[randi() % Globals.custom_pictures.size()]
	while previous_pictures.has(current_picture):
		current_picture = Globals.custom_pictures[randi() % Globals.custom_pictures.size()]
	previous_pictures.push_back(current_picture)
	
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
	var tile_width = floor(clamp(image.get_width(), 0, 960) / grid_size)
	var tile_height = floor(clamp(image.get_height(), 0, 960) / grid_size)

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
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x + 350, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
		tween.start()
		if Globals.game_in_progress:
			reference_container.show()
		if Globals.game_in_progress:
			reference.texture = picture_container.get_child(0).sprite.texture
	else:
		tween.interpolate_property(picture_container, "position:x", picture_container.position.x, picture_container.position.x - 350, 1, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
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
		$DragDelayTimer.start()
	else:
		game_won = true

		launch_fireworks()
		
		emit_signal("game_ended")
	
		set_process(false)
	
	
func _on_Shuffle_completed():
	game_won = false
	start_time = OS.get_unix_time()
	restart_time = start_time
	paused_time = 0
	set_process(true)
	can_move = true
	can_drag = true

func _on_Settings_popup_hide():
	if Globals.game_in_progress:
		restart_time = OS.get_unix_time()
		set_process(true)


func _on_NextPictureButton_pressed():
	for button in get_tree().get_nodes_in_group("NextQuitButtons"):
		button.disabled = true
	clear_board()
	emit_signal("game_started")



func _on_QuitButton_pressed():
	for button in get_tree().get_nodes_in_group("NextQuitButtons"):
		button.disabled = true
	clear_board()


func _on_ClickTimer_timeout():
	press_and_hold = true
	if !can_move:
		return
	if last_clicked_tile == null or blank == null:
		return
	can_move = false
	if Globals.rotations_enabled:
		grid.rotate(last_clicked_tile)
	else:
		grid.switch(last_clicked_tile, blank)


func _on_DragDelayTimer_timeout():
	can_drag = true
