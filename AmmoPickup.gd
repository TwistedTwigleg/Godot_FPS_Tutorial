extends Spatial

# The size of this ammo pickup
export (int, "full size", "small") var kit_size = 0 setget kit_size_change

# The amount of ammo clips each pickup in each size contains
# 0 = full size pickup, 1 = small pickup
const AMMO_AMOUNTS = [4, 1];
# The amount of grenades each pickup in each size contains
# 0 = full size pickup, 1 = small pickup
const GRENADE_AMOUNTS = [2, 0];

# The leng of time (in seconds) will it take for the pickup to respawn
const RESPAWN_TIME = 20;
# A variable for tracking how much time has passed
var respawn_timer = 0;

# A variable for tracking whether _ready has been called.
# Because of how exported variables work, we need to ignore the first
# kit_size_chance call because it is called before _ready.
var is_ready = false;

func _ready():
	
	# Get the area for the trigger, and assign it's body_entered signal to trigger_body_entered
	get_node("Holder/AmmoPickupTrigger").connect("body_entered", self, "trigger_body_entered");
	
	set_physics_process(true);
	is_ready = true;
	
	# Hide all of the possible kit sizes
	kit_size_change_values(0, false);
	kit_size_change_values(1, false);
	# Then make only the proper one visible
	kit_size_change_values(kit_size, true);


func _physics_process(delta):
	# If the respawn timer is more than 0, then we're currently invisible and need
	# to reduce time from the timer
	if (respawn_timer > 0):
		respawn_timer -= delta;
		
		# If the timer is 0 or less, then we've successfully waited long enough and can make ourselves visible again
		if (respawn_timer <= 0):
			kit_size_change_values(kit_size, true);


func kit_size_change(value):
	# We only want to change things IF we have already had _ready called.
	# this is because we cannot access nodes until _ready has been called, but any setget
	# function is called before _ready. To get around this, we just set the value if we are
	# not ready
	if (is_ready == true):
		# Make the current kit invisible and disable its collision shape
		kit_size_change_values(kit_size, false)
		kit_size = value;
		# Make the newly assigned kit visible and enable its collision shape
		kit_size_change_values(kit_size, true)
	else:
		kit_size = value;


func kit_size_change_values(size, enable):
	# Based on the size passed in, enable/disable the correct nodes
	if (size == 0):
		get_node("Holder/AmmoPickupTrigger/ShapeKit").disabled = !enable;
		get_node("Holder/AmmoKit").visible = enable;
	elif (size == 1):
		get_node("Holder/AmmoPickupTrigger/ShapeKitSmall").disabled = !enable;
		get_node("Holder/AmmoKitSmall").visible = enable;


func trigger_body_entered(body):
	# If the body has the add_ammo function, then call it,
	# set the respawn timer (so we have to wait), and make the current
	# size's nodes enabled/disabled.
	if (body.has_method("add_ammo")):
		body.add_ammo(AMMO_AMOUNTS[kit_size]);
		respawn_timer = RESPAWN_TIME;
		kit_size_change_values(kit_size, false);
	
	# If the body has the add_grenade function, then call it,
	# set the respawn timer (so we have to wait), and make the current
	# size's nodes enabled/disabled.
	if (body.has_method("add_grenade")):
		body.add_grenade(GRENADE_AMOUNTS[kit_size])
		respawn_timer = RESPAWN_TIME;
		kit_size_change_values(kit_size, false);