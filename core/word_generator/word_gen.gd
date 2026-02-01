extends MarginContainer

signal mistake_happened
signal game_ended

var word_scene = preload("res://core/word_generator/word.tscn")
@onready var death_timer = $Timer

# --- CONFIGURATION ---
@export var penalty_amount: float = 0.25
@export var powerup_decrement_timer: float = 0.15
@export var initial_bonus_on_food: float = 2.0

# --- STATE ---
var word_list: Array[String] = [] 
var current_word_node = null 
var is_game_active: bool = true
var current_powerup_time: float = 0.0

func _ready():
	load_words_from_file()
	spawn_next_word()
	is_game_active = true

func _process(delta):
	if is_game_active:
		# Handle Powerup Decay
		if current_powerup_time > 0:
			current_powerup_time -= powerup_decrement_timer * delta
			if current_powerup_time < 0:
				current_powerup_time = 0
		
		# Optional: Debug Print
		# var total_time = death_timer.time_left + current_powerup_time
		# print(total_time)

# --- GAME LOGIC ---

func apply_powerup(amount: float):
	if not is_game_active: return
	current_powerup_time += amount
	print("POWERUP! Added %.2f secs. Buffer: %.2f" % [amount, current_powerup_time])

func punish_player():
	if not is_game_active: return
	
	emit_signal("mistake_happened")
	
	if current_powerup_time > 0:
		current_powerup_time -= penalty_amount
		if current_powerup_time < 0:
			var remainder = abs(current_powerup_time)
			current_powerup_time = 0
			modify_death_timer(-remainder)
	else:
		modify_death_timer(-penalty_amount)
	
	print("WRONG! Penalty applied.")

func modify_death_timer(amount: float):
	var new_time = death_timer.time_left + amount
	if new_time <= 0:
		_on_timer_timeout()
		death_timer.stop()
	else:
		death_timer.start(new_time)

func _on_timer_timeout():
	# Survival Check: Use powerup buffer to survive death
	if current_powerup_time > 0.5:
		death_timer.start(current_powerup_time)
		current_powerup_time = 0
		print("SAVED BY POWERUP!")
		return

	is_game_active = false
	print("GAME OVER")
	if current_word_node: current_word_node.queue_free()
	game_ended.emit()

func on_word_typed_correctly():
	if is_game_active:
		spawn_next_word()

# --- WORD SPAWNING ---

func spawn_next_word():
	if not is_game_active: return
	if current_word_node != null: current_word_node.queue_free()
	
	if word_list.is_empty(): 
		word_list = ["error", "empty"]

	var word_instance = word_scene.instantiate()
	add_child(word_instance)
	word_instance.setup(word_list.pick_random())
	word_instance.position = Vector2.ZERO
	current_word_node = word_instance
	
	# FIX IS HERE: We force the timer to restart every time a word spawns.
	# Calling .start() with no arguments resets it to the inspector's Wait Time (5s).
	death_timer.start()

func load_words_from_file():
	var file = FileAccess.open("res://core/words.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var raw_lines = content.split("\n", false)
		for line in raw_lines:
			var clean = line.strip_edges()
			if clean != "": word_list.append(clean)
