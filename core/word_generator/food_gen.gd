extends MarginContainer

signal food_consumed(bonus_amount)

var word_scene = preload("res://core/word_generator/word.tscn")
@onready var spawn_timer = $Timer 

# --- CONFIGURATION ---
@export var spawn_chance: float = 0.3 
@export var check_interval: float = 2.0 
@export var bonus_time_amount: float = 2.0 

# --- UI REFERENCES (Assigned by Game.gd) ---
var ui_root: Control = null
var ui_icon: TextureRect = null

# --- ASSETS ---
var food_data = {
	"cassava": preload("res://assets/food items/cassavacake.png"),
	"kalamay": preload("res://assets/food items/kalamay.png"),
	"puto":    preload("res://assets/food items/puto.png")
}

var current_food_node = null

func _ready():
	randomize()
	if spawn_timer:
		spawn_timer.wait_time = check_interval
		spawn_timer.autostart = true
		spawn_timer.one_shot = false
		spawn_timer.timeout.connect(_on_spawn_check)
		spawn_timer.start()

func _on_spawn_check():
	if current_food_node == null and randf() < spawn_chance:
		spawn_food()

func spawn_food():
	var keys = food_data.keys()
	var random_food_name = keys.pick_random()
	var random_food_icon = food_data[random_food_name]

	var word_instance = word_scene.instantiate()
	
	# FIX 1: Add child to SELF (FoodGen) so it respects your CenterContainer layout
	add_child(word_instance)
	
	word_instance.setup(random_food_name)
	current_food_node = word_instance

	# FIX 2: Update the Bubble Visuals and Move it to the Word
	if ui_root and ui_icon:
		ui_icon.texture = random_food_icon
		ui_root.show()
		
		# We wait one frame to let Godot calculate the new position of the word inside the container
		await get_tree().process_frame
		
		# Now we snap the bubble to the word's position
		if is_instance_valid(word_instance):
			ui_root.global_position = word_instance.global_position
			
			# OPTIONAL: If the alignment is slightly off, add an offset here:
			# ui_root.global_position += Vector2(-10, -10) 

func process_input(typed_char: String) -> int:
	if current_food_node and current_food_node.has_method("process_input"):
		var status = current_food_node.process_input(typed_char)
		
		if status == 1: 
			# Food Eaten!
			emit_signal("food_consumed", bonus_time_amount)
			current_food_node = null
			
			# Hide the bubble when word is done
			if ui_root:
				ui_root.hide()
			return 1
			
		elif status == -1: 
			return -1
		return 0 
	return 0
