extends Node
class_name Localizer

# you don't need to use this node to localize stuff if you don't want to
# as an example, if you want to localize the text of a label, you can just:
# label.text = Localization.localize(*localization id goes here*)
# or if you have arguments you can:
# label.text = Localization.localize(*localization id goes here*,*dictionary containing arguments goes here*)
# this node does not localize with any arguments.

@export var targets : Dictionary[Node,PackedStringArray]
# if nested collection types where allowed, I would do Dictionary[Node,Dictionary[StringName,String]]
# but alas that is not possible
# so please remember it's [var_name,localization_id,var_name,localization_id,var_name,localization_id...]
# example ["text","button.new_game","tooltip_text","tooltip.new_game"]

func _ready() -> void:
	localize()
	Localization.connect_signal(localize)

func localize() -> void:
	for t : Node in targets.keys():
		var s : PackedStringArray = targets[t]
		for i in s.size()/2: t.set(s[i*2],Localization.localize(s[i*2+1]))
