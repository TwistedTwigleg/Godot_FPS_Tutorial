extends KinematicBody

# Walking variables.
# This manages how fast we are moving, fast we can walk,
# how quickly we can get to top speed, how strong gravity is, and how high we jump.
const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL= 4.5

# A vector for storing the direction the player intends to move towards.
var dir = Vector3()

# Sprinting variables. Similar to the varibles above for walking,
# but these are used when sprinting (so they should be faster/higher)
const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
# A boolean to track if we are spriting
var is_sprinting = false

# How fast we slow down, and the steepest angle that counts as a floor (to the KinematicBody).
const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

# The camera and the rotation helper.
# We need the camera to get its directional vectors.
#We rotate ourselves on the Y-axis using the rotation_helper to avoid rotating on more than one axis at a time.
var camera
var rotation_helper

# The sensitivity of the mouse
# (Higher values equals faster movements with the mouse. Lower values equals slower movements with the mouse)
# (You may need to adjust depending on the sensitivity of your mouse)
var MOUSE_SENSITIVITY = 0.05
# The value of the scroll wheel (relative to our current weapon)
var mouse_scroll_value = 0
# How much a single scroll action increases mouse_scroll_value
const MOUSE_SENSITIVITY_SCROLL_WHEEL = 0.08

# The sensitivity of the joypad's joysticks.
# (Higher values equals faster movements with the mouse. Lower values equals slower movements with the mouse)
# (You may need to adjust depending on the sensitivity of your joypad)
var JOYPAD_SENSITIVITY = 2
# The dead zone for the joypad. Many joypads jitter around a certain point, so any movement in a
# with a radius of JOYPAD_DEADZONE should be ignored (or the camera will jitter)
const JOYPAD_DEADZONE = 0.15

# The animation manager that holds all of our animations and their transition states
var animation_manager

# Weapon variables.
# The name of the weapon we are currently using
var current_weapon_name = "UNARMED"
# A dictionary of all the weapons we have
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
# A dictionary containing the weapons names and which number they use
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
# A boolean to track if we are changing weapons
var changing_weapon = false
# The name of the weapon we want to change to, if we are changing weapons
var changing_weapon_name = "UNARMED"
# A boolean to track if we are reloading
var reloading_weapon = false

# The amount of health we currently have
var health = 100
# The amount of health we have when fully healed
const MAX_HEALTH = 150
# The amount of time (in seconds) required to respawn
const RESPAWN_TIME = 4
# A variable to track how long we've been dead
var dead_time = 0
# A variable to track whether or not we are currently dead
var is_dead = false

# The label for how much health we have, how many grenades we have,
# and how much ammo is in our current weapon (along with how much ammo we have in reserve for that weapon)
var UI_status_label
# The flashlight spotlight
var flashlight

# The audio player scene. Will play a sound, and then destroy itself.
var simple_audio_player = preload("res://Simple_Audio_Player.tscn")

# Grenade variables
# The number of grenades we currently have for each type of grenade
var grenade_amounts = {"Grenade":2, "Sticky Grenade":2}
# The current selected grenade
var current_grenade = "Grenade"
# The grenade and sticky grenade scenes
var grenade_scene = preload("res://Grenade.tscn")
var sticky_grenade_scene = preload("res://Sticky_Grenade.tscn")
# The amount of force we throw the grenades at
const GRENADE_THROW_FORCE = 50

# The object we currently have grabbed
var grabbed_object = null
# The amount of force we throw grabbed objects at
const OBJECT_THROW_FORCE = 120
# The distance we hold grabbed objects at
const OBJECT_GRAB_DISTANCE = 7
# The distance of our grabbing raycast
const OBJECT_GRAB_RAY_DISTANCE = 10

# Our globals script.
# We need this for making sounds, and getting a respawn point
var globals


