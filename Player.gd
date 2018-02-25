extends KinematicBody

# Walking variables.
# This manages how fast we walk (and how quickly we can get to top speed),
# how strong gravity is, and how high we jump.
const norm_grav = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL= 4.5

# Sprinting variables. Similar to the varibles above, just allowing for quicker movement
const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
# A boolean to track whether or not we are spriting
var is_spriting = false

# How fast we slow down, and the steepest angle we can climb.
const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

# We need the camera for getting directional vectors. We rotate ourselves on the Y-axis using
# the rotation_helper to avoid rotating on more than one axis at a time.
var camera
var rotation_helper

# You may need to adjust depending on the sensitivity of your mouse
const MOUSE_SENSITIVITY = 0.05

# The animation manager that holds all of our animations and their transition states
var animation_manager

# Gun variables.
# The name of the gun we are currently using
var current_gun = "UNARMED"
# A boolean to track if we are changing guns
var changing_gun = false
# A boolean to track if we are reloading
var reloading_gun = false
# How much ammo we have in reserve for the guns. This can be viewed as the ammount of bullets
# we have on our person, but not in our guns. (total ammo = ammo_for_guns + ammo_in_guns)
var ammo_for_guns = {"PISTOL":60, "RIFLE":160, "KNIFE":1}
# How much ammo we currently have in the guns.
var ammo_in_guns = {"PISTOL":20, "RIFLE":80, "KNIFE":1}
# How much ammo fills a magazine.
const AMMO_IN_MAGS = {"PISTOL":20, "RIFLE":80, "KNIFE":1}
# The bullet scene we'll spawn when we create a bullet
var bullet_scene = preload("Bullet_Scene.tscn")

# How much health we currently have
var health = 100
# How much damage a single rifle bullet causes
const RIFLE_DAMAGE = 4
# How much damage a single knife stab/swipe causes
const KNIFE_DAMAGE = 40

# The label for how much health we have, and how much ammo we have.
var UI_status_label
# The flashlight spotlight
var flashlight

var simple_audio_player = preload("res://SimpleAudioPlayer.tscn")


func _ready():
	
	camera = get_node("Rotation_helper/Camera")
	rotation_helper = get_node("Rotation_helper")
	
	# Get the animation manager and pass in a funcref for 'fire bullet'.
	# This allows 'fire_bullet' to be called from the guns fire animations.
	animation_manager = get_node("Rotation_helper/Model/AnimationPlayer")
	animation_manager.callback_function = funcref(self, "fire_bullet")
	
	set_physics_process(true)
	
	# We need to capture the mouse in order to use it for a FPS style camera control.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)
	
	# Make sure the bullet spawn point, the raycast, and the knife area are aiming at the center of the screen
	var gun_aim_point_pos = get_node("Rotation_helper/Gun_aim_point").global_transform.origin
	get_node("Rotation_helper/Gun_fire_points/Pistol_point").look_at(gun_aim_point_pos, Vector3(0, 1, 0))
	get_node("Rotation_helper/Gun_fire_points/Rifle_point").look_at(gun_aim_point_pos, Vector3(0, 1, 0))
	get_node("Rotation_helper/Gun_fire_points/Knife_point").look_at(gun_aim_point_pos, Vector3(0, 1, 0))
	
	# Because we have the camera rotated by 180 degrees, we need to rotate the points around by 180
	# degrees on their local Y axis because otherwise the bullets will fire backwards
	get_node("Rotation_helper/Gun_fire_points/Pistol_point").rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
	get_node("Rotation_helper/Gun_fire_points/Rifle_point").rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
	get_node("Rotation_helper/Gun_fire_points/Knife_point").rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
	
	# Get the UI label so we can show our health and ammo, and get the flashlight spotlight
	UI_status_label = get_node("HUD/Panel/Gun_label")
	flashlight = get_node("Rotation_helper/Flashlight")


