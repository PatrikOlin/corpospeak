extends NinePatchRect

signal clicked(slot)

onready var _button = $Button
onready var _text = $Text

var slot

func _on_Button_pressed():
	emit_signal("clicked", slot)

func set_text(new_text : String):
	_text.text = new_text

