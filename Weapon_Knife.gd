extends Spatial

# NOTE: we do not need these values, but we may in the future
# (or rather we may need all weapons to have these variables)
var ammo_in_weapon = 1
var spare_ammo = 1
const AMMO_IN_MAG = 1

# How much damage does this weapon do
const DAMAGE = 40

# Can this weapon reload?
const CAN_RELOAD = false
# Can this weapon be refilled
const CAN_REFILL = false

# The name of the reloading animation.
const RELOADING_ANIM_NAME = ""
# The name of the idle animation.
const IDLE_ANIM_NAME = "Knife_idle"
# The name of the firing animation
const FIRE_ANIM_NAME = "Knife_fire"

# Is this weapon enabled?
var is_weapon_enabled = false

# The player script. This is so we can easily access the animation player
# and other variables.
var player_node = null

func _ready():
	# We are going to assume the player will pass themselves in.
	# While we can have cases where the player does not pass themselves in,
	# having a complicated get_node call does not look pretty and it (relatively) safe to assume
	# player_node will be passed in.
	pass

func fire_weapon():
	# Get the knife area and all of the overlapping bodies.
	var area = $Area
	var bodies = area.get_overlapping_bodies()
	
	# For every body inside the knife's area, see if it has the method 'bullet_hit'.
	# If one of the bodies do, then call it and pass the area's global origin as the bullet collision point.
	for body in bodies:
		
		# Make sure we're not going to hurt ourselves, so check to see if the body we collided with is ourself.
		# If it is, then do nothing.
		if body == player_node:
			continue
		
		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, area.global_transform)


func reload_weapon():
	# Return false because we cannot reload a knife
	return false

func equip_weapon():
	# If we are in our idle animation, then we have successfully been equipped.
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true
	
	# If we are in a animation state where we can be equipped (Idle_unarmed), then
	# change to our equip animation
	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Knife_equip")
	
	return false

func unequip_weapon():
	
	# If we are in our idle animation, then set the animation to our unequip animation
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		player_node.animation_manager.set_animation("Knife_unequip")
	
	# If we have returned to "Idle_unarmed", then we have been successfully unequipped.
	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true
	
	return false

func reset_weapon():
	# Reset the ammo count
	ammo_in_weapon = 1
	spare_ammo = 1
