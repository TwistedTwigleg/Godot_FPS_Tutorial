extends Spatial

# The speed the bullet travels at
var BULLET_SPEED = 70
# The damage the bullet does on whatever it hits
var BULLET_DAMAGE = 15
# NOTE: for both BULLET_SPEED and BULLET_DAMAGE, we are keeping their
# names uppercase because we do not want their values to change outside of
# when they are instanced/spawned.

# The length of time this bullet last (in seconds) before we free it.
# (because we do not want the bullet to travel forever, as it will consume resources)
const KILL_TIMER = 4
var timer = 0

# A boolean to store whether or not we have hit something.
# This is so we cannot damage more than one object if we manage to hit more than one before
# this bullet is set free / destroyed
var hit_something = false

func _ready():
	# We want to get the area and connect ourself to it's body_entered signal.
	# This is so we can tell when we've collided with an object.
	$Area.connect("body_entered", self, "collided")
	

func _physics_process(delta):
	# Get the forward directional vector and move ourself by it (times BULLET_SPEED and delta)
	# NOTE: This is the bullet's local positive Z axis.
	var forward_dir = global_transform.basis.z.normalized()
	global_translate(forward_dir * BULLET_SPEED * delta)
	
	# A simple timer check that frees this node when the timer is done.
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()


func collided(body):
	# If we have not hit something already check if the body we collided with has the 'bullet_hit' method.
	# If it does, then call it, passing our global origin as the bullet collision point.
	if hit_something == false:
		if body.has_method("bullet_hit"):
			body.bullet_hit(BULLET_DAMAGE, global_transform)
	
	# Set hit_something to true because we've hit an object and set free ourself.
	hit_something = true
	queue_free()
