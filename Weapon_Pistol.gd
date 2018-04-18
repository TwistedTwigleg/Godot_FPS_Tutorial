extends Spatial

# Variables for storing how much ammo is in the weapon, how much spare ammo this weapon has
# and how much ammo is in a full weapon/magazine.
var ammo_in_weapon = 10
var spare_ammo = 20
const AMMO_IN_MAG = 10
# How much damage does this weapon do
const DAMAGE = 15

# Can this weapon reload?
const CAN_RELOAD = true
# Can this weapon be refilled
const CAN_REFILL = true

# The name of the reloading animation.
const RELOADING_ANIM_NAME = "Pistol_reload"
# The name of the idle animation.
const IDLE_ANIM_NAME = "Pistol_idle"
# The name of the firing animation
const FIRE_ANIM_NAME = "Pistol_fire"

# Is this weapon enabled?
var is_weapon_enabled = false

# The bullet scene the pistol fires
var bullet_scene = preload("Bullet_Scene.tscn")

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
	# Clone the bullet, get the scene root, and add the bullet as a child.
	# NOTE: we are assuming that the first child of the scene's root is
	# the 3D level we're wanting to spawn the bullet at.
	var clone = bullet_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	
	# Set the bullet's global_transform to that of the pistol spawn point (which is this node).
	clone.global_transform = self.global_transform
	# The bullet is a little too small (by default), so let's make it bigger!
	clone.scale = Vector3(4, 4, 4)
	# Set how much damage the bullet does
	clone.BULLET_DAMAGE = DAMAGE
	# Remove the bullet from the pistol's magazine
	ammo_in_weapon -= 1
	
	# Play the gun sound
	player_node.create_sound("pistol_shot", self.global_transform.origin)


func reload_weapon():
	# Make sure we can reload
	var can_reload = false
	
	# Make sure we are in the correct animation for reloading
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		can_reload = true
	
	# Make sure we have ammo to reload, and that our gun is not already fully loaded.
	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false
	
	if can_reload == true:
		# Calculate how much ammo we need
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon
		
		# If we have enough ammo to refil the gun, then do so.
		if spare_ammo >= ammo_needed:
			spare_ammo -= ammo_needed
			ammo_in_weapon = AMMO_IN_MAG
		# If we do not, then just put the remaining ammo into the gun.
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0
		
		# Set the reloading animation
		player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)
		
		# Play the 'gun_cock' sound so it sounds like we've reloaded.
		player_node.create_sound("gun_cock", player_node.camera.global_transform.origin)
		
		# Return true so the player script knows we've reloaded
		return true
	
	# Return false because we could not reload (for some reason or another)
	return false

func equip_weapon():
	# If we are in our idle animation, then we have successfully been equipped.
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true
	
	# If we are in a animation state where we can be equipped (Idle_unarmed), then
	# change to our equip animation
	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Pistol_equip")
		
		# Play a sound when we play a equipping animation
		player_node.create_sound("gun_cock", player_node.camera.global_transform.origin)
	
	return false

func unequip_weapon():
	
	# If we are in our idle animation, then set the animation to our unequip animation
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		if player_node.animation_manager.current_state != "Pistol_unequip":
			player_node.animation_manager.set_animation("Pistol_unequip")
	
	# If we have returned to "Idle_unarmed", then we have been successfully unequipped.
	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true
	else:
		return false

func reset_weapon():
	# Reset the ammo count
	ammo_in_weapon = 10
	spare_ammo = 20
