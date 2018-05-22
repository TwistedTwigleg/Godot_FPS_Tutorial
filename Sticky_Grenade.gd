extends RigidBody

const GRENADE_DAMAGE = 40

const GRENADE_TIME = 3
var grenade_timer = 0

const EXPLOSION_WAIT_TIME = 0.48
var explosion_wait_timer = 0

var attached = false
var attach_point = null

var rigid_shape
var grenade_mesh
var blast_area
var explosion_particles

var player_body

func _ready():
	rigid_shape = $Collision_Shape
	grenade_mesh = $Sticky_Grenade
	blast_area = $Blast_Area
	explosion_particles = $Explosion

	explosion_particles.emitting = false
	explosion_particles.one_shot = true

	$Sticky_Area.connect("body_entered", self, "collided_with_body")


func collided_with_body(body):

	if body == self:
		return

	if player_body != null:
		if body == player_body:
			return

	if attached == false:
		attached = true
		attach_point = Spatial.new()
		body.add_child(attach_point)
		attach_point.global_transform.origin = global_transform.origin

		rigid_shape.disabled = true

		mode = RigidBody.MODE_STATIC


func _process(delta):

	if attached == true:
		if attach_point != null:
			global_transform.origin = attach_point.global_transform.origin

	if grenade_timer < GRENADE_TIME:
		grenade_timer += delta
		return
	else:
		if explosion_wait_timer <= 0:
			explosion_particles.emitting = true

			grenade_mesh.visible = false
			rigid_shape.disabled = true

			mode = RigidBody.MODE_STATIC

			var bodies = blast_area.get_overlapping_bodies()
			for body in bodies:
				if body.has_method("bullet_hit"):
					body.bullet_hit(GRENADE_DAMAGE, global_transform.origin)

			# This would be the perfect place to play a sound!


		if explosion_wait_timer < EXPLOSION_WAIT_TIME:
			explosion_wait_timer += delta

			if explosion_wait_timer >= EXPLOSION_WAIT_TIME:
				if attach_point != null:
					attach_point.queue_free()
				queue_free()