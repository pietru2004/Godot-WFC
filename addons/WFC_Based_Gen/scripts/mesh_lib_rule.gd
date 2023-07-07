@tool
extends Resource
class_name MeshLibRule

@export var id := 0
@export var object_name := ""
@export var rotation := 0

@export var front := [] #Z-
@export var back := [] #Z+
@export var left := [] #X-
@export var right := [] #X+
@export var down := [] #Y-
@export var up := [] #Y+

func add_item_front(id:int,item:MeshLibItem,rotation:int):
	add_item(front,id,item,rotation)

func add_item_back(id:int,item:MeshLibItem,rotation:int):
	add_item(back,id,item,rotation)

func add_item_right(id:int,item:MeshLibItem,rotation:int):
	add_item(right,id,item,rotation)

func add_item_left(id:int,item:MeshLibItem,rotation:int):
	add_item(left,id,item,rotation)

func add_item_down(id:int,item:MeshLibItem,rotation:int):
	add_item(down,id,item,rotation)

func add_item_up(id:int,item:MeshLibItem,rotation:int):
	add_item(up,id,item,rotation)

func add_item(array:Array,id:int,item:MeshLibItem,rotation:int):
	var can = true
	if item.ignore_rotation:
		for object in array:
			if object as MeshLibRuleItem:
				if object.id==id:
					can = false
		if !can:
			return
		add_rule(array,id,item,rotation)
		
	for object in array:
		if object as MeshLibRuleItem:
			if object.id==id and object.rotation==rotation:
				can = false
	if !can:
			return
	add_rule(array,id,item,rotation)

func add_rule(array:Array,id:int,item:MeshLibItem,rotation:int):
	var rule = MeshLibRuleItem.new()
	rule.id=id
	rule.rotation=rotation
	rule.object_name=item.object_name
	rule.weight=item.weight
	array.append(rule)