func _ready():
	
	# Get the camera and the rotation helper
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	
	# Get the animation manager and pass in a funcref for 'fire bullet'.
	# This allows 'fire_bullet' to be called from the guns fire animations.
	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")
	
	# We need to capture the mouse in order to use it for a FPS style camera control.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Get all of the weapon nodes
	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
	
	# The point where we want all of the weapons to aim at
	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin
	
	# Send ourself to all of the weapons, and then rotate them to aim at the center of the screen
	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			weapon_node.player_node = self
			# Make the weapon node look at the center point
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
			# Because we have the camera rotated by 180 degrees, we need to rotate the weapon around by 180
			# degrees on their local Y axis because otherwise the bullets will fire backwards
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
	
	# Make sure the starting weapon is UNARMED,
	# and we are using normal grenades at the start
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	current_grenade = "Grenade"
	
	# Get the UI label so we can show our health and ammo, and get the flashlight spotlight
	UI_status_label = $HUD/Panel/Gun_label
	flashlight = $Rotation_Helper/Flashlight
	
	# Get the globals autoload script
	# We have to use get node, because we cannot access autoload scripts using $
	globals = get_node("/root/Globals")
	
	# Start at a random respawn point
	global_transform.origin = globals.get_respawn_position()
	
	# Get the mouse and joypad sensitivity
	MOUSE_SENSITIVITY = globals.mouse_sensitivity
	JOYPAD_SENSITIVITY = globals.joypad_sensitivity


func _physics_process(delta):
	
	# If we are dead, we do not want to process anything that moves the player, or takes player input.
	#So we check to make sure we are not dead before calling any of those functions
	if !is_dead:
		# Process most of the input related code.
		# This includes: Movement, jumping, flash light toggling, freeing/locking the cursor,
		# 				 firing the weapons, throwing grenades, and reloading.
		process_input(delta)
		
		# Process view related input (Joypad)
		process_view_input(delta)
		
		# Process our movement using functions provided in KinematicBody.
		# This will move us based on our previous state, and the input we just processed
		process_movement(delta)
	
	# If we have grabbed a object, we do not want to be able to change weapons or reload
	if grabbed_object == null:
		# Process the weapon changing logic. 
		process_changing_weapons(delta)
		
		# Process the weapon reloading logic
		process_reloading(delta)
	
	# Process the UI
	process_UI(delta)
	
	# Process respawning
	process_respawn(delta)


