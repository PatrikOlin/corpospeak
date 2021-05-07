extends Sprite

const KNOWN_CORPOSPEAK = []
const MAX_WORKLOAD = 2
const STARTING_WORKLOAD = 0

# player state
var current_workload = 0

func _ready():
	pass


func knows_phrase(phrase):
	return KNOWN_CORPOSPEAK.has(phrase)
