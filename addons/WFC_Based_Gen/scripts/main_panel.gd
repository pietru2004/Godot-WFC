tool
extends Control

onready var SetMainModelBtn = $VBoxContainer/SetModelBtn
onready var ClearMainModelBtn = $VBoxContainer/ClearModelBtn

onready var main_model = $ViewHolder/Viewport/MainModel
onready var Model_x_plus = $ViewHolder/Viewport/Model_x_plus
onready var Model_x_minus = $ViewHolder/Viewport/Model_x_minus
onready var Model_y_plus = $ViewHolder/Viewport/Model_y_plus
onready var Model_y_minus = $ViewHolder/Viewport/Model_y_minus
onready var Model_z_plus = $ViewHolder/Viewport/Model_z_plus
onready var Model_z_minus = $ViewHolder/Viewport/Model_z_minus

onready var tile_creator = $TileCreator

func _ready():
	get_node("ViewHolder/Viewport").size=rect_size
	
#	var txt = ViewportTexture.new()
#	txt.viewport_path=get_node("Viewport").get_path()
#	get_node("TextureRect").texture=txt
	
	print_debug("GUI Initialized")
	set_models_pos()
	$FileMenu.get_popup().connect("id_pressed",self,"_on_file_menu_press")

onready var OpenModelDialouge = $OpenModel
onready var OpenFileDialouge = $OpenFile
onready var SaveFileDialouge = $SaveFile

var distance_between := 2.0
var file_action : String
var tileset_file_path : String

func _on_file_menu_press(index):
	match(index):
		0:
			OpenFileDialouge.popup_centered()
			file_action="WGTSFile"
		1:
			if tileset_file_path.length()>0:
				save_file()
			else:
				SaveFileDialouge.popup_centered()
		2:
			SaveFileDialouge.popup_centered()

func open_file(path):
	if path.ends_with(".wgts"):
		var file := File.new()
		file.open(path,File.READ)
		while file.get_position() < file.get_len():
			var data = parse_json(file.get_line())
			if data.has("tiles_indexes") and data.has("tiles_data"):
				tile_creator._on_ItemList_nothing_selected()
				tile_creator.tiles_list=data["tiles_indexes"].duplicate()
				tile_creator.tiles_data=data["tiles_data"].duplicate()
				tile_creator.load_tiles()
				break
		file.close()

func _on_OpenModel_file_selected(path):
	load_file(OpenModelDialouge.current_path)

func _on_OpenModel_confirmed():
	load_file(OpenModelDialouge.current_path)

func _on_OpenFile_file_selected(path):
	load_file(OpenFileDialouge.current_path)

func _on_OpenFile_confirmed():
	load_file(OpenFileDialouge.current_path)

func load_file(path):
	match (file_action):
		"MainModel":
			if tile_creator.cur_tile_index>=0:
				var loaded_file = load(path)
				if (loaded_file is Mesh) or (loaded_file is ArrayMesh) or (loaded_file is PrimitiveMesh):
					tile_creator.tiles_data[tile_creator.tiles_list[tile_creator.cur_tile_index]]["mesh_path"]=path
					main_model.mesh=loaded_file
			else:
				print_debug("Warning - Select Tile first.")
		"WGTSFile":
			open_file(path)
	file_action=""

func _on_SaveFile_confirmed():
	save_file()


func _on_SaveFile_file_selected(path):
	save_file()


func save_file():
	var file_name = SaveFileDialouge.current_file
	if file_name.length()>0:
		if !file_name.ends_with(".wgts"):
			file_name=file_name+".wgts"
		var file_path = SaveFileDialouge.current_path
		if !file_path.ends_with(".wgts"):
			file_path=file_path+".wgts"
		var data = {
			"tiles_indexes": tile_creator.tiles_list.duplicate(),
			"tiles_data": tile_creator.tiles_data.duplicate(true)
		}
		var file := File.new()
		file.open(file_path,File.WRITE)
		file.store_line(to_json(data))
		file.close()
		print_debug("File Saved in "+file_path)

func _on_SetModelBtn_pressed():
	file_action="MainModel"
	OpenModelDialouge.popup_centered()


func _on_ClearModelBtn_pressed():
	main_model.mesh=null




onready var dist_lanel = $VBoxContainer2/Panel/Distance

func _on_RiseDistBtn_pressed():
	distance_between+=1
	dist_lanel.text=str(distance_between)
	set_models_pos()


func _on_LowerDistBtn_pressed():
	distance_between-=1
	dist_lanel.text=str(distance_between)
	set_models_pos()


func _on_RiseDistBtn2_pressed():
	distance_between+=.1
	dist_lanel.text=str(distance_between)
	set_models_pos()


func _on_LowerDistBtn2_pressed():
	distance_between-=.1
	dist_lanel.text=str(distance_between)
	set_models_pos()

func set_models_pos():
	Model_x_plus.transform.origin=Vector3(distance_between,0,0)
	Model_x_minus.transform.origin=Vector3(-distance_between,0,0)
	Model_y_plus.transform.origin=Vector3(0,distance_between,0)
	Model_y_minus.transform.origin=Vector3(0,-distance_between,0)
	Model_z_plus.transform.origin=Vector3(0,0,distance_between)
	Model_z_minus.transform.origin=Vector3(0,0,-distance_between)

func clear_models_mesh():
	main_model.mesh=CubeMesh.new()
	Model_x_plus.mesh=null
	Model_x_minus.mesh=null
	Model_y_plus.mesh=null
	Model_y_minus.mesh=null
	Model_z_plus.mesh=null
	Model_z_minus.mesh=null
