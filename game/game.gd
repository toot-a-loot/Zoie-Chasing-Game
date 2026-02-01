extends Node

# --- NODES ---
@onready var word_gen = $CanvasLayer/NotebookTexture/CenterContainer/WordGen
@onready var food_gen = $CanvasLayer/NotebookTexture/CenterContainer2/FoodGen 

# UPDATE THIS PATH if your FoodBubble is somewhere else in the tree
# Based on your description, it's likely a direct child of CanvasLayer
@onready var food_bubble_root = $CanvasLayer/FoodBubble 
@onready var food_icon_rect = $CanvasLayer/FoodBubble/Icon 

@onready var player = $Player
@onready var player_sprite = player.get_node_or_null("AnimatedSprite2D")
@onready var monsters = [$Monster1, $Monster2, $Monster3]
@onready var parallax_bg = $ParallaxBackground 
@onready var music_player = $MusicPlayer
@onready var correct_sfx = $CorrectSfx
@onready var wrong_sfx = $WrongSfx

# --- CONFIGURATION ---
@export var monster_start_y: float = 60.0
@export var monster_catch_y: float = 140.0
@export var chase_smoothness: float = 0.1
@export var scroll_speed: float = -200.0

func _ready():
	if player_sprite:
		player_sprite.play("default")
		player_sprite.animation_finished.connect(_on_animation_finished)
	
	if word_gen:
		word_gen.mistake_happened.connect(play_trip_animation)
		word_gen.game_ended.connect(_on_game_over)
	
	if food_gen:
		food_gen.food_consumed.connect(_on_food_consumed)
		
		# --- LINK UI TO FOOD GEN ---
		# We pass the actual Bubble and Icon nodes to the food generator
		food_gen.ui_root = food_bubble_root
		food_gen.ui_icon = food_icon_rect
		
		# Ensure the bubble is hidden at start
		if food_bubble_root: 
			food_bubble_root.hide()

	music_player.play()

func _on_food_consumed(amount):
	if word_gen:
		word_gen.apply_powerup(amount)

func _unhandled_input(event):
	if not word_gen or not word_gen.is_game_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var typed_char = OS.get_keycode_string(event.keycode).to_lower()
		
		var main_word = word_gen.current_word_node
		var food_word = food_gen.current_food_node
		
		# Priority Logic: Check if we have already started typing one of them
		var main_started = main_word and main_word.letter_index > 0
		var food_started = food_word and food_word.letter_index > 0
		
		if main_started:
			process_main_word(typed_char)
		elif food_started:
			process_food_word(typed_char)
		else:
			# Neither started, check starting letters
			if main_word and typed_char == main_word.target_word[0]:
				process_main_word(typed_char)
			elif food_word and typed_char == food_word.target_word[0]:
				process_food_word(typed_char)
			else:
				word_gen.punish_player()

# --- HELPER FUNCTIONS ---

func process_main_word(char):
	var status = word_gen.current_word_node.process_input(char)
	if status == 1:
		word_gen.on_word_typed_correctly()
		if correct_sfx: correct_sfx.play()
	elif status == -1:
		word_gen.punish_player()
		if wrong_sfx: wrong_sfx.play()

func process_food_word(char):
	var status = food_gen.process_input(char)
	if status == 0 and correct_sfx:
		correct_sfx.play()

func play_trip_animation():
	if player_sprite:
		player_sprite.play("trip")

func _on_animation_finished():
	if player_sprite.animation == "trip":
		if word_gen.is_game_active:
			player_sprite.play("default")

func _on_game_over():
	music_player.stop()
	if player_sprite:
		player_sprite.play("death")
		await player_sprite.animation_finished
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func _process(delta):
	if not word_gen.is_game_active: return
	
	var is_tripping = player_sprite and (player_sprite.animation == "trip" or player_sprite.animation == "death")
	if not is_tripping:
		parallax_bg.scroll_offset.y += scroll_speed * delta
	
	update_monster_positions(delta)

# --- MONSTER DISTANCE LOGIC ---
func update_monster_positions(delta):
	if not word_gen or not word_gen.death_timer: return
	
	var timer = word_gen.death_timer
	
	if not timer.is_stopped():
		# 1. Calculate Total Effective Time (Base + Powerup)
		var total_time_left = timer.time_left + word_gen.current_powerup_time
		var max_base_time = timer.wait_time 
		
		# 2. Calculate Ratio
		# Higher time = Lower ratio (closer to start/safe)
		# Lower time = Higher ratio (closer to catch/death)
		var time_ratio = 1.0 - (total_time_left / max_base_time)
		
		# 3. Clamp
		# Prevents monsters from flying backward if you have 10 seconds of powerup
		time_ratio = clamp(time_ratio, 0.0, 1.0)
		
		var target_y = lerp(monster_start_y, monster_catch_y, time_ratio) 
		
		# 4. Move Monsters
		for monster in monsters:
			if is_instance_valid(monster):
				monster.position.y = lerp(monster.position.y, target_y, chase_smoothness)
