extends Node

const SFX = [preload("res://assets/sounds/fw_01.ogg"), preload("res://assets/sounds/fw_05.ogg")]

onready var sfx = $Sfx
onready var music = $Music

enum {
	FIREWORK_1,
	FIREWORK_2
}


func play_effect(effect):
	for channel in $Sfx.get_children():
		if !channel.is_playing():
			channel.stream = SFX[effect]
			channel.play()
			break
			
func set_master_volume(value):
	if value == -40:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, value)

func set_sfx_volume(value):
	if value == -40:
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_mute(1, false)
		AudioServer.set_bus_volume_db(1, value)
	
func set_music_volume(value):
	if value == -40:
		AudioServer.set_bus_mute(2, true)
	else:
		AudioServer.set_bus_mute(2, false)
		AudioServer.set_bus_volume_db(2, value)
