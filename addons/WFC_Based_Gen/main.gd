@tool
extends EditorPlugin

func _get_plugin_name():
	return "WFC Rule Creator"


func _get_plugin_icon():
	# Must return some kind of Texture2D for the icon.
	#return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
	return load("res://addons/WFC_Based_Gen/icon.png")
