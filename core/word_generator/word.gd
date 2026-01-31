extends RichTextLabel

@export var untyped_color: Color = Color("888888") 
@export var typed_color: Color = Color("00FF00")
# 1. NEW: Color for errors (Red)
@export var error_color: Color = Color("FF0000") 

var target_word: String = ""
var letter_index: int = 0

func setup(text_to_type: String):
	target_word = text_to_type
	update_display()

# 2. UPDATED: Returns an int code now
# 1 = Word Finished, 0 = Correct Letter, -1 = Wrong Letter
func process_input(input_letter: String) -> int:
	if input_letter == target_word[letter_index]:
		letter_index += 1
		update_display()
		
		if letter_index == target_word.length():
			queue_free()
			return 1 # Code for "Finished"
		return 0 # Code for "Correct, keep going"
	else:
		shake_and_flash()
		return -1 # Code for "Wrong letter"

# 3. NEW: Visual Feedback (Shake + Red Flash)
func shake_and_flash():
	var tween = create_tween()
	
	# Shake Effect (Wiggle Rotation)
	# We use rotation because it works better inside Containers than position
	# Pivot offset ensures it shakes from the center, not top-left
	pivot_offset = size / 2 
	tween.tween_property(self, "rotation_degrees", 5, 0.05)
	tween.tween_property(self, "rotation_degrees", -5, 0.05)
	tween.tween_property(self, "rotation_degrees", 5, 0.05)
	tween.tween_property(self, "rotation_degrees", 0, 0.05)
	
	# Flash Red Effect (parallel to shake)
	# We momentarily override the text color to red
	modulate = error_color
	# Create a second tween for color so it doesn't wait for the shake to finish
	var color_tween = create_tween()
	color_tween.tween_interval(0.2) # Stay red for 0.2 seconds
	color_tween.tween_property(self, "modulate", Color.WHITE, 0.1) # Fade back to normal

func update_display():
	# (Your existing update_display logic remains mostly the same)
	var color_typed_hex = typed_color.to_html(false)
	var color_untyped_hex = untyped_color.to_html(false)
	
	var typed_part = "[color=#" + color_typed_hex + "]" + target_word.substr(0, letter_index) + "[/color]"
	var untyped_part = "[color=#" + color_untyped_hex + "]" + target_word.substr(letter_index) + "[/color]"
	
	text = typed_part + untyped_part