func process_input(delta):
	# ----------------------------------
	# Walking
	# Based on the action pressed, we move in a direction relative to the camera.
	
	# Reset dir, so our previous movement does not effect us
	dir = Vector3()
	# Get the camera's global transform so we can use its directional vectors
	var cam_xform = camera.get_global_transform()
	
	# Create a vector for storing our keyboard/joypad input
	var input_movement_vector = Vector2()
	
	# Add keyboard input
	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x = 1
	
	# Add joypad input, if there is a joypad
	if Input.get_connected_joypads().size() > 0:
		# Make a Vector2 with the left joy stick axes.
		# 
		# NOTE: You may need to change the axes depending on your controller/OS.
		var joypad_vec = Vector2(0, 0)
		
		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 0), -Input.get_joy_axis(0, 1))
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 1), Input.get_joy_axis(0, 2))
		
		# Account for joypad dead zones.
		# Using the code provided in the article linked below:
		# (http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html)
		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))
		
		# Apply the joypad movement
		input_movement_vector += joypad_vec
	
	# Normalize the input movement vector so we cannot move faster if we have
	# keyboard movement and joypad movement at the same time.
	input_movement_vector = input_movement_vector.normalized()
	
	# Add the camera's local vectors based on what direction we are heading towards.
	# NOTE: because the camera is rotated by -180 degrees
	# all of the directional vectors are the opposite in comparison to our KinematicBody.
	# (The camera's local Z axis actually points backwards while our KinematicBody points forwards)
	# To get around this, we flip the camera's directional vectors so they point in the same direction
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	# ----------------------------------
	
	# ----------------------------------
	# Sprinting
	# If we are sprinting, we need change the is_sprinting boolean accordingly
	if Input.is_action_pressed("movement_sprint"):
		is_sprinting = true
	else:
		is_sprinting = false
	# ----------------------------------
	
	# ----------------------------------
	# Jumping
	# Check if we are on the floor. If we are and the "movement_jump" action has
	# been pressed, then jump.
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------
	
	# ----------------------------------
	# Changing weapons.
	# Get the current weapon's number.
	var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
	
	# If any of the number keys are pressed, then change weapon_change_number to the pressed number.
	# We offset the number keys by negative 1, so the 1 key really is mapped 0.
	if Input.is_key_pressed(KEY_1):
		weapon_change_number = 0
	if Input.is_key_pressed(KEY_2):
		weapon_change_number = 1
	if Input.is_key_pressed(KEY_3):
		weapon_change_number = 2
	if Input.is_key_pressed(KEY_4):
		weapon_change_number = 3
	
	# Shift the weapon_change_number by one depending on which action is pressed
	if Input.is_action_just_pressed("shift_weapon_positive"):
		weapon_change_number += 1
	if Input.is_action_just_pressed("shift_weapon_negative"):
		weapon_change_number -= 1
	
	# Make sure we are using a valid weapon_change_number by clamping it
	weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size()-1)
	
	# Make sure we are not changing weapons, or reloading. We do not want to be able to change weapons
	# if we are already changing weapons, or reloading.
	if changing_weapon == false:
		if reloading_weapon == false:
			# Convert the weapon change number into a weapon name and check
			# if we are not using that weapon. If we are not, then change to it.
			if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
				# Set changing_weapon_name to the name of the weapon we want to change to, and set changing_weapon to true.
				changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
				changing_weapon = true
				
				# Set the scroll wheel value to reflect the newly changed weapon
				mouse_scroll_value = weapon_change_number
	# ----------------------------------
	
	# ----------------------------------
	# Reloading
	# Make sure we are not changing weapons, or already reloading.
	if reloading_weapon == false:
		if changing_weapon == false:
			if Input.is_action_just_pressed("reload"):
				# Get the current weapon, and make sure it is not null
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null:
					# Make sure this weapon can reload
					if current_weapon.CAN_RELOAD == true:
						# Make sure we're not in a reloading animation. If we are not, then set reloading_weapon to true
						# so we can reload as soon as possible
						var current_anim_state = animation_manager.current_state
						var is_reloading = false
						# Make sure we are not in any weapon's reloading animation
						for weapon in weapons:
							var weapon_node = weapons[weapon]
							if weapon_node != null:
								if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
									is_reloading = true
						# If we are not reloading, then we can set reloading_weapon to true so we can reload as soon as possible
						if is_reloading == false:
							reloading_weapon = true
	# ----------------------------------
	
	# ----------------------------------
	# Firing the weapons
	if Input.is_action_pressed("fire"):
		# Make sure we are not trying to reload or change weapons.
		if reloading_weapon == false:
			if changing_weapon == false:
				# Make sure we are using a weapon (not using UNARMED)
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null:
					# If we have ammo in our current weapon, then change to its firing animation
					# If we do not have ammo in our current weapon, then reload.
					if current_weapon.ammo_in_weapon > 0:
						if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
							animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME)
					else:
						reloading_weapon = true
	# ----------------------------------
	
	# ----------------------------------
	# Turning the flashlight on/off
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.is_visible_in_tree():
			flashlight.hide()
		else:
			flashlight.show()
	# ----------------------------------
	
	# ----------------------------------
	# Capturing the mouse.
	# Because our pause menu assures the mouse is visible, all we need to do is
	# check if the mouse is visible, and if it is make it captured.
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# ----------------------------------
	
	
	# ----------------------------------
	# Changing and throwing grenades
	
	# Change the name of the current grenade based on which grenade we are using
	if Input.is_action_just_pressed("change_grenade"):
		if current_grenade == "Grenade":
			current_grenade = "Sticky Grenade"
		elif current_grenade == "Sticky Grenade":
			current_grenade = "Grenade"
	
	# Fire the grenade when fire_grenade is pressed
	if Input.is_action_just_pressed("fire_grenade"):
		# If we have a grenade for the current grenade type we are using
		if grenade_amounts[current_grenade] > 0:
			# Remove one from the grenade count
			grenade_amounts[current_grenade] -= 1
			
			# Based on which grenade we are using, instance it and assign it to grenade_clone
			var grenade_clone
			if (current_grenade == "Grenade"):
				grenade_clone = grenade_scene.instance()
			elif (current_grenade == "Sticky Grenade"):
				grenade_clone = sticky_grenade_scene.instance()
				# Sticky grenades will stick to the player if we do not pass ourselves
				grenade_clone.player_body = self
			
			# Add the grenade as a child, position it correctly, and apply an impulse so we are throwing it
			get_tree().root.add_child(grenade_clone)
			grenade_clone.global_transform = $Rotation_Helper/Grenade_Toss_Pos.global_transform
			grenade_clone.apply_impulse(Vector3(0,0,0), grenade_clone.global_transform.basis.z * GRENADE_THROW_FORCE)
	# ----------------------------------
	
	# ----------------------------------
	# Grabbing and throwing objects
	
	# If the fire action is pressed, and we are UNARMED.
	# We could make a grab action, but because our UNARMED 'weapon' does nothing with fire anyway, we'll just use
	# the fire action to avoid making another action.
	if Input.is_action_just_pressed("fire") and current_weapon_name == "UNARMED":
		# If we are not holding a object...
		if grabbed_object == null:
			# Get the direct space state so we can raycast into the world.
			var state = get_world().direct_space_state
			# We want to project the ray from the camera, using the center of the screen
			var center_position = get_viewport().size/2
			var ray_from = camera.project_ray_origin(center_position)
			var ray_to = ray_from + camera.project_ray_normal(center_position) * OBJECT_GRAB_RAY_DISTANCE
			# Send our ray into the space state and see if we got a result.
			# We want to exclude ourself, and the knife's Area so that does not mess up the results
			var ray_result = state.intersect_ray(ray_from, ray_to, [self, $Rotation_Helper/Gun_Fire_Points/Knife_Point/Area])
			if ray_result:
				# If the result's collider is a RigidBody...
				if ray_result["collider"] is RigidBody:
					# Set grabbed object to the RigidBody
					grabbed_object = ray_result["collider"]
					# Set it's mode to static so gravity does not effect it
					grabbed_object.mode = RigidBody.MODE_STATIC
					# Place it on collision layer and mask zero, which means it is not
					# on any collision layer, nor mask
					grabbed_object.collision_layer = 0
					grabbed_object.collision_mask = 0
		# We are holding a object...
		else:
			# Set the RigidBody's mode back to MODE_RIGID
			grabbed_object.mode = RigidBody.MODE_RIGID
			# Send it flying in the direction we are looking at
			grabbed_object.apply_impulse(Vector3(0,0,0), -camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE)
			# Set it's collision layer and mask back to one
			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1
			# And set grabbed object to null, because we have successfully thrown the object
			grabbed_object = null
	
	# While technically not input related, it's easy enough to place the code moving the grabbed object here
	# because it's only two lines, and then all of the grabbing/throwing code is in one place
	if grabbed_object != null:
		grabbed_object.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z.normalized() * OBJECT_GRAB_DISTANCE)
	# ----------------------------------


