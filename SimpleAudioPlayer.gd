extends Spatial

# The audio player node.
var audio_node = null
# A variable to track whether or not we should loop
var should_loop = false
# The globals autoload script
var globals = null

func _ready():
	# Get the audio player node, connect the finished signal, and assure it's not playing anything.
	audio_node = $Audio_Stream_Player
	audio_node.connect("finished", self, "sound_finished")
	audio_node.stop()
	
	# Get the globals script
	globals = get_node("/root/Globals")


func play_sound(audio_stream, position=null):
	# Based on the passed in sound, set the audio stream and then play it.
	# If we do not have an sound stream with that name, then simply destroy ourselves.
	#
	# This is not included in the tutorial, but is here because you have to provide your
	# own audio. To make the project work, we add this check.
	if audio_stream == null:
		print ("No audio stream passed, cannot play sound")
		globals.created_audio.remove(globals.created_audio.find(self))
		queue_free()
		return
	
	# Set the audio stream to the passed in audio stream
	audio_node.stream = audio_stream
	
	# If you are using a AudioPlayer3D, then uncomment these lines to set the position.
	# if position != null:
	#	audio_node.global_transform.origin = position
	
	# Play the sound from the beginning
	audio_node.play(0.0)


func sound_finished():
	if should_loop:
		# Start playing again, at the beginning
		audio_node.play(0.0)
	else:
		# Destroy/Free this sound.
		globals.created_audio.remove(globals.created_audio.find(self))
		audio_node.stop()
		queue_free()
