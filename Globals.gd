extends Node

# The path to the title screen scene
const MAIN_MENU_PATH = "res://Main_Menu.tscn"


# ------------------------------------
# All of the GUI/UI related variables

# The popup scene, and a variable to hold the popup
const POPUP_SCENE = preload("res://Pause_Popup.tscn")
var popup = null

# A canvas layer node so our GUI/UI is always drawn on top
var canvas_layer = null

# The debug display scene, and a variable to hold the debug display
const DEBUG_DISPLAY_SCENE = preload("res://Debug_Display.tscn")
var debug_display = null

# ------------------------------------


# A variable to hold all of the respawn points in a level
var respawn_points = null

# A variable to hold the mouse sensitivity (so Player.gd can load it)
var mouse_sensitivity = 0.08
# A variable to hold the joypad sensitivity (so Player.gd can load it)
var joypad_sensitivity = 2


# ------------------------------------
# All of the audio files.

# You will need to provide your own sound files.
# One site I'd recommend is GameSounds.xyz. I'm using Sonniss' GDC Game Audio bundle for 2017.
# The tracks I've used (with some minor editing) are as follows:
#	Gamemaster audio gun sound pack:
#		gun_revolver_pistol_shot_04,
#		gun_semi_auto_rifle_cock_02,
#		gun_submachine_auto_shot_00_automatic_preview_01
var audio_clips = {
	"pistol_shot":null, #preload("res://path_to_your_audio_here!")
	"rifle_shot":null, #preload("res://path_to_your_audio_here!")
	"gun_cock":null, #preload("res://path_to_your_audio_here!")
}

# The simple audio player scene
const SIMPLE_AUDIO_PLAYER_SCENE = preload("res://Simple_Audio_Player.tscn")

# A list to hold all of the created audio nodes
var created_audio = []

# ------------------------------------


func _ready():
	# Randomize the random number generator, so we get random values
	randomize()
	
	# Make a new canvas layer.
	# This is so our popup always appears on top of everything else
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)



func get_respawn_position():
	# If we do not have any respawn points, return origin
	if respawn_points == null:
		return Vector3(0, 0, 0)
	# If we have respawn points, get a random one and return it's global position
	else:
		var respawn_point = rand_range(0, respawn_points.size()-1)
		return respawn_points[respawn_point].global_transform.origin


func load_new_scene(new_scene_path):
	# Set respawn points to null so when/if we get to a level with no respawn points,
	# we do not respawn at the respawn points in the level prior.
	respawn_points = null
	
	# Delete all of the sounds
	for sound in created_audio:
		if (sound != null):
			sound.queue_free()
	created_audio.clear()
	
	# Change scenes
	get_tree().change_scene(new_scene_path)


func _process(delta):
	# If ui_cancel is pressed, we want to open a popup if one is not already open
	if Input.is_action_just_pressed("ui_cancel"):
		if popup == null:
			# Make a new popup scene
			popup = POPUP_SCENE.instance()
			
			# Connect the signals
			popup.get_node("Button_quit").connect("pressed", self, "popup_quit")
			popup.connect("popup_hide", self, "popup_closed")
			popup.get_node("Button_resume").connect("pressed", self, "popup_closed")
			
			# Add it as a child, and make it pop up in the center of the screen
			canvas_layer.add_child(popup)
			popup.popup_centered()
			
			# Make sure the mouse is visible
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			# Pause the game
			get_tree().paused = true


func popup_closed():
	# Unpause the game
	get_tree().paused = false
	
	# If we have a popup, destoy it
	if popup != null:
		popup.queue_free()
		popup = null

func popup_quit():
	get_tree().paused = false
	
	# Make sure the mouse is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# If we have a popup, destoy it
	if popup != null:
		popup.queue_free()
		popup = null
	
	# Go back to the title screen scene
	load_new_scene(MAIN_MENU_PATH)


func set_debug_display(display_on):
	# If we are turning off the debug display
	if display_on == false:
		# If we have a debug display, then free it and set debug_display to null
		if debug_display != null:
			debug_display.queue_free()
			debug_display = null
	# If we are turning on the debug display
	else:
		# If we do not have a debug display, instance/spawn a new one and set it to debug_display
		if debug_display == null:
			debug_display = DEBUG_DISPLAY_SCENE.instance()
			canvas_layer.add_child(debug_display)


func play_sound(sound_name, loop_sound=false, sound_position=null):
	# If we have a audio clip with with the name sound_name
	if audio_clips.has(sound_name):
		# Make a new simple audio player and set it's looping variable to the loop_sound
		var new_audio = SIMPLE_AUDIO_PLAYER_SCENE.instance()
		new_audio.should_loop = loop_sound
		
		# Add it as a child and add it to created_audio
		add_child(new_audio)
		created_audio.append(new_audio)
		
		# Send the newly created simple audio player the audio stream and sound position
		new_audio.play_sound(audio_clips[sound_name], sound_position)
	
	# If we do not have an audio clip with the name sound_name, print a error message
	else:
		print ("ERROR: cannot play sound that does not exist in audio_clips!")


