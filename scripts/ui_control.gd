extends Control

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

signal next_picture
signal quit_to_menu

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
	Globals.start()


func _on_SettingsButton_pressed():
	settings_panel.popup()


func _on_GridSizeSlider_value_changed(value):
	Globals.GRID_SIZE = value
	

func _on_HintDisplayButton_toggled(button_pressed):
	Globals.set_hints_display(button_pressed)


func _on_ReferenceDisplayButton2_toggled(button_pressed):
	Globals.set_reference_display(button_pressed)


func _on_RotationButton_toggled(button_pressed):
	Globals.set_rotations(button_pressed)


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
	tab_container.current_tab = 0
	grid_size_slider = Globals.GRID_SIZE
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
