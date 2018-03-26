extends StaticBody

const TARGET_HEALTH = 40
var current_health = 40;

var broken_target_holder;
var target_collision_shape;

const TARGET_RESPAWN_TIME = 14;
var target_respawn_timer = 0;

export (PackedScene) var destroyed_target;

func _ready():
	broken_target_holder = get_parent().get_node("BrokenTargetHolder")
	target_collision_shape = get_node("CollisionShape")
	
	set_physics_process(true)


func _physics_process(delta):
	if (target_respawn_timer > 0):
		target_respawn_timer -= delta;
		if (target_respawn_timer <= 0):
			# Remove all children
			for child in broken_target_holder.get_children():
				child.queue_free();
				
			target_collision_shape.disabled = false;
			visible = true;
			current_health = TARGET_HEALTH;


func bullet_hit(damage, bullet_hit_pos):
	current_health -= damage
	if current_health <= 0:
		var clone = destroyed_target.instance()
		broken_target_holder.add_child(clone)
		
		# make them explode outwards
		for rigid in clone.get_children():
			if rigid is RigidBody:
				# Find the center position of the target relative to the RigidBody
				var center_in_rigid_space = broken_target_holder.global_transform.origin - rigid.global_transform.origin;
				# Find the direction from the local center to the RigidBody
				var direction = (rigid.transform.origin - center_in_rigid_space).normalized();
				# Apply the impulse with some additional force (I find 12 works nicely)
				rigid.apply_impulse(center_in_rigid_space, direction * 12 * damage);
		
		target_respawn_timer = TARGET_RESPAWN_TIME;
		
		target_collision_shape.disabled = true;
		visible = false;