extends Spatial

# A variable for tracking whether or not to use raycasts over
# creating bullets using the bullet scene
export (bool) var use_raycast = false

# How much damage each bullet option does
const TURRET_DAMAGE_BULLET = 20
const TURRET_DAMAGE_RAYCAST = 5

# The amount of time (in seconds) the flash meshes are visible
const FLASH_TIME = 0.1
# A variable for tracking how long the flash meshes have been visible
var flash_timer = 0

# The amount of time (in seconds) needed to fire
const FIRE_TIME = 0.8
# A variable for tracking how long it has been since we last fired
var fire_timer = 0

# all of the nodes we need
var node_turret_head = null
var node_raycast = null
var node_flash_one = null
var node_flash_two = null

# The amount of ammo currently in the turret
var ammo_in_turret = 20
# The amount of ammo in a full turret
const AMMO_IN_FULL_TURRET = 20
# The amount of time (in seconds) it takes for the turret to reload
const AMMO_RELOAD_TIME = 4
# A variable for tracking how long it has been since we started reloading
var ammo_reload_timer = 0

# The current target we are aiming for
var current_target = null

# A variable for tracking whether we are active or not.
# Active in this case means able to fire at the target
var is_active = false

# Because the player's position is its feet, we have to add some height so we are aiming at
# the body. This is the amount of height we add so we're (hopefully) shooting it's body.
const PLAYER_HEIGHT = 3

# The smoke particles node
var smoke_particles

# The amount of health the turret currently has
var turret_health = 60
# The amount of health a fully healed turret has
const MAX_TURRET_HEALTH = 60

# The amount of time (in seconds) it takes for a destroyed turret to repair itself
const DESTROYED_TIME = 20
# A variable for tracking the amount of time the turret has been destroyed
var destroyed_timer = 0

# The bullet scene the turret fires (same scene as the pistol)
var bullet_scene = preload("Bullet_Scene.tscn")

func _ready():
	
	# We want to know when a body has entered/exited our vision area, so we assign the body_entered and body_exited
	# signals.
	$Vision_Area.connect("body_entered", self, "body_entered_vision")
	$Vision_Area.connect("body_exited", self, "body_exited_vision")
	
	# Get all of the nodes we will need
	node_turret_head = $Head
	node_raycast = $Head/Ray_Cast
	node_flash_one = $Head/Flash
	node_flash_two = $Head/Flash_2
	
	# Add some exceptions to the raycast (so we cannot hurt ourself)
	node_raycast.add_exception(self)
	node_raycast.add_exception($Base/Static_Body)
	node_raycast.add_exception($Head/Static_Body)
	node_raycast.add_exception($Vision_Area)
	
	# Because we are not firing at start, we need to assure the flash is invisible.
	node_flash_one.visible = false
	node_flash_two.visible = false
	
	# Get the smoke particles and make sure it's not emitting
	smoke_particles = $Smoke
	smoke_particles.emitting = false
	
	# make sure our turret has max health at start
	turret_health = MAX_TURRET_HEALTH


func _physics_process(delta):
	
	# If the turret is active, then we want to process the firing code
	if is_active == true:
		
		# If the flash timer is more than zero (meaning the flash is visible) we want to remove
		# time (delta) from it
		if flash_timer > 0:
			flash_timer -= delta
			
			# If the flash timer is 0 or less, hide the flash meshes because we have waited long enough
			# and no longer need to show them
			if flash_timer <= 0:
				node_flash_one.visible = false
				node_flash_two.visible = false
		
		# If we have a target...
		if current_target != null:
			
			# Make the head look at the target, adding the player height to it's position so we are not aiming
			# at the player's feet.
			node_turret_head.look_at(current_target.global_transform.origin + Vector3(0, PLAYER_HEIGHT, 0), Vector3(0, 1, 0))
			
			# If we are not destroyed...
			if turret_health > 0:
				
				# If we have ammo, we need to see if we can fire. Otherwise, we need to process the reloading code
				if ammo_in_turret > 0:
					# If we have waited long enough to fire, then fire a bullet
					if fire_timer > 0:
						fire_timer -= delta
					else:
						fire_bullet()
				else:
					# If we're reloading, then subtract delta from ammo_reload_timer.
					# If not, then refill the turret's ammo.
					if ammo_reload_timer > 0:
						ammo_reload_timer -= delta
					else:
						ammo_in_turret = AMMO_IN_FULL_TURRET
	
	# If we are broken, then we need to wait until we are repaired
	if turret_health <= 0:
		# If we are repairing, then subtract delta from destroyed_timer.
		# Otherwise we set our health to that of a fully repaired turret and stop
		# emitting the smoke particles.
		if destroyed_timer > 0:
			destroyed_timer -= delta
		else:
			turret_health = MAX_TURRET_HEALTH
			smoke_particles.emitting = false


