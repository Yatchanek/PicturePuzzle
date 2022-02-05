extends Popup

var picure_preview = preload("res://scenes/picture_list_tile.tscn")

onready var grid_size_button = $TabContainer/Gameplay/MarginContainer/GridContainer/HBoxContainer/GridSizeButton
onready var number_hints_button = $TabContainer/Gameplay/MarginContainer/GridContainer/NumberHintsButton
onready var reference_button = $TabContainer/Gameplay/MarginContainer/GridContainer/ReferencePictureButton
onready var rotation_button = $TabContainer/Gameplay/MarginContainer/GridContainer/TileRotationButton
onready var warning_label = $TabContainer/Gameplay/MarginContainer/GridContainer/WarningLabel
onready var browse_grid_container = $"TabContainer/Browse Custom Pictures/MarginContainer/ScrollContainer/GridContainer"
onready var tab_container = $TabContainer
onready var display_mode_button = $"TabContainer/Video Options/MarginContainer/GridContainer/DisplayModeButton"
onready var master_volume_slider = $"TabContainer/Audio Options/MarginContainer/GridContainer/HBoxContainer/MasterVolumeSlider"
onready var sfx_volume_slider = $"TabContainer/Audio Options/MarginContainer/GridContainer/HBoxContainer2/SfxVolumeSlider"
onready var music_volume_slider = $"TabContainer/Audio Options/MarginContainer/GridContainer/HBoxContainer3/MusicVolumeSlider"


func _ready():
	pass
	
func _on_GridSizeButton_value_changed(value) -> void:
	Globals.set_grid_size(value)
	warning_label.show()	


func _on_NumberHintsButton_toggled(button_pressed) -> void:
	Globals.set_hints_display(button_pressed)


func _on_ReferencePictureButton_toggled(button_pressed) -> void:
	Globals.set_reference_display(button_pressed)


func _on_TileRotationButton_toggled(button_pressed) -> void:
	Globals.set_rotations(button_pressed)


func _on_MasterVolumeSlider_value_changed(value) -> void:
	Sounds.set_master_volume(value)


func _on_SfxVolumeSlider_value_changed(value) -> void:
	Sounds.set_sfx_volume(value)


func _on_MusicVolumeSlider_value_changed(value) -> void:
	Sounds.set_music_volume(value)
	
func _on_DisplayModeButton_item_selected(index) -> void:
	OS.window_fullscreen = (true if index == 1 else false)
	
func _on_Button_pressed() -> void:
	hide()

func _on_Settings_popup_hide() -> void:
#	for tile in browse_grid_container.get_children():
#		tile.queue_free()
	pass

func _on_TabContainer_tab_selected(tab) -> void:
	pass
#	if tab == 1 and browse_grid_container.get_child_count() < Globals.custom_pictures.size():
#		browse_grid_container.columns = floor(browse_grid_container.rect_size.x / 125) - 1
#		for i in range(browse_grid_container.get_child_count(), Globals.custom_pictures.size()):
#			var img = Image.new()
#			img.load(Globals.custom_pictures[i])
#			var tex = ImageTexture.new()
#			tex.create_from_image(img)
#			var atlas_tex = AtlasTexture.new()
#			var min_size = min(tex.get_width(), tex.get_height())
#			atlas_tex.atlas = tex
#			atlas_tex.region = Rect2(0, 0, min_size, min_size)
#
#			var s = picure_preview.instance()
#			s.texture = atlas_tex
#			browse_grid_container.add_child(s)
#			s.get_node("Button").connect("pressed", self, "_on_Remove_button_pressed", [s.get_node("Button")])

func _on_Remove_button_pressed(button) -> void:
	var i = button.get_parent().get_index()
	Globals.custom_pictures.remove(i)
	Globals.save_custom_pictures()
	button.get_parent().queue_free()


func _on_Settings_about_to_show() -> void:
	tab_container.current_tab = 0
	grid_size_button.value = Globals.GRID_SIZE
	number_hints_button.pressed = Globals.display_hints
	reference_button.pressed = Globals.display_reference
	rotation_button.pressed = Globals.enable_rotations
	warning_label.visible = Globals.grid_size_changed
	display_mode_button.selected = (1 if OS.is_window_fullscreen() else 0)
	master_volume_slider.value = AudioServer.get_bus_volume_db(0)
	sfx_volume_slider = AudioServer.get_bus_volume_db(1)
	music_volume_slider = AudioServer.get_bus_volume_db(2)
	



