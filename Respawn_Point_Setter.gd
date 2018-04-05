extends Spatial

func _ready():
	# Get the globals autoload script
	var globals = get_node("/root/Globals")
	# We assume every child is a respawn point, so we add all of our children as the spawn point
	globals.respawn_points = get_children()
