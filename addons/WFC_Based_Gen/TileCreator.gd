@tool
extends Control


var tiles_list := []
var tiles_data := {}

func load_tiles():
	get_node("ItemListCont/ItemList").clear()
	for i in range(tiles_list.size()):
		get_node("ItemListCont/ItemList").add_item(tiles_list[i])

var cur_tile_index := -1

func create_tile():
	var tile_name = get_node("TileName").text
	if tile_name.length()>0:
		tiles_list.append(tile_name)
		tiles_data[tile_name]={
			"mesh_path":"",
			"x_plus":[],
			"x_minus":[],
			"y_plus":[],
			"y_minus":[],
			"z_plus":[],
			"z_minus":[],
		}
		load_tiles()
		get_node("TileName").text=""
		await get_tree().idle_frame
		get_node("ItemListCont/ItemList").select(tiles_list.size()-1)
		_on_ItemList_item_selected(tiles_list.size()-1)

func DeleteTile():
	if cur_tile_index>=0:
		var tile_name = tiles_list[cur_tile_index]
		tiles_list.remove(cur_tile_index)
		tiles_data.erase(tile_name)
		load_tiles()
		_on_ItemList_nothing_selected()

func similarities(array_a:Array,array_b:Array) -> Array:
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		for j in range(array_b.size()):
			if array_b[j]==bl:
				array_c.append(bl)
	return array_c

func diffrences(array_a:Array,array_b:Array) -> Array:
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		var can = true
		for j in range(array_b.size()):
			if array_b[j]==bl:
				can=false
		if can:
			array_c.append(bl)
	return array_c

func _on_ItemList_item_selected(index):
	var tile_name = tiles_list[index]
	get_node("CurEdit").text="Editing: "+tile_name
	cur_tile_index=index


func _on_ItemList_nothing_selected():
	get_node("CurEdit").text=""
	cur_tile_index=-1




