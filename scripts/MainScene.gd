extends Node

const blocks_list = {
	"Grass":"res://scenes/Blocks/Grass.tscn",
	"Rock":"res://scenes/Blocks/Rock.tscn",
	"Sand":"res://scenes/Blocks/Sand.tscn",
	"Sea":"res://scenes/Blocks/Sea.tscn",
}

const block_size = 2


onready var map = get_node("Demo-2D")
var x:=0
func _process(_delta):
	if x<1000:
		for y in range(500):
			var list : Array
			if map.has_node(str(x)+"x"+str(y-1)):
				list=map.get_node(str(x)+"x"+str(y-1)).aviable_near.duplicate()
			if map.has_node(str(x-1)+"x"+str(y)):
				if list.size()>0:
					list=compare(map.get_node(str(x-1)+"x"+str(y)).aviable_near.duplicate(),list.duplicate())
				else:
					list=map.get_node(str(x-1)+"x"+str(y)).aviable_near.duplicate()
			if list.size()==0:
				for key in blocks_list.keys():
					list.append(key)
			randomize()
			var block_name:String = list[rand_range(0,list.size())]
			var block = load(blocks_list[block_name]).instance() as Block
			block.name=str(x)+"x"+str(y)
			block.rect_min_size=Vector2(block_size,block_size)
			block.rect_size=Vector2(block_size,block_size)
			map.add_child(block)
			block.rect_position = Vector2(x*block_size,y*block_size)
			block.x=x
			block.y=y
		x+=1



func compare(array_a:Array,array_b:Array) -> Array:
	var array_c := []
	for i in range(array_a.size()):
		var bl : String = array_a[i]
		for j in range(array_b.size()):
			if array_b[j]==bl:
				array_c.append(bl)
	return array_c
