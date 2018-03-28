extends RigidBody

# The amount of damage the grenade explosion does
const GRENADE_DAMAGE = 60;

# The amount of time the grenade takes (in seconds) to explode once it's created/thrown
const GRENADE_TIME = 2;
# A variable for tracking how long the grenade has been created/thrown
var grenade_timer = 0;

# The amount of time needed (in seconds) to wait so we can destroy the grenade after the explosion
# (Calculated by the particle life time divided by the particle speed)
const EXPLOSION_WAIT_TIME = 0.48;
# A variable to track how long we've waited after the explosion
var explosion_wait_timer = 0;

# All of the nodes we need
var rigid_shape;
var grenade_mesh;
var blast_area;
var explosion_particles;

func _ready():
	# Get all of the nodes
	rigid_shape = get_node("CollisionShape");
	grenade_mesh = get_node("Grenade");
	blast_area = get_node("BlastArea");
	explosion_particles = get_node("Explosion");
	
	# Make sure the explosion particles are not emitting, and make sure one_shot is enabled.
	explosion_particles.emitting = false;
	explosion_particles.one_shot = true;

func _process(delta):
	
	# If the grenade timer is not at GRENADE_TIME, add delta to the grenade timer and return
	if (grenade_timer < GRENADE_TIME):
		grenade_timer += delta;
		return;
	else:
		# If we have waited long enough, we need to explode!
		if (explosion_wait_timer <= 0):
			# Make the explosion particles emit
			explosion_particles.emitting = true;
			
			# Make the grenade mesh invisible, and disable the collision shape for the RigidBody
			grenade_mesh.visible = false;
			rigid_shape.disabled = true;
			
			# Set the RigidBody mode to static so it does not move
			mode = RigidBody.MODE_STATIC;
			
			# Get all of the bodies in the area, and apply damage to them
			var bodies = blast_area.get_overlapping_bodies();
			for body in bodies:
				if body.has_method("bullet_hit"):
					body.bullet_hit(GRENADE_DAMAGE, global_transform.origin);
			
			# This would be the perfect place to play a sound!
		
		
		# See if we need to free the grenade
		if (explosion_wait_timer < EXPLOSION_WAIT_TIME):
			explosion_wait_timer += delta;
			
			# If we have waited long enough, then free the grenade
			if (explosion_wait_timer >= EXPLOSION_WAIT_TIME):
				queue_free();
