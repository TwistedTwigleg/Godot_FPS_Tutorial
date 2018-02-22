extends RigidBody

func _ready():
	pass

func bullet_hit(damage, bullet_hit_pos):
	# We get the directional vector pointing from the bullet hit position to our origin.
	var direction_vect = self.global_transform.origin - bullet_hit_pos
	# Normalize the directional vector (so distance doesn't change the knockback)
	direction_vect = direction_vect.normalized()
	
	# Then we apply a local impulse at the hit position with a force pointed at the directional vector.
	# This gives the appearance of the bullet push the object on collision.
	self.apply_impulse(bullet_hit_pos, direction_vect * damage)