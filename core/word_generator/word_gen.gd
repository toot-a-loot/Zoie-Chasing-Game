extends MarginContainer

var word_scene = preload("res://core/word_generator/word.tscn")
@onready var death_timer = $Timer

@export var penalty_amount: float = 0.25

# We start with an empty list, it will be filled by the file
var word_list: Array[String] = [] 
var current_word_node = null 

var is_game_active: bool = true

func _ready():
	load_words_from_file() # <--- Load the file first
	spawn_next_word()
	is_game_active = true

func load_words_from_file():
	# Open the file in Read mode
	var file = FileAccess.open("res://core/words.txt", FileAccess.READ)
	
	if file:
		# Read the whole file as one long string
		var content = file.get_as_text()
		
		# Split the string every time there is a new line
		# The 'false' argument tells Godot to ignore empty lines
		var raw_lines = content.split("\n", false)
		
		# Clean up every word to remove spaces or "\r" (windows line endings)
		for line in raw_lines:
			var clean_word = line.strip_edges()
			if clean_word != "":
				word_list.append(clean_word)
	else:
		print("ERROR: Could not find words.txt!")
		# Fallback list just in case
		word_list = ["error", "file", "missing"]

func spawn_next_word():
	# 2. UPDATED: Don't spawn if game is over
	if not is_game_active:
		return

	if current_word_node != null:
		current_word_node.queue_free()
	
	if word_list.is_empty():
		print("Word list is empty!")
		return

	var word_instance = word_scene.instantiate()
	var random_word = word_list.pick_random()
	
	add_child(word_instance)
	word_instance.setup(random_word)
	word_instance.position = Vector2.ZERO
	
	current_word_node = word_instance
	
	# Only start timer if it's not already running (or restart it)
	if death_timer.is_stopped():
		death_timer.start()

func _on_timer_timeout():
	# 4. UPDATED: Handle Game Over logic
	is_game_active = false
	print("TIMEOUT! Final Time: 0.00")
	print("GAME OVER")
	
	# Optional: Destroy the current word so they can't type anymore
	if current_word_node != null:
		current_word_node.queue_free()

func on_word_typed_correctly():
	if is_game_active:
		death_timer.stop()
		spawn_next_word()
		# Restart timer for the next word (if you want a fresh timer per word)
		# Or keep it running if it's a global timer.
		death_timer.start()

func punish_player():
	# 3. UPDATED: Apply penalty and print the timer
	if not is_game_active: return
	
	var new_time = death_timer.time_left - penalty_amount
	
	print("WRONG LETTER! Penalty applied. Time left: %.2f" % new_time)

	if new_time <= 0:
		_on_timer_timeout()
		death_timer.stop()
	else:
		death_timer.start(new_time)
