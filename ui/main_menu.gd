extends Control

# --- References to Containers ---
@onready var main_menu_container = $MainMenuContainer
@onready var settings_container = $SettingsContainer

# --- References to Buttons ---
@onready var start_button = $MainMenuContainer/Main/TextureButton
@onready var options_button = $MainMenuContainer/Main/TextureButton2
@onready var exit_button = $MainMenuContainer/Main/TextureButton3
@onready var back_button = $SettingsContainer/TextureRect/BackButton

# --- References to Sliders ---
@onready var music_slider = $SettingsContainer/TextureRect/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider = $SettingsContainer/TextureRect/VBoxContainer/SFXContainer/SFXSlider

# Audio Bus Indices
var music_bus_index
var sfx_bus_index

func _ready():
	# 1. Setup Audio Buses
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# 2. Connect Buttons
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# 3. Connect Sliders
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# 4. Initialize State
	# Force Main Menu to be visible and Settings to be hidden on start
	main_menu_container.visible = true
	settings_container.visible = false
	
	# 5. Load current volume values into sliders
	# (Prevents sliders jumping to 100% if volume is already lower)
	if music_bus_index != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	if sfx_bus_index != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))

# --- Button Functions ---

func _on_start_pressed():
	# Change to your game scene path
	get_tree().change_scene_to_file("res://game/game.tscn")

func _on_options_pressed():
	main_menu_container.visible = false
	settings_container.visible = true

func _on_exit_pressed():
	get_tree().quit()

func _on_back_pressed():
	settings_container.visible = false
	main_menu_container.visible = true

# --- Slider Functions ---

func _on_music_changed(value):
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
		AudioServer.set_bus_mute(music_bus_index, value < 0.05)

func _on_sfx_changed(value):
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
		AudioServer.set_bus_mute(sfx_bus_index, value < 0.05)

func _input(event):
	# Allow pressing ESC to go back from settings
	if event.is_action_pressed("ui_cancel") and settings_container.visible:
		_on_back_pressed()
