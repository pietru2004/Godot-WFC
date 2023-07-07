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
#########################
##Mesh Library Creation##
#########################
@export_category("MeshLibCreation")
@export var mesh_lib_data : MeshLibDefiner = MeshLibDefiner.new()
@export var generate_meshlib : bool = false : set = run_generate_meshlib

func run_generate_meshlib(val):
	generate_meshlib=false
	if generation_lock:
		return
	mesh_library=mesh_lib_data.get_meshlib()

###################
##Rule Generation##
###################
@export_category("RuleSetCreation")
@export var generate_rules : bool = false : set = run_generate_rules
@export var mesh_lib_rule_set : MeshLibRulesSet = MeshLibRulesSet.new()

func run_generate_rules(val):
	generate_rules=false
	if generation_lock:
		return
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


##################
##Map Generation##
##################
@export_category("MapGeneration")
@export var map_size: int = 10
@export var allow_up: bool = true
@export var allow_down: bool = false
@export var conflict_repair: bool = true

@export var delay_between_tries := 0.05

var start_point := Vector3.ZERO

@export var generate_map : bool = false : set = run_generate_map

@export var running := false
var waiting := []

func run_generate_map(val):
	generate_map=false
	if generation_lock or mesh_lib_data.items.size()==0:
		return
	running=false
	await get_tree().process_frame
	waiting.clear()
	clear()
	clear_baked_meshes()
	waiting.append(start_point)
	running=true

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
			running=false
			return
		var data = calc_celc_entropy()
		waiting.sort_custom(sort_entropy)
		var cell = waiting[0]
		var suc = generate_cell(cell)
		if suc:
			add_new_cells_to_list(cell)
			waiting.remove_at(0)

func sort_entropy(a, b):
	return a[1] < b[1]

func generate_cell(vec:Vector3)->bool:
	var cell_front = get_rule(vec+Vector3.FORWARD)#.back
	var cell_back = get_rule(vec+Vector3.BACK)#.front
	var cell_left = get_rule(vec+Vector3.LEFT)#.left
	var cell_right = get_rule(vec+Vector3.RIGHT)#.right
	var cell_down = get_rule(vec+Vector3.DOWN)#.up
	var cell_up = get_rule(vec+Vector3.UP)#.down
	var data_cells := [cell_front.back,cell_back.front,cell_left.right,cell_right.left,cell_down.up,cell_up.down]
	var use_cells := [cell_front.id!=-1,cell_back.id!=-1,cell_left.id!=-1,cell_right.id!=-1,cell_down.id!=-1,cell_up.id!=-1]
	var similar_cells:Array=findSimilarCells(data_cells,use_cells)
	var weights = get_weights(similar_cells)
	var starter :bool= (cell_front.id==-1 and cell_back.id==-1 and cell_left.id==-1 and cell_right.id==-1 and cell_down.id==-1 and cell_up.id==-1)
	if starter:
		var id = mesh_lib_rule_set.items.pick_random().id
		set_cell_item(vec,id)
		return true
	if similar_cells.size()==0:
		error_out=[]
		error_out.append(vec)
		error_out.append(data_cells)
		error_out.append(use_cells)
		printerr(vec)
		#findSimilarCells(data_cells,use_cells,true)
		if conflict_repair:
			add_repairs(vec)
			return false
		running=false
		return false
	var selected :MeshLibRuleItem=pickRandomValue(similar_cells,weights)
	set_cell_item(vec,selected.id,selected.rotation)
	return true

func add_new_cells_to_list(vec:Vector3):
	if vec.z-1>=0:
		try_add_cell(vec+Vector3.FORWARD)
	if vec.z+1<map_size:
		try_add_cell(vec+Vector3.BACK)

	if vec.x-1>=0:
		try_add_cell(vec+Vector3.LEFT)
	if vec.x+1<map_size:
		try_add_cell(vec+Vector3.RIGHT)

	if vec.y-1>=0 and allow_down:
		try_add_cell(vec+Vector3.DOWN)
	if vec.y+1<map_size and allow_up:
		try_add_cell(vec+Vector3.UP)
		
func try_add_cell(vec:Vector3):
	if get_cell_item(vec)==-1:
		if !waiting.has(vec):
			waiting.append(vec)

func add_repairs(vec:Vector3):
	if vec.z-1>=0:
		try_regen_cell(vec+Vector3.FORWARD)
		if vec.x-1>=0:
			try_regen_cell(vec+Vector3.FORWARD+Vector3.LEFT)
		if vec.x+1<map_size:
			try_regen_cell(vec+Vector3.FORWARD+Vector3.RIGHT)
	if vec.z+1<map_size:
		try_regen_cell(vec+Vector3.BACK)
		if vec.x-1>=0:
			try_regen_cell(vec+Vector3.BACK+Vector3.LEFT)
		if vec.x+1<map_size:
			try_regen_cell(vec+Vector3.BACK+Vector3.RIGHT)
		
		
	if vec.x-1>=0:
		try_regen_cell(vec+Vector3.LEFT)
	if vec.x+1<map_size:
		try_regen_cell(vec+Vector3.RIGHT)

	if vec.y-1>=0 and allow_down:
		try_regen_cell(vec+Vector3.DOWN)
		if vec.z-1>=0:
			try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD)
			if vec.x-1>=0:
				try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD+Vector3.LEFT)
			if vec.x+1<map_size:
				try_regen_cell(vec+Vector3.DOWN+Vector3.FORWARD+Vector3.RIGHT)
		if vec.z+1<map_size:
			try_regen_cell(vec+Vector3.DOWN+Vector3.BACK)
			if vec.x-1>=0:
				try_regen_cell(vec+Vector3.DOWN+Vector3.BACK+Vector3.LEFT)
			if vec.x+1<map_size:
				try_regen_cell(vec+Vector3.DOWN+Vector3.BACK+Vector3.RIGHT)
	if vec.y+1<map_size and allow_up:
		try_regen_cell(vec+Vector3.UP)
		if vec.z-1>=0:
			try_regen_cell(vec+Vector3.UP+Vector3.FORWARD)
			if vec.x-1>=0:
				try_regen_cell(vec+Vector3.UP+Vector3.FORWARD+Vector3.LEFT)
			if vec.x+1<map_size:
				try_regen_cell(vec+Vector3.UP+Vector3.FORWARD+Vector3.RIGHT)
		if vec.z+1<map_size:
			try_regen_cell(vec+Vector3.UP+Vector3.BACK)
			if vec.x-1>=0:
				try_regen_cell(vec+Vector3.UP+Vector3.BACK+Vector3.LEFT)
			if vec.x+1<map_size:
				try_regen_cell(vec+Vector3.UP+Vector3.BACK+Vector3.RIGHT)
		
func try_regen_cell(vec:Vector3):
	if get_cell_item(vec)!=-1:
		if !waiting.has(vec):
			waiting.append(vec)
			set_cell_item(vec,-1)


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
