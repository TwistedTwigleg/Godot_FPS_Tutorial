extends RigidBody

# The amount of damage the grenade explosion does
const GRENADE_DAMAGE = 40

# The amount of time the grenade takes (in seconds) to explode once it's created/thrown
const GRENADE_TIME = 3
# A variable for tracking how long the grenade has been created/thrown
var grenade_timer = 0

# The amount of time needed (in seconds) to wait so we can destroy the grenade after the explosion
# (Calculated by taking the particle life time and dividing it by the particle's speed scale)
const EXPLOSION_WAIT_TIME = 0.48
# A variable for tracking how much time has passed since this grenade exploded
var explosion_wait_timer = 0

# A boolean for tracking whether or not we've attached to a CollisionBody
var attached = false
# The point we've attached to.
var attach_point = null

# All of the nodes we need
var rigid_shape
var grenade_mesh
var blast_area
var explosion_particles

# The player KinematicBody.
# We need this so we can make sure we are not going to stick to the player that threw this grenade
var player_body

func _ready():
	# Get all of the nodes we will need
	rigid_shape = $Collision_Shape
	grenade_mesh = $Sticky_Grenade
	blast_area = $Blast_Area
	explosion_particles = $Explosion
	
	# Make sure the explosion particles are not emitting, and make sure one_shot is enabled.
	explosion_particles.emitting = false
	explosion_particles.one_shot = true
	
	# Connect the sticky area's body_entered signal so we can know when we've collided with something
	$Sticky_Area.connect("body_entered", self, "collided_with_body")


func collided_with_body(body):
	
	# Make sure we are not colliding with ourself
	if body == self:
		return
	
	# We do not want to collide with the player that's thrown this grenade
	if player_body != null:
		if body == player_body:
			return
	
	if attached == false:
		# Attach ourselves to the body at that position.
		# We will do this by making a new Spatial node, and making it a child of the body we
		# collided with. Then we will set it's transform to our transform, and the follow
		# that node in _process
		attached = true
		attach_point = Spatial.new()
		body.add_child(attach_point)
		attach_point.global_transform.origin = global_transform.origin
		
		# Disable our collision shape so we don't knock the body we've attached to around while we're stuck to it
		rigid_shape.disabled = true
		
		# Set our mode to MODE_STATIC so the grenade does not move around
		mode = RigidBody.MODE_STATIC


func _process(delta):
	
	# If we have attached to something, then stick to the point we attached to
	if attached == true:
		if attach_point != null:
			global_transform.origin = attach_point.global_transform.origin
	
	# If the grenade timer is not at GRENADE_TIME, add time (delta) to the grenade timer and return
	if grenade_timer < GRENADE_TIME:
		grenade_timer += delta
		return
	else:
		# If we have waited long enough, we need to explode!
		# NOTE: this will only be called once, because we add time (delta) to explosion_wait_timer
		# below.
		if explosion_wait_timer <= 0:
			# Make the explosion particles emit
			explosion_particles.emitting = true
			
			# Make the grenade mesh invisible, and disable the collision shape for the RigidBody
			grenade_mesh.visible = false
			rigid_shape.disabled = true
			
			# Set the RigidBody mode to static so it does not move
			mode = RigidBody.MODE_STATIC
			
			# Get all of the bodies in the area, and apply damage to them
			var bodies = blast_area.get_overlapping_bodies()
			for body in bodies:
				if body.has_method("bullet_hit"):
					body.bullet_hit(GRENADE_DAMAGE, body.global_transform.looking_at(global_transform.origin, Vector3(0,1,0)) )
			
			# This would be the perfect place to play a sound!
		
		
		# See if we need to free the grenade
		if explosion_wait_timer < EXPLOSION_WAIT_TIME:
			explosion_wait_timer += delta
			
			# If we have waited long enough, then free the grenade.
			# If we have a attached point, we want to free that too
			if explosion_wait_timer >= EXPLOSION_WAIT_TIME:
				if attach_point != null:
					attach_point.queue_free()
				queue_free()
			
		
	
