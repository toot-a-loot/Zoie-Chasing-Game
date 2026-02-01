extends Node

@onready var word_gen = $CanvasLayer/NotebookTexture/CenterContainer/WordGen
@onready var player = $Player
@onready var player_sprite = player.get_node_or_null("AnimatedSprite2D")
@onready var monsters = [$Monster1, $Monster2, $Monster3]
@onready var parallax_bg = $ParallaxBackground 
@onready var music_player = $MusicPlayer
@onready var correct_sfx = $CorrectSfx
@onready var wrong_sfx = $WrongSfx
@onready var trip_sfx = $TripSfx
@onready var running_sfx = $RunningSfx
@onready var type_sfx = $TypeSfx
@onready var death_sfx = $DeathSfx
@export var monster_start_y: float = 60.0
@export var monster_catch_y: float = 140.0
@export var chase_smoothness: float = 0.1
@export var scroll_speed: float = -200.0 : 
	set(value):
		if value == null:
			scroll_speed = -200.0
		else:
			scroll_speed = value

func _ready():
	# Start animation
	if player_sprite:
		player_sprite.play("default")
		player_sprite.animation_finished.connect(_on_animation_finished)
	
	# Connect Signals
	word_gen.mistake_happened.connect(play_trip_animation)
	word_gen.game_ended.connect(_on_game_over)
		
	for monster in monsters:
		var monster_sprite = monster.get_node_or_null("AnimatedSprite2D")
		if monster_sprite:
			monster_sprite.play("default")
	
	music_player.play()
	running_sfx.play()

func _unhandled_input(event):
	if not word_gen.is_game_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var typed_char = OS.get_keycode_string(event.keycode).to_lower()
		var active_word = word_gen.current_word_node
		
		if active_word and active_word.has_method("process_input"):
			var status = active_word.process_input(typed_char)
			
			if status == 1:
				word_gen.on_word_typed_correctly()
				correct_sfx.play() 
				
			elif status == 0: 
				type_sfx.pitch_scale = randf_range(0.9, 1.1)
				type_sfx.play()
				
			elif status == -1:
				word_gen.punish_player()
				wrong_sfx.play()

# --- ANIMATION LOGIC ---

func play_trip_animation():
	running_sfx.stop()
	# If we are already tripping or dying, ignore new trip requests.
	if player_sprite.animation == "trip" and player_sprite.is_playing():
		return
	if player_sprite.animation == "death":
		return
		
	player_sprite.play("trip")
	
	var notebook = $CanvasLayer/NotebookTexture
	var tween = create_tween()
	tween.tween_property(notebook, "position:y", notebook.position.y + 10, 0.05)
	tween.tween_property(notebook, "position:y", notebook.position.y, 0.05)
	
	trip_sfx.play()
	running_sfx.play()

func _on_animation_finished():
	# If trip finished, go back to running (unless we are dead)
	if player_sprite.animation == "trip":
		if word_gen.is_game_active:
			player_sprite.play("default")

func _on_game_over():
	death_sfx.play()
	music_player.stop()
	# 2. Play death animation and wait for it
	print("Player Died! Playing animation...")
	
	if player_sprite:
		player_sprite.play("death")
		
		# "await" pauses this function until the signal fires
		await player_sprite.animation_finished
		
	# Change the scene
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

# --- BACKGROUND ---
func _process(delta):
	if not word_gen.is_game_active:
		return

	var is_tripping = player_sprite and (player_sprite.animation == "trip" or player_sprite.animation == "death")

	if not is_tripping:
		parallax_bg.scroll_offset.y += scroll_speed * delta
	
	update_monster_positions(delta)

func update_monster_positions(delta):
	if not word_gen or not word_gen.death_timer: 
		return
	
	var timer = word_gen.death_timer
	
	if not timer.is_stopped() and timer.wait_time > 0:
		# 1. Calculate the 'Target' based on the timer 
		var time_ratio = 1.0 - (timer.time_left / timer.wait_time) 
		var target_y = lerp(monster_start_y, monster_catch_y, time_ratio) 
		
		# 2. Smoothly move each monster toward that target
		for monster in monsters:
			if is_instance_valid(monster):
				monster.position.y = lerp(monster.position.y, target_y, chase_smoothness)
