// ---- SSdort (Defence of Roguetown): defines ----

#define DORT_CHECK_INTERVAL (1 SECONDS)
#define DORT_PLAYER_ZONE_RANGE 14
#define DORT_SPAWN_EDGE_RANGE 7
#define DORT_MAX_PHYSICAL_PER_ZONE 12
#define DORT_VIRTUAL_STEP_TICKS 2
#define DORT_DEVIRT_COOLDOWN (2 SECONDS)
#define DORT_SAFE_RANGE 3
#define DORT_WITHER_DPS 1.6
#define DORT_VIRTUAL_CHASE_TIMEOUT (90 SECONDS)
#define DORT_DEBUG TRUE

/proc/log_dort_debug(message)
	if(!DORT_DEBUG)
		return
	log_game("SSdort DEBUG: [message]")
