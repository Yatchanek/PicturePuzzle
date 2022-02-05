extends CPUParticles2D


func _ready():
	randomize()
	amount = int(rand_range(128, 256))
	Sounds.play_effect(Sounds.FIREWORK_1 + randi() % 2)

func _on_Timer_timeout():
	queue_free()

