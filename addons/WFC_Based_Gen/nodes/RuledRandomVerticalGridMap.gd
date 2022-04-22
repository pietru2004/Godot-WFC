tool
extends GridMap
class_name RuledRandomVerticalGridMap

export(String) var TilesDataPath
export(int) var map_size = 10
export(int) var map_max_height = 6
export(bool) var regen_lock = true
export(bool) var press_to_regen setget regen


var tiles_list := []
var tiles_data := {}


func regen(value=true):
	if open_file(TilesDataPath) and !regen_lock:
		var MeshLib := MeshLibrary.new()
		for i in range(tiles_list.size()):
			var mesh = load(tiles_data[tiles_list[i]]["mesh_path"])
			MeshLib.create_item(i)
			MeshLib.set_item_name(i,tiles_list[i])
			MeshLib.set_item_mesh(i,mesh)
			MeshLib.set_item_shapes(i,[mesh.create_trimesh_shape()])
		mesh_library=MeshLib
		generate()

func generate():
	self.clear()
	for y in range(map_max_height):
		var tiles := []
		for x in range(map_size):
			for z in range(map_size):
				tiles.append(Vector2(x,z))
		
		var is_first
		while(tiles.size()>0):
			randomize()
			var tl_id = floor(rand_range(0,tiles.size()))
			var tile : Vector2 = tiles[tl_id]
			var x = tile.x
			var z = tile.y
			tiles.remove(tl_id)
			
			var y_m = get_cell_item(x,y-1,z)
			var x_m = get_cell_item(x-1,y,z)
			var z_m = get_cell_item(x,y,z-1)
			var y_p = get_cell_item(x,y+1,z)
			var x_p = get_cell_item(x+1,y,z)
			var z_p = get_cell_item(x,y,z+1)
			var list := []
			
			if z_m>=0:
				list=tiles_data[tiles_list[z_m]]["z_plus"].duplicate()
			
			if y_m>=0:
				if list.size()>0:
					list=compare(tiles_data[tiles_list[y_m]]["y_plus"].duplicate(),list.duplicate())
				else:
					list=tiles_data[tiles_list[y_m]]["y_plus"].duplicate()
			
			if x_m>=0:
				if list.size()>0:
					list=compare(tiles_data[tiles_list[x_m]]["x_plus"].duplicate(),list.duplicate())
				else:
					list=tiles_data[tiles_list[x_m]]["x_plus"].duplicate()
			
			if z_p>=0:
				if list.size()>0:
					list=compare(tiles_data[tiles_list[z_p]]["z_minus"].duplicate(),list.duplicate())
				else:
					list=tiles_data[tiles_list[z_p]]["z_minus"].duplicate()
			
			if y_p>=0:
				if list.size()>0:
					list=compare(tiles_data[tiles_list[y_p]]["y_minus"].duplicate(),list.duplicate())
				else:
					list=tiles_data[tiles_list[y_p]]["y_minus"].duplicate()
			
			if x_p>=0:
				if list.size()>0:
					list=compare(tiles_data[tiles_list[x_p]]["x_minus"].duplicate(),list.duplicate())
				else:
					list=tiles_data[tiles_list[x_p]]["x_minus"].duplicate()
			
			if list.size()==0 and y==0 and y_p==x_p and x_p==z_p and z_p==y_m and y_m==x_m and x_m==z_m and z_m==-1:
				for key in tiles_data.keys():
					list.append(key)
			
			if list.size()>0:
				randomize()
				var cell_name:String = list[rand_range(0,list.size())]
				var id = get_cell_id(cell_name)
				if id>=0:
					set_cell_item(x,y,z,id,tiles_data[tiles_list[id]]["orientation"])

func get_cell_id(cell_name) -> int:
	var id := -1
	for i in range(tiles_list.size()):
		if tiles_list[i]==cell_name:
			id=i
			break
	return id

func compare(array_a:Array,array_b:Array) -> Array:
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		for j in range(array_b.size()):
			if array_b[j]==bl:
				array_c.append(bl)
	return array_c

func open_file(path) -> bool:
	var ret := false
	if path.ends_with(".wgts"):
		var file := File.new()
		file.open(path,File.READ)
		while file.get_position() < file.get_len():
			var data = parse_json(file.get_line())
			if data.has("tiles_indexes") and data.has("tiles_data"):
				tiles_list=data["tiles_indexes"].duplicate()
				tiles_data=data["tiles_data"].duplicate()
				ret=true
				break
		file.close()
	return ret
