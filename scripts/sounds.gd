extends Node

const SFX = [
	preload("res://assets/sounds/fw_01.ogg"), 
	preload("res://assets/sounds/fw_05.ogg"),
	preload("res://assets/sounds/slide.wav")	
]

const MUSIC = [
	preload("res://assets/sounds/music_1.mp3"),
	preload("res://assets/sounds/music_2.mp3"),
	preload("res://assets/sounds/music_3.mp3"),
	preload("res://assets/sounds/music_4.mp3"),
	preload("res://assets/sounds/music_5.mp3"),
	preload("res://assets/sounds/music_6.mp3"),
	preload("res://assets/sounds/music_7.mp3"),
	
]

onready var sfx = $Sfx
onready var music = $Music
onready var music_player = $Music/MusicPlayer
onready var tween = $Tween
onready var music_timer = $MusicTimer

var current_track
var previous_track
var previous_volume

enum {
	FIREWORK_1,
	FIREWORK_2,
	SLIDE
}

func _ready():
	play_music()

func play_effect(effect):
	for channel in $Sfx.get_children():
		if !channel.is_playing():
			channel.stream = SFX[effect]
			channel.play()
			break

func play_music():
	randomize()
	previous_track = current_track
	current_track = MUSIC[randi() % MUSIC.size()]
	while current_track == previous_track:
		current_track = MUSIC[randi() % MUSIC.size()]	
	music_player.stream = current_track
	music_timer.wait_time = music_player.stream.get_length() - 2.0
	music_player.play()
	music_timer.start()
			
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

func fade_out():
	tween.interpolate_property(music_player, "volume_db", 0, -80, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func fade_in():
	tween.interpolate_property(music_player, "volume_db", -80, 0, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_MusicTimer_timeout():
	fade_out()
	yield(tween, "tween_completed")
	play_music()
	fade_in()
