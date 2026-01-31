extends Node

@onready var word_gen = $CanvasLayer/NotebookTexture/CenterContainer/WordGen

func _unhandled_input(event):
	# 1. NEW: Check if game is over before doing anything
	if word_gen.is_game_active == false:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var typed_char = OS.get_keycode_string(event.keycode).to_lower()
		
		var active_word = word_gen.current_word_node
		
		# Ensure active_word exists before accessing it
		if active_word and active_word.has_method("process_input"):
			var status = active_word.process_input(typed_char)
			
			if status == 1:
				word_gen.on_word_typed_correctly()
			elif status == -1:
				word_gen.punish_player()
