tool
extends GridMap
class_name WFCMapGenerator

##
## Wave Function Colapse Generator script
##
## @desc:
##     This Generator uses Data set created using WFCDataGenerator node.
##     Recomended Mesh library the same as one used during data set generation
##     Side Note: Generator uses Mesh Library IDs from the Data Set
##     
##     Point Mode creates terrain from single point.
##     
##     Plane mode adds all possible points to the list and tries to set
##     cell item on them.
##     
##     If allow_above_start_height is true generator will add tile above after
##     item in cell in setted
##     
##     If allow_under_start_height is true generator will add tile above after
##     item in cell in setted
##     
##     The delay_wait_every is how many tiles can be generated before in one cycle.
##     The delay_wait_yields is how many idle_frames delay between cycles lasts.
##     
##     Set regen_lock variable to disallow usage of press_to_generate button.
##     
##     Use generate() function to generate new map.
##     
##     Use save_data() function to retrieve data of current cell placement.
##     Use load_data(data) function to load data of saved cell placement.
##     

export(String) var wfc_data_path := "res://data/tile_data.json"
export(int) var map_size = 10

var plane_start_height = 0
export(bool) var allow_above_start_height = true
export(bool) var allow_under_start_height = false

var delay_wait_every := 5
var delay_wait_yields := 4

#export(Array) var allowed_grid_start_ids := [0]
export(String,"Point","Plane") var start_mode := "Plane"
var point_start_point := Vector3.ZERO
export(bool) var generation_lock = true
export(bool) var use_threads = true
export(bool) var click_to_generate := false setget run_generate


func _get_property_list():
	var properties = []
	properties.append_array([
		{
			name = "Point Mode",
			type = TYPE_NIL,
			hint_string = "point_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "point_start_point",
			type = TYPE_VECTOR3
		}
	])
	
	
	properties.append_array([
		{
			name = "Plane Mode",
			type = TYPE_NIL,
			hint_string = "plane_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "plane_start_height",
			type = TYPE_INT
		}
	])
	
	properties.append_array([
		{
			name = "Tile Set Delay",
			type = TYPE_NIL,
			hint_string = "delay_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "delay_wait_every",
			type = TYPE_INT
		},
		{
			name = "delay_wait_yields",
			type = TYPE_INT
		}
	])
	
	return properties

func set_delay_wait_every(val):
	if val>=1:
		delay_wait_every=val

func set_delay_wait_yields(val):
	if val>=1:
		delay_wait_yields=val


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

var map_start_height := 0
var used_ids := []
var cells_data := {}
func load_wfc_data() -> bool:
	var ret := false
	if wfc_data_path.ends_with(".json"):
		var file := File.new()
		file.open(wfc_data_path,File.READ)
		while file.get_position() < file.get_len():
			var data = parse_json(file.get_line())
			if data.has("used_ids") and data.has("wfc_data"):
				used_ids=data["used_ids"].duplicate()
				cells_data=data["wfc_data"].duplicate()
				ret=true
				break
		file.close()
	return ret

var gen_thread : Thread
func run_generate(val):
	if !generation_lock:
		if use_threads:
			if gen_thread!=null:
				if gen_thread.is_alive():
					return
			print("Starting generation on thread...")
			gen_thread = Thread.new()
			gen_thread.start(self,"generate")
		else:
			if gen_thread!=null:
				if gen_thread.is_alive():
					return
				else:
					gen_thread=null
			generate()

func _exit_tree():
	gen_thread.wait_to_finish()

var tiles := []
func generate():
	if !load_wfc_data():
		printerr("Could not load wfc data set...")
		return
	
	tiles.clear()
	clear()
	clear_baked_meshes()
	match start_mode:
		"Point":
			tiles.append(point_start_point)
			map_start_height=point_start_point.y
		"Plane":
			map_start_height=plane_start_height
			for x in range(map_size):
				for z in range(map_size):
					tiles.append(Vector3(x,plane_start_height,z))
	
	
	while(tiles.size()>0):
		var tile : Vector3 = get_lowest_list_tile_and_remove()
		var x = tile.x
		var y = tile.y
		var z = tile.z
		var list := get_cell_nsides(x,y,z)
		
		if tiles.size()%delay_wait_every==0:
			for i in range(delay_wait_yields):
				yield(get_tree(),"idle_frame")
		
		randomize()
		#print(str(list)+" "+str(tile))
		if list.size()>0:
			var cell_name:String = list[rand_range(0,list.size())]
			var id = int(cell_name.split(":")[0])
			var rot = int(cell_name.split(":")[1])
			if id>=0:
				set_cell_item(x,y,z,id,rot)
				
				if start_mode=="Point":
					add_cell_if_in_bounds(Vector3(x+1,y,z))
					add_cell_if_in_bounds(Vector3(x-1,y,z))
					
					add_cell_if_in_bounds(Vector3(x,y,z+1))
					add_cell_if_in_bounds(Vector3(x,y,z-1))
				
				var y_p = get_cell_item(x,y+1,z)
				if allow_above_start_height and y_p==-1 and !(y<map_start_height):
					tiles.append(Vector3(x,y+1,z))
				
				var y_m = get_cell_item(x,y-1,z)
				if allow_under_start_height and y_m==-1 and !(y>map_start_height):
					tiles.append(Vector3(x,y-1,z))

