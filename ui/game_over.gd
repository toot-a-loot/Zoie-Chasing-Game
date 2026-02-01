extends Control

# State variables
var current_target_word: String = "" 
var current_index: int = 0

# Cursor variables
var cursor_timer: float = 0.0
var cursor_visible: bool = true

# References
@onready var feedback_label = $InputFeedback 

func _ready():
	$AnimationHolder/AnimatedSprite2D.play("default")
	update_display() # Draw the initial cursor

func _process(delta):
	cursor_timer += delta
	if cursor_timer >= 0.5: # Blink every half second
		cursor_timer = 0.0
		cursor_visible = not cursor_visible
		update_display()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var typed_char = char(event.unicode).to_upper()
		
		if current_target_word == "":
			if typed_char == "Y":
				start_typing("YES")
			elif typed_char == "N":
				start_typing("NO")
		else:
			var needed_char = current_target_word[current_index]
			if typed_char == needed_char:
				current_index += 1
				
				# Reset cursor to be visible immediately when typing (feels better)
				cursor_timer = 0.0
				cursor_visible = true
				
				update_display()
				
				if current_index >= current_target_word.length():
					execute_choice()
			else:
				reset_typing()

func start_typing(word):
	current_target_word = word
	current_index = 1
	cursor_timer = 0.0
	cursor_visible = true
	update_display()

func execute_choice():
	if current_target_word == "YES":
		get_tree().change_scene_to_file("res://game/game.tscn")
	elif current_target_word == "NO":
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func reset_typing():
	current_target_word = ""
	current_index = 0
	update_display()

func update_display():
	# 1. Get what we have typed so far
	var final_text = current_target_word.substr(0, current_index)
	
	# 2. Add the blinking cursor if it's currently "on"
	if cursor_visible:
		final_text += "_"
	else:
		final_text += " " 
		
	# 3. Update the label
	feedback_label.text = "[center]" + final_text + "[/center]"
