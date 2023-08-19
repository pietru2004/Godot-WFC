@tool
extends GridMap
class_name WFCMapGenerator

##
## Wave Function Colapse Generator script
##
## @desc:
##     Mesh Library Creation - define all meshes, their names and collisions
##     
##     Rule Generation - after painting rules you can use this button to generate rule set
##
##     Map Generation - after generating meshlib and rule set you can use this section 
##     to generate map
##

@export var generation_lock: bool = true
@export var error_out := []
@export var debug_error_print_out := true
#########################
##Mesh Library Creation##
#########################
@export_category("MeshLibCreation")
@export var mesh_lib_data : MeshLibDefiner = MeshLibDefiner.new()
@export var generate_meshlib : bool = false : set = run_generate_meshlib

func run_generate_meshlib(val):
	generate_meshlib=false
	if generation_lock or running:
		return
	mesh_library=mesh_lib_data.get_meshlib()

###################
##Rule Generation##
###################
@export_category("RuleSetCreation")
@export var add_mode : bool = false ## Should add to existing rule set.
@export var generate_rules : bool = false : set = run_generate_rules
@export var mesh_lib_rule_set : MeshLibRulesSet = MeshLibRulesSet.new()

func run_generate_rules(val):
	generate_rules=false
	if generation_lock or running:
		return
	if !add_mode:
		mesh_lib_rule_set=MeshLibRulesSet.new()
	var cells := {}
	for vec in get_used_cells():
		var id = get_cell_item(vec)
		var rot = get_cell_item_orientation(vec)
		var item = mesh_lib_rule_set.add_get_item(id,mesh_lib_data.items[id],rot)
		add_rule_FORWARD(item,vec)
		add_rule_BACK(item,vec)
		add_rule_RIGHT(item,vec)
		add_rule_LEFT(item,vec)
		add_rule_DOWN(item,vec)
		add_rule_UP(item,vec)

