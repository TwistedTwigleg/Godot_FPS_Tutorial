extends Spatial

# The speed the bullet travels at
const BULLET_SPEED = 80
# The damage it causes
const BULLET_DAMAGE = 15

# How many seconds does it last before we free it
# (because we do not want bullets traveling forever as they will consume resources)
const KILL_TIMER = 4
var timer = 0

# A boolean to store whether or not we have hit something.
# This is so we cannot damage more than one object.
var hit_something = false

func _ready():
	# We want to get the area and connect ourself to it's body_entered signal.
	# This is so we can tell when we've collided with an object.
	get_node("Area").connect("body_entered", self, "collided")
	set_physics_process(true)


func _physics_process(delta):
	# Get the forward directional vector and move ourself by it (times BULLET_SPEED and delta)
	# NOTE: This is the bullet's local positive Z axis.
	var forward_dir = global_transform.basis.z.normalized()
	global_translate(forward_dir * BULLET_SPEED * delta)
	
	# A simple timer check that frees this node when the timer is done.
	timer += delta;
	if timer >= KILL_TIMER:
		queue_free()


func collided(body):
	# If we have not hit something already check if the body we collided with has the 'bullet_hit' method.
	# If it does, then call it, passing our global origin as the bullet collision point.
	if hit_something == false:
		if body.has_method("bullet_hit"):
			body.bullet_hit(BULLET_DAMAGE, self.global_transform.origin)
	
	# Set hit_something to true because we've hit an object and set free ourself.
	hit_something = true
	queue_free()
