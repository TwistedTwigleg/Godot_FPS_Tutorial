extends Node

const TITLE_SCREEN_PATH = "res://Main_Menu.tscn"

const POPUP_SCENE = preload("res://Pause_Popup.tscn")
var popup = null
var canvas_layer = null

const DEBUG_DISPLAY_SCENE = preload("res://Debug_Display.tscn")
var debug_display = null

var respawn_points = null

func _ready():
	# Remove this if you want determinstic random functions
	randomize()
	# Make a new canvas layer.
	# This is so our popup always appears on top of everything else
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)



func get_respawn_position():
	if respawn_points == null:
		return Vector3(0, 0, 0)
	else:
		var respawn_point = rand_range(0, respawn_points.size()-1);
		return respawn_points[respawn_point].global_transform.origin;


func load_new_scene(new_scene_path):
	respawn_points = null
	get_tree().change_scene(new_scene_path)


func _process(delta):
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
	load_new_scene(TITLE_SCREEN_PATH)


func set_debug_display(display_on):
	if display_on == false:
		if debug_display != null:
			debug_display.queue_free()
			debug_display = null
	else:
		if debug_display == null:
			debug_display = DEBUG_DISPLAY_SCENE.instance()
			canvas_layer.add_child(debug_display)
