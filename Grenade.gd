extends RigidBody

const GRENADE_DAMAGE = 60;

const GRENADE_TIME = 2;
var grenade_timer = 0;

const EXPLOSION_WAIT_TIME = 0.48;
var explosion_wait_timer = 0;

var rigid_shape;
var grenade_mesh;
var blast_area;
var explosion_particles;

func _ready():
	rigid_shape = get_node("CollisionShape");
	grenade_mesh = get_node("Grenade");
	blast_area = get_node("BlastArea");
	explosion_particles = get_node("Explosion");
	
	explosion_particles.emitting = false;
	explosion_particles.one_shot = true;

func _process(delta):
	
	if (grenade_timer < GRENADE_TIME):
		grenade_timer += delta;
		return;
	
	if (explosion_wait_timer < EXPLOSION_WAIT_TIME):
		explosion_wait_timer += delta;
		
		# If we have waited long enough, we need to explode!
		# Doing the check this way reduces a boolean, and since this is a small script, its likely okay
		# to use some coding tricks like this.
		if (explosion_wait_timer >= EXPLOSION_WAIT_TIME):
			explosion_particles.emitting = true;
			
			grenade_mesh.visible = false;
			rigid_shape.disabled = true;
			mode = RigidBody.MODE_STATIC;
			
			# Get all of the bodies in the area, and apply damage to them
			var bodies = blast_area.get_overlapping_bodies();
			for body in bodies:
				if body.has_method("bullet_hit"):
					body.bullet_hit(GRENADE_DAMAGE, global_transform.origin);
			
			# If you want, this would be the perfect place to play a sound!
			
	else:
		if (explosion_wait_timer < EXPLOSION_WAIT_TIME):
			explosion_wait_timer += delta;
			
			if (explosion_wait_timer >= EXPLOSION_WAIT_TIME):
				queue_free();