func add_cell_if_in_bounds(cell:Vector3):
	if is_in_bounds(cell):
		if get_cell_item(cell.x,cell.y,cell.z)==-1:
			tiles.append(cell)

func is_in_bounds(cell:Vector3)->bool:
	var map_h_min := 0
	var map_h_max := 0
	if allow_above_start_height:
		map_h_max+=map_size
	if allow_under_start_height:
		map_h_min-=map_size
	if map_size>=cell.x and cell.x>=0:
		if map_h_max>=cell.y and cell.y>=map_h_min:
			if map_size>=cell.z and cell.z>=0:
				return true
	return false

func get_lowest_list_tile_and_remove() -> Vector3:
	var tile_counts := {}
	
	for i in range(tiles.size()):
		var tl : Vector3 = tiles[i]
		var list := get_cell_nsides(tl.x,tl.y,tl.z)
		var nm : String = str(list.size())
		
		if tile_counts.has(nm):
			tile_counts[nm].append(tl)
		else:
			tile_counts[nm]=[tl]
	
	if tile_counts.has(0):
		tile_counts.erase(0)
	
	var lowest_n : int = 999999999
	for key in tile_counts.keys():
		if int(key)<lowest_n:
			lowest_n=int(key)
	#print(lowest_n)
	
	randomize()
	var result_list = tile_counts[str(lowest_n)]
	var result_tile : Vector3 = result_list[rand_range(0,result_list.size())]
	
	for i in range(tiles.size()):
		if tiles[i]==result_tile:
			tiles.remove(i)
			break
	
	#tiles.remove(tl_id)
	return result_tile

func get_cell_nsides(x,y,z) -> Array:
	var cell = Vector3(x,y,z)
	var x_p = get_cell_item(x+1,y,z)
	var x_m = get_cell_item(x-1,y,z)
	var y_p = get_cell_item(x,y+1,z)
	var y_m = get_cell_item(x,y-1,z)
	var z_p = get_cell_item(x,y,z+1)
	var z_m = get_cell_item(x,y,z-1)
	var list :Array = []
#	if (x_m>=0 or y_m>=0 or z_m>=0 or x_p>=0 or y_p>=0 or z_p>=0) or y==map_start_height:
	for i in used_ids:
		for key in cells_data.keys():
			if key.split(":")[0]==str(i):
				list.append(key)
	list=check_cell_side(list,Vector3(x-1,y,z),"x_plus")
	list=check_cell_side(list,Vector3(x+1,y,z),"x_minus")
	
	list=check_cell_side(list,Vector3(x,y-1,z),"y_plus")
	list=check_cell_side(list,Vector3(x,y+1,z),"y_minus")
	
	list=check_cell_side(list,Vector3(x,y,z-1),"z_plus")
	list=check_cell_side(list,Vector3(x,y,z+1),"z_minus")
	
	if y_p==x_p and x_p==z_p and z_p==y_m and y_m==x_m and x_m==z_m and z_m==-1 and y==map_start_height:
		for i in used_ids:
			for key in cells_data.keys():
				if key.split(":")[0]==str(i):
					list.append(key)
	return list

func check_cell_side(list:Array,n_cell:Vector3,side:String)->Array:
	var n = get_cell_item(n_cell.x,n_cell.y,n_cell.z)
	if list.size()>0 and n>=0:
		var rot = get_cell_item_orientation(n_cell.x,n_cell.y,n_cell.z)
		return check_list(list.duplicate(),str(n)+":"+str(rot),side)
	return list

func check_list(list : Array,n : String,side : String) -> Array:
	var n_list := list.duplicate()
	if n.length()>=3:
		if list.size()>0:
			n_list=select_similar(cells_data[n][side].duplicate(),list.duplicate())
	return n_list

func select_similar(array_a:Array,array_b:Array) -> Array:
#	print(array_a)
#	print(array_b)
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		for j in range(array_b.size()):
			if array_b[j]==bl:
				array_c.append(bl)
	return array_c



func save_data():
	var data = {}
	var used = get_used_cells()
	var cell_data : Array = []
	for i in range(used.size()):
		var cell : Vector3 = used[i]
		cell_data.append({"pos":cell,"id":get_cell_item(cell.x,cell.y,cell.z),"orientation":get_cell_item_orientation(cell.x,cell.y,cell.z)})
	data["cell_data"]=cell_data
	return data

func load_data(data):
	clear()
	clear_baked_meshes()
	var used = get_used_cells()
	var cell_data : Array = data["cell_data"]
	for i in range(cell_data.size()):
		var cell_dt : Dictionary = used[i]
		var pos = cell_dt["pos"]
		var id = cell_dt["id"]
		var orientation = cell_dt["orientation"]
		set_cell_item(pos.x,pos.y,pos.z,id,orientation)
