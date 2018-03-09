extends KinematicBody

# Walking variables.
# This manages how fast we walk (and how quickly we can get to top speed),
# how strong gravity is, and how high we jump.
const norm_grav = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL= 4.5

# A vector for storing the direction the player intends to walk towards.
var dir = Vector3()

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
# The scroll wheel value
var mouse_scroll_value = 0
# How much a single scroll action increases mouse_scroll_value
const MOUSE_SENSITIVITY_SCROLL_WHEEL = 0.08

# You may need to adjust depending on the sensitivity of your joypad
const JOYPAD_SENSITIVITY = 2
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
const weapon_number_to_name = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const weapon_name_to_number = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
# A boolean to track if we are changing weapons
var changing_weapon = false
# The name of the weapon we want to change to, if we are changing weapons
var changing_weapon_name = "UNARMED"
# A boolean to track if we are reloading
var reloading_weapon = false

# How much health we currently have
var health = 100

# The label for how much health we have, and how much ammo we have.
var UI_status_label
# The flashlight spotlight
var flashlight

# The audio player scene. Will play a sound, and then destroy itself.
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
	# We need to process _input if we want to use the mouse wheel
	set_process_input(true)
	
	# Get all of the weapon nodes
	weapons["KNIFE"] = get_node("Rotation_helper/Gun_fire_points/Knife_point")
	weapons["PISTOL"] = get_node("Rotation_helper/Gun_fire_points/Pistol_point")
	weapons["RIFLE"] = get_node("Rotation_helper/Gun_fire_points/Rifle_point")
	
	# The point where we want all of the weapons to aim at
	var gun_aim_point_pos = get_node("Rotation_helper/Gun_aim_point").global_transform.origin
	
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
	
	# Make sure the starting weapon is UNARMED
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	
	# Get the UI label so we can show our health and ammo, and get the flashlight spotlight
	UI_status_label = get_node("HUD/Panel/Gun_label")
	flashlight = get_node("Rotation_helper/Flashlight")


func _physics_process(delta):
	
	# Process most of the input related code.
	# This includes: Movement, jumping, flash light toggling, freeing/locking the cursor,
	# 				 firing the weapons, and reloading.
	process_input(delta)
	
	# Process view related input (Joypad)
	process_view_input(delta)
	
	# Process our movement using functions provided in KinematicBody.
	# This will move us based on our previous state, and the input we just processed
	process_movement(delta)
	
	# Process the weapon changing logic. 
	process_changing_weapons(delta)
	
	# Process the weapon reloading logic
	process_reloading(delta)
	
	# Process the UI
	process_UI(delta)


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
	if (Input.is_action_pressed("movement_forward")):
		input_movement_vector.y += 1
	if (Input.is_action_pressed("movement_backward")):
		input_movement_vector.y -= 1
	if (Input.is_action_pressed("movement_left")):
		input_movement_vector.x -= 1
	if (Input.is_action_pressed("movement_right")):
		input_movement_vector.x = 1
	
	# Add joypad input, if there is a joypad
	if Input.get_connected_joypads().size() > 0:
		# Make a Vector2 with the left joy stick axes.
		# 
		# NOTE: You may need to change the axes depending on your controller/OS.
		# This tutorial assumes you are using a XBOX 360 controller on Windows.
		# The bindings are likely different for different operating systems and/or controllers
		var joypad_vec = Vector2(Input.get_joy_axis(0, 0), -Input.get_joy_axis(0, 1))
		
		# Account for joypad dead zones
		if (abs(joypad_vec.x) <= JOYPAD_DEADZONE):
			joypad_vec.x = 0
		if (abs(joypad_vec.y) <= JOYPAD_DEADZONE):
			joypad_vec.y = 0
		
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
		is_spriting = true
	else:
		is_spriting = false
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
	var weapon_change_number = weapon_name_to_number[current_weapon_name]
	
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
	weapon_change_number = clamp(weapon_change_number, 0, weapon_number_to_name.size()-1)
	
	# Make sure we are not changing weapons, or reloading. We do not want to be able to change weapons
	# if we are already changing weapons, or reloading.
	if changing_weapon == false:
		if reloading_weapon == false:
			# Convert the weapon change number into a weapon name and check
			# if we are not using that weapon. If we are not, then change to it.
			if weapon_number_to_name[weapon_change_number] != current_weapon_name:
				# Set changing_weapon_name to the name of the weapon we want to change to, and set changing_weapon to true.
				changing_weapon_name = weapon_number_to_name[weapon_change_number]
				changing_weapon = true
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
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
		
		# For windows (XBOX 360)
		joypad_vec = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
		# For Linux (XBOX 360)
		#joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		# For Mac (XBOX 360) Unknown, but likely:
		#joypad_vec = Vector2(Input.get_joy_axis(0, 3), Input.get_joy_axis(0, 4))
		
		# Account for joypad dead zones
		if abs(joypad_vec.x) <= JOYPAD_DEADZONE:
			joypad_vec.x = 0
		if abs(joypad_vec.y) <= JOYPAD_DEADZONE:
			joypad_vec.y = 0
	
	# Rotate the camera holder (everything that needs to rotate on the X-axis) by the relative Y joypad motion.
	# NOTE: If you want your joystick inverted, then change "joypad_vec.y" to "-joypad_vec.y".
	rotation_helper.rotate_x(deg2rad(joypad_vec.y * JOYPAD_SENSITIVITY))
	# Rotate the kinematic body on the Y axis by the relative X motion.
	# We also need to multiply it by -1 because we're wanting to turn in the same direction as
	# joystick motion in real life. If we physically move the joystick left, we want to turn to the left.
	self.rotate_y(deg2rad(joypad_vec.x * JOYPAD_SENSITIVITY * -1))
	# ----------------------------------
	
	# We need to clamp the rotation_helper's rotation so we cannot rotate ourselves upside down
	# We need to do this every time we rotate so we cannot rotate upside down with mouse and/or joypad input
	var camera_rot = rotation_helper.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, -70, 70)
	rotation_helper.rotation_degrees = camera_rot


