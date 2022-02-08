extends TileMap
class_name Grid

var _size : int

signal shuffle_completed

var _directions : Array
var _cell_mappings: Dictionary


func init(size):
	_size = size
	_cell_mappings = {}
	clear()

func _ready():
	_directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	

func shuffle():
	randomize()
	for i in range (_size * _size - 1):
		var j = i + randi() % (_size * _size - i - 1)
		
		var a = Vector2(i % _size, floor(i / _size))
		var b = Vector2(j % _size, floor(j / _size))

		switch(a, b, 0)
		yield(get_tree(), "idle_frame")
		if Globals.enable_rotations:
			if randf() < 0.15:
			 _cell_mappings[b].rotate_self(0)
		
	if !is_solvable():
		var a = Vector2(randi() % _size, randi() % _size)
		var b = Vector2(randi() % _size, randi() % _size)
		while (a.x == b.x and a.y == b.y) or _cell_mappings[a].index == 0 or _cell_mappings[b].index == 0:
			a = Vector2(randi() % _size, randi() % _size)
			b = Vector2(randi() % _size, randi() % _size)
		switch(a, b, 0)
		
	emit_signal("shuffle_completed")
	
func switch(cell_one : Vector2, cell_two : Vector2, speed : float = 0.25, trail : bool = false) -> void:
	var temp = _cell_mappings[cell_one]
	var pos = temp.position
	
	_cell_mappings[cell_one].move(_cell_mappings[cell_two].position, speed, trail)
	_cell_mappings[cell_two].move(pos, speed)
	_cell_mappings[cell_one] = _cell_mappings[cell_two]
	_cell_mappings[cell_two] = temp
	
	switch_cells(cell_one, cell_two)

func map_cell(coords : Vector2, tile : Node2D):
	_cell_mappings[coords] = tile

func find_blank_neighbour(cell : Vector2):
	for dir in _directions:
		var neighbour = cell + dir
		if get_cellv(neighbour) == 0:
			return neighbour
	return

func get_valid_neighbours(cell : Vector2) -> Array:
	var neighbours = []
	for dir in _directions:
		var neighbour = cell + dir
		if neighbour in get_used_cells():
			neighbours.push_back(neighbour)
	return neighbours
			
func find_blank_tile():
	for i in range(_size):
		for j in range(_size):
			if get_cell(i, j) == 0:
				return Vector2(i, j)

func find_direction(blank_cell, cell):
	var dir = _cell_mappings[blank_cell].position - _cell_mappings[cell].position
	return dir.normalized()

func switch_cells(cell_one, cell_two):
	var temp = get_cellv(cell_one)
	set_cellv(cell_one, get_cellv(cell_two))
	set_cellv(cell_two, temp)

func rotate(cell):
	_cell_mappings[cell].rotate_self()

func check_for_win() -> bool:
	for i in range(_size):
		for j in range(_size):
			var index = _cell_mappings[Vector2(i, j)].index
			if index > 0:
				if index != j * _size + i + 1:
					return false
					
	return true

func is_solvable() -> bool:
	var inv_count = get_inversions_count()
	
	if _size & 1:
		return !(inv_count & 1)
	
	else:
		var blank_pos_y = _size - int(find_blank_tile().y)
		if blank_pos_y & 1:
			return !(inv_count & 1)
		else:
			return inv_count & 1
	
func get_inversions_count() -> int:
	var arr : Array = []
	for i in range(_size):
		for j in range(_size):
			arr.append(get_cell(j, i))


	var inv_count : int = 0
	for i in range(_size * _size - 1):
		for j in range(i + 1, _size * _size):
			if arr[i] and arr[j] and arr[i] > arr[j]:
				inv_count += 1
	
	return inv_count
