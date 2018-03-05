extends Spatial

# NOTE: we do not need these values, but we may in the future
# (or rather we may need all weapons to have these values)
var ammo_in_weapon = 1;
var spare_ammo = 1;
const AMMO_IN_MAG = 1;

# How much damage does this weapon do
const DAMAGE = 40;

# Can this weapon reload?
const CAN_RELOAD = false;
# The name of the reloading animation.
const RELOADING_ANIM_NAME = ""
# The name of the idle animation.
const IDLE_ANIM_NAME = "Knife_idle"
# The name of the firing animation
const FIRE_ANIM_NAME = "Knife_fire"

# Is this weapon enabled?
var is_weapon_enabled = false;

# The player script. This is so we can easily access the animation player
# and other variables.
var player_node = null;

func _ready():
	# We are going to assume the player will pass themselves in.
	# While we can have cases where the player does not pass themselves in
	# (say we forget to), having a complicated get_node call does not look pretty.
	pass;

func fire_weapon():
	# Get the knife area and all of the overlapping bodies.
	var area = get_node("Area")
	var bodies = area.get_overlapping_bodies()
	
	# For every body inside the knife's area, see if it has the method 'bullet_hit'.
	# If one of the bodies do, then call it and pass the area's global origin as the bullet collision point.
	for body in bodies:
		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, area.global_transform.origin)


func reload_weapon():
	# Return false because we cannot reload a knife
	return false;

func equip_weapon():
	if player_node.animation_manager.current_state == "Knife_idle":
		is_weapon_enabled = true;
		return true
	
	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Knife_equip")
	
	return false

func unequip_weapon():
	
	if player_node.animation_manager.current_state == "Knife_idle":
		if (player_node.animation_manager.current_state != "Knife_unequip"):
			player_node.animation_manager.set_animation("Knife_unequip")
	
	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false;
		return true
	else:
		return false