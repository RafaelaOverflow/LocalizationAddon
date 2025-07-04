extends Control

@onready var rich: RichTextLabel = $HBoxContainer/ScrollContainer/VBoxContainer/RichTextLabel
@onready var lob: OptionButton = $HBoxContainer/VBoxContainer/LanguageOptionButton

const LOC_FOLDER = "res://demo/rafaelas_localization/localization/"
var languages := [
	"en",
	"pt",
]
var current_language := "en"

var array := [
	"sheep",
	"cow",
	"chicken",
]
var people := {
	"john" : {"age":20,"job":"gamer","gender":"m"},
	"rafaela" : {"age":22,"job":"dev","gender":"f"}
}
var wacky_map_value : String = (["0","cow","planet"].pick_random())
var default_font_size : int = 30
func localization_setup() -> void:
	Localization.add_global_arg("main",self)
	Localization.register_function("repeat",func(post,args):
		var x = Localization.post_split(post)
		var text = Localization.maybe_get(x[0],args)
		var amount = Localization.maybe_get(x[1],args)
		if amount is String: amount = amount.to_int()
		return text.repeat(amount)
	)
	Localization.connect_signal(localization_update)
	Localization.load_localization("en",[LOC_FOLDER])

func localization_update() -> void:
	lob.clear()
	for l in languages:
		lob.add_item(Localization.localize("language.%s"%l))
	lob.selected = languages.find(current_language)

func _ready() -> void:
	localization_setup()

func _on_update_loc_button_pressed() -> void:
	Localization.emit_update()


func _on_toggle_bb_code_button_pressed() -> void:
	rich.bbcode_enabled = !rich.bbcode_enabled


func _on_raw_text_button_pressed() -> void:
	rich.text = "[font_size=%s]" % default_font_size +Localization.recursive_get("ui.main.rich",Localization.loc_data)


var repeats = 1
func _on_spin_box_value_changed(value: float) -> void:
	repeats = int(value)
	Localization.emit_update()

func _on_see_code_button_pressed() -> void:
	rich.text = "[font_size=%s]" % default_font_size + get_script().source_code

func _on_spin_box_2_value_changed(value: float) -> void:
	default_font_size = int(value)
	Localization.emit_update()

func _on_language_option_button_item_selected(index: int) -> void:
	current_language = languages[index]
	Localization.load_localization(current_language,[LOC_FOLDER])

var repeat = "test"
func _on_line_edit_text_changed(new_text: String) -> void:
	repeat = new_text
