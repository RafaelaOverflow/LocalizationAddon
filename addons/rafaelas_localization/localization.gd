extends Node
class_name Localization

# no static signals, so I have to do this:
class Updater:
	signal update()
static var updater:=Updater.new()
static func connect_signal(function:Callable) -> void: updater.update.connect(function)
static func emit_update() -> void:updater.update.emit()
# this signal is emmited when the localization is loaded
# (so you can automatically update labels,buttons, etc whenever the language changes)

#you can change these if you want, I would recommend keeping the OPEN and CLOSE the same length
static var OPEN := "{{"
static var OPENL := 2 # I have these l variables, because I assume it would be more performant than to call .lenght() every time
static func set_open(open:String) -> void:
	OPEN = open
	OPENL = open.length()
static var CLOSE := "}}"
static var CLOSEL := 2 
static func set_close(close:String) -> void:
	CLOSE = close
	CLOSEL = close.length()
static var SPLIT := "::"
static var SPLITL := 2
static func set_split(split:String) -> void:
	SPLIT = split
	SPLITL = split.length()

static func load_dict(base : Dictionary, delta : Dictionary) -> Dictionary:
	for key in delta.keys():
		if base.has(key):
			if typeof(base[key]) == typeof(delta[key]):
				if typeof(base[key]) == TYPE_DICTIONARY:
					load_dict(base[key],delta[key])
				elif typeof(base[key]) == TYPE_ARRAY:
					base[key] = delta[key]
				else:
					base[key] = delta[key]
			else: base[key] = delta[key]
		else: base[key] = delta[key]
	return base

static var loc_data := {}
# you can set loc_data manually if you want,
# but there's this function here below where you can just inform the folders you localization files are located 
# and it will do it for you!
# It assumes you are using the JSON format for you localization files.
# you can change where it gets the id (with id_key) and the localization data (with loc_key)
# like if your localization files look like the following
# {"info":{"language_id":"[LANGUAGE ID HERE]"},"data":{}}
# you could call Localization.load_localization(lid,folders,"info.language_id","data")
# btw reminder to when exporting to make sure .json files get included in the export (if you are using .json files)
static func load_localization(lid : String,folders:=["res://localization/"],id_key:="id",loc_key:="loc") -> void: #lid = localization id / language id
	loc_data.clear()
	for folder in folders:
		for f in DirAccess.get_files_at(folder):
			f = folder + f
			var d : Dictionary = JSON.parse_string(FileAccess.get_file_as_string(f))
			if d == null:
				push_error("unable to load localization file: %s" % f)
			if id_key.is_empty() or recursive_get(id_key,d) == lid:
				if loc_key.is_empty(): load_dict(loc_data,d)
				else: load_dict(loc_data,recursive_get(loc_key,d))
	emit_update()

#hope you don't ever have to modify the 2 functions below (get_leng and post_split), they are hell
static func get_leng(text:String,start) -> int:
	var c = text.find(CLOSE,start)
	if c == -1: return -1
	var ns = text.find(OPEN,start)
	var open = text.countn(OPEN,start,c)
	if open > 0:
		var last_c = c
		while true:
			for i in open:
				c = text.find(CLOSE,c+CLOSEL)
			if c == -1: return -1
			open = text.countn(OPEN,last_c,c)
			last_c = c
			if open == 0: break
	return c - start
static func post_split(text:String) -> PackedStringArray:
	var array := PackedStringArray()
	var i = 0
	var splits = []
	for x in text.count(SPLIT):
		i = text.find(SPLIT,i)
		splits.append(i)
		i += SPLITL
	var sub = []
	i=0
	if OPEN in text:
		for n in text.count(OPEN):
			i = text.find(OPEN,i)
			if i == -1: break
			var v = Vector2i(i,0)
			i+=OPENL
			var leng = get_leng(text,i)
			if leng == -1: break
			i += leng
			v.y = i
			i += CLOSEL
			sub.append(v)
	for split in splits.duplicate():
		for v : Vector2i in sub:
			if split > v.x and split < v.y:
				splits.erase(split)
				break
	var last_split = 0
	splits.append(text.length())
	for split in splits:
		array.append(text.substr(last_split,split-last_split))
		last_split = split+SPLITL
	return array

#if you have a dict (let's it's name is d)
#and d = { "test_key":"test_value", "fruit":{"banana":"Banana"}}
#if you want to get test value you can just d.get("test_key") or even d["test_key"]
#but what if you want to get "Banana"?
#you can use recursive_get("fruit.banana",d)!!!
#recursive_get was made so you can organize you localization with sub dictionaries like
#{"ui":{
#	"main_menu":{
#		"button":{
#			"new_game":"Create New Game"
#		}
#	}
#}}
static func recursive_get(id : String, dict):
	var v = dict
	for i in id.split("."):
		v = v.get(i)
		if v == null: return id
	return v
static func maybe_get(value,dict:Dictionary,default=value):
	if !value is String: return value
	if value.begins_with("$"): return recursive_get(value.trim_prefix("$"),dict)
	if value.begins_with(OPEN): return Localization.process_text(value,dict)
	return default
#so here's what this is all about! Localization!
static func localize(id,args:={}) -> String:
	var text = recursive_get(id,loc_data)
	if text is Array: text = text.pick_random()
	return process_text(text,args)
#and this is where the text functions get processed!
#more on functions below!
static func process_text(text : String, args : Dictionary) -> String:
	while OPEN in text:
		var start = text.find(OPEN) + OPENL
		var leng = get_leng(text,start)
		if leng == -1: break
		var code = text.substr(start,leng)
		var value = from_code(code,args)
		text = text.replace(text.substr(start-OPENL,leng+4),str(value))
	return text

