extends Control


func _on_SettingsButton_pressed():
	$Settings.popup()


func _on_StartGameButton_pressed():
	hide()
	Globals.start()

func _on_AddPicturesButton_pressed():
	$FileDialog.popup()

func _on_FileDialog_files_selected(paths):
	for i in paths.size():
		var file_name = paths[i]
		#if !Globals.custom_pictures.has(file_name):
		Globals.custom_pictures.push_back(file_name)
	Globals.save_custom_pictures()



