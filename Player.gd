extends Sprite

const MAX_WORKLOAD = 2
const STARTING_WORKLOAD = 0
const PATH = "res://Data/corpospeak_dict.json"

onready var _registry = get_node("/root/Registry")

# player state
var current_workload = 0
var corpo_dict = {}

func _ready():
	_load_corpospeak_dict()
	_register_to_registry()

func _register_to_registry():
	_registry.register(self, "player/max_workload", MAX_WORKLOAD)
	_registry.register(self, "player/current_workload", current_workload)
	_registry.register(self, "player/corpo_dict", corpo_dict)

func _load_corpospeak_dict():
	var file = File.new()

	if not file.file_exists(PATH):
		print("file no exists!")
		return
	
	file.open(PATH, file.READ)
	corpo_dict = parse_json(file.get_as_text())
	file.close()

func knows_phrase(id):
	return corpo_dict.get(id).known 

func learn_phrase(id):
	corpo_dict.get(id).known = true
	print(corpo_dict.get(id))
