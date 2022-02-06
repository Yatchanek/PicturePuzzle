extends CPUParticles2D


func _ready():
	amount = int(rand_range(32, 64))

func _on_Timer_timeout():
	queue_free()
