extends TileMap
class_name Grid

var _size : int

signal shuffle_completed

var _directions : Array
var _cell_mappings: Dictionary = {}
var _blank_coords : Vector2
var can_move : bool
var can_drag : bool
var shuffling : bool

func init(size):
	_size = size
	_blank_coords = Vector2(_size - 1, _size - 1)
	clear()

func _ready():
	_directions = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	shuffling = false
	
	
func shuffle():
	can_move = false
	can_drag = false
	shuffling = true
	randomize()
	for i in range (_size * _size - 1):
		var j = i + randi() % (_size * _size - i - 1)
		
		var a = Vector2(i % _size, floor(i / _size))
		var b = Vector2(j % _size, floor(j / _size))

		switch(a, b, 0, false)
		yield(get_tree(), "idle_frame")
		if Globals.enable_rotations:
			if randf() < 0.15:
			 _cell_mappings[b].rotate_self(0)
		
	if !is_solvable():
		var a = Vector2(randi() % _size, randi() % _size)
		var b = Vector2(randi() % _size, randi() % _size)
		while a == b or a == _blank_coords or b == _blank_coords:
			a = Vector2(randi() % _size, randi() % _size)
			b = Vector2(randi() % _size, randi() % _size)
		switch(a, b, 0, false)

	emit_signal("shuffle_completed")
	can_move = true
	can_drag = true
	shuffling = false
	
func switch(cell_one : Vector2, cell_two : Vector2, speed : float = 0.25, trail : bool = true) -> void:
	var temp = _cell_mappings[cell_one]
	var pos = temp.position

	_cell_mappings[cell_one].move(_cell_mappings[cell_two].position, speed, trail)
	_cell_mappings[cell_two].move(pos, speed)
	_cell_mappings[cell_one] = _cell_mappings[cell_two]
	_cell_mappings[cell_two] = temp

	_switch_cells(cell_one, cell_two)
	
func _switch_cells(cell_one, cell_two):
	var temp = get_cellv(cell_one)
	set_cellv(cell_one, get_cellv(cell_two))
	set_cellv(cell_two, temp)
	
func move_tile(dir: Vector2) -> void:
	if !can_move:
		return
	var cell = _blank_coords - dir
	if !get_used_cells().has(cell):
		return
		
	can_move = false
	can_drag = false
	switch(cell, _blank_coords, 0.25, true)
	_blank_coords = cell

	
func can_move_cell(cell):
	for dir in _directions:
		if cell + dir == _blank_coords:
			return dir
			break
	return false

func map_cell(coords : Vector2, tile : Node2D):
	_cell_mappings[coords] = tile


			
func find_blank_tile():
	for i in range(_size):
		for j in range(_size):
			if get_cell(i, j) == 0:
				return Vector2(i, j)


func rotate(cell):
	if !can_move:
		return
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
		var blank_pos_y = _size - int(_blank_coords.y)
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
