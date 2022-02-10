extends Control

var thumbnail_scene = preload("res://scenes/thumbnail.tscn")

onready var title_screen = $TitleScreen
onready var settings_panel = $Settings
onready var tab_container = $Settings/TabContainer
onready var thumbnail_grid = $CustomPictures/Panel/MarginContainer/ScrollContainer/ThumbnailGrid
onready var custom_images_panel = $CustomPictures
onready var reference_container = $ReferenceContainer
onready var instructions_panel = $Instructions
onready var file_dialog = $CustomPictures/Panel/FileDialog
onready var error_popup = $ErrorPopup
onready var stats_container = $StatsContainer

onready var grid_size_slider = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/HBoxContainer/GridSizeSlider
onready var hint_display_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/HintDisplayButton
onready var reference_display_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/ReferenceDisplayButton2
onready var rotation_toggle_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/RotationButton
onready var custom_image_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/CustomPictureButton
onready var built_in_image_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/BuiltInPictureButton
onready var master_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer/MasterVolumeSlider
onready var sfx_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer2/SFXVolumeSlider
onready var music_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer3/MusicVolumeSlider
onready var fullscreen_button = $Settings/TabContainer/Video/MarginContainer/GridContainer/FullscreenModeButton
onready var add_images_button = $TitleScreen/MarginContainer/VBoxContainer/AddCustomPicturesButton
onready var next_quit_buttons = $NextQuitButtonContainer
onready var quit_game_button = $TitleScreen/MarginContainer/VBoxContainer/QuitGameButton

onready var no_images_label = $CustomPictures/Panel/MarginContainer/NoImageLabel
onready var info_label = $ReferenceContainer/ReferenceControl/InfoLabel
onready var time_label = $StatsContainer/HBoxContainer/TimeLabel
onready var move_counter_label = $StatsContainer/HBoxContainer/MoveCounterLabel
onready var warning_label = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/WarningLabel
onready var warning_label2 = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/WarningLabel2

onready var spawner = $TileSpawner




signal next_picture
signal quit_to_menu

var thread = Thread.new()

func _ready():
	add_images_button.visible = !(OS.has_feature("HTML5") or OS.has_feature("Android") or OS.has_feature("iOS"))
	quit_game_button.visible = add_images_button.visible
		

func update_time_label(minutes, seconds):
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func update_move_count(value):
	move_counter_label.text = "Moves: %s" % str(value)

func reset_stats():
	time_label.text = "Time: 00:00"
	move_counter_label.text = "Moves: 0"


func return_to_menu():
	reset_stats()
	reference_container.hide()
	next_quit_buttons.hide()
	stats_container.hide()
	title_screen.show()
	spawner.show()
	spawner.spawn()

func display_thumbnails():
	no_images_label.visible = Globals.custom_images.size() == 0	
	if thumbnail_grid.get_child_count() != Globals.custom_images.size():
		thumbnail_grid.columns = (thumbnail_grid.rect_size.x / 150) - 1
		thread.start(self, "prepare_thumbnails")

#Create thumbails for custom images
func prepare_thumbnails():
	for i in range(thumbnail_grid.get_child_count(), Globals.custom_images.size()):
		create_thumbnail(i)
	call_deferred("finish_making_thumbnails")

func finish_making_thumbnails():
	thread.wait_to_finish()
	no_images_label.visible = thumbnail_grid.get_child_count() == 0
			
func create_thumbnail(idx):
	var img = Image.new()
	var err = img.load(Globals.custom_images[idx])
	if err == OK:
		var img_tex = ImageTexture.new()
		img_tex.create_from_image(img)
		
		var atlas_tex = AtlasTexture.new()
		var min_size = min(img_tex.get_width(), img_tex.get_height())
		
		atlas_tex.atlas = img_tex
		atlas_tex.region = Rect2(0, 0, min_size, min_size)

		var thumbnail = thumbnail_scene.instance()
		thumbnail.texture = atlas_tex
		thumbnail.get_node("Button").connect("pressed", self, "_on_Thumbnail_button_pressed", [thumbnail])
		thumbnail_grid.call_deferred("add_child", thumbnail)

