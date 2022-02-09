extends Sprite

func initialize(tex : Texture, coords : Vector2, size : int):
	randomize()
	texture = tex
	region_rect = Rect2(coords.x * size, coords.y * size, size, size)
	$Frame.scale *= size / 300.0

	#rotation = rand_range(- PI / 16, PI / 16)
