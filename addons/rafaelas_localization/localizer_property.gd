@tool
extends HBoxContainer

var localizer : Localizer
var key : Node
@onready var property: LineEdit = %Property
@onready var localization_id: LineEdit = %LocalizationId

func _ready() -> void:
	var i = get_index()*2
	property.text = localizer.targets[key][i]
	localization_id.text = localizer.targets[key][i+1]

func _on_property_text_changed(new_text: String) -> void:
	var i = get_index()*2
	localizer.targets[key][i] = new_text
	EditorInterface.mark_scene_as_unsaved()

func _on_localization_id_text_changed(new_text: String) -> void:
	var i = get_index()*2
	localizer.targets[key][i+1] = new_text
	EditorInterface.mark_scene_as_unsaved()

func _on_remove_pressed() -> void:
	var i = get_index()*2
	localizer.targets[key].remove_at(i)
	localizer.targets[key].remove_at(i)
	queue_free()
	EditorInterface.mark_scene_as_unsaved()