#Set buttons	
func _on_Settings_about_to_show():
	warning_label.text = ""
	tab_container.current_tab = 0
	grid_size_slider.value = Globals.GRID_SIZE
	hint_display_button.pressed = Globals.display_hints
	reference_display_button.pressed = Globals.display_reference
	rotation_toggle_button.pressed = Globals.enable_rotations
	custom_image_button.pressed = Globals.use_custom_images
	custom_image_button.disabled = Globals.custom_images.size() == 0
	built_in_image_button.pressed = Globals.use_built_in_images
	built_in_image_button.disabled = !custom_image_button.pressed
	master_volume_slider.value = AudioServer.get_bus_volume_db(0)
	sfx_volume_slider.value = AudioServer.get_bus_volume_db(1)
	music_volume_slider.value = AudioServer.get_bus_volume_db(2)
	fullscreen_button.pressed = OS.is_window_fullscreen() 

#Start Game
func _on_StartGameButton_pressed():
	title_screen.hide()
	spawner.hide()
	info_label.show()
	Globals._on_Game_started()

#Settings
func _on_SettingsButton_pressed():
	settings_panel.popup()

#Change grid size
func _on_GridSizeSlider_value_changed(value):
	Globals.GRID_SIZE = value
	if Globals.game_in_progress:
		warning_label.text = "*Grid size change will take effect from the next game."

#Toggle hints
func _on_HintDisplayButton_toggled(button_pressed):
	Globals.set_hints_display(button_pressed)

#Toggle reference display
func _on_ReferenceDisplayButton2_toggled(button_pressed):
	Globals.set_reference_display(button_pressed)

#Toggle rotations
func _on_RotationButton_toggled(button_pressed):
	Globals.set_rotations(button_pressed)
	if Globals.game_in_progress:
		var status : String = "enabled" if button_pressed else "disabled"
		warning_label2.text = "*Rotations will be %s from the next game." % status


#Toggle built-in images
func _on_BuiltInPictureButton_toggled(button_pressed):
	Globals.set_built_in_images_usage(button_pressed)

#Toggle custom images
func _on_CustomPictureButton_toggled(button_pressed):
	Globals.set_custom_images_usage(button_pressed)
	built_in_image_button.disabled = !button_pressed
	if !button_pressed and !built_in_image_button.pressed:
		built_in_image_button.pressed = true
		Globals.set_built_in_images_usage(true)
	
func _on_FullscreenModeButton_toggled(button_pressed):
	OS.window_fullscreen = button_pressed


func _on_MasterVolumeSlider_value_changed(value):
	Sounds.set_master_volume(value)


func _on_SFXVolumeSlider_value_changed(value):
	Sounds.set_sfx_volume(value)


func _on_MusicVolumeSlider_value_changed(value):
	Sounds.set_music_volume(value)

#Close settings
func _on_Button_pressed():
	settings_panel.hide()
	
#Next picture
func _on_NextButton_pressed():
	emit_signal("next_picture")
	next_quit_buttons.hide()

#Quit to menu
func _on_QuitButton_pressed():
	emit_signal("quit_to_menu")
	next_quit_buttons.hide()
	reference_container.hide()
	stats_container.hide()
	info_label.hide()
	title_screen.show()

#Quit game
func _on_QuitGameButton_pressed():
	get_tree().quit()

#Show instrucions
func _on_InstructionsButton_pressed():
	instructions_panel.popup()

#Close instructions
func _on_InstructionsOKButton_pressed():
	instructions_panel.hide()

#Add filepaths to custom pictures
func _on_FileDialog_files_selected(paths):
	for path in paths:
		if !Globals.custom_images.has(path):
			Globals.custom_images.push_back(path)
	Globals.save_custom_images()
	display_thumbnails()

#Remove a custom picture and its thumbnail
func _on_Thumbnail_button_pressed(thumbnail):
	Globals.custom_images.remove(thumbnail.get_index())
	thumbnail.queue_free()
	Globals.save_custom_images()

#Open custom images panel
func _on_AddCustomPicturesButton_pressed():
	custom_images_panel.popup()
	display_thumbnails()

#Open file dialog to add images
func _on_AddPicturesButton_pressed():
	file_dialog.show()
	file_dialog.invalidate()

#Close custom images panel
func _on_PicturesPanelCloseButton_pressed():
	custom_images_panel.hide()
	for thumbnail in thumbnail_grid.get_children():
		thumbnail.queue_free()

#Close error popup
func _on_ErrorCloseButton_pressed():
	error_popup.hide()





