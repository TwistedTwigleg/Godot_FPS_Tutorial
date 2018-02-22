extends AnimationPlayer

# A simple state machine like structure for changing animations.
#
# NOTE: While this works for a simple tutorial with not that many animations,
# it is highly recommended to use a proper state machine for handling animations
# and their transitions.
#
# Structure -> Animation name :[Connecting Animation states]
var states = {
	"Idle_unarmed":["Knife_equip", "Pistol_equip", "Rifle_equip", "Idle_unarmed"],
	
	"Pistol_equip":["Pistol_idle"],
	"Pistol_fire":["Pistol_idle"],
	"Pistol_idle":["Pistol_fire", "Pistol_reload", "Pistol_unequip", "Pistol_idle"],
	"Pistol_reload":["Pistol_idle"],
	"Pistol_unequip":["Idle_unarmed"],
	
	"Rifle_equip":["Rifle_idle"],
	"Rifle_fire":["Rifle_idle"],
	"Rifle_idle":["Rifle_fire", "Rifle_reload", "Rifle_unequip", "Rifle_idle"],
	"Rifle_reload":["Rifle_idle"],
	"Rifle_unequip":["Idle_unarmed"],
	
	"Knife_equip":["Knife_idle"],
	"Knife_fire":["Knife_idle"],
	"Knife_idle":["Knife_fire", "Knife_unequip", "Knife_idle"],
	"Knife_unequip":["Idle_unarmed"],
}

# How fast should each animation play?
# Because some of the animation is too slow, we'll speed them up
# to make everything look and feel smooth
var animation_speeds = {
	"Idle_unarmed":1,
	
	"Pistol_equip":1.4,
	"Pistol_fire":1.8,
	"Pistol_idle":1,
	"Pistol_reload":1,
	"Pistol_unequip":1.4,
	
	"Rifle_equip":2,
	"Rifle_fire":6,
	"Rifle_idle":1,
	"Rifle_reload":1.45,
	"Rifle_unequip":2,
	
	"Knife_equip":1,
	"Knife_fire":1.35,
	"Knife_idle":1,
	"Knife_unequip":1,
}

# The current animation state we are in (the name of the current animation)
var current_state = null

# A variable to hold the funcref that will be called from the animations
var callback_function = null


func _ready():
	set_animation("Idle_unarmed")
	connect("animation_finished", self, "animation_ended")



func set_animation(animation_name):
	# Set the animation to the passed in animation if we can transition to it.
	# Returns true if we can transition (or already are playing) the passed in animation.
	# Returns false if we cannot transition (or there is some other error).
	
	
	# Check if we are already playing this animation. If we are, then return.
	# Otherwise we could potentially reset the animation before it is ready, which would lead
	# to jittery animations (and would break Player.gd's animation checking)
	if animation_name == current_state:
		print ("AnimationPlayer_Manager.gd -- WARNING: animation is already ", animation_name)
		return true
	
	
	if has_animation(animation_name) == true:
		# Check if we already have a state. If we do not, then we'll just set the animation without checking.
		if current_state != null:
			# Get all of the possible animations we can transition to from our current state
			var possible_animations = states[current_state]
			# If we can transition to the new state, then do so.
			# If we cannot, then return with a warning message
			if animation_name in possible_animations:
				current_state = animation_name
				play(animation_name, -1, animation_speeds[animation_name])
				return true
			else:
				print ("AnimationPlayer_Manager.gd -- WARNING: Cannot change to ", animation_name, " from ", current_state)
				return false
		else:
			current_state = animation_name
			play(animation_name, -1, animation_speeds[animation_name])
			return true
	return false


func animation_ended(anim_name):
	# When the animation has ended, we may need to transition
	# to another state (like from equiping to idle).
	# For the sake of simplicity, we'll write all of the transitions as 'if' and 'elif' checks.
	#
	# NOTE: If this was a proper state machine, we'd build in transitions into each state and the
	# state machine would handle these transitions.
	
	# UNARMED transitions
	if current_state == "Idle_unarmed":
		pass
	# KNIFE transitions
	elif current_state == "Knife_equip":
		set_animation("Knife_idle")
	elif current_state == "Knife_idle":
		pass
	elif current_state == "Knife_fire":
		set_animation("Knife_idle")
	elif current_state == "Knife_unequip":
		set_animation("Idle_unarmed")
	# PISTOL transitions
	elif current_state == "Pistol_equip":
		set_animation("Pistol_idle")
	elif current_state == "Pistol_idle":
		pass
	elif current_state == "Pistol_fire":
		set_animation("Pistol_idle")
	elif current_state == "Pistol_unequip":
		set_animation("Idle_unarmed")
	elif current_state == "Pistol_reload":
		set_animation("Pistol_idle")
	# RIFLE transitions
	elif current_state == "Rifle_equip":
		set_animation("Rifle_idle")
	elif current_state == "Rifle_idle":
		pass;
	elif current_state == "Rifle_fire":
		set_animation("Rifle_idle")
	elif current_state == "Rifle_unequip":
		set_animation("Idle_unarmed")
	elif current_state == "Rifle_reload":
		set_animation("Rifle_idle")
	



func animation_callback():
	# This function is called from a AnimationPlayer (in this case, the one this script is attached to).
	# If we have a callback function (and we should) then we call it. Otherwise, we need to print a warning
	# message.
	if callback_function == null:
		print ("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()
