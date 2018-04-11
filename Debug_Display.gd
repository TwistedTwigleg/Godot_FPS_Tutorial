extends Control

func _ready():
	# Set the OS label and the engine version label
	$OS_Label.text = "OS:" + OS.get_name()
	$Engine_Label.text = "Godot version:" + Engine.get_version_info()["string"]

func _process(delta):
	# Update the FPS label
	$FPS_Label.text = "FPS:" + str(Engine.get_frames_per_second())
