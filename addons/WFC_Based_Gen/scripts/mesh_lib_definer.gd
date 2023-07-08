@tool
extends Resource
class_name MeshLibDefiner

@export var items := [] : set = set_items

func set_items(val:Array):
	for v in val.size():
		if val[v]==null or !(val[v] is MeshLibItem):
			val[v]=MeshLibItem.new()
	items = val

func get_meshlib()->MeshLibrary:
	var meshlib = MeshLibrary.new()
	for i in items.size():
		var item :MeshLibItem = items[i]
		meshlib.create_item(i)
		meshlib.set_item_mesh(i,item.mesh)
		meshlib.set_item_mesh_transform(i,item.transform)
		meshlib.set_item_name(i,item.object_name)
		if item.auto_generate_collision and item.mesh!=null:
			meshlib.set_item_shapes(i,[item.mesh.create_trimesh_shape()])
		else:
			meshlib.set_item_shapes(i,[item.collision])
	return meshlib

func get_item_ignore_rotation(id:int)->bool:
	if items[id]:
		return items[id].ignore_rotation
	printerr("Item ID "+str(id)+" not found... ignore rotation...")
	return true

func get_item_weight(id:int)->float:
	if items[id]:
		return items[id].weight
	printerr("Item ID "+str(id)+" not found... weight 1.0 ...")
	return 1.0

func get_item_name(id:int)->String:
	if items[id]:
		return items[id].object_name
	printerr("Item ID "+str(id)+" not found... empty string ...")
	return ""

func get_starter_tiles()->Array:
	var tiles := []
	for i in items.size():
		if items[i].starter_tile:
			tiles.append(i)
	return tiles
