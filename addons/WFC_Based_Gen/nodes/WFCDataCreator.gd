tool
extends GridMap
class_name WFCDataCreator

##
## Wave Function Colapse Data Creator script
##
## @desc:
##     This Scripts creates data set used in WFCMapGenerator.
##     Required - existing mesh Library and painted rules
##     Side Note: Data Saver ignores fields where
##     
##     The auto_add_tile_rotations allows tile to be automaticaly added
##     in all 4 Y rotations.
##     
##     The tile_duplicates allows the tile to be added multiple times,
##     which allows how often should tile be placed in sittuation,
##     this might require more rules in extreme situations.
##     
##     Pressing click_to_export exports data set to selected file path in json format.
##     

export(String) var export_file_path := "res://data/tile_data.json"
export(bool) var auto_add_tile_rotations := true
export(bool) var tile_duplicates := false
export(bool) var click_to_export := false setget run_export

var next_y_rot := {
	"0":22,
	"22":10,
	"10":16,
	"16":0
}

var next_rot_side := {
	"x_plus": "z_plus",
	"z_plus": "x_minus",
	"x_minus": "z_minus",
	"z_minus": "x_plus"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Engine.editor_hint:
		queue_free()

func run_export(value):
	var cells = get_used_cells()
	
	var used_ids := []
	var cells_data := {}
	
	for cell in cells:
		var cell_data = get_cell_data(cell)
		var ncell := {}
		
		cells_data=add_key_if_not_exist(cells_data,cell_data["id"],cell_data["orientation"])
		
		ncell=get_cell_data(cell+Vector3(1,0,0))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"x_plus")
		ncell=get_cell_data(cell+Vector3(-1,0,0))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"x_minus")
		
		ncell=get_cell_data(cell+Vector3(0,1,0))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"y_plus")
		ncell=get_cell_data(cell+Vector3(0,-1,0))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"y_minus")
		
		ncell=get_cell_data(cell+Vector3(0,0,1))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"z_plus")
		ncell=get_cell_data(cell+Vector3(0,0,-1))
		cells_data=add_neighbours(cells_data,cell_data,ncell,"z_minus")
		
		if !used_ids.has(cell_data["id"]):
			used_ids.append(cell_data["id"])
	
	save_file(used_ids,cells_data)

func get_cell_data(cell)->Dictionary:
	var id = get_cell_item(cell.x,cell.y,cell.z)
	var orientation = get_cell_item_orientation(cell.x,cell.y,cell.z)
	return {"id":id,"orientation":orientation,"cell":cell}

func add_key_if_not_exist(data:Dictionary,key,orientation:int)->Dictionary:
	if !data.has(str(key)+":"+str(orientation)):
		var tile_name = mesh_library.get_item_name(key)
		
		if !auto_add_tile_rotations:
			data[str(key)+":"+str(orientation)]={
					"tile_name":tile_name,
					"orientation":orientation,
					"tile_auto_rotated":false,
					"x_plus":[],
					"x_minus":[],
					"y_plus":[],
					"y_minus":[],
					"z_plus":[],
					"z_minus":[],
				}
		if auto_add_tile_rotations:
			var rot :int= orientation
			for _i in range(4):
				data[str(key)+":"+str(rot)]={
						"tile_name":tile_name,
						"orientation":rot,
						"tile_auto_rotated":true,
						"x_plus":[],
						"x_minus":[],
						"y_plus":[],
						"y_minus":[],
						"z_plus":[],
						"z_minus":[],
					}
				rot=next_y_rot[str(rot)]
	return data

func add_neighbours(cells:Dictionary,key_cell:Dictionary,ncell:Dictionary,side:String)->Dictionary:
	if ncell["id"]>=0:
		if auto_add_tile_rotations:
			var m_orientation :int= key_cell["orientation"]
			var n_orientation :int= ncell["orientation"]
			var m_side :String= side
			for _i in range(4):
				var key_m := str(key_cell["id"])+":"+str(m_orientation)
				var key_n := str(ncell["id"])+":"+str(n_orientation)
				if !cells[key_m][m_side].has(key_n) or tile_duplicates:
					cells[key_m][m_side].append(key_n)
				m_orientation=next_y_rot[str(m_orientation)]
				n_orientation=next_y_rot[str(n_orientation)]
				m_side = next_rot_side[m_side]
		if !auto_add_tile_rotations:
			var key_m := str(key_cell["id"])+":"+str(key_cell["orientation"])
			var key_n := str(ncell["id"])+":"+str(ncell["orientation"])
			if !cells[key_m][side].has(key_n) or tile_duplicates:
				cells[key_m][side].append(key_n)
	return cells

func save_file(used_ids,data):
	if export_file_path.length()>0:
		if !export_file_path.ends_with(".json"):
			export_file_path=export_file_path+".json"
		
		var file := File.new()
		file.open(export_file_path,File.WRITE)
		file.store_line(to_json({"used_ids":used_ids,"wfc_data":data}))
		file.close()
		print_debug("File Saved in "+export_file_path)
