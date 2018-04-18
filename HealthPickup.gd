extends Spatial

# The size of this ammo pickup
export (int, "full size", "small") var kit_size = 0 setget kit_size_change

# The amount of health each pickup in each size contains
# 0 = full size pickup, 1 = small pickup
const HEALTH_AMOUNTS = [70, 30]

# The length of time (in seconds) it will take for the pickup to respawn
const RESPAWN_TIME = 20
# A variable for tracking how much respawn time has passed
var respawn_timer = 0

# A variable for tracking whether _ready has been called.
# Because setget functions are called before _ready, we need to ignore the
# first kit_size_change call, because we cannot access child nodes until _ready is called
var is_ready = false

func _ready():
	
	# Get the area for the trigger, and assign it's body_entered signal to trigger_body_entered
	$Holder/Health_Pickup_Trigger.connect("body_entered", self, "trigger_body_entered")
	
	# Now we can use all of our setget functions.
	is_ready = true
	
	# Hide all of the possible kit sizes
	kit_size_change_values(0, false)
	kit_size_change_values(1, false)
	# Then make only the proper one visible
	kit_size_change_values(kit_size, true)


func _physics_process(delta):
	# If the respawn timer is more than 0, then we are currently invisible and need
	# to subtract time (delta) from the timer.
	if respawn_timer > 0:
		respawn_timer -= delta
		
		# If the timer is 0 or less, then we've successfully waited long enough and can make ourselves visible again
		if respawn_timer <= 0:
			kit_size_change_values(kit_size, true)


func kit_size_change(value):
	# We only want to change things IF _ready has already been called.
	# this is because we cannot access nodes until _ready has been called, but all setget
	# functions are called before _ready. To get around this, we only set kit_value if we
	# are not ready.
	if is_ready:
		# Make the current kit invisible and disable its collision shape
		kit_size_change_values(kit_size, false)
		kit_size = value
		# Make the newly assigned kit visible and enable its collision shape
		kit_size_change_values(kit_size, true)
	else:
		kit_size = value


func kit_size_change_values(size, enable):
	# Based on the size passed in, enable/disable the correct nodes.
	# This includes the collision shape, so we cannot pickup health for a size that is not visible.
	# (If all sizes are disabled, then we cannot collect health at all)
	if size == 0:
		$Holder/Health_Pickup_Trigger/Shape_Kit.disabled = !enable
		$Holder/Health_Kit.visible = enable
	elif size == 1:
		$Holder/Health_Pickup_Trigger/Shape_Kit_Small.disabled = !enable
		$Holder/Health_Kit_Small.visible = enable


func trigger_body_entered(body):
	# If the body has the add_health function, then call it,
	# set the respawn timer (so we have to wait for the health to respawn),
	# and make the nodes for the current size disabled.
	if body.has_method("add_health"):
		body.add_health(HEALTH_AMOUNTS[kit_size])
		respawn_timer = RESPAWN_TIME
		kit_size_change_values(kit_size, false)