func _physics_process(delta):
	
	# A vector for storing the direction the player intends to walk towards.
	var dir = Vector3()
	# We also get the camera's global transform so we can use its directional vectors
	var cam_xform = camera.get_global_transform()
	
	
	# ----------------------------------
	# Walking
	# Based on the action pressed, we move in a direction relative to the camera.
	# 
	# NOTE: because the camera is rotated by -180 degrees
	# all of the directional vectors are the opposite in comparison to our KinematicBody.
	# (The camera's local Z axis actually points backwards while our KinematicBody points forwards)
	# To get around this, we flip the camera's directional vectors so they point in the same direction
	if Input.is_action_pressed("movement_forward"):
		dir += -cam_xform.basis.z.normalized()
	if Input.is_action_pressed("movement_backward"):
		dir += cam_xform.basis.z.normalized()
	if Input.is_action_pressed("movement_left"):
		dir += -cam_xform.basis.x.normalized()
	if Input.is_action_pressed("movement_right"):
		dir += cam_xform.basis.x.normalized()
	# ----------------------------------
	
	
	# ----------------------------------
	# Sprinting
	# If we are sprinting, we need to increase our gravity and
	# change the is_sprinting boolean accordingly
	if Input.is_action_pressed("movement_sprint"):
		is_spriting = true
	else:
		is_spriting = false
	# ----------------------------------
	
	
	# ----------------------------------
	# Processing our movements and sending them to KinematicBody
	
	# Apply gravity
	var grav = norm_grav;
	
	# Assure our movement direction on the Y axis is zero, and then normalize it.
	dir.y = 0
	dir = dir.normalized()
	
	# Apply gravity
	vel.y += delta*grav
	
	# Set our velocity to a new variable (hvel) and remove the Y velocity.
	var hvel = vel
	hvel.y = 0
	
	# Based on whether we are sprinting or not, set our max speed accordingly.
	var target = dir
	if is_spriting:
		target *= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED
	
	
	# If we have movement input, then accelerate.
	# Otherwise we are not moving and need to start slowing down.
	var accel
	if dir.dot(hvel) > 0:
		# We should accelerate faster if we are sprinting
		if is_spriting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		accel = DEACCEL
	
	# Interpolate our velocity (without gravity), and then move using move_and_slide
	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	# ----------------------------------
	
	
	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------
	
	
	# ----------------------------------
	# Input handling for changing weapons, reloading,
	# turning the flashlight on/off, and for capturing/freeing the cursor
	
	# Changing weapons.
	if changing_gun == false and reloading_gun == false:
		if Input.is_key_pressed(KEY_1):
			current_gun = "UNARMED"
			changing_gun = true
		elif Input.is_key_pressed(KEY_2):
			current_gun = "KNIFE"
			changing_gun = true
		elif Input.is_key_pressed(KEY_3):
			current_gun = "PISTOL"
			changing_gun = true
		elif Input.is_key_pressed(KEY_4):
			current_gun = "RIFLE"
			changing_gun = true
	
	# Reloading
	if reloading_gun == false:
		if Input.is_action_just_pressed("reload"):
			# Make sure we are using a  gun we can reload
			if current_gun == "PISTOL" or current_gun == "RIFLE":
				# Make sure we're not in a reloading animation. If we are not, then set reloading gun to true
				# so we can reload as soon as possible
				if animation_manager.current_state != "Pistol_reload" and animation_manager.current_state != "Rifle_reload":
					reloading_gun = true
	
	# Turning the flashlight on/off
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.is_visible_in_tree():
			flashlight.hide()
		else:
			flashlight.show()
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------
	
	
	# ----------------------------------
	# Animation state changing based on player data
	#
	# NOTE: in theory this should be in a statemachine elsewhere (likely in AnimationPlayer_Manager)
	# but for simplicity, we'll just change the states as we need here.
	
	# changing weapons
	if changing_gun == true:
		
		# If we are in a idle state with the weapon we do not want to be changing to,
		# then we need to unequip it
		if current_gun != "PISTOL":
			if animation_manager.current_state == "Pistol_idle":
				animation_manager.set_animation("Pistol_unequip")
		if current_gun != "RIFLE":
			if animation_manager.current_state == "Rifle_idle":
				animation_manager.set_animation("Rifle_unequip")
		if current_gun != "KNIFE":
			if animation_manager.current_state == "Knife_idle":
				animation_manager.set_animation("Knife_unequip")
		
		# If we are changing to UNARMED and we are at 'Idle_unarmed', then
		# we've successfully changed weapons
		if current_gun == "UNARMED":
			if animation_manager.current_state == "Idle_unarmed":
				changing_gun = false
		
		# For all of the other weapons, we need to see if we are at '[weapon]_idle'.
		# If we are, then we have successfully changed weapons.
		# If we are at 'Idle_unarmed', then we need to change to '[weapon]_equip'
		# so we get to '[weapon]_idle'.
		elif current_gun == "KNIFE":
			if animation_manager.current_state == "Knife_idle":
				changing_gun = false
			if animation_manager.current_state == "Idle_unarmed":
				animation_manager.set_animation("Knife_equip")
				
		elif current_gun == "PISTOL":
			if animation_manager.current_state == "Pistol_idle":
				changing_gun = false
			if animation_manager.current_state == "Idle_unarmed":
				animation_manager.set_animation("Pistol_equip")
				
				# Play a sound when we play a equiping animation
				create_sound("Gun_cock", camera.global_transform.origin)
				
		elif current_gun == "RIFLE":
			if animation_manager.current_state == "Rifle_idle":
				changing_gun = false
			if animation_manager.current_state == "Idle_unarmed":
				animation_manager.set_animation("Rifle_equip")
				
				# Play a sound when we play a equiping animation
				create_sound("Gun_cock", camera.global_transform.origin)
	
	
	# Firing the weapons
	if Input.is_action_pressed("fire"):
		
		if current_gun == "PISTOL":
			# If we have ammo, and we're at 'Pistol_idle', then set the animation to 'Pistol_fire'
			# If we do not have ammo, then we should (try to) reload.
			if ammo_in_guns["PISTOL"] > 0:
				if animation_manager.current_state == "Pistol_idle":
					animation_manager.set_animation("Pistol_fire")
			else:
				reloading_gun = true
		
		elif current_gun == "RIFLE":
			# Same as the pistol, just changed for the rifle
			if ammo_in_guns["RIFLE"] > 0:
				if animation_manager.current_state == "Rifle_idle":
					animation_manager.set_animation("Rifle_fire")
			else:
				reloading_gun = true
		
		# Because the knife does not have ammo, we just change to 'Knife_fire' if we are at 'Knife_idle'.
		elif current_gun == "KNIFE":
			if animation_manager.current_state == "Knife_idle":
				animation_manager.set_animation("Knife_fire")
	
	# ----------------------------------
	
	# ----------------------------------
	# Reloading logic
	
	if reloading_gun == true:
		
		# We need to check whether it is possible to reload or not.
		var can_reload = false
		
		# Make sure the animation is correct for reloading.
		if current_gun == "PISTOL":
			if animation_manager.current_state == "Pistol_idle":
				can_reload = true
		elif current_gun == "RIFLE":
			if animation_manager.current_state == "Rifle_idle":
				can_reload = true
		elif current_gun == "KNIFE":
			# We cannon reload a knife, so do nothing and stop reloading
			can_reload = false
			reloading_gun = false
		else:
			# If it is a weapon we do not know about, then we cannot reload it!
			can_reload = false
			reloading_gun = false
		
		# Make sure we have ammo to reload, and that our gun is not already fully loaded.
		if ammo_for_guns[current_gun] <= 0 or ammo_in_guns[current_gun] == AMMO_IN_MAGS[current_gun]:
			can_reload = false
			reloading_gun = false
		
		
		if can_reload == true:
			
			# Calculate how much ammo we need
			var ammo_needed = AMMO_IN_MAGS[current_gun] - ammo_in_guns[current_gun]
			
			# If we have enough ammo to refil the gun, then do so.
			if ammo_for_guns[current_gun] >= ammo_needed:
				ammo_for_guns[current_gun] -= ammo_needed
				ammo_in_guns[current_gun] = AMMO_IN_MAGS[current_gun]
			# If we do not, then just put the remaining ammo into the gun.
			else:
				ammo_in_guns[current_gun] += ammo_for_guns[current_gun]
				ammo_for_guns[current_gun] = 0
			
			# Set the reloading animation
			if current_gun == "PISTOL":
				animation_manager.set_animation("Pistol_reload")
			elif current_gun == "RIFLE":
				animation_manager.set_animation("Rifle_reload")
			
			# We've finished reloading, so set reloading_gun to false
			reloading_gun = false
			
			# Play the 'gun_cock' sound so it sounds like we've reloaded.
			create_sound("Gun_cock", camera.global_transform.origin)
	
	# ----------------------------------
	
	
	# ----------------------------------
	# UI processing
	
	# HUD (UI)
	if current_gun == "UNARMED" or current_gun == "KNIFE":
		UI_status_label.text = "HEALTH: " + str(health)
	else:
		UI_status_label.text = "HEALTH: " + str(health) + "\nAMMO:" + \
			str(ammo_in_guns[current_gun]) + "/" + str(ammo_for_guns[current_gun])
	# ----------------------------------
	


