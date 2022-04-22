tool
extends Control

var all_tiles := []
var selected_tiles := []

onready var unselected_list = $NotSelected/ItemList
onready var selected_list = $Selected/ItemList

onready var SyncTiles = $SyncTiles

func load_tiles():
	unselected_list.clear()
	selected_list.clear()
	for i in range(all_tiles.size()):
		var can = can_select(all_tiles[i])
		if can:
			unselected_list.add_item(all_tiles[i],null,can)
		else:
			unselected_list.add_item("",null,can)
	for i in range(selected_tiles.size()):
		selected_list.add_item(selected_tiles[i])

func can_select(tile_name) -> bool:
	var can = true
	for i in range(selected_tiles.size()):
		if tile_name==selected_tiles[i]:
			can = false
	return can

func select():
	var items = unselected_list.get_selected_items()
	for i in range(items.size()):
		selected_tiles.append(all_tiles[items[i]])
	unselected_list.unselect_all()
	load_tiles()

func un_select():
	var items = selected_list.get_selected_items()
	var tmp := []
	for i in range(items.size()):
		tmp.append(selected_tiles[items[i]])
	selected_tiles = diffrences_of_a_from_b(selected_tiles.duplicate(),tmp)
	unselected_list.unselect_all()
	load_tiles()


func similarities(array_a:Array,array_b:Array) -> Array:
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		for j in range(array_b.size()):
			if array_b[j]==bl:
				array_c.append(bl)
	return array_c

func diffrences_of_a_from_b(array_a:Array,array_b:Array) -> Array:
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
