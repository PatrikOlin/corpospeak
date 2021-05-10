extends Node

var _registry = {
	"DATE": {"owner": "system" , "value": OS.get_datetime()},
	}

const PATH = "res://Data/corpospeak_dict.json"

func _ready():
	_load_full_corpospeak_dict()

func register(instance, key, value):
	_registry[key] = {"owner": instance, "value": value}
	
func unregister(instance, key):
	if _registry[key].owner == instance:
		_registry.erase(key)

func lookup(key : String):
	if _registry.has(key):
		return _registry[key].value
	else:
		return ""

func _load_full_corpospeak_dict():
	var file = File.new()

	if not file.file_exists(PATH):
		print("file no exists!")
		return
	
	file.open(PATH, file.READ)
	var full_corpo_dict = parse_json(file.get_as_text())
	register(self, "system/full_corpo_dict", full_corpo_dict)
	file.close()
