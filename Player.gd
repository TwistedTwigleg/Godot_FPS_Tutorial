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

# The animation manager that holds all of our animations and their transition states
var animation_manager

# Gun variables.
# The name of the weapon we are currently using
var current_weapon_name = "UNARMED"
# A dictonary of all the weapons we have
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
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
	
	# Get all of the weapons
	weapons["KNIFE"] = get_node("Rotation_helper/Gun_fire_points/Knife_point")
	weapons["PISTOL"] = get_node("Rotation_helper/Gun_fire_points/Pistol_point")
	weapons["RIFLE"] = get_node("Rotation_helper/Gun_fire_points/Rifle_point")
	
	# The point where we want all of the guns to aim at
	var gun_aim_point_pos = get_node("Rotation_helper/Gun_aim_point").global_transform.origin
	
	# Send our script to all of the weapons and rotate them to aim at the center of the screen
	for weapon in weapons:
		var weapon_node = weapons[weapon];
		if weapon_node != null:
			weapon_node.player_node = self;
			# Look at the center point
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0));
			# Because we have the camera rotated by 180 degrees, we need to rotate the points around by 180
			# degrees on their local Y axis because otherwise the bullets will fire backwards
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad(180));
	
	# Make sure we are starting with UNARMED
	current_weapon_name = "UNARMED";
	changing_weapon_name = "UNARMED";
	
	# Get the UI label so we can show our health and ammo, and get the flashlight spotlight
	UI_status_label = get_node("HUD/Panel/Gun_label")
	flashlight = get_node("Rotation_helper/Flashlight")


func _physics_process(delta):
	
	# Process all of the input related code.
	# This includes: Movement, jumping, flash light toggling, freeing/locking the cursor,
	# 				 firing the weapons, and reloading.
	process_input(delta);
	
	# Process our KinematicBody's movement.
	# This will move our KinematicBody based on its previous state, and the input we just processed
	process_movement(delta);
	
	# Process the weapon changing logic. 
	process_changing_weapons(delta);
	
	# Process the weapon reloading logic
	process_reloading(delta);
	
	# Process the UI
	process_UI(delta);


func process_input(delta):
	# ----------------------------------
	# Walking
	# Based on the action pressed, we move in a direction relative to the camera.
	# 
	# NOTE: because the camera is rotated by -180 degrees
	# all of the directional vectors are the opposite in comparison to our KinematicBody.
	# (The camera's local Z axis actually points backwards while our KinematicBody points forwards)
	# To get around this, we flip the camera's directional vectors so they point in the same direction
	
	# Reset dir, so our previous movement does not effect us
	dir = Vector3()
	# Get the camera's global transform so we can use its directional vectors
	var cam_xform = camera.get_global_transform()
	
	# Based on which directional key is pressed, add that direction to dir
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
	# Jumping
	# Check if we are on the floor. If we are and the "movement_jump" action has
	# been pressed, then jump.
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------
	
	# ----------------------------------
	# Changing weapons.
	if changing_weapon == false:
		if reloading_weapon == false:
			if Input.is_key_pressed(KEY_1):
				changing_weapon_name = "UNARMED"
				changing_weapon = true
			elif Input.is_key_pressed(KEY_2):
				changing_weapon_name = "KNIFE"
				changing_weapon = true
			elif Input.is_key_pressed(KEY_3):
				changing_weapon_name = "PISTOL"
				changing_weapon = true
			elif Input.is_key_pressed(KEY_4):
				changing_weapon_name = "RIFLE"
				changing_weapon = true
	# ----------------------------------
	
	# ----------------------------------
	# Reloading
	if reloading_weapon == false:
		if (changing_weapon == false):
			if Input.is_action_just_pressed("reload"):
				# Get the current weapon, and make sure it is not null
				var current_weapon = weapons[current_weapon_name];
				if (current_weapon != null):
					# Make sure this weapon can reload
					if (current_weapon.CAN_RELOAD == true):
						# Make sure we're not in a reloading animation. If we are not, then set reloading gun to true
						# so we can reload as soon as possible
						var current_anim_state = animation_manager.current_state;
						var is_reloading = false;
						for weapon in weapons:
							var weapon_node = weapons[weapon];
							if weapon_node != null:
								if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
									is_reloading = true;
						if is_reloading == false:
							reloading_weapon = true;
	# ----------------------------------
	
	# ----------------------------------
	# Firing the weapons
	if Input.is_action_pressed("fire"):
		if (reloading_weapon == false):
			if (changing_weapon == false):
				var current_weapon = weapons[current_weapon_name];
				if (current_weapon != null):
					if current_weapon.ammo_in_weapon > 0:
						if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
							animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME);
					else:
						reloading_weapon = true;
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


func process_movement(delta):
	# Process our movements (influnced by our input) and sending them to KinematicBody
	
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


func process_changing_weapons(delta):
	# changing weapons
	if changing_weapon == true:
		
		# Unequip the current gun
		var gun_unequipped = false
		var current_weapon = weapons[current_weapon_name]
		if current_weapon == null:
			gun_unequipped = true
		else:
			if (current_weapon.is_weapon_enabled == true):
				gun_unequipped = current_weapon.unequip_weapon()
			else:
				gun_unequipped = true;
		
		if gun_unequipped == true:
			
			var weapon_equiped = false
			var weapon_to_equip = weapons[changing_weapon_name]
			
			if weapon_to_equip == null:
				weapon_equiped = true
			else:
				if (weapon_to_equip.is_weapon_enabled == false):
					weapon_equiped = weapon_to_equip.equip_weapon()
				else:
					weapon_equiped = true;
			
			if weapon_equiped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name;
				changing_weapon_name = "";


func process_reloading(delta):
	# Reloading logic
	if reloading_weapon == true:
		var current_weapon = weapons[current_weapon_name];
		if (current_weapon != null):
			current_weapon.reload_weapon();
		reloading_weapon = false;


func process_UI(delta):
	# UI processing
	
	# HUD (UI)
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		UI_status_label.text = "HEALTH: " + str(health)
	else:
		var current_weapon = weapons[current_weapon_name];
		UI_status_label.text = "HEALTH: " + str(health) + "\nAMMO:" + \
			str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo)


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
	if changing_weapon == true:
		return
	
	var current_weapon = weapons[current_weapon_name];
	current_weapon.fire_weapon()


func create_sound(sound_name, position=null):
	# Play the inputted sound at the inputted position
	# (NOTE: it will only play at the inputted position if you are using a AudioPlayer3D node)
	var audio_clone = simple_audio_player.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	audio_clone.play_sound(sound_name, position)