# Mouse based camera movement
func _input(event):
	
	# Make sure the event is a mouse motion event and that our cursor is locked.
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		# Rotate the camera holder (everything that needs to rotate on the X-axis) by the relative Y motion.
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		# Rotate the kinematic body on the Y axis by the relative X motion.
		# We also need to multiply it by -1 because we're wanting to turn in the same direction as
		# mouse motion in real life. If we physically move the mouse left, we want to turn to the left.
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		# We need to clamp the rotation_helper's rotation so we cannot rotate ourselves upside down
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot



func fire_bullet():
	# Do not fire if we are changing weapons.
	# (Because the rifle fires so fast, we fire a couple pistol bullets when we change if we do not check this)
	if changing_gun == true:
		return
	
	# Pistol bullet handling: Spawn a bullet object!
	if current_gun == "PISTOL":
		# Clone the bullet, get the scene root, and add the bullet as a child.
		# NOTE: we are assuming that the first child of the scene's root is
		# the 3D level we're wanting to spawn the bullet at.
		var clone = bullet_scene.instance()
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(clone)
		
		# Set the bullet's global_transform to that of the pistol spawn point.
		clone.global_transform = get_node("Rotation_helper/Gun_fire_points/Pistol_point").global_transform
		# The bullet is a little too small (by default), so let's make it bigger!
		clone.scale = Vector3(4, 4, 4)
		# Remove the bullet from the pistol's magazine
		ammo_in_guns["PISTOL"] -= 1
		
		# Play the gun sound
		create_sound("Pistol_shot", get_node("Rotation_helper/Gun_fire_points/Pistol_point").global_transform.origin)
	
	# Rifle bullet handeling: Send a raycast!
	elif current_gun == "RIFLE":
		# Get the raycast node
		var ray = get_node("Rotation_helper/Gun_fire_points/Rifle_point/RayCast")
		# Force the raycast to update. This will force the raycast to detect collisions when we call it.
		# This means we are getting a frame perfect collision check with the 3D world.
		ray.force_raycast_update()
		
		# If the ray hit something, get its collider and see if it has the 'bullet_hit' method.
		# If it does, then call it and pass the ray's collision point as the bullet collision point.
		if ray.is_colliding():
			var body = ray.get_collider()
			if body.has_method("bullet_hit"):
				body.bullet_hit(RIFLE_DAMAGE, ray.get_collision_point())
		
		# Remove the bullet from the mag
		ammo_in_guns["RIFLE"] -= 1
		
		# Play the gun sound
		create_sound("Rifle_shot", ray.global_transform.origin)
	
	# Knife bullet(?) handeling: Use an area!
	elif current_gun == "KNIFE":
		# Get the knife area and all of the overlapping bodies.
		var area = get_node("Rotation_helper/Gun_fire_points/Knife_point/Area")
		var bodies = area.get_overlapping_bodies()
		
		# For every body inside the knife's area, see if it has the method 'bullet_hit'.
		# If one of the bodies do, then call it and pass the area's global origin as the bullet collision point.
		for body in bodies:
			if body.has_method("bullet_hit"):
				body.bullet_hit(KNIFE_DAMAGE, area.global_transform.origin)



func create_sound(sound_name, position=null):
	# Play the inputted sound at the inputted position
	# (NOTE: it will only play at the inputted position if you are using a AudioPlayer3D node)
	var audio_clone = simple_audio_player.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	audio_clone.play_sound(sound_name, position)