func process_view_input(delta):
	
	# If our cursor is not captured, then we do NOT want to rotate
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	
	# NOTE: Until some bugs relating to captured mouses are fixed, we cannot put the mouse view
	# rotation code here. Once the bug(s) are fixed, code for mouse view rotation code will go here!
	
	# ----------------------------------
	# Joypad rotation
	
	# Get the right joypad movement vector, if there is a joypad connected (otherwise joypad_vec will equal (0, 0))
	var joypad_vec = Vector2()
	if Input.get_connected_joypads().size() > 0:
		
		# For windows (Wired XBOX 360 controller)
		if OS.get_name() == "Windows":
			joypad_vec = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
		# For Linux (Wired XBOX 360 controller)
		elif OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		# For Mac (Wired XBOX 360 controller). (I have no idea on it's axis, so we'll just use the same as Linux):
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		
		# Account for joypad dead zones.
		# Using the code provided in the article linked below:
		# (http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html)
		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0, 0)
		else:
			joypad_vec = joypad_vec.normalized() * ((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))
	
		# Rotate the camera holder (everything that needs to rotate on the X-axis) by the relative Y joypad motion.
		# NOTE: If you want your joystick inverted, then change "joypad_vec.y" to "-joypad_vec.y".
		rotation_helper.rotate_x(deg2rad(joypad_vec.y * JOYPAD_SENSITIVITY))
		
		# Rotate the kinematic body on the Y axis by the relative X motion.
		# We also need to multiply it by -1 because we're wanting to turn in the same direction as
		# joystick motion in real life. If we physically move the joystick left, we want to turn to the left.
		rotate_y(deg2rad(joypad_vec.x * JOYPAD_SENSITIVITY * -1))
		
		# We need to clamp the rotation_helper's rotation so we cannot rotate ourselves upside down
		# We need to do this every time we rotate so we cannot rotate upside down with mouse and/or joypad input
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
	# ----------------------------------


func process_movement(delta):
	# Process our movements (influenced by our input) and sending them to KinematicBody
	
	# Assure our movement direction on the Y axis is zero, and then normalize it.
	dir.y = 0
	dir = dir.normalized()
	
	# Apply gravity
	vel.y += delta*GRAVITY
	
	# Set our velocity to a new variable (hvel) and remove the Y velocity.
	var hvel = vel
	hvel.y = 0
	
	# Based on whether we are sprinting or not, set our max speed accordingly.
	var target = dir
	if is_sprinting:
		target *= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED
	
	
	# If we have movement input, then accelerate.
	# Otherwise we are not moving and need to start slowing down.
	var accel
	if dir.dot(hvel) > 0:
		# We should accelerate faster if we are sprinting
		if is_sprinting:
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


