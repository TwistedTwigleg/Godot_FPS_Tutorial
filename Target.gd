extends StaticBody

# The amount of damage needed to break a target
const TARGET_HEALTH = 40
# The amount of health the target currently has
var current_health = 40

# A node for holding the broken target scene.
# We use this to easily add/remove the broken target scene
var broken_target_holder

# The collision shape for the target.
# NOTE: this is for the whole target, not the pieces of the target
var target_collision_shape

# The amount of time (in seconds) it takes for a target to respawn
const TARGET_RESPAWN_TIME = 14
# A variable for tracking how long a target has been broken
var target_respawn_timer = 0

# The destroyed target scene. We use 'export' so we can assign it from
# the editor
export (PackedScene) var destroyed_target

func _ready():
	# Get the required nodes
	# NOTE: we are using get_node here because we need to get a node in the parent
	broken_target_holder = get_parent().get_node("Broken_Target_Holder")
	target_collision_shape = $Collision_Shape


func _physics_process(delta):
	# If the target respawn timer is more than 0, then we're currently disabled and need
	# to reduce time from the timer so we can respawn
	if target_respawn_timer > 0:
		target_respawn_timer -= delta
		
		# If the target respawn timer is 0 or less, we've waited long enough and can now respawn
		if target_respawn_timer <= 0:
			
			# Remove all children in the broken target holder
			for child in broken_target_holder.get_children():
				child.queue_free()
			
			# Enable the target collision shape
			target_collision_shape.disabled = false
			# Make ourselves visible
			visible = true
			# Reset our health
			current_health = TARGET_HEALTH


func bullet_hit(damage, bullet_hit_pos):
	current_health -= damage
	
	# If we're at 0 health or below, we need to spawn the broken target scene
	if current_health <= 0:
		# Instance the scene and add it as a child of the broken target holder
		var clone = destroyed_target.instance()
		broken_target_holder.add_child(clone)
		
		# make the pieces of the target explode outwards
		for rigid in clone.get_children():
			if rigid is RigidBody:
				# Find the center position of the target relative to the RigidBody
				var center_in_rigid_space = broken_target_holder.global_transform.origin - rigid.global_transform.origin
				# Find the direction from the local center to the RigidBody
				var direction = (rigid.transform.origin - center_in_rigid_space).normalized()
				# Apply the impulse with some additional force (I find 12 works nicely)
				rigid.apply_impulse(center_in_rigid_space, direction * 12 * damage)
		
		# Set our respawn timer
		target_respawn_timer = TARGET_RESPAWN_TIME
		
		# Disable our collision shape and make ourselves invisible
		target_collision_shape.disabled = true
		visible = false