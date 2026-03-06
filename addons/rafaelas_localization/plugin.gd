@tool
extends EditorPlugin

var localizer_panel

func _enter_tree() -> void:
	localizer_panel = EditorDock.new()
	localizer_panel.title = "Localizer"
	localizer_panel.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	#localizer_panel.transient = true
	localizer_panel.add_child(preload("res://addons/rafaelas_localization/localizer_panel.tscn").instantiate())
	add_dock(localizer_panel)

func _exit_tree() -> void:
	remove_dock(localizer_panel)
	localizer_panel.queue_free()
	localizer_panel = null
