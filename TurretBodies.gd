extends StaticBody

# The path to the turret root node (needed to send the signal pack up)
export (NodePath) var path_to_turret_root

func _ready():
	pass

func bullet_hit(damage, bullet_hit_pos):
	# Send everything passed to us to our turret's bullet_hit function
	if path_to_turret_root != null:
		get_node(path_to_turret_root).bullet_hit(damage, bullet_hit_pos)