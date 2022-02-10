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
onready var error_popup =$HUD/UIControl/ErrorPopup



signal game_ended
signal game_started

var shuffling : bool
var game_won : bool
var press_and_hold : bool
var current_picture : String
var previous_pictures : Array
var start_time : int
var current_time : int
var paused_time : int
var restart_time : int
var last_clicked_tile
var load_picture_attempts : int
var repeat_threshold : int = 5
var moves : int
var dirs = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]


func _unhandled_input(event):
	var dir
	if event is InputEventKey and event.is_pressed():
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
				if !OS.has.feature("HTML5"):
					get_tree().quit()
			elif grid.can_move:
				hud.return_to_menu()
				set_process(false)
				clear_board()
				
		if event.scancode == KEY_T:
			Globals.set_hints_display(!Globals.display_hints)
			toggle_label_hints()
		
		if event.scancode == KEY_R:
			Globals.set_reference_display(!Globals.display_reference)
			toggle_reference_display()
		
		else:
			match event.scancode:
				KEY_UP, KEY_W:
					dir = Vector2(0, -1)
				KEY_DOWN, KEY_S:
					dir = Vector2(0, 1)
				KEY_RIGHT, KEY_D:
					dir = Vector2(1, 0)
				KEY_LEFT, KEY_A:
					dir = Vector2(-1, 0)
			if dir:
				grid.move_tile(dir)
		
	if event is InputEventScreenTouch:
		if event.is_pressed():
			var pos = picture_container.to_local(event.position)
			last_clicked_tile = grid.world_to_map(pos)

			if last_clicked_tile == null or !grid.get_used_cells().has(last_clicked_tile):
				return

			press_and_hold = false

			click_timer.start()
		else:
			click_timer.stop()
			if !press_and_hold and last_clicked_tile != null:
				var valid_move = grid.can_move_cell(last_clicked_tile)
				if valid_move:
					grid.move_tile(valid_move)

	if event is InputEventScreenDrag:
		if !grid.can_drag or event.relative.length() < 10:
			return

		last_clicked_tile = null
		dir = event.relative.normalized()

		for direction in dirs:
			if dir.dot(direction) > 0.85:
				grid.move_tile(direction)
				break
		

func _ready():
	Globals.connect("start_game", self, "start_game")
	Globals.connect("reference_display_toggled", self, "toggle_reference_display")
	Globals.connect("toggle_labels", self, "toggle_label_hints")
	hud.connect("next_picture", self, "_on_NextPictureButton_pressed")
	hud.connect("quit_to_menu", self, "_on_QuitButton_pressed")
	connect("game_started", Globals, "_on_Game_started")
	connect("game_ended", Globals, "_on_Game_ended")
	game_won = false
	load_picture_attempts = 0
	set_process(false)

func _process(_delta):
	update_time_label()
	
func update_time_label():
	current_time = paused_time + OS.get_unix_time() - restart_time
	var minutes = floor(current_time / 60.0)
	var seconds = current_time % 60
	hud.update_time_label(minutes, seconds)
	
func start_game():
	moves = 0
	load_picture()		
	
func load_picture(failed_load : bool = false):
	for tile in picture_container.get_children():
		tile.queue_free()
	
	var img : Texture
	
	if failed_load:
		img = load_default_image()
	
	else:
		if Globals.use_built_in_images and ! Globals.use_custom_images:
			img = load_default_image()
		elif !Globals.use_built_in_images and Globals.use_custom_images:
			img = load_custom_image()
		elif Globals.use_built_in_images and Globals.use_custom_images:
			randomize()
			if randf() < 0.5:
				img = load_default_image()
			else:
				img = load_custom_image()

	
	if img != null:
		prepare_picture(img)
	else:
		load_picture(true)

func prepare_picture(img):
		var w : int = clamp(img.get_width(), 0, 960)
		var h : int = clamp(img.get_height(), 0, 960)
		
		create_tiles(img, Globals.GRID_SIZE)
		picture_container.position = Vector2((1920 - w - Globals.GRID_SIZE * Globals.GAP) / 2.0,  (1080 - h - Globals.GRID_SIZE * Globals.GAP) / 2.0)

		next_quit_buttons.hide()
		hud.reset_stats()
		hud.stats_container.show()
		
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
	if previous_pictures.size() > repeat_threshold:
		previous_pictures.pop_front()
	var img = load(current_picture)
	info_label.text = Globals.captions[Globals.default_pictures.find(current_picture)]
	return img
	
func load_custom_image():
	var attempts = 0
	if Globals.custom_images.size() == 0:
		var img = load_default_image()
		return img

	randomize()
	current_picture = Globals.custom_images[randi() % Globals.custom_images.size()]
	if Globals.custom_images.size() > repeat_threshold:
		while previous_pictures.has(current_picture):
			if attempts > 10:
				var img = load_default_image()
				return img
			current_picture = Globals.custom_images[randi() % Globals.custom_images.size()]
			attempts += 1
		previous_pictures.push_back(current_picture)
		if previous_pictures.size() > repeat_threshold:
			previous_pictures.pop_front()
	var img = Image.new()
	var err = img.load(current_picture)
	if err != OK:
		load_picture_attempts += 1
		if load_picture_attempts > 5:
			return null
		else:
			load_custom_image()
	else:	
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		var min_size = min(tex.get_width(), tex.get_height())

		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = tex
		atlas_tex.region = Rect2(0, 0, min_size, min_size)
		info_label.text = ""
		return atlas_tex
	
func create_tiles(image : Texture, grid_size : int):
	var tile_width = floor(clamp(image.get_width(), 0, 960) / grid_size)
	var tile_height = floor(clamp(image.get_height(), 0, 960) / grid_size)

	grid.init(grid_size)
	grid.set_cell_size(Vector2(tile_width + 5, tile_height + 5))

	for i in range(grid_size):
		for j in range(grid_size):
			var img = image.duplicate()
			var tile = tile_scene.instance()
			picture_container.add_child(tile)
			var index = tile.setup(img, grid_size, i, j)
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
	grid.can_move = false
	grid.can_drag = false
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
	yield(tween, "tween_completed")
	grid.can_move = true

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
	if grid.shuffling:
		return
	moves += 1
	hud.update_move_count(moves)
	var win = grid.check_for_win()
	if !win:
		grid.can_move = true
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
	if last_clicked_tile == null:
		return
	if Globals.rotations_enabled:
		grid.rotate(last_clicked_tile)
	else:
		var valid_move = grid.can_move_cell(last_clicked_tile)
		if valid_move:
			grid.move_tile(valid_move)

func _on_DragDelayTimer_timeout():
	grid.can_drag = true
