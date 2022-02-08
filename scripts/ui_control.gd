extends Control

var thumbnail_scene = preload("res://scenes/thumbnail.tscn")

onready var settings_panel = $Settings
onready var tab_container = $Settings/TabContainer
onready var grid_size_slider = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/HBoxContainer/GridSizeSlider
onready var hint_display_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/HintDisplayButton
onready var reference_display_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/ReferenceDisplayButton2
onready var rotation_toggle_button = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/RotationButton
onready var master_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer/MasterVolumeSlider
onready var sfx_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer2/SFXVolumeSlider
onready var music_volume_slider = $Settings/TabContainer/Audio/MarginContainer/GridContainer/HBoxContainer3/MusicVolumeSlider
onready var fullscreen_button = $Settings/TabContainer/Video/MarginContainer/GridContainer/FullscreenModeButton
onready var time_label = $TimeLabelContainer/TimeLabel
onready var title_screen = $TitleScreen
onready var next_quit_buttons = $NextQuitButtonContainer
onready var reference_container = $ReferenceContainer
onready var info_label = $ReferenceContainer/ReferenceControl/InfoLabel
onready var instructions_panel = $Instructions
onready var warning_label = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/WarningLabel
onready var warning_label2 = $Settings/TabContainer/Gameplay/MarginContainer/GridContainer/WarningLabel2
onready var add_pictures_button = $TitleScreen/MarginContainer/VBoxContainer/AddCustomPicturesButton
onready var custom_pictures_tab = $"Settings/TabContainer/Browse Custom Pictures"
onready var thumbnail_grid = $"Settings/TabContainer/Browse Custom Pictures/MarginContainer/ScrollContainer/ThumbnailGrid"

signal next_picture
signal quit_to_menu

var thread = Thread.new()

func _ready():
	add_pictures_button.visible = !(OS.has_feature("HTML5") or OS.has_feature("Android") or OS.has_feature("iOS"))
	if !add_pictures_button.visible:
		tab_container.set_tab_hidden(3, true)

func update_time_label(minutes, seconds):
	time_label.text = "%02d:%02d" % [minutes, seconds]

func reset_time_label():
	time_label.text = "00:00"
	
func return_to_menu():
	reset_time_label()
	reference_container.hide()
	next_quit_buttons.hide()
	time_label.hide()
	title_screen.show()

func _on_StartGameButton_pressed():
	title_screen.hide()
	time_label.show()
	info_label.show()
	Globals._on_Game_started()


func _on_SettingsButton_pressed():
	settings_panel.popup()


func _on_GridSizeSlider_value_changed(value):
	Globals.GRID_SIZE = value
	if Globals.game_in_progress:
		warning_label.text = "*Grid size change will take effect from the next game."

func _on_HintDisplayButton_toggled(button_pressed):
	Globals.set_hints_display(button_pressed)


func _on_ReferenceDisplayButton2_toggled(button_pressed):
	Globals.set_reference_display(button_pressed)


func _on_RotationButton_toggled(button_pressed):
	Globals.set_rotations(button_pressed)
	if Globals.game_in_progress:
		var status : String = "enabled" if button_pressed else "disabled"
		warning_label2.text = "*Rotations will be %s from the next game." % status


func _on_FullscreenModeButton_toggled(button_pressed):
	OS.window_fullscreen = button_pressed


func _on_MasterVolumeSlider_value_changed(value):
	Sounds.set_master_volume(value)


func _on_SFXVolumeSlider_value_changed(value):
	Sounds.set_sfx_volume(value)


func _on_MusicVolumeSlider_value_changed(value):
	Sounds.set_music_volume(value)


func _on_Button_pressed():
	settings_panel.hide()
	
	
func _on_Settings_about_to_show():
	warning_label.text = ""
	tab_container.current_tab = 0
	grid_size_slider.value = Globals.GRID_SIZE
	hint_display_button.pressed = Globals.display_hints
	reference_display_button.pressed = Globals.display_reference
	rotation_toggle_button.pressed = Globals.enable_rotations
	master_volume_slider.value = AudioServer.get_bus_volume_db(0)
	sfx_volume_slider.value = AudioServer.get_bus_volume_db(1)
	music_volume_slider.value = AudioServer.get_bus_volume_db(2)
	fullscreen_button.pressed = OS.is_window_fullscreen() 


func _on_NextButton_pressed():
	emit_signal("next_picture")
	next_quit_buttons.hide()

func _on_QuitButton_pressed():
	emit_signal("quit_to_menu")
	next_quit_buttons.hide()
	reference_container.hide()
	info_label.hide()
	title_screen.show()


func _on_InstructionsButton_pressed():
	instructions_panel.popup()


func _on_InstructionsOKButton_pressed():
	instructions_panel.hide()


func _on_FileDialog_files_selected(paths):
	for path in paths:
		if !Globals.custom_pictures.has(path):
			Globals.custom_pictures.push_back(path)
	Globals.save_custom_pictures()


func _on_TabContainer_tab_changed(tab):
	if tab == 3 and thumbnail_grid.get_child_count() != Globals.custom_pictures.size():
		thumbnail_grid.columns = (thumbnail_grid.rect_size.x / 150) - 1
		thread.start(self, "prepare_thumbnails")


func prepare_thumbnails():
	for i in range(thumbnail_grid.get_child_count(), Globals.custom_pictures.size()):
		var tex = create_thumbnail(i)
	call_deferred("finish_making_thumbnails")

func finish_making_thumbnails():
	thread.wait_to_finish()
#	for thumbnail in thumbnail_grid.get_children():
#		#var b = Button.new()
#		thumbnail.get_node("Button").call_deferred("set_text", "Remove")
#		thumbnail.get_node("Button").call_deferred("set_anchors_and_margins_preset", Control.PRESET_CENTER_BOTTOM)
#		#b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
#		thumbnail.get_node("Button").connect("pressed", self, "_on_Thumbnail_button_pressed", [thumbnail])
#		#thumbnail.add_child(b)
			
func create_thumbnail(idx):
	var img = Image.new()
	img.load(Globals.custom_pictures[idx])
	
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img)
	
	var atlas_tex = AtlasTexture.new()
	var min_size = min(img_tex.get_width(), img_tex.get_height())
	
	atlas_tex.atlas = img_tex
	atlas_tex.region = Rect2(0, 0, min_size, min_size)

	var thumbnail = thumbnail_scene.instance()
	thumbnail.texture = atlas_tex
	thumbnail_grid.call_deferred("add_child", thumbnail)



func _on_Thumbnail_button_pressed(thumbnail):
	#var thumbnail = button.get_parent()
	Globals.custom_pictures.remove(thumbnail.get_index())
	thumbnail.queue_free()
	Globals.save_custom_pictures()

func _on_AddCustomPicturesButton_pressed():
	$FileDialog.popup()
