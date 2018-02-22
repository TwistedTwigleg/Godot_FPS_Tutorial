extends Spatial

# All of the audio files.
# You will need to provide your own sound files.
# One site I'd reccomend is GameSounds.xyz. I'm using Sonniss' GDC Game Audio bundle for 2017.
# The tracks I've used are as follows:
#	Gamemaster audio gun sound pack:
#		gun_revolver_pistol_shot_04,
#		gun_semi_auto_rifle_cock_02,
#		gun_submachine_auto_shot_00_automatic_preview_01
#
# Minor editing was done to shorten the length of those clips to better fit the tutorial.
var audio_pistol_shot = null #preload("res://path_to_your_audio_here!")
var audio_gun_cock = null #preload("res://path_to_your_audio_here!")
var audio_rifle_shot = null #preload("res://path_to_your_audio_here!")

# The audio player node.
var audio_node = null

func _ready():
	# Get the audio player node, connect the finished singal, and assure it's not playing anything.
	audio_node = get_node("AudioStreamPlayer")
	audio_node.connect("finished", self, "destroy_self")
	audio_node.stop()


func play_sound(sound_name, position=null):
	# Based on the passed in sound, set the audio stream and then play it.
	# If we do not have an sound stream with that name, then simply destroy ourselves.
	#
	# This is not included in the tutorial, but is here because you have to provide your
	# own audio. To make the project work, we add these checks.
	if audio_pistol_shot == null or audio_rifle_shot == null or audio_gun_cock == null:
		print ("AUDIO NOT SETUP")
		queue_free()
		return
	
	if sound_name == "Pistol_shot":
		audio_node.stream = audio_pistol_shot
	elif sound_name == "Rifle_shot":
		audio_node.stream = audio_rifle_shot
	elif sound_name == "Gun_cock":
		audio_node.stream = audio_gun_cock
	else:
		print ("UNKNOWN STREAM")
		queue_free()
		return
	
	# If you are using a AudioPlayer3D, then uncomment these lines to set the position.
	# if position != null:
	#	audio_node.global_transform.origin = position
	
	# Play the sound
	audio_node.play()


func destroy_self():
	# When the sound is finished playing, destroy/free ourself.
	audio_node.stop()
	queue_free()
