extends StaticBody

export (NodePath) var path_to_turret_root;

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func bullet_hit(damage, bullet_hit_pos):
	if (path_to_turret_root != null):
		get_node(path_to_turret_root).bullet_hit(damage, bullet_hit_pos);