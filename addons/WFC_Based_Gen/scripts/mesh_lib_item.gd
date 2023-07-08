@tool
extends Resource
class_name MeshLibItem

@export var mesh : Mesh
@export var collision : Shape3D
@export var auto_generate_collision := true
@export var ignore_rotation := true
@export var starter_tile := true
@export var weight := 1.0
@export var object_name := ""
@export var transform := Transform3D.IDENTITY
