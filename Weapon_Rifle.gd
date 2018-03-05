extends Spatial

# Variables for storing how much ammo is in the weapon, how much spare ammo this weapon has
# and how much ammo is in a full weapon/magazine.
var ammo_in_weapon = 80;
var spare_ammo = 160;
const AMMO_IN_MAG = 80;
# How much damage does this weapon do
const DAMAGE = 4;

# Can this weapon reload?
const CAN_RELOAD = true;
# The name of the reloading animation.
const RELOADING_ANIM_NAME = "Rifle_reload"
# The name of the idle animation.
const IDLE_ANIM_NAME = "Rifle_idle"
# The name of the firing animation
const FIRE_ANIM_NAME = "Rifle_fire"

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
	# Get the raycast node
	var ray = get_node("RayCast")
	# Force the raycast to update. This will force the raycast to detect collisions when we call it.
	# This means we are getting a frame perfect collision check with the 3D world.
	ray.force_raycast_update()
	
	# If the ray hit something, get its collider and see if it has the 'bullet_hit' method.
	# If it does, then call it and pass the ray's collision point as the bullet collision point.
	if ray.is_colliding():
		var body = ray.get_collider()
		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, ray.get_collision_point())
	
	# Remove the bullet from the mag
	ammo_in_weapon -= 1;
	
	# Play the gun sound
	player_node.create_sound("Rifle_shot", ray.global_transform.origin)


func reload_weapon():
	# Make sure we can reload
	var can_reload = false;
	
	# Make sure we are in the correct animation for reloading
	if player_node.animation_manager.current_state == "Rifle_idle":
		can_reload = true
	
	# Make sure we have ammo to reload, and that our gun is not already fully loaded.
	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false
	
	if can_reload == true:
		# Calculate how much ammo we need
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon;
		
		# If we have enough ammo to refil the gun, then do so.
		if spare_ammo >= ammo_needed:
			spare_ammo -= ammo_needed
			ammo_in_weapon = AMMO_IN_MAG;
		# If we do not, then just put the remaining ammo into the gun.
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0
		
		# Set the reloading animation
		player_node.animation_manager.set_animation("Rifle_reload")
		
		# Play the 'gun_cock' sound so it sounds like we've reloaded.
		player_node.create_sound("Gun_cock", player_node.camera.global_transform.origin)
		
		# Return true so the player script knows we've reloaded
		return true;
	
	# Return false because we could not reload (for some reason or another)
	return false;

func equip_weapon():
	if player_node.animation_manager.current_state == "Rifle_idle":
		is_weapon_enabled = true;
		return true
	
	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Rifle_equip")
		
		# Play a sound when we play a equiping animation
		player_node.create_sound("Gun_cock", player_node.camera.global_transform.origin)
	
	return false

func unequip_weapon():
	
	if player_node.animation_manager.current_state == "Rifle_idle":
		if (player_node.animation_manager.current_state != "Rifle_unequip"):
			player_node.animation_manager.set_animation("Rifle_unequip")
	
	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false;
		return true
	else:
		return false