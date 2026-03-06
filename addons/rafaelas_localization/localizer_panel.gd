@tool
extends Control

const TARGET = preload("res://addons/rafaelas_localization/localizer_target.tscn")

@onready var localizer_stuff: ScrollContainer = $LocalizerStuff
@onready var no_localizer: HBoxContainer = $NoLocalizer
@onready var localizer_targets: VBoxContainer = %LocalizerTargets

@onready var dock : EditorDock = get_parent()


func _ready() -> void:
	pass

var localizer_node : Localizer = null

func _process(delta: float) -> void:
	var scene = get_tree().edited_scene_root
	if scene == null:
		localizer_node = null
	else:
		var new_localizer = scene.get_node_or_null("Localizer")
		if new_localizer == null:
			localizer_node = null
		elif new_localizer != localizer_node:
			localizer_node = new_localizer
			update_localizer_stuff()
	no_localizer.visible = localizer_node == null
	localizer_stuff.visible = localizer_node != null

func update_localizer_stuff() -> void:
	for child in localizer_targets.get_children():
		child.queue_free()
	for key in localizer_node.targets.keys():
		var target = TARGET.instantiate()
		target.key = key
		target.localizer = localizer_node
		localizer_targets.add_child(target)

func _on_node_selected(path:NodePath) -> void:
	var node = get_tree().edited_scene_root.get_node_or_null(path)
	if node == null: return
	if !node in localizer_node.targets.keys():
		var target = TARGET.instantiate()
		localizer_node.targets.set(node,PackedStringArray())
		target.key = node
		target.localizer = localizer_node
		localizer_targets.add_child(target)
		EditorInterface.mark_scene_as_unsaved()

func _on_add_node_button_pressed() -> void:
	EditorInterface.popup_node_selector(_on_node_selected)

func _on_add_localizer_pressed() -> void:
	var l = Localizer.new()
	l.name = "Localizer"
	get_tree().edited_scene_root.add_child(l)
	l.owner = get_tree().edited_scene_root
