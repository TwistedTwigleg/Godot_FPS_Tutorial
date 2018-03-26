extends Spatial

export (bool) var use_raycast = false;

const TURRET_DAMAGE_BULLET = 20;
const TURRET_DAMAGE_RAYCAST = 5;

const FLASH_TIME = 0.1;
var flash_timer = 0;
const FIRE_TIME = 0.8;
var fire_timer = 0;

var node_turret_head = null;
var node_raycast = null;
var node_flash_one = null;
var node_flash_two = null;

var ammo_in_turret = 20;
const AMMO_IN_FULL_TURRET = 20;
const AMMO_RELOAD_TIME = 4;
var ammo_reload_timer = 0;

var current_target = null;
var is_active = false;
const PLAYER_HEIGHT = 3;

var smoke_particles;
var turret_health = 60;
const MAX_TURRET_HEALTH = 60;
const DESTROYED_TIME = 20;
var destroyed_timer = 0;

# The bullet scene the turret fires
var bullet_scene = preload("Bullet_Scene.tscn")

func _ready():
	get_node("VisionArea").connect("body_entered", self, "body_entered_vision");
	get_node("VisionArea").connect("body_exited", self, "body_exited_vision");
	
	node_turret_head = get_node("Head");
	node_raycast = get_node("Head/RayCast");
	node_flash_one = get_node("Head/Flash");
	node_flash_two = get_node("Head/Flash2");
	
	node_flash_one.visible = false;
	node_flash_two.visible = false;
	
	smoke_particles = get_node("Smoke");
	smoke_particles.emitting = false;
	turret_health = MAX_TURRET_HEALTH;
	
	set_physics_process(true)


func _physics_process(delta):
	if (is_active == true):
		if (flash_timer > 0):
			flash_timer -= delta;
			if (flash_timer <= 0):
				node_flash_one.visible = false;
				node_flash_two.visible = false;
		
		if (current_target != null):
			node_turret_head.look_at(current_target.global_transform.origin + Vector3(0, PLAYER_HEIGHT, 0), Vector3(0, 1, 0));
			
			if (turret_health > 0):
				if (ammo_in_turret > 0):
					if (fire_timer > 0):
						fire_timer -= delta;
					else:
						fire_bullet()
				else:
					if (ammo_reload_timer > 0):
						ammo_reload_timer -= delta;
					else:
						ammo_in_turret = AMMO_IN_FULL_TURRET;
	
	if (turret_health <= 0):
		if (destroyed_timer > 0):
			destroyed_timer -= delta;
		else:
			turret_health = MAX_TURRET_HEALTH;
			smoke_particles.emitting = false;


func fire_bullet():
	if (use_raycast == false):
		# Clone the bullet, get the scene root, and add the bullet as a child.
		# NOTE: we are assuming that the first child of the scene's root is
		# the 3D level we're wanting to spawn the bullet at.
		var clone = bullet_scene.instance()
		var scene_root = get_tree().root.get_children()[0]
		scene_root.add_child(clone)
		
		# Set the bullet's global_transform to that of the pistol spawn point (which is this node).
		clone.global_transform = get_node("Head/BarrleEnd").global_transform;
		# The bullet is a little too small (by default), so let's make it bigger!
		clone.scale = Vector3(8, 8, 8)
		# Set how much damage the bullet does
		clone.BULLET_DAMAGE = TURRET_DAMAGE_BULLET;
		clone.BULLET_SPEED = 60;
		clone.rotate_object_local(Vector3(0, 1, 0), deg2rad(180));
		
		# Remove the bullet from the turret
		ammo_in_turret -= 1
	else:
		# Force the raycast to update. This will force the raycast to detect collisions when we call it.
		# This means we are getting a frame perfect collision check with the 3D world.
		node_raycast.force_raycast_update()
		
		# If the ray hit something, get its collider and see if it has the 'bullet_hit' method.
		# If it does, then call it and pass the ray's collision point as the bullet collision point.
		if node_raycast.is_colliding():
			var body = node_raycast.get_collider()
			if body.has_method("bullet_hit"):
				body.bullet_hit(TURRET_DAMAGE_RAYCAST, node_raycast.get_collision_point())
		
		# Remove the bullet from the turret
		ammo_in_turret -= 1;
	
	node_flash_one.visible = true;
	node_flash_two.visible = true;
	
	flash_timer = FLASH_TIME;
	fire_timer = FIRE_TIME;
	
	if (ammo_in_turret <= 0):
		ammo_reload_timer = AMMO_RELOAD_TIME;


func body_entered_vision(body):
	if (current_target == null):
		if (body is KinematicBody):
			current_target = body;
			is_active = true;


func body_exited_vision(body):
	if (body == current_target):
		current_target = null;
		is_active = false;
		
		flash_timer = 0;
		fire_timer = 0;
		node_flash_one.visible = false;
		node_flash_two.visible = false;


func bullet_hit(damage, bullet_hit_pos):
	turret_health -= damage;
	
	if (turret_health <= 0):
		smoke_particles.emitting = true;
		destroyed_timer = DESTROYED_TIME;

