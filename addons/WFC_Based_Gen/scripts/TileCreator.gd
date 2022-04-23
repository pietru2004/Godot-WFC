tool
extends Control


var tiles_list := []
var tiles_data := {}

func load_tiles():
	get_node("ItemListCont/ItemList").clear()
	for i in range(tiles_list.size()):
		get_node("ItemListCont/ItemList").add_item(tiles_list[i])

var cur_tile_index := -1
enum rot_indexes {front=0,right=22,left=16,back=10}

func create_tile():
	var tile_name = get_node("TileName").text
	if tile_name.length()>0:
		var can = true
		for i in range(tiles_list.size()):
			if tiles_list[i]==tile_name:
				can = false
				break
		if can:
			tiles_list.append(tile_name)
			tiles_data[tile_name]={
				"mesh_path":"",
				"orientation":0,
				"x_plus":[],
				"x_minus":[],
				"y_plus":[],
				"y_minus":[],
				"z_plus":[],
				"z_minus":[],
			}
			load_tiles()
			yield(get_tree(), "idle_frame")
			get_node("ItemListCont/ItemList").select(tiles_list.size()-1)
			_on_ItemList_item_selected(tiles_list.size()-1)
		get_node("TileName").text=""

func DeleteTile():
	if cur_tile_index>=0:
		var tile_name = tiles_list[cur_tile_index]
		tiles_list.remove(cur_tile_index)
		tiles_data.erase(tile_name)
		load_tiles()
		_on_ItemList_nothing_selected()

onready var cur_selection_btn = $SwapArea/OptionButton
func _on_ItemList_item_selected(index):
	var tile_name = tiles_list[index]
	get_node("CurEdit").text="Editing: "+tile_name
	cur_tile_index=index
	_on_OptionButton_item_selected(cur_selection_btn.selected)
	var mesh_path : String = tiles_data[tiles_list[cur_tile_index]]["mesh_path"]
	if mesh_path.length()>0:
		get_parent().main_model.mesh=load(mesh_path)
	else:
		get_parent().clear_models_mesh()
	#print(tiles_data[tiles_list[cur_tile_index]]["orientation"])
	#print(rot_indexes)
#	-------------------------
#	IDK - THIS stoped working
#	match tiles_data[tiles_list[cur_tile_index]]["orientation"]:
#		rot_indexes.front:
#			get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Front"
#			get_parent().main_model.rotation_degrees=Vector3(0,0,0)
#		rot_indexes.right:
#			get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Right"
#			get_parent().main_model.rotation_degrees=Vector3(0,-90,0)
#		rot_indexes.left:
#			get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Left"
#			get_parent().main_model.rotation_degrees=Vector3(0,90,0)
#		rot_indexes.back:
#			get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Back"
#			get_parent().main_model.rotation_degrees=Vector3(0,180,0)
#	----------------------
#	\/ THIS WORKS...
	var orientation=tiles_data[tiles_list[cur_tile_index]]["orientation"]
	if orientation==rot_indexes.front:
		get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Front"
		get_parent().main_model.rotation_degrees=Vector3(0,0,0)
	elif orientation==rot_indexes.right:
		get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Right"
		get_parent().main_model.rotation_degrees=Vector3(0,-90,0)
	elif orientation==rot_indexes.left:
		get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Left"
		get_parent().main_model.rotation_degrees=Vector3(0,90,0)
	elif orientation==rot_indexes.back:
		get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Back"
		get_parent().main_model.rotation_degrees=Vector3(0,180,0)


func _on_ItemList_nothing_selected():
	get_node("CurEdit").text=""
	cur_tile_index=-1
	get_parent().main_model.rotation_degrees=Vector3(0,0,0)
	get_parent().clear_models_mesh()

func set_tile_orientation(val):
	if cur_tile_index>=0:
		var rot = 0
		match(val):
			"front":
				rot=rot_indexes.front
				get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Front"
				get_parent().main_model.rotation_degrees=Vector3(0,0,0)
			"right":
				rot=rot_indexes.right
				get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Right"
				get_parent().main_model.rotation_degrees=Vector3(0,-90,0)
			"left":
				rot=rot_indexes.left
				get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Left"
				get_parent().main_model.rotation_degrees=Vector3(0,90,0)
			"back":
				rot=rot_indexes.back
				get_parent().get_node("VBoxContainer/rotN").text="Cur Rotation:\n Back"
				get_parent().main_model.rotation_degrees=Vector3(0,180,0)
		tiles_data[tiles_list[cur_tile_index]]["orientation"]=rot

func _on_OptionButton_item_selected(index):
	if cur_tile_index>=0:
		$SwapArea.all_tiles=tiles_list.duplicate()
		$SwapArea.selected_tiles=tiles_data[tiles_list[cur_tile_index]][get_cur_tile_edited_side()].duplicate()
		$SwapArea.load_tiles()

func _on_Save_pressed():
	if cur_tile_index>=0:
		if $SwapArea.SyncTiles.pressed:
			var cur_side = get_cur_tile_edited_side()
			var selected_tiles = $SwapArea.selected_tiles.duplicate()
			var cur_tiles = tiles_data[tiles_list[cur_tile_index]][cur_side]
			var added_tiles = $SwapArea.diffrences_of_a_from_b(selected_tiles,cur_tiles)
			var removed_tiles = $SwapArea.diffrences_of_a_from_b(cur_tiles,selected_tiles)
			
			var cur_tile_name : String = tiles_list[cur_tile_index]
			var mirror_side : String = mirror_sides[cur_side]
			for i in range(added_tiles.size()):
				if added_tiles[i]!=cur_tile_name:
					var can = true
					var mirror_data = tiles_data[added_tiles[i]][mirror_side].duplicate()
					for j in range(mirror_data.size()):
						if mirror_data[j]==cur_tile_name:
							can=false
							break
					if can:
						tiles_data[added_tiles[i]][mirror_side].append(cur_tile_name)
			
			for i in range(removed_tiles.size()):
				if removed_tiles[i]!=cur_tile_name and tiles_data.has(removed_tiles[i]):
					for j in range(tiles_data[removed_tiles[i]][mirror_side].size()):
						if tiles_data[removed_tiles[i]][mirror_side][j]==cur_tile_name:
							tiles_data[removed_tiles[i]][mirror_side].remove(j)
							break
			
			tiles_data[tiles_list[cur_tile_index]][cur_side]=selected_tiles
		else:
			tiles_data[tiles_list[cur_tile_index]][get_cur_tile_edited_side()]=$SwapArea.selected_tiles.duplicate()

const mirror_sides := {
	"x_plus":"x_minus",
	"x_minus":"x_plus",
	"y_plus":"y_minus",
	"y_minus":"y_plus",
	"z_plus":"z_minus",
	"z_minus":"z_plus",
}

func get_cur_tile_edited_side():
	match (cur_selection_btn.selected):
		0:
			return "x_plus"
		1:
			return "x_minus"
		2:
			return "y_plus"
		3:
			return "y_minus"
		4:
			return "z_plus"
		5:
			return "z_minus"