func process_changing_weapons(delta):
	# changing weapons
	if changing_weapon == true:
		
		# A variable to hold whether or not we've unequipped the current weapon
		var weapon_unequipped = false
		# Get the current weapon.
		var current_weapon = weapons[current_weapon_name]
		# If the current weapon is null (UNARMED), then we can change weapons.
		# If not, then we need to check if the current weapon is enabled or not.
		if current_weapon == null:
			weapon_unequipped = true
		else:
			# If the current weapon is enabled, then call unequip_weapon.
			if current_weapon.is_weapon_enabled == true:
				weapon_unequipped = current_weapon.unequip_weapon()
			else:
				weapon_unequipped = true
		
		# If we have successfully unequipped the current weapon, we need to equip the new weapon
		if weapon_unequipped == true:
			
			# A variable to hold whether or not we've equipped the new weapon
			var weapon_equiped = false
			# Get the new weapon
			var weapon_to_equip = weapons[changing_weapon_name]
			
			# If the new weapon is null (UNARMED), then we can say we've successfully equipped the new weapon.
			# If not, then we need to check if the new weapon is enabled or not.
			if weapon_to_equip == null:
				weapon_equiped = true
			else:
				# If the new weapon is not enabled, then call equip_weapon.
				if weapon_to_equip.is_weapon_enabled == false:
					weapon_equiped = weapon_to_equip.equip_weapon()
				else:
					weapon_equiped = true
			
			# If we have successfully equipped the new weapon then we need to
			# set some variables to reflect the change in weapon.
			if weapon_equiped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name
				changing_weapon_name = ""


func process_reloading(delta):
	# Reloading logic
	if reloading_weapon == true:
		# If the weapon is not null, then call it's reload_weapon function.
		var current_weapon = weapons[current_weapon_name]
		if current_weapon != null:
			current_weapon.reload_weapon()
		# We have called the weapon's reload function, so we no longer are reloading
		reloading_weapon = false


func process_UI(delta):
	# UI processing
	
	# Set the HUD text
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		# First line: Health, second line: Grenades
		UI_status_label.text = "HEALTH: " + str(health) + \
		"\n" + current_grenade + ":" + str(grenade_amounts[current_grenade])
	else:
		var current_weapon = weapons[current_weapon_name]
		# First line: Health, second line: weapon and ammo, third line: grenades
		UI_status_label.text = "HEALTH: " + str(health) + \
		"\nAMMO:" + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo) + \
		"\n" + current_grenade + ":" + str(grenade_amounts[current_grenade])


func process_respawn(delta):
	# If we just died
	if health <= 0 and !is_dead:
		# Disable our collision shapes
		$Body_CollisionShape.disabled = true
		$Feet_CollisionShape.disabled = true
		# change our weapon to UNARMED
		changing_weapon = true
		changing_weapon_name = "UNARMED"
		# Enable the death UI
		$HUD/Death_Screen.visible = true
		# Disable the other UI
		$HUD/Panel.visible = false
		$HUD/Crosshair.visible = false
		# Wait to respawn
		dead_time = RESPAWN_TIME
		# Set is_dead, so we know we are dead
		is_dead = true
		
		# If we are holding an object, then let it go
		if grabbed_object != null:
			# Set the grabbed RigidBody's mode back to MODE_RIGID
			grabbed_object.mode = RigidBody.MODE_RIGID
			# Send it flying in the direction we are looking at (at half our normal force)
			grabbed_object.apply_impulse(Vector3(0,0,0), -camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE / 2)
			# Set it's collision layer and mask back to one
			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1
			# And set grabbed object to null, because we have successfully thrown the object
			grabbed_object = null
	
	if is_dead:
		# Subtract time from dead_time
		dead_time -= delta
		# We the purposes of the label, we ideally want the time to be in a prettier format.
		# Do do this, we convert dead_time to a string, and get the first three characters (2.0, for example)
		var dead_time_pretty = str(dead_time).left(3)
		# Update the death screen label
		$HUD/Death_Screen/Label.text = "You died\n" + dead_time_pretty + " seconds till respawn"
		
		# If dead time is 0 or less, we've waited long enough and can respawn
		if dead_time <= 0:
			# Get a respawn position
			global_transform.origin = globals.get_respawn_position()
			# Enable our collision shapes
			$Body_CollisionShape.disabled = false
			$Feet_CollisionShape.disabled = false
			# Disable the death UI
			$HUD/Death_Screen.visible = false
			# Enable the other UI
			$HUD/Panel.visible = true
			$HUD/Crosshair.visible = true
			# Reset all of the weapons
			for weapon in weapons:
				var weapon_node = weapons[weapon]
				if weapon_node != null:
					weapon_node.reset_weapon()
			# Reset our health
			health = 100
			# Reset our grenades
			grenade_amounts = {"Grenade":2, "Sticky Grenade":2}
			current_grenade = "Grenade"
			# Now we have respawned, and are no longer dead
			is_dead = false