func fire_bullet():
	# If we are not using raycasting, then spawn a bullet using the bullet scene
	if use_raycast == false:
		
		# Clone the bullet, get the scene root, and add the bullet as a child.
		# NOTE: we are assuming that the first child of the scene's root is
		# the 3D level we're wanting to spawn the bullet at.
		var clone = bullet_scene.instance()
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(clone)
		
		# Set the bullet's global_transform to that of the pistol spawn point (which is this node).
		clone.global_transform = $Head/Barrel_End.global_transform
		# The bullet is a little too small (by default), so let's make it bigger!
		clone.scale = Vector3(8, 8, 8)
		# Set how much damage the bullet does
		clone.BULLET_DAMAGE = TURRET_DAMAGE_BULLET
		# Set how fast the bullet travels. We want the bullet to travel a little slower than the player
		clone.BULLET_SPEED = 60
		
		# Remove the bullet from the turret
		ammo_in_turret -= 1
	# Otherwise we are using raycasting (which works most of the time, sometimes it does not for some reason)
	else:
		# Rotate the raycast to look at the target (assuring we'll hit the target)
		node_raycast.look_at(current_target.global_transform.origin + Vector3(0, PLAYER_HEIGHT, 0), Vector3(0,1,0))
		
		# Force the raycast to update. This will force the raycast to detect collisions when we call it.
		# This means we are getting a frame perfect collision check with the 3D world.
		node_raycast.force_raycast_update()
		
		# If the ray hit something, get its collider and see if it has the 'bullet_hit' method.
		# If it does, then call it and pass the ray's global transform so we can tell which direction the bullet game from
		if node_raycast.is_colliding():
			var body = node_raycast.get_collider()
			if body.has_method("bullet_hit"):
				body.bullet_hit(TURRET_DAMAGE_RAYCAST, node_raycast.global_transform)
		
		# Remove the bullet from the turret
		ammo_in_turret -= 1
	
	# Make the flash meshes visible
	node_flash_one.visible = true
	node_flash_two.visible = true
	
	# Set the flash and fire timers
	flash_timer = FLASH_TIME
	fire_timer = FIRE_TIME
	
	# If the turret is out of ammo, set the reload timer
	if ammo_in_turret <= 0:
		ammo_reload_timer = AMMO_RELOAD_TIME


func body_entered_vision(body):
	# If we do not have a target, and the body that's entered our
	# vision area is a KinematicBody, we want to fire at it
	if current_target == null:
		if body is KinematicBody:
			current_target = body
			is_active = true


func body_exited_vision(body):
	# If the body that has just left is our target, we need to
	# reset the turret's target dependent variables and set the target to null.
	if current_target != null:
		if body == current_target:
			# Set the target to null, and since we do not have a target, we are no longer active
			current_target = null
			is_active = false
			
			# Reset all of the firing variables
			flash_timer = 0
			fire_timer = 0
			node_flash_one.visible = false
			node_flash_two.visible = false


func bullet_hit(damage, bullet_hit_pos):
	# Remove however much damage we have received from our health
	turret_health -= damage
	
	# If the turret is destroyed, start emitting smoke particles and set
	# the destroyed timer so we can start repairing ourself.
	if turret_health <= 0:
		smoke_particles.emitting = true
		destroyed_timer = DESTROYED_TIME

