// ---- Necromantic Monolith: shared defines & globals ----

#define NECROMONOLITH_BUILD_TIME (2 SECONDS)
#define NECROMONOLITH_SPAWN_INTERVAL (1 MINUTES)
#define NECROMONOLITH_MIN_SPAWN 2
#define NECROMONOLITH_MAX_SPAWN 3
#define NECROMONOLITH_DESIRED_ROUTES 4
#define NECROMONOLITH_ROUTE_DEPTH 900
#define NECROMONOLITH_MAX_MINIONS 30
#define NECROMONOLITH_MINION_LIFETIME (10 MINUTES)
#define NECROMONOLITH_CHASE_TIMEOUT (90 SECONDS)
#define NECROMONOLITH_REENGAGE_COOLDOWN (30 SECONDS)
#define NECROMONOLITH_ROUTE_VALIDATE_EVERY 3
#define NECROMONOLITH_WAVES_PER_REST 3
#define NECROMONOLITH_DEBUG TRUE

var/global/list/necromonolith_throne_cache

// ---- Debug helpers ----

/proc/log_necromonolith_debug(message)
	if(!NECROMONOLITH_DEBUG)
		return
	log_game("Necromonolith DEBUG: [message]")

/proc/necromonolith_debug_coords(atom/thing)
	if(!thing)
		return "null"
	return "[thing.type]([thing.x],[thing.y],[thing.z])"

/proc/describe_necromonolith_route(list/route)
	if(!length(route))
		return "len=0"
	var/turf/start = route[1]
	var/turf/end = route[length(route)]
	return "len=[length(route)] [necromonolith_debug_coords(start)] -> [necromonolith_debug_coords(end)]"

/proc/describe_necromonolith_routes(list/routes)
	if(!length(routes))
		return "none"
	var/list/descriptions = list()
	for(var/i in 1 to length(routes))
		descriptions += "#[i] [describe_necromonolith_route(routes[i])]"
	return descriptions.Join("; ")
