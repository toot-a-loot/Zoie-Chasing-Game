extends Node

@onready var word_gen = $CanvasLayer/NotebookTexture/CenterContainer/WordGen
@onready var player = $Player
@onready var player_sprite = player.get_node_or_null("AnimatedSprite2D")
@onready var monsters = [$Monster1, $Monster2, $Monster3]

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

func _unhandled_input(event):
	if word_gen.is_game_active == false:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var typed_char = OS.get_keycode_string(event.keycode).to_lower()
		var active_word = word_gen.current_word_node
		
		if active_word and active_word.has_method("process_input"):
			var status = active_word.process_input(typed_char)
			
			if status == 1:
				word_gen.on_word_typed_correctly()
			elif status == -1:
				word_gen.punish_player()

# --- ANIMATION LOGIC ---

func play_trip_animation():
	# If we are already tripping or dying, ignore new trip requests.
	if player_sprite.animation == "trip" and player_sprite.is_playing():
		return
	if player_sprite.animation == "death":
		return
		
	player_sprite.play("trip")

func _on_animation_finished():
	# If trip finished, go back to running (unless we are dead)
	if player_sprite.animation == "trip":
		if word_gen.is_game_active:
			player_sprite.play("default")

func _on_game_over():
	# 2. Play death animation and wait for it
	print("Player Died! Playing animation...")
	
	if player_sprite:
		player_sprite.play("death")
		
		# "await" pauses this function until the signal fires
		await player_sprite.animation_finished
		
	# Change the scene
	get_tree().change_scene_to_file("res://ui/game_over.tscn")
