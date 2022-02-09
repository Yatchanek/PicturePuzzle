extends Position2D

var tile = preload("res://scenes/title_screen_tile.tscn")

var used_coords = []

func _ready():
	spawn()
	
func spawn():
	for child in get_children():
		child.queue_free()
	var grid_size = int(rand_range(4,8))
	randomize()
	var tex = load(Globals.default_pictures[randi() % Globals.default_pictures.size()])
	
	var size = int(tex.get_width() / grid_size)

	for i in range(grid_size * grid_size * 0.75):
		var t = tile.instance()
		var coords = Vector2(randi() % grid_size, randi() % grid_size)
		if used_coords.has(coords):
			coords = Vector2(randi() % grid_size, randi() % grid_size)
		used_coords.append(coords)
		t.initialize(tex, coords, size)
		add_child(t)
		t.position = Vector2(rand_range(-450, 850), rand_range(-200, 400))