# here below are the functions that get called by the from_code function
# if you write {{do_thing::argument1::argument2}} then the "do_thing" function will be called 
# (assuming there's a function with that name)
# you can use Localization.register_function(id,function) to add a function!
# functions take two parameters "post" and "args" (in that order)
# -----------------------------------------------------------------------
# post is everything past the first "::"
# so in {{do_thing::argument1::argument2}}, it would be "argument1::argument2"
# but how do you separate argument1 from argument2?
# you can call Localization.post_split(post)!
# why not just use post.split("::")? because with that you are unable to have functions inside functions!
# an example: {{do_thing::argument1::{{do_thing2::argument2}}}}
# the post = argument1::{{do_thing2::argument2}}
# post with post_split =  ["argument1","{{do_thing2::argument2}}"]
# post with normal split = ["argument1","{{do_thing2","argument2}}"]
# -----------------------------------------------------------------------
# args is global_args + whatever you put in the args when calling the localize function
# (you can call localize without informing the args parameter, in which case it will just be an empty dictionary)
static var f : Dictionary[StringName,Callable]= {
		"#" : func(post,args): # comment function
			return "",
		"%" : func(post,args):
			var s = post_split(post)
			var v = recursive_get(maybe_get(s[0],args),args)
			return s[1] % v if s.size() == 2 else "%s" % v,
		"bbcode" : func(post,args):
			var x := post_split(post)
			if " " in x[0]:
				var x2 := x[0].split(" ")
				var x3 := ""
				var i = 0
				for x2_ in x2:
					if i > 0: x3+=" "
					var x3_ = x2_.split("=")
					x3 += "%s=%s" % [x3_[0],maybe_get(x3_[1],args)]
					i+=1
				return "[%s]%s[/%s]" % [x3,x[1],x2[0]]
			var x2 := x[0].split("=")
			if x2.size() == 2: return "[%s=%s]%s[/%s]" % [x2[0],maybe_get(x2[1],args),x[1],x2[0]]
			return "[%s]%s[/%s]" % [x[0],x[1],x[0]],
		"cap" : func(post,args):
			return process_text(maybe_get(post,args),args).capitalize(),
		"compare" : func(post,args):
			var c = post_split(post)
			var v = recursive_get(c[0],args)
			var compare = c[2].to_float() if c[2].is_valid_float() else c[2].to_int() if c[2].is_valid_int() else c[2]
			var r = false
			match c[1]:
				">": r = v > compare
				"<": r = v < compare
				">=": r = v >= compare
				"<=": r = v <= compare
				"==": r = v == compare
				"!=": r = v != compare
			if r: return c[3]
			return c[4] if c.size() == 5 else "",
		"if" : func(post,args):
			var x := post_split(post)
			var i = recursive_get(maybe_get(x[0],args),args)
			if bool(i): return x[1]
			return x[2] if x.size() == 3 else "",
		"loc" : func(post,args):
			return localize(maybe_get(post,args),args),
		"locmap" : func(post,args):
			var s = post_split(post)
			var v = recursive_get(s[1],args)
			return localize("%s.%s" % [s[0],v],args),
		"!locmap" : func(post,args):
			var s = post_split(post)
			var v = recursive_get(s[1],args)
			return localize("%s.%s" % [v,s[0]],args),
		"locmap!" : func(post,args):
			var s = post_split(post)
			var v = recursive_get(s[1],args)
			return localize("%s.%s.%s" % [s[0],v,s[1]],args),
		"locarr": func(post,args):
			var s = post_split(post)
			var loc_id = s[0]
			var g = s[1]
			var arr = recursive_get(g,args)
			var split
			if s.size() == 3:
				split = s[2]
			else:
				g = s[2]
				split = s[3]
			var t = ""
			if arr is Array:
				var size = arr.size()
				for i in size:
					if i != 0: t += split
					t += localize(loc_id,{g:arr[i],"args":args})
			return t,
		"locdict": func(post,args):
			var s = post_split(post)
			var loc_id = s[0]
			var dict = recursive_get(maybe_get(s[1],args),args)
			var n0 = s[2]
			var n1 = s[3]
			var split = s[4]
			var t = ""
			if dict is Dictionary:
				var i := 0
				for k in dict:
					if i != 0: t += split
					t += localize(loc_id,{n0:k,n1:dict[k],"args":args})
					i+=1
			return t,
		"map" : func(post,args):
			var s = post_split(post)
			var v = recursive_get(s[0],args)
			if !v is String: v = "%s" % v
			for i in range(1,s.size()):
				var s2 = s[i].split("==")
				if s2[0] == v: return s2[1]
			return "",
		"quote" : func(post,args):
			return "\"%s\"" % post,
		"random" : func(post,args):
			var x = Localization.post_split(post)
			return Array(x).pick_random(),
		"range" : func(post,args):
			var x := post_split(post)
			var v = recursive_get(maybe_get(x[0],args),args)
			x.remove_at(0)
			for x2 in x:
				var y = x2.split("--")
				if y.size() == 1: return y[0]
				if v <= y[0].to_float(): return y[1]
			return "",
	}
# remember to make sure you function takes the parameters post and args
static func register_function(id:StringName,function:Callable) -> void: f[id] = function
# if you don't want any of my premade functions, you can remove them all with this
static func clear_functions() -> void: f.clear()

static var global_args := {}
static func add_global_arg(id:StringName,arg) -> void: global_args[id] = arg
static func from_code(code : String, args = {}):
	args.merge(global_args)
	var divide = code.find(SPLIT)
	var pre = code.substr(0,divide)
	divide += SPLITL
	var post = code.substr(divide, code.length()-divide)
	return f.get(pre,func(post,args):
			return "ERROR: MISSING FUNCTION '%s'" % pre
			).call(post,args)
