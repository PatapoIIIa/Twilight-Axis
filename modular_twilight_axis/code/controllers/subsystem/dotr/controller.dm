// ---- SSdotr: controller interface ----
// Thin relay between a spawner and SSdotr. Like the minion component relays
// to the monolith, the controller relays spawner data to the subsystem.

/datum/dotr_controller
	var/datum/weakref/owner_ref
	var/controller_id = 0
	var/faction_tag = ""
	var/safe_range = DOTR_SAFE_RANGE

/datum/dotr_controller/Destroy()
	owner_ref = null
	return ..()

/// List of living mobs this spawner manages
/datum/dotr_controller/proc/get_managed_mobs()
	return list()

/// Can this mob be virtualized right now?
/datum/dotr_controller/proc/can_virtualize(mob/living/the_mob)
	return FALSE

/// Create a profile from a living mob. Removes the mob. Returns profile or null.
/datum/dotr_controller/proc/capture(mob/living/the_mob)
	return null

/// Recreate a mob from profile at turf. Returns mob or null.
/datum/dotr_controller/proc/materialize(datum/dotr_profile/profile, turf/spawn_turf)
	return null

/// Called when a profile dies virtually
/datum/dotr_controller/proc/on_profile_died(datum/dotr_profile/profile)
	return

/// Z-level of the spawner
/datum/dotr_controller/proc/get_z_level()
	var/atom/A = owner_ref?.resolve()
	return A ? A.z : 0

/// Routes for virtual movement
/datum/dotr_controller/proc/get_routes()
	return list()

/// Hostility check for virtual combat
/datum/dotr_controller/proc/is_hostile_to(datum/dotr_controller/other)
	if(!other || !faction_tag || !other.faction_tag)
		return FALSE
	return faction_tag != other.faction_tag
