# Rafaela's Localization Addon

In most of my Godot projects throught the years I have used variations of the same Localization system.
So I thought, "If I'm gonna put this in all of my projects, wouldn't it be easier to just make it an Addon?"

There are comments on the code explaining how it works and an example in the demo folder (you can try it on the web, here: https://rafaelaoverflow.github.io/localization_addon_example.html) , but here's an overview:


## Localization

<details><summary><h3>Loading Localization Data</h3></summary> 

You can set the localization data manually

	Localization.loc_data = {localization data inside here}

Or use the very handy Localization.load_localization method! (to use it you must store your Localization as files in the JSON format (they don't need to end in ".json" though))

	Localization.load_localization(language id, array of folders where localization is located (default = ["res://localization/"]))
By default it will expect a format like this:

	{
		"id":language id here,
		"loc":{
			localization data here
		}
	}
But what if your files are organized like this?

	{
		"info":{
			"id":language id here
		}
		"data":{
			localization data
		}
	}
Then you can: 

	Localization.load_localization(language id, array with localizations folder, "info.id","data")

However, what if instead of having the language id in your localization file, each language has a folder? And also the files are like this?

	{
		localization data
	}
Then you should:

	Localization.load_localization("",\[localization folder of the language you want\],"","")
</details>
<details><summary><h3>Localization.localize</h3></summary>

Here is where the magic happens.
You can call with just the id: 

	Localization.localize("ui.main_menu.button.new_game")
Or with arguments as well: 

	Localization.localize("ui.hud.health_display",{"hp":50})

Let's say your localization data is like this:

	{
		"nothing":"nothing"
		"show_number":"{{%::number}}",
		"animal":"{{locmap::animal_map::animal}}"
		"animal_map":{
			"cow":"cow",
			"sheep":"sheep"
		}
	}
Then:

	Localization.localize("nothing") -> "nothing"
	Localization.localize("show_number",{"number":5}) -> "5"
	Localization.localize("animal",{"animal":"cow"}) -> "cow"
</details>
<details><summary><h3>Auto Update Localization</h3></summary>

When you use Localization.load_localization, after it finishes it calls Localization.emit_update() which emits a signal.
You can connect a function to the signal with Localization.connect_signal(function).

So you could have a script like this:

	extends Control

	@onready var new_game_button = $VBoxContainer/NewGameButton

	func _ready():
		Localization.connect_signal(update_localization)

	func update_localization() -> void:
		new_game_button.text = Localization.localize("ui.main_menu.")
And it will automatically update when the language is changed!
You can also manually call Localization.emit_update() any time you want!
</details>
<details><summary><h3>Text Functions</h3></summary>

Here's the most fun part!
You already seem some ("%" and "locmap") at the Localization.localize section.
Basically, when you call localize, it doesn't return the raw localization text, it processes it first.
During processing it replaces your functions with its return.
A function starts with "{{" and ends with "}}" and you can even have functions inside functions!

	Localization.process_text("{{bbcode::font_size=50::{{bbcode::color=red::test}}}}") -> "[font_size=50][color=red]test[/color][/font_size]"
A function's arguments are split with "::"

if you don't like "{{", "::" and "}}", then you can:

	Localization.set_open(replacement for "{{")
	Localization.set_close(replacement for "}}")
	Localization.set_split(replacement for "::")

You can add your own functions if you want (you can see how in the section after this one).
Here are the functions that come with the addon:

#### "#"
This always returns an empty string ("")
So you can use it to write comments on the text:

	"test blah blah blah {{#::nobody will be able to see this}}" -> "test blah blah blah"

#### "%"

	args = {"value":5.5}
	"{{%::value}}" -> "%s" % value -> "5.5"
	"{{%::value::%d}}" -> "%d" % value -> "5"

#### bbcode
(Remember to enable BBCode on the RichTextLabel)

	"{{bbcode::b::test}}" -> "[b]test[/b]"
	"{{bbcode::color=red::test}}" -> "[color=red]test[/color]"
	args = {"size":30}
	"{{bbcode::font_size=$size::test}}" -> "[font_size=30]test[/font_size]"

#### cap
Capitalizes

	"{{cap::test}}" -> "Test"

#### compare

	args = {"value":5}
	"{{compare::value::==::5::Yes::No}}" -> "Yes"
	"{{compare::value::==::6::Yes::No}}" -> "No"
	"{{compare::value::!=::5::Yes::No}}" -> "No"
	"{{compare::value::!=::6::Yes::No}}" -> "Yes"
	"{{compare::value::>=::5::Yes::No}}" -> "Yes"
	"{{compare::value::>=::6::Yes::No}}" -> "No"
	"{{compare::value::>::5::Yes::No}}" -> "No"
	"{{compare::value::>::4::Yes::No}}" -> "Yes"
	"{{compare::value::<=::5::Yes::No}}" -> "Yes"
	"{{compare::value::<=::4::Yes::No}}" -> "No"
	"{{compare::value::<::5::Yes::No}}" -> "No"
	"{{compare::value::<::6::Yes::No}}" -> "Yes"

#### if
	args = {"value":true}
	"{{if::value::Yes}}" -> "Yes"
	"{{if::value::Yes::No}}" -> "No"
	args = {"value":false}
	"{{if::value::Yes}}" -> ""
	"{{if::value::Yes::No}}" -> "No"

#### loc

	loc_data = {
		"thing": "the thing"
		"things":{
			"0":"thing 0",
			"1":"thing 1",
			"%":"thing {{%::thing}}"
		}
	}
	"{{loc::thing}}" -> localizes thing -> "the thing"
	"{{loc::things.0}}" -> localizes things.0 -> "thing 0"
	args = {"loc_id":"things.%","thing":5}
	"{{loc::$loc_id}}" -> localizes things.% -> "thing {{%::thing}}" -> "thing 5"

#### locmap

	loc_data = {
		"animal_map":{
			"cow":"The Cow",
			"sheep":"The Sheep"
		}
	}
	args = {"animal":"cow"}
	"{{locmap::animal_map::animal}}" -> localizes animal_map.cow -> "The Cow"

#### !locmap

	loc_data = {
		"cow":{
			"sound":"moo"
		},
		"sheep":{
			"sound":"bah"
		}
	}
	args = {"animal":"cow"}
	"{{!locmap::sound::animal}}" -> localizes cow.sound -> "moo"

#### locmap!

	loc_data = {
		"animal_map" : {
			"cow":{
				"sound":"moo"
			},
			"sheep":{
				"sound":"bah"
			}
		}
	}
	args = {"animal":"cow"}
	"{{!locmap::animal_map::animal::sound}}" -> localizes animal_map.cow.sound -> "moo"

#### locarr

	loc_data = {
		"person_desc": "Name: {{%::person.name}} | Age: {{%::person.age}}" 
	}
	args = {
		"people" = [
			{"name":"John","age":20},
			{"name":"Rafaela","age":22}
		]
	}
	"{{locarr::person_desc::people::person::\n}}" -> "Name: John | Age: 20\nName: Rafaela | Age: 22"

#### locdict

	loc_data = {
		"person_desc": "Name: {{%::name}} | Age: {{%::age}}" 
	}
	args = {
		"people" = {
			"John":20,
			"Rafaela":22
		}
	}
	"{{locdict::person_desc::people::name::age::\n}}" -> "Name: John | Age: 20\nName: Rafaela | Age: 22"

#### "map"

	args = {"animal":"cow"}
	"{{map::animal::cow==moo::chicken==noise chicken makes}}" -> "moo"

#### "quote"

	"{{quote::test}}" -> "\"test\""

#### "random"

	"{{random::Italy::France::Türkiye}}" -> could be any of these: "Italy", "France" or "Türkiye"

#### "range"

	args = {"value":50}
	"{{range::value::20--A::40--B::50--C::60--D::E}}" -> "C"
	args = {"value":51}
	"{{range::value::20--A::40--B::50--C::60--D::E}}" -> "D"
	args = {"value":61}
	"{{range::value::20--A::40--B::50--C::60--D::E}}" -> "E"
	args = {"value":0}
	"{{range::value::20--A::40--B::50--C::60--D::E}}" -> "A"
</details>
<details><summary><h3>Adding Custom Functions</h3></summary>

You can use Localization.register_function to add a custom function.

	Localization.register_function(function id, function)

It's important to remember that the function always takes two parameters: post and args
Post is everything after the first split ("::") so the post of "{{bbcode::font_size=50::text}}", would be "font_size=50::text"
Args is the arguments you used when calling Localization.localize plus the global arguments

	Localization.localize(localization id, dictionary containing the arguments (AKA args) here)
	(Doing Localization.localize(localization id) is the same as Localization.localize(localization id, {}))

To add a global argument you can:

	Localization.add_global_arg(argument id, argument)

#### RECURSIVE GET AND MAYBE GET

Let's say we want to make a function that returns PI multiplied by a value:

	Localization.register_function("pitimes", func(post,args):
		return "%s" % (PI*post.to_float())
	)
	Localization.process_text("{{pitimes::5}}") -> "15.708"
But what if we want to get the value from an argument?

	Localization.register_function("pitimes", func(post,args):
		post = Localization.recursive_get(post,args)
		if post is String: post = post.to_float()
		return "%s" % (PI*post)
	)
Why recursive_get instead of simply args.get(post)?

	with normal get you can only do this:
	Localization.process_text("{{pitimes::value}}",{"value":5}) -> "15.708"
	with recursive_get you can also do this:
	Localization.process_text("{{pitimes::test.value}}",{"test":{"value":5}}) -> "15.708"
Okay, but what if sometimes I want to get the value from an argument and sometimes just get a value I wrote?

	Localization.register_function("pitimes", func(post,args):
		post = Localization.maybe_get(post,args)
		if post is String: post = post.to_float()
		return "%s" % (PI*post)
	)
	Localization.process_text("{{pitimes::5}}") -> "15.708"
	Localization.process_text("{{pitimes::$value}}",{"value":5}) -> "15.708"
	Localization.process_text("{{pitimes::$test.value}}",{"test":{"value":5}}) -> "15.708"

#### POST SPLITTING

Let's say you want a function that repeats something a certain amount of times:

	Localization.register_function("repeat",func(post,args):
		var x = Localization.post_split(post)
		var text = Localization.maybe_get(x[0],args)
		var amount = Localization.maybe_get(x[1],args)
		if amount is String: amount = amount.to_int()
		return text[0].repeat(amount)
	)
	Localization.process_text("{{repeat::test::2}}") -> "testtest"
	Localization.process_text("{{repeat::$0::$1}}",{"0":"test","1":2}) -> "testtest"
	Localization.process_text("{{repeat::{{pitimes::5}}::2}}") -> "15.70815.708"
Now, why didn't I use the default split function?

	"{{repeat::{{pitimes::5}}::2}}" -> post = {{pitimes::5}}::2
	post.split(LOCALIZATION.SPLIT) -> ["{{pitimes",    "5}}",    "2"] WRONG, BREAKS THINGS
	Localization.post_split(post) -> ["{{pitimes::5}}",    "2"] CORRECT, WORKS PERFECTLY

#### Recommendation

I would recommend you register functions before loading localization if you don't want a bunch of ERROR: MISSING FUNCTION on your games text!
You could do something like this:

	func _ready() -> void:
		initialize_localization()

	func initialize_localization() -> void:
		Localization.register_function(id, function)
		Localization.register_function(id2, function2)
		Localization.register_function(id3, function3)
		Localization.register_function(id4, function4)
		Localization.register_function(id5, function5)
		Localization.add_global_arg("main",self)
		Localization.load_localization(language_id)

</details>

<details><summary><h2>Localizer</h2></summary>

A simple node that automatically updates the localization of nodes.
It exports a dictionary where the keys are nodes and the values are PackedStringArrays.

Let's say you have a button. You have localization for its "text" variable and for its "tooltip_text" variable.
The id of the text localization is "ui.button" and the id of the tooltip_text localization is "ui.tooltip.button".
Then you: 

-Add a Localizer node to the scene

-Add the button as a key

-Then you insert in the array "text", "ui.button", "tooltip_text" and "ui.tooltip.button" (it's always the name of a variable followed by a localization id)

-It is done (don't forget to press "Add Key/Value Pair")

</details>

### Ko-Fi:
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E4Y5I7B)