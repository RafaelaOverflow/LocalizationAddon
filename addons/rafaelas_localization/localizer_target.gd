@tool
extends HBoxContainer

const PROPERTY = preload("res://addons/rafaelas_localization/localizer_property.tscn")

@onready var node_label: Label = %NodeLabel
@onready var properties: VBoxContainer = %Properties

var localizer : Localizer
var key : Node

func _ready() -> void:
	node_label.text = key.name
	node_label.tooltip_text = key.get_path()
	var arr = localizer.targets[key]
	for i in (arr.size()/2):
		var p = PROPERTY.instantiate()
		p.key = key
		p.localizer = localizer
		properties.add_child(p)

func _on_remove_pressed() -> void:
	localizer.targets.erase(key)
	queue_free()
	EditorInterface.mark_scene_as_unsaved()

func _on_add_property_pressed() -> void:
	localizer.targets[key].append_array(["",""])
	var p = PROPERTY.instantiate()
	p.key = key
	p.localizer = localizer
	properties.add_child(p)
	EditorInterface.mark_scene_as_unsaved()