func add_rule_FORWARD(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.FORWARD
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_front(id,dir_item,rot)

func add_rule_BACK(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.BACK
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_back(id,dir_item,rot)

func add_rule_RIGHT(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.RIGHT
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_right(id,dir_item,rot)

func add_rule_LEFT(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.LEFT
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_left(id,dir_item,rot)

func add_rule_DOWN(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.DOWN
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_down(id,dir_item,rot)

func add_rule_UP(item:MeshLibRule,vec:Vector3):
	var dir = vec+Vector3.UP
	var id = get_cell_item(dir)
	if id==-1:
		return
	var dir_item = mesh_lib_data.items[id]
	var rot = get_cell_item_orientation(dir)
	item.add_item_up(id,dir_item,rot)

###############
##Map Cleaner##
###############
@export_category("MapCleaning")
@export var clean_lock: bool = true
@export var clear_map : bool = false : set = run_clear_map

func run_clear_map(val):
	clear_map=false
	if generation_lock or running or clean_lock:
		return
	clean_map_segment()
	clear_baked_meshes()
	clean_lock=true

##################
##Map Generation##
##################
@export_category("MapGeneration")
@export var map_start := Vector3.ZERO
@export var map_end := Vector3(10,10,10)

enum sorting_mode {
	entropy, ##sort using entropy
	xzy, ##sort using vec 3
	no_sorting ##use order as cells were added...
}
@export var cell_sorting:=sorting_mode.entropy

@export var allow_up: bool = true
@export var allow_down: bool = false

enum cell_adding_mode {
	always, ##add cell always
	when_one_can_add, ##when one of cells has more than 0 options in that direction
	when_all_can_add ##when all cells has more than 0 options in that direction
}
@export var cell_add_to_gen_list:=cell_adding_mode.always

@export var conflict_repair: bool = true
@export var allow_empty_cells: bool = true ##for 3D Maps

@export var delay_between_tries := 0.05

var start_point := map_start
var had_start_point := false

@export var generate_map : bool = false : set = run_generate_map

@export var running := false
var waiting := []
var up_wait := []
var down_wait := []

func run_generate_map(val):
	generate_map=false
	if generation_lock or mesh_lib_data.items.size()==0:
		return
	running=false
	await get_tree().process_frame
	waiting.clear()
	clean_map_segment()
	clear_baked_meshes()
	waiting.append(start_point)
	running=true
	had_start_point = false

func clean_map_segment():
	if generation_lock or mesh_lib_data.items.size()==0:
		return
	for _x in range(map_start.x,map_end.x):
		for _y in range(map_start.y,map_end.y):
			for _z in range(map_start.z,map_end.z):
				set_cell_item(Vector3(_x,_y,_z),-1)

@export var time:=0.0
@export var remaining_cells := 0
func _process(delta):
	time+=delta
	if time>=delay_between_tries:
		time=0
		if !running:
			return
		remaining_cells=waiting.size()
		if waiting.size()==0:
			if up_wait.size()>0:
				waiting.append_array(up_wait)
				up_wait.clear()
				return
			if down_wait.size()>0:
				waiting.append_array(up_wait)
				down_wait.clear()
				return
			running=false
			return
		var cell_n := 0
		if cell_sorting==sorting_mode.entropy:
			var data = calc_celc_entropy()
			data.sort_custom(sort_entropy)
			waiting=get_sorted_vectors_from_entropy_data(data)
			var rang := get_the_same_entropy_range(data)
			cell_n = randi_range(0,rang)
		elif cell_sorting==sorting_mode.xzy:
			waiting.sort_custom(sort_xzy)
		var cell = waiting[cell_n]
		var suc = generate_cell(cell,cell_n)
		if suc:
			add_new_cells_to_list(cell)
			waiting.remove_at(cell_n)

func sort_entropy(a, b):
	return (a[1] < b[1]) #and !(a[1]<=0)

func sort_xzy(a:Vector3, b:Vector3):
	if a.x != b.x:
		return a.x < b.x
	elif a.z != b.z:
		return a.z < b.z
	else:
		return a.y < b.y
	return false

func get_sorted_vectors_from_entropy_data(input:Array)->Array:
	var export := []
	#[cell,entropy] => set
	for set in input:
		export.append(set[0])
	return export

func get_the_same_entropy_range(input:Array)->int:
	var _i := 0
	var entropy = input[0][1]
	#[cell,entropy] => set
	for set in input:
		if _i!=set[1]:
			break
		_i+=1
	if _i==0:
		return 0
	return _i-1

func generate_cell(vec:Vector3,cell_n:int)->bool:
	if !can_check_cell(vec) and had_start_point:
		waiting.remove_at(cell_n)
		return get_cell_item(vec)!=-1
	var cell_front = get_rule(vec+Vector3.FORWARD)#.back
	var cell_back = get_rule(vec+Vector3.BACK)#.front
	var cell_left = get_rule(vec+Vector3.LEFT)#.left
	var cell_right = get_rule(vec+Vector3.RIGHT)#.right
	var cell_down = get_rule(vec+Vector3.DOWN)#.up
	var cell_up = get_rule(vec+Vector3.UP)#.down
	var empty :bool= (cell_front.back.size()==0 and cell_back.front.size()==0 and cell_left.right.size()==0 and cell_right.left.size()==0 and cell_down.up.size()==0 and cell_up.down.size()==0)
	var data_cells := [cell_front.back,cell_back.front,cell_left.right,cell_right.left,cell_down.up,cell_up.down]
	var use_cells := [cell_front.id!=-1,cell_back.id!=-1,cell_left.id!=-1,cell_right.id!=-1,cell_down.id!=-1,cell_up.id!=-1]
	var similar_cells:Array=findSimilarCells(data_cells,use_cells)
	var weights = get_weights(similar_cells)
	if !had_start_point:
		had_start_point=true
		var starter :bool= (cell_front.id==-1 and cell_back.id==-1 and cell_left.id==-1 and cell_right.id==-1 and cell_down.id==-1 and cell_up.id==-1)
		if starter and empty:
			var st :MeshLibRule= mesh_lib_rule_set.pick_random_tile(mesh_lib_data.get_starter_tiles())
			set_cell_item(vec,st.id,st.rotation)
			return true
	if empty:
		set_cell_item(vec,-1)
		waiting.remove_at(cell_n)
		return false
	if similar_cells.size()==0:
		error_out=[]
		error_out.append(vec)
		error_out.append(data_cells)
		error_out.append(use_cells)
		if debug_error_print_out:
			printerr(vec)
		#findSimilarCells(data_cells,use_cells,true)
		if conflict_repair:
			add_repairs(vec)
			waiting.remove_at(cell_n)
			return false
		running=false
		return false
	var selected :MeshLibRuleItem=pickRandomValue(similar_cells,weights)
	set_cell_item(vec,selected.id,selected.rotation)
	return true

func can_check_cell(vec:Vector3)->bool:
	var cell_front = get_cell_item(vec+Vector3.FORWARD)#.back
	var cell_back = get_cell_item(vec+Vector3.BACK)#.front
	var cell_left = get_cell_item(vec+Vector3.LEFT)#.left
	var cell_right = get_cell_item(vec+Vector3.RIGHT)#.right
	var cell_down = get_cell_item(vec+Vector3.DOWN)#.up
	var cell_up = get_cell_item(vec+Vector3.UP)#.down
	return (cell_front!=-1 or cell_back!=-1 or cell_left!=-1 or cell_right!=-1 or cell_down!=-1 or cell_up!=-1)

func add_new_cells_to_list(vec:Vector3):
	if vec.z-1>=map_start.z:
		try_add_cell(vec+Vector3.FORWARD)
	if vec.z+1<map_end.z:
		try_add_cell(vec+Vector3.BACK)

	if vec.x-1>=map_start.x:
		try_add_cell(vec+Vector3.LEFT)
	if vec.x+1<map_end.x:
		try_add_cell(vec+Vector3.RIGHT)

	if vec.y-1>=map_start.y and allow_down:
		try_add_cell(vec+Vector3.DOWN,2)
	if vec.y+1<map_end.y and allow_up:
		try_add_cell(vec+Vector3.UP,1)
		
func try_add_cell(vec:Vector3,mode:=0):
	if get_cell_item(vec)==-1:
		if can_check_cell(vec):
			if !waiting.has(vec) and mode==0 and check_side_allowement(vec):
				waiting.append(vec)
			if !up_wait.has(vec) and mode==1 and check_side_allowement(vec): #up
				up_wait.append(vec)
			if !down_wait.has(vec) and mode==2 and check_side_allowement(vec): #down
				down_wait.append(vec)
	

func add_repairs(vec:Vector3):
	var list := [-1,0,1]
	for x in list:
		if vec.x+x>=map_start.x and vec.x+x<map_end.x:
			for z in list:
				if vec.z+z>=map_start.z and vec.z+z<map_end.z:
					try_regen_cell(vec+Vector3(x,0,z))
#	if vec.z-1>=map_start.z:
#		try_regen_cell(vec+Vector3.FORWARD)
#		if vec.x-1>=map_start.x:
#			try_regen_cell(vec+Vector3.FORWARD+Vector3.LEFT)
#		if vec.x+1<map_end.x:
#			try_regen_cell(vec+Vector3.FORWARD+Vector3.RIGHT)
#	if vec.z+1<map_end.z:
#		try_regen_cell(vec+Vector3.BACK)
#		if vec.x-1>=map_start.x:
#			try_regen_cell(vec+Vector3.BACK+Vector3.LEFT)
#		if vec.x+1<map_end.x:
#			try_regen_cell(vec+Vector3.BACK+Vector3.RIGHT)
#
#
#	if vec.x-1>=map_start.x:
#		try_regen_cell(vec+Vector3.LEFT)
#	if vec.x+1<map_end.x:
#		try_regen_cell(vec+Vector3.RIGHT)

#	if vec.y-1>=map_start.y and allow_down:
#		try_regen_cell(vec+Vector3.DOWN)
#		if vec.z-1>=0:
#			try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD)
#			if vec.x-1>=map_start.x:
#				try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD+Vector3.LEFT)
#			if vec.x+1<map_end.x:
#				try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD+Vector3.RIGHT)
#		if vec.z+1<map_end.z:
#			try_regen_cell(vec+Vector3.DOWN+Vector3.BACK)
#			if vec.x-1>=map_start.x:
#				try_regen_cell(vec+Vector3.DOWN+Vector3.BACK+Vector3.LEFT)
#			if vec.x+1<map_end.x:
#				try_regen_cell(vec+Vector3.DOWN+Vector3.BACK+Vector3.RIGHT)
#	if vec.y+1<map_end.y and allow_up:
#		try_regen_cell(vec+Vector3.UP)
#		if vec.z-1>=0:
#			try_regen_cell(vec+Vector3.UP+Vector3.FORWARD)
#			if vec.x-1>=map_start.x:
#				try_regen_cell(vec+Vector3.UP+Vector3.FORWARD+Vector3.LEFT)
#			if vec.x+1<map_end.x:
#				try_regen_cell(vec+Vector3.UP+Vector3.FORWARD+Vector3.RIGHT)
#		if vec.z+1<map_end.z:
#			try_regen_cell(vec+Vector3.UP+Vector3.BACK)
#			if vec.x-1>=map_start.x:
#				try_regen_cell(vec+Vector3.UP+Vector3.BACK+Vector3.LEFT)
#			if vec.x+1<map_end.x:
#				try_regen_cell(vec+Vector3.UP+Vector3.BACK+Vector3.RIGHT)
		
func try_regen_cell(vec:Vector3,mode:=0):
	if get_cell_item(vec)!=-1:
		set_cell_item(vec,-1)
		if can_check_cell(vec):
			if !waiting.has(vec) and mode==0 and check_side_allowement(vec):
				set_cell_item(vec,-1)
				waiting.append(vec)
			if !up_wait.has(vec) and mode==1 and check_side_allowement(vec): #up
				set_cell_item(vec,-1)
				up_wait.append(vec)
			if !down_wait.has(vec) and mode==2 and check_side_allowement(vec): #down
				set_cell_item(vec,-1)
				down_wait.append(vec)

func check_side_allowement(vec:Vector3)->bool:
	match cell_add_to_gen_list:
		cell_adding_mode.always:
			return true
		cell_adding_mode.when_one_can_add:
			var cell_front = get_rule(vec+Vector3.FORWARD)#.back
			var cell_back = get_rule(vec+Vector3.BACK)#.front
			var cell_left = get_rule(vec+Vector3.LEFT)#.left
			var cell_right = get_rule(vec+Vector3.RIGHT)#.right
			var cell_down = get_rule(vec+Vector3.DOWN)#.up
			var cell_up = get_rule(vec+Vector3.UP)#.down
			return (cell_front.back.size()!=0 or cell_back.front.size()!=0 or cell_left.right.size()!=0 or cell_right.left.size()!=0 or cell_down.up.size()!=0 or cell_up.down.size()!=0)
		cell_adding_mode.when_all_can_add:
			var cell_front = get_rule(vec+Vector3.FORWARD)#.back
			var cell_back = get_rule(vec+Vector3.BACK)#.front
			var cell_left = get_rule(vec+Vector3.LEFT)#.left
			var cell_right = get_rule(vec+Vector3.RIGHT)#.right
			var cell_down = get_rule(vec+Vector3.DOWN)#.up
			var cell_up = get_rule(vec+Vector3.UP)#.down
			return add_mode_check_all_cell_sides([cell_front.id, cell_back.id, cell_left.id, cell_right.id, cell_down.id, cell_up.id],[cell_front.back, cell_back.front, cell_left.right, cell_right.left, cell_down.up, cell_up.down])
	return false

func add_mode_check_all_cell_sides(ids:Array,arrs:Array)->bool:
	for _i in ids.size():
		if ids[_i]!=-1:
			if arrs[_i].size()==0:
				return false
	return true

func pickRandomValue(data: Array, dataWeights: Array):
	randomize()
	var weightedData = []
	if weightedData.size()==0:
		return data.pick_random()

	# Create weighted data based on weights
	for i in range(data.size()):
		for j in range(dataWeights[i]):
			weightedData.append(data[i])

	# Pick a random value from weighted data
	return weightedData.pick_random()

func calc_celc_entropy()->Array:
	var data := []
	for cell in waiting:
		var cell_front = get_rule(cell+Vector3.FORWARD)#.back
		var cell_back = get_rule(cell+Vector3.BACK)#.front
		var cell_left = get_rule(cell+Vector3.LEFT)#.left
		var cell_right = get_rule(cell+Vector3.RIGHT)#.right
		var cell_down = get_rule(cell+Vector3.DOWN)#.up
		var cell_up = get_rule(cell+Vector3.UP)#.down
		var data_cells := [cell_front.back,cell_back.front,cell_left.right,cell_right.left,cell_down.up,cell_up.down]
		var use_cells := [cell_front.id!=-1,cell_back.id!=-1,cell_left.id!=-1,cell_right.id!=-1,cell_down.id!=-1,cell_up.id!=-1]
		var similar_cells:Array=findSimilarCells(data_cells,use_cells)
		var weights = get_weights(similar_cells)
		var entropy = calculateEntropy(weights)
		data.append([cell,entropy])
	return data

func get_rule(vec:Vector3)->MeshLibRule:
	var id = get_cell_item(vec)
	if id<=-1:
		var rule = MeshLibRule.new()
		rule.id=-1
		return rule
	if mesh_lib_data.get_item_ignore_rotation(id):
		return mesh_lib_rule_set.get_item(id,true,0)
	var rot = get_cell_item_orientation(vec)
	return mesh_lib_rule_set.get_item(id,false,rot)

func findSimilarCells(arrays: Array, useArrays: Array,debug:=false) -> Array:
	var similarCells = []
	
	# Find the arrays to be used
	var activeArrays = []
	for i in range(arrays.size()):
		if useArrays[i]:
			activeArrays.append(arrays[i])
	if debug:
		error_out.append(activeArrays)
	if activeArrays.size()==0:
		return []
	
	# Check for common elements
	for cell in activeArrays[0]:
		var common = true
		for i in range(1, activeArrays.size()):
			if !has_item(activeArrays[i],cell):
				common = false
				break
		
		if common:
			similarCells.append(cell)
	if debug:
		error_out.append(similarCells)
	
	return similarCells

func has_item(array:Array,item:MeshLibRuleItem)->bool:
	for object in array:
		if object as MeshLibRuleItem:
			if object.id==item.id:
				if mesh_lib_data.get_item_ignore_rotation(item.id):
					return true
				if object.rotation==item.rotation:
					return true
	return false

func get_weights(array:Array)->Array:
	var weights := []
	for object in array:
		if object is MeshLibRuleItem:
			weights.append(object.weight)
	return weights


func log2(x: float) -> float:
	return log(x) / log(2)

func calculateEntropy(weights: Array) -> float:
	var total = 0.0
	var entropy = 0.0

	# Calculate the total sum of weights
	for weight in weights:
		total += weight

	# Calculate the entropy
	for weight in weights:
		var probability = weight / total
		entropy -= probability * log2(probability)

	return entropy
