@tool
extends Resource
class_name MeshLibRulesSet

@export var items := [] : set = set_items
@export var force_list_fix := false
@export var force_integrity_check := true

func set_items(val:Array):
	var can = true
	for v in val.size():
		if val[v]==null or !(val[v] is MeshLibRule):
			if force_integrity_check:
				can=false
				break
			if force_list_fix:
				val[v]=MeshLibRule.new()
	if can:
		items = val

func add_get_item(id,item:MeshLibItem,rotation:int)->MeshLibRule:
	var rule=null
	for object in items:
		if object as MeshLibRule:
			if object.id==id:
				if item.ignore_rotation:
					rule=object
				if object.rotation==rotation:
					rule=object
	if rule == null:
		rule = MeshLibRule.new()
		rule.id=id
		rule.object_name=item.object_name
		rule.rotation=rotation
		items.append(rule)
	return rule

func get_item(id,ignore_rot:bool,rotation:int)->MeshLibRule:
	var rule=null
	for object in items:
		if object as MeshLibRule:
			if object.id==id:
				if ignore_rot:
					rule=object
				if object.rotation==rotation:
					rule=object
	if rule==null:
		rule = MeshLibRule.new()
		rule.id=-1
	return rule

func pick_random_tile(restrictions:Array)->MeshLibRule:
	if restrictions.size()==0:
		return items.pick_random()
	var tiles := []
	for rule in items:
		if restrictions.has(rule.id):
			tiles.append(rule)
	return tiles.pick_random()