func process_movement(delta):
	# Process our movements (influenced by our input) and sending them to KinematicBody
	
	# Apply gravity
	var grav = norm_grav
	
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
		UI_status_label.text = "HEALTH: " + str(health)
	else:
		var current_weapon = weapons[current_weapon_name]
		UI_status_label.text = "HEALTH: " + str(health) + "\nAMMO:" + \
			str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo)


# Mouse based camera movement
func _input(event):
	
	# Make sure the event is a mouse motion event and that our cursor is locked.
	if event is InputEventMouseButton && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# We can ONLY access the scroll wheel in _input. Because of this,
		# we have to process changing weapons with the scroll wheel here.
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			# Add/Remove MOUSE_SENSITIVITY_SCROLL_WHEEL based on which direction we are scrolling
			if event.button_index == BUTTON_WHEEL_UP:
				mouse_scroll_value += MOUSE_SENSITIVITY_SCROLL_WHEEL
			elif event.button_index == BUTTON_WHEEL_DOWN:
				mouse_scroll_value -= MOUSE_SENSITIVITY_SCROLL_WHEEL
			
			# Make sure we are using a valid number by clamping the value
			mouse_scroll_value = clamp(mouse_scroll_value, 0, weapon_number_to_name.size()-1)
			
			# Make sure we are not already changing weapons, or reloading.
			if changing_weapon == false:
				if reloading_weapon == false:
					# Round mouse_scroll_view so we get a full number and convert it from a float to a int
					var round_mouse_scroll_value = int(round(mouse_scroll_value))
					# If we are not already using the weapon at that position, then change to it.
					if weapon_number_to_name[round_mouse_scroll_value] != current_weapon_name:
						changing_weapon_name = weapon_number_to_name[round_mouse_scroll_value]
						changing_weapon = true
						# Set mouse scroll value to the rounded value so the amount of time it takes to change weapons
						# is consistent.
						mouse_scroll_value = round_mouse_scroll_value
	
	# Make sure the event is a mouse motion event, and that the cursor is captured
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
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
	var audio_clone = simple_audio_player.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	audio_clone.play_sound(sound_name, position)