# Mouse based camera movement
func _input(event):
	
	# If we are dead, we do not want to process input events
	if is_dead:
		return
	
	# Make sure the event is a mouse motion event and that our cursor is locked.
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# We can ONLY access the scroll wheel in _input. Because of this,
		# we have to process changing weapons with the scroll wheel here.
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			# Add/Remove MOUSE_SENSITIVITY_SCROLL_WHEEL based on which direction we are scrolling
			if event.button_index == BUTTON_WHEEL_UP:
				mouse_scroll_value += MOUSE_SENSITIVITY_SCROLL_WHEEL
			elif event.button_index == BUTTON_WHEEL_DOWN:
				mouse_scroll_value -= MOUSE_SENSITIVITY_SCROLL_WHEEL
			
			# Make sure we are using a valid number by clamping the value
			mouse_scroll_value = clamp(mouse_scroll_value, 0, WEAPON_NUMBER_TO_NAME.size()-1)
			
			# Make sure we are not already changing weapons, or reloading.
			if changing_weapon == false:
				if reloading_weapon == false:
					# Round mouse_scroll_view so we get a full number and convert it from a float to a int
					var round_mouse_scroll_value = int(round(mouse_scroll_value))
					# If we are not already using the weapon at that position, then change to it.
					if WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value] != current_weapon_name:
						changing_weapon_name = WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value]
						changing_weapon = true
						# Set mouse scroll value to the rounded value so the amount of time it takes to change weapons
						# is consistent.
						mouse_scroll_value = round_mouse_scroll_value
	
	# Make sure the event is a mouse motion event, and that the cursor is captured
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Mouse rotation.
		
		# Rotate the camera holder (everything that needs to rotate on the X-axis) by the relative Y mouse motion.
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		# Rotate the kinematic body on the Y axis by the relative X motion.
		# We also need to multiply it by -1 because we're wanting to turn in the same direction as
		# mouse motion in real life. If we physically move the mouse left, we want to turn to the left.
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		# ----------------------------------
		
		# We need to clamp the rotation_helper's rotation so we cannot rotate ourselves upside down
		# We need to do this every time we rotate so we cannot rotate upside down with mouse and/or joypad input
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot


func fire_bullet():
	# Do not fire if we are changing weapons.
	# (Because the rifle fires so fast, we fire a couple pistol bullets when we change if we do not check this)
	if changing_weapon == true:
		return
	
	# Get the current weapon and call it's fire_weapon function
	weapons[current_weapon_name].fire_weapon()


func create_sound(sound_name, position=null):
	# Play the inputted sound at the inputted position
	# (NOTE: it will only play at the inputted position if you are using a AudioPlayer3D node)
	globals.play_sound(sound_name, false, position)


func add_health(additional_health):
	# Adds addition_health to our player, and clamps the health from 0 to MAX_HEALTH
	health += additional_health
	health = clamp(health, 0, MAX_HEALTH)


func add_ammo(additional_ammo):
	# Adds ammo to the current weapon, IF we are not unarmed and we can refil the current weapon.
	if (current_weapon_name != "UNARMED"):
		if (weapons[current_weapon_name].CAN_REFILL == true):
			weapons[current_weapon_name].spare_ammo += weapons[current_weapon_name].AMMO_IN_MAG * additional_ammo

func add_grenade(additional_grenade):
	# Adds additional_grenade to our player's current selected grenade, and clamps the amount from 0 to 4.
	grenade_amounts[current_grenade] += additional_grenade
	grenade_amounts[current_grenade] = clamp(grenade_amounts[current_grenade], 0, 4)


func bullet_hit(damage, bullet_global_transform):
	# Removes damage from our health
	health -= damage

