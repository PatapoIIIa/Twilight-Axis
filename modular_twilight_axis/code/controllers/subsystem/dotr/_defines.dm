// ---- SSdotr (Defence of the Roguetown): defines ----

#define DOTR_CHECK_INTERVAL (1 SECONDS)
#define DOTR_PLAYER_ZONE_RANGE 14
#define DOTR_SPAWN_EDGE_RANGE 7
#define DOTR_MAX_PHYSICAL_PER_ZONE 12
#define DOTR_VIRTUAL_STEP_TICKS 2
#define DOTR_DEVIRT_COOLDOWN (2 SECONDS)
#define DOTR_SAFE_RANGE 3
#define DOTR_WITHER_DPS 1.6
#define DOTR_VIRTUAL_CHASE_TIMEOUT (90 SECONDS)
#define DOTR_DEBUG TRUE

/proc/log_dotr_debug(message)
	if(!DOTR_DEBUG)
		return
	log_game("SSdotr DEBUG: [message]")
