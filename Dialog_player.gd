extends Node

onready var _body_animationplayer = find_node("Body_AnimationPlayer")
onready var _body_label = find_node("Body_Label")
onready var _dialog_box = find_node("Dialog_Box")
onready var _speaker_label = find_node("Speaker_Label")
onready var _confirm_icon = find_node("Confirm_NinePatchRect")
onready var _option_list = find_node("Option_List")
onready var _select_option = find_node("SelectOption_NinePatchRect")
onready var _registry = get_node("/root/Registry")
onready var _player = get_node("/root/Player")
onready var _portrait = get_node("Dialog_Box/Body_NinePatchRect/Character_portrait")

onready var _option_scene = load("res://Option.tscn")

signal dialog_closed(corpo_id)

var _did = 0
var _nid = 0
var _final_nid = 0
var _current_corpo_id
var _story_reader
var _portrait_library : Dictionary = {}

func _ready():
	var Story_Reader_Class = load("res://addons/EXP-System-Dialog/Reference_StoryReader/EXP_StoryReader.gd") 
	_story_reader = Story_Reader_Class.new()

	var story = load("res://test_worker_baked.tres")
	_story_reader.read(story)

	_load_portraits()

	_dialog_box.visible = false
	_confirm_icon.visible = false
	_option_list.visible = false
	_select_option.visible = false

	_clear_options()

	# play_dialog("DialogPlayer/Branching")

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_SPACE and event.pressed == true:
			_on_Dialog_Player_pressed_spacebar()
			

func _on_Dialog_Player_pressed_spacebar():
	if _is_waiting():
		_confirm_icon.visible = false
		_portrait.visible = false
		_get_next_node()
		if _is_playing():
			_play_node()

func _on_Body_AnimationPlayer_animation_finished(anim_name):
	if _option_list.get_child_count() == 0:
		_confirm_icon.visible = true
	else:
		_select_option.visible = true
		_option_list.visible = true

func _on_Option_clicked(slot):
	_select_option.visible = false
	_option_list.visible = false
	_portrait.visible = false
	_get_next_node(slot)
	_clear_options()
	if _is_playing():
		_play_node()

func play_dialog(record_name : String):
	_did = _story_reader.get_did_via_record_name(record_name)
	_nid = _story_reader.get_nid_via_exact_text(_did, "<start>")
	_final_nid = _story_reader.get_nid_via_exact_text(_did, "<end>")

	_get_next_node()
	_play_node()

	_dialog_box.visible = true

func _clear_options():
	var children = _option_list.get_children()
	for child in children:
		_option_list.remove_child(child)
		child.queue_free()
	
func _inject_variables(text : String) -> String:
	var variable_count = text.count("<var>")

	for i in range(variable_count):
		var variable_name = _get_tagged_text("var", text)
		var variable_value = _registry.lookup(variable_name)
		var start_index = text.find("<var>")
		var end_index = text.find("</var>") + "</var>".length()
		var substr_length = end_index - start_index
		text.erase(start_index, substr_length)
		text = text.insert(start_index, str(variable_value))

	return text

func _inject_corpospeak(text : String, tag : String):
	var start_tag = "<" + tag + ">"
	var end_tag = "</" + tag + ">"
	var phrases_count = text.count(start_tag)
	var known_corpospeak = _registry.lookup("player/corpo_dict")

	for i in range(phrases_count):
		var phrase_id = _get_tagged_text(tag, text)
		_current_corpo_id = phrase_id
		var corpo
		if tag == "corpoPhrase":
			corpo = known_corpospeak.get(phrase_id).phrase 
		elif tag == "corpoReaction":
			corpo = known_corpospeak.get(phrase_id).reaction
		var start_index = text.find(start_tag)
		var end_index = text.find(end_tag) + end_tag.length()
		var substr_length = end_index - start_index
		text.erase(start_index, substr_length)
		text = text.insert(start_index, str(corpo))

	return text

func _is_playing() -> bool:
	return _dialog_box.visible 

func _is_waiting() -> bool:
	return _confirm_icon.visible

func _load_portraits():
	var did = _story_reader.get_did_via_record_name("DialogPlayer/CharacterPortraits")
	var json_text = _story_reader.get_text(did, 1)
	var raw_portrait_library : Dictionary = parse_json(json_text)

	for key in raw_portrait_library:
		var portrait_path = raw_portrait_library[key]
		var loaded_portrait = load(portrait_path)
		_portrait_library[key] = loaded_portrait

func _get_next_node(slot : int = 0):
	_nid = _story_reader.get_nid_from_slot(_did, _nid, slot)

	if _nid == _final_nid:
		_dialog_box.visible = false
		emit_signal("dialog_closed", _current_corpo_id)

func _get_tagged_text(tag : String, text : String) -> String:
	var start_tag = "<" + tag + ">"
	var end_tag = "</" + tag + ">"
	var start_index = text.find(start_tag) + start_tag.length()
	var end_index = text.find(end_tag)
	var substr_length = end_index - start_index
	return text.substr(start_index, substr_length)

func _play_node():
	var text = _story_reader.get_text(_did, _nid)
	text = _inject_variables(text)
	text = _inject_corpospeak(text, "corpoPhrase")
	text = _inject_corpospeak(text, "corpoReaction")
	var speaker = _get_tagged_text("speaker", text)
	var dialog = _get_tagged_text("dialog", text)
	
	if "<choiceJSON>" in text:
		var options = _get_tagged_text("choiceJSON", text)
		_populate_options(options)
	if "<portrait>" in text:
		var portrait_key = _get_tagged_text("portrait", text)
		_display_portrait(portrait_key)

	_speaker_label.text = speaker
	_body_label.text = dialog
	_body_animationplayer.play("BodyTextReveal")


func _display_portrait(key : String):
	_portrait.texture = _portrait_library[key]
	_portrait.visible = true
	
func _populate_options(JSONText : String):
	var optDict : Dictionary = parse_json(JSONText)
	var known_corpospeak = _registry.lookup("player/corpo_dict")

	for opt in optDict.options:
		var slot = opt.slot
		var corpo = known_corpospeak.get(opt.id)
		if corpo and corpo.known:
			var text = corpo.answer
			var new_option_button = _option_scene.instance()
			_option_list.add_child(new_option_button)
			new_option_button.slot = slot
			new_option_button.set_text(text)
			new_option_button.connect("clicked", self, "_on_Option_clicked")
			
			

	
