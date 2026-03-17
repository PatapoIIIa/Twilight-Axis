#define NECROMONOLITH_BUILD_TIME (2 SECONDS)
#define NECROMONOLITH_SPAWN_INTERVAL (1 MINUTES)
#define NECROMONOLITH_MIN_SPAWN 2
#define NECROMONOLITH_MAX_SPAWN 3
#define NECROMONOLITH_DESIRED_ROUTES 4
#define NECROMONOLITH_ROUTE_DEPTH 900
#define NECROMONOLITH_REST_INTERVAL (2 MINUTES)
#define NECROMONOLITH_REST_DURATION (2 MINUTES)
#define NECROMONOLITH_MAX_MINIONS 30
#define NECROMONOLITH_MINION_LIFETIME (10 MINUTES)
#define NECROMONOLITH_CHASE_TIMEOUT (90 SECONDS)
#define NECROMONOLITH_REENGAGE_COOLDOWN (30 SECONDS)
#define NECROMONOLITH_DEBUG TRUE

/obj/effect/proc_holder/spell/invoked/necromantic_monolith
	name = "Necromantic Monolith"
	desc = "Raise a necromantic monolith that fixes several routes toward the throne and periodically births aggressive skeletons to march along them."
	clothes_req = FALSE
	overlay_state = "animate"
	range = 7
	sound = list('sound/magic/magnet.ogg')
	releasedrain = 60
	chargetime = 1 SECONDS
	warnie = "spellwarning"
	no_early_release = TRUE
	charging_slowdown = 1
	chargedloop = /datum/looping_sound/invokegen
	gesture_required = TRUE
	associated_skill = /datum/skill/magic/arcane
	recharge_time = 90 SECONDS
	spell_tier = 4
	zizo_spell = TRUE
	hide_charge_effect = TRUE
	invocations = list("ZIZO, ANCHOR MY DEAD TO THE THRONE!")
	invocation_type = "shout"
	var/datum/weakref/active_monolith

/obj/effect/proc_holder/spell/invoked/necromantic_monolith/cast(list/targets, mob/living/user)
	. = ..()

	if(!HAS_TRAIT(user, TRAIT_CABAL))
		to_chat(user, span_warning("The dead do not heed me."))
		revert_cast()
		return FALSE

	var/obj/structure/necromantic_monolith/existing_monolith = active_monolith?.resolve()
	if(existing_monolith && !QDELETED(existing_monolith))
		to_chat(user, span_warning("A necromantic monolith is already bound to me."))
		revert_cast()
		return FALSE

	if(istype(get_area(user), /area/rogue/indoors/ravoxarena))
		to_chat(user, span_userdanger("Something in this place chokes the rite before it can root."))
		revert_cast()
		return FALSE

	if(!length(targets))
		revert_cast()
		return FALSE

	var/turf/target_turf = get_turf(targets[1])
	var/place_failure = can_place_necromonolith_on(target_turf, user)
	if(place_failure)
		to_chat(user, span_warning(place_failure))
		revert_cast()
		return FALSE

	var/list/setup = prepare_necromonolith_routes(target_turf, user)
	if(!setup)
		to_chat(user, span_warning("The dead cannot find a road from that place to the throne."))
		revert_cast()
		return FALSE

	user.visible_message(span_warning("[user] begins shaping a jagged monolith from necromantic force."), span_notice("I begin anchoring a necromantic monolith."))
	if(!do_after(user, NECROMONOLITH_BUILD_TIME, target_turf))
		to_chat(user, span_warning("My concentration breaks before the monolith can take shape."))
		return FALSE

	place_failure = can_place_necromonolith_on(target_turf, user)
	if(place_failure)
		to_chat(user, span_warning(place_failure))
		return FALSE

	setup = prepare_necromonolith_routes(target_turf, user)
	if(!setup)
		to_chat(user, span_warning("The throne's roads slip away before the rite can be finished."))
		return FALSE

	var/obj/structure/necromantic_monolith/monolith = new(target_turf, user, setup["throne"], setup["routes"])
	if(QDELETED(monolith))
		to_chat(user, span_warning("The rite collapses before the monolith can stabilize."))
		return FALSE

	active_monolith = WEAKREF(monolith)
	monolith.visible_message(span_userdanger("A necromantic monolith claws its way into reality, humming with tethered routes."))
	return TRUE

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

/obj/structure/necromantic_monolith
	name = "necromantic monolith"
	desc = "A hateful shard of dark progress. It pulses with fixed roads leading to the throne."
	icon = 'icons/roguetown/items/gems.dmi'
	icon_state = "necro_crystal"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	max_integrity = 250
	var/datum/weakref/owner_ref
	var/owner_name
	var/owner_faction_tag
	var/atom/movable/target_throne
	var/list/cached_routes = list()
	var/list/active_minions = list()
	var/spawn_timer_id
	var/next_route_pick = 1

/obj/structure/necromantic_monolith/Initialize(mapload, mob/living/caster, atom/movable/preferred_throne, list/precomputed_routes)
	. = ..()
	if(caster)
		owner_ref = WEAKREF(caster)
		owner_name = caster.real_name ? caster.real_name : caster.name
		if(caster.mind?.current)
			owner_faction_tag = "[caster.mind.current.real_name]_faction"
	if(preferred_throne && !QDELETED(preferred_throne))
		target_throne = preferred_throne
	cached_routes = normalize_necromonolith_routes(precomputed_routes, get_turf(src))
	if(!length(cached_routes) && !refresh_necromonolith_routes())
		return INITIALIZE_HINT_QDEL
	log_necromonolith_debug("initialized monolith=[necromonolith_debug_coords(src)] throne=[necromonolith_debug_coords(target_throne)] routes=[describe_necromonolith_routes(cached_routes)]")
	set_light(3, 2, 1, l_color = "#6f2036")
	queue_next_spawn_cycle()

/obj/structure/necromantic_monolith/Destroy()
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
	collapse_necromonolith_minions()
	target_throne = null
	cached_routes = null
	active_minions = null
	return ..()

/obj/structure/necromantic_monolith/examine(mob/user)
	. = ..()
	if(length(cached_routes))
		. += span_notice("It currently holds [length(cached_routes)] cached route[length(cached_routes) == 1 ? "" : "s"] to the throne.")
	if(target_throne && !QDELETED(target_throne))
		. += span_notice("Its necromantic pull is fixed toward [target_throne].")

/obj/structure/necromantic_monolith/proc/queue_next_spawn_cycle()
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(process_spawn_cycle)), NECROMONOLITH_SPAWN_INTERVAL, TIMER_STOPPABLE)

/obj/structure/necromantic_monolith/proc/process_spawn_cycle()
	spawn_timer_id = null
	if(QDELETED(src))
		return
	cleanup_necromonolith_minions()
	if(refresh_necromonolith_routes())
		spawn_necromonolith_wave()
	else
		log_necromonolith_debug("spawn cycle aborted, no valid throne route from monolith=[necromonolith_debug_coords(src)]")
	queue_next_spawn_cycle()

/obj/structure/necromantic_monolith/proc/refresh_necromonolith_routes()
	if(target_throne && !QDELETED(target_throne) && length(cached_routes))
		return TRUE

	var/mob/living/caster = owner_ref?.resolve()
	var/list/setup = prepare_necromonolith_routes(get_turf(src), caster)
	if(!setup)
		return FALSE

	target_throne = setup["throne"]
	cached_routes = normalize_necromonolith_routes(setup["routes"], get_turf(src))
	next_route_pick = 1
	log_necromonolith_debug("refreshed routes monolith=[necromonolith_debug_coords(src)] throne=[necromonolith_debug_coords(target_throne)] routes=[describe_necromonolith_routes(cached_routes)]")
	return length(cached_routes) > 0

/obj/structure/necromantic_monolith/proc/take_next_necromonolith_route_slot()
	if(!length(cached_routes))
		return 0
	if(next_route_pick < 1 || next_route_pick > length(cached_routes))
		next_route_pick = 1
	. = next_route_pick
	next_route_pick++
	if(next_route_pick > length(cached_routes))
		next_route_pick = 1

/obj/structure/necromantic_monolith/proc/spawn_necromonolith_wave()
	var/current_minions = cleanup_necromonolith_minions()
	if(current_minions >= NECROMONOLITH_MAX_MINIONS)
		return
	if(!length(cached_routes))
		return

	var/mob/living/caster = owner_ref?.resolve()
	var/to_spawn = min(rand(NECROMONOLITH_MIN_SPAWN, NECROMONOLITH_MAX_SPAWN), NECROMONOLITH_MAX_MINIONS - current_minions)
	var/list/spawn_points = get_necromonolith_spawn_turfs(src)
	if(!length(spawn_points))
		return

	var/list/spawn_types = list(
		/mob/living/simple_animal/hostile/rogue/skeleton/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/axe/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/spear/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/guard/necromonolith,
		/mob/living/simple_animal/hostile/rogue/skeleton/bow/necromonolith,
	)

	var/list/available_points = spawn_points.Copy()
	for(var/i in 1 to to_spawn)
		if(!length(available_points))
			available_points = spawn_points.Copy()
		var/turf/spawn_turf = pick(available_points)
		available_points -= spawn_turf

		var/spawn_type = pick(spawn_types)
		var/mob/living/simple_animal/hostile/rogue/skeleton/new_minion = new spawn_type(spawn_turf, caster, TRUE, FALSE)
		if(QDELETED(new_minion))
			continue

		new /obj/effect/temp_visual/bluespace_fissure(spawn_turf)
		apply_necromonolith_owner_data(new_minion)
		var/route_slot = take_next_necromonolith_route_slot()
		new_minion.configure_necromonolith(src, cached_routes[route_slot], route_slot)
		log_necromonolith_debug("spawned [new_minion.type] at [necromonolith_debug_coords(new_minion)] route_slot=[route_slot] route=[describe_necromonolith_route(cached_routes[route_slot])]")
		active_minions += WEAKREF(new_minion)

/obj/structure/necromantic_monolith/proc/apply_necromonolith_owner_data(mob/living/simple_animal/hostile/rogue/skeleton/minion)
	if(!minion)
		return
	if(owner_name)
		minion.summoner = owner_name
	if(owner_faction_tag)
		minion.faction |= owner_faction_tag

/obj/structure/necromantic_monolith/proc/cleanup_necromonolith_minions()
	var/list/valid_minions = list()
	for(var/datum/weakref/minion_ref as anything in active_minions)
		var/mob/living/simple_animal/hostile/rogue/skeleton/minion = minion_ref.resolve()
		if(!minion || QDELETED(minion) || minion.stat == DEAD)
			continue
		valid_minions += minion_ref
	active_minions = valid_minions
	return length(active_minions)

/obj/structure/necromantic_monolith/proc/collapse_necromonolith_minions()
	for(var/datum/weakref/minion_ref as anything in active_minions)
		var/mob/living/simple_animal/hostile/rogue/skeleton/minion = minion_ref.resolve()
		if(!minion || QDELETED(minion))
			continue
		minion.visible_message(span_danger("[minion] collapses into lifeless bone as the monolith breaks."))
		qdel(minion)

/datum/ai_controller/necromonolith_skeleton
	movement_delay = SKELETON_MOVEMENT_SPEED
	ai_movement = /datum/ai_movement/hybrid_pathing
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/necromonolith()
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/ai_planning_subtree/travel_to_point/and_clear_target,
	)
	idle_behavior = /datum/idle_behavior/nothing
	can_idle = FALSE

/datum/ai_controller/necromonolith_skeleton_spear
	movement_delay = SKELETON_MOVEMENT_SPEED
	ai_movement = /datum/ai_movement/hybrid_pathing
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/necromonolith()
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/ai_planning_subtree/travel_to_point/and_clear_target,
		/datum/ai_planning_subtree/spacing/melee,
	)
	idle_behavior = /datum/idle_behavior/nothing
	can_idle = FALSE

/datum/ai_controller/necromonolith_skeleton_ranged
	movement_delay = SKELETON_MOVEMENT_SPEED * 1.2
	ai_movement = /datum/ai_movement/hybrid_pathing
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/necromonolith()
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/basic_ranged_attack_subtree,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/travel_to_point/and_clear_target,
		/datum/ai_planning_subtree/spacing/ranged,
	)
	idle_behavior = /datum/idle_behavior/nothing
	can_idle = FALSE

/datum/targetting_datum/basic/necromonolith/can_attack(mob/living/living_mob, atom/the_target)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/rogue/skeleton/skeleton = living_mob
	if(!istype(skeleton))
		return TRUE
	return skeleton.can_necromonolith_engage(the_target)

/mob/living/simple_animal/hostile/rogue/skeleton
	var/is_necromonolith_minion = FALSE
	var/list/necromonolith_route
	var/necromonolith_route_index = 1
	var/turf/necromonolith_goal
	var/necromonolith_rest_until = 0
	var/necromonolith_next_rest_time = 0
	var/datum/weakref/necromonolith_ref
	var/datum/weakref/necromonolith_chase_ref
	var/necromonolith_chase_started_at = 0
	var/necromonolith_reengage_after = 0
	var/necromonolith_route_slot = 1

/mob/living/simple_animal/hostile/rogue/skeleton/Life(mob/user)
	. = ..()
	if(!target)
		if(prob(60))
			emote(pick("idle"), TRUE)
	if(start_take_damage == TRUE)
		if(world.time > damage_check + 5 SECONDS)
			src.adjustFireLoss(8)
	if(is_necromonolith_minion)
		handle_necromonolith_behavior()

/mob/living/simple_animal/hostile/rogue/skeleton/Destroy()
	if(is_necromonolith_minion)
		unregister_from_necromonolith()
	return ..()

/mob/living/simple_animal/hostile/rogue/skeleton/proc/configure_necromonolith(obj/structure/necromantic_monolith/monolith, list/route, route_slot = 1)
	if(!ai_controller)
		InitializeAIController()
	is_necromonolith_minion = TRUE
	necromonolith_ref = WEAKREF(monolith)
	necromonolith_route = sanitize_necromonolith_route(route, get_turf(src))
	necromonolith_goal = length(necromonolith_route) ? necromonolith_route[length(necromonolith_route)] : null
	necromonolith_route_index = 1
	necromonolith_rest_until = 0
	necromonolith_next_rest_time = world.time + NECROMONOLITH_REST_INTERVAL
	necromonolith_chase_ref = null
	necromonolith_chase_started_at = 0
	necromonolith_reengage_after = 0
	necromonolith_route_slot = route_slot
	loot = list()
	remains_type = null
	wander = FALSE
	QDEL_IN(src, NECROMONOLITH_MINION_LIFETIME)
	ai_controller.CancelActions()
	ai_controller.clear_blackboard_key(BB_FOLLOW_TARGET)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
	log_necromonolith_debug("configured [src.type] at [necromonolith_debug_coords(src)] route_slot=[route_slot] goal=[necromonolith_debug_coords(necromonolith_goal)] route=[describe_necromonolith_route(necromonolith_route)]")

/mob/living/simple_animal/hostile/rogue/skeleton/proc/can_necromonolith_engage(atom/the_target)
	if(!is_necromonolith_minion)
		return TRUE
	if(necromonolith_rest_until && world.time < necromonolith_rest_until)
		return FALSE
	if(necromonolith_reengage_after && world.time < necromonolith_reengage_after)
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/rogue/skeleton/proc/clear_necromonolith_chase_state()
	necromonolith_chase_ref = null
	necromonolith_chase_started_at = 0

/mob/living/simple_animal/hostile/rogue/skeleton/proc/force_necromonolith_return_to_route(reason)
	if(ai_controller)
		ai_controller.CancelActions()
		ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
		ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
		ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
	LoseTarget()
	clear_necromonolith_chase_state()
	log_necromonolith_debug("[src.type] at [necromonolith_debug_coords(src)] forced back to route ([reason]); next waypoint index=[necromonolith_route_index]")

/mob/living/simple_animal/hostile/rogue/skeleton/proc/handle_necromonolith_chase(atom/current_target)
	if(!current_target || QDELETED(current_target))
		force_necromonolith_return_to_route("invalid target")
		return
	if(necromonolith_reengage_after && world.time < necromonolith_reengage_after)
		force_necromonolith_return_to_route("reengage cooldown")
		return

	var/atom/tracked_target = necromonolith_chase_ref?.resolve()
	if(current_target != tracked_target)
		necromonolith_chase_ref = WEAKREF(current_target)
		necromonolith_chase_started_at = world.time
		log_necromonolith_debug("[src.type] at [necromonolith_debug_coords(src)] acquired chase target=[necromonolith_debug_coords(current_target)] route_slot=[necromonolith_route_slot]")
		return

	if(!necromonolith_chase_started_at)
		necromonolith_chase_started_at = world.time
		return

	if(world.time < necromonolith_chase_started_at + NECROMONOLITH_CHASE_TIMEOUT)
		return

	necromonolith_reengage_after = world.time + NECROMONOLITH_REENGAGE_COOLDOWN
	force_necromonolith_return_to_route("chase timeout vs [necromonolith_debug_coords(current_target)]")

/mob/living/simple_animal/hostile/rogue/skeleton/proc/handle_necromonolith_behavior()
	if(stat == DEAD || QDELETED(src) || !ai_controller?.blackboard)
		return

	var/atom/current_target = ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(current_target)
		handle_necromonolith_chase(current_target)
		return

	clear_necromonolith_chase_state()

	if(necromonolith_rest_until && world.time >= necromonolith_rest_until)
		log_necromonolith_debug("[src.type] at [necromonolith_debug_coords(src)] finished rest and resumes route_slot=[necromonolith_route_slot]")
		necromonolith_rest_until = 0

	if(!necromonolith_rest_until && world.time >= necromonolith_next_rest_time && necromonolith_goal)
		necromonolith_rest_until = world.time + NECROMONOLITH_REST_DURATION
		necromonolith_next_rest_time = world.time + NECROMONOLITH_REST_INTERVAL + NECROMONOLITH_REST_DURATION
		force_necromonolith_return_to_route("scheduled rest")
		return

	if(necromonolith_rest_until)
		return

	while(necromonolith_route_index <= length(necromonolith_route))
		var/turf/next_turf = necromonolith_route[necromonolith_route_index]
		if(!next_turf || QDELETED(next_turf))
			necromonolith_route_index++
			continue
		if(get_turf(src) == next_turf)
			necromonolith_route_index++
			continue
		var/turf/current_destination = ai_controller.blackboard[BB_TRAVEL_DESTINATION]
		if(current_destination == next_turf)
			return
		ai_controller.set_blackboard_key(BB_TRAVEL_DESTINATION, next_turf)
		return

	if(necromonolith_goal && get_turf(src) != necromonolith_goal)
		if(ai_controller.blackboard[BB_TRAVEL_DESTINATION] != necromonolith_goal)
			ai_controller.set_blackboard_key(BB_TRAVEL_DESTINATION, necromonolith_goal)

/mob/living/simple_animal/hostile/rogue/skeleton/proc/unregister_from_necromonolith()
	var/obj/structure/necromantic_monolith/monolith = necromonolith_ref?.resolve()
	if(!monolith || !length(monolith.active_minions))
		return
	for(var/datum/weakref/minion_ref as anything in monolith.active_minions)
		if(minion_ref.resolve() != src)
			continue
		monolith.active_minions -= minion_ref
		break

/mob/living/simple_animal/hostile/rogue/skeleton/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton

/mob/living/simple_animal/hostile/rogue/skeleton/axe/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton

/mob/living/simple_animal/hostile/rogue/skeleton/spear/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton_spear

/mob/living/simple_animal/hostile/rogue/skeleton/guard/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton

/mob/living/simple_animal/hostile/rogue/skeleton/bow/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton_ranged

/datum/outfit/job/roguetown/wretch/necromancer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly || !H?.mind)
		return
	if(!H.mind.has_spell(/obj/effect/proc_holder/spell/invoked/necromantic_monolith))
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/necromantic_monolith)

/datum/outfit/job/roguetown/lich/post_equip(mob/living/carbon/human/H)
	..()
	var/datum/antagonist/lich/lichman = H.mind.has_antag_datum(/datum/antagonist/lich)
	var/obj/item/phylactery/new_phylactery = new(H.loc)
	lichman.phylacteries += new_phylactery
	new_phylactery.possessor = lichman
	H.equip_to_slot_or_del(new_phylactery, SLOT_IN_BACKPACK, TRUE)
	if(!H.mind.has_spell(/obj/effect/proc_holder/spell/invoked/necromantic_monolith))
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/necromantic_monolith)

/proc/can_place_necromonolith_on(turf/target_turf, mob/living/user)
	if(!target_turf || !isopenturf(target_turf))
		return "The monolith needs open ground."
	if(!target_turf.can_traverse_safely(user))
		return "That ground rejects the rite."
	if(locate(/obj/structure/necromantic_monolith) in target_turf)
		return "A monolith is already rooted there."
	for(var/atom/movable/blocker in target_turf)
		if(blocker == user)
			continue
		if(blocker.density)
			return "Something blocks the monolith from taking shape there."
	return null

/proc/prepare_necromonolith_routes(turf/origin, mob/living/caster)
	var/list/candidate_thrones = rank_necromonolith_candidate_thrones(origin)
	if(!length(candidate_thrones))
		log_necromonolith_debug("no throne candidates found from origin=[necromonolith_debug_coords(origin)]")
		return null

	for(var/atom/movable/target_throne as anything in candidate_thrones)
		var/list/goal_turfs = get_necromonolith_goal_turfs(target_throne)
		if(!length(goal_turfs))
			continue

		var/list/routes = calculate_necromonolith_routes(origin, goal_turfs)
		if(!length(routes))
			continue

		log_necromonolith_debug("route prep origin=[necromonolith_debug_coords(origin)] throne=[necromonolith_debug_coords(target_throne)] routes=[describe_necromonolith_routes(routes)]")
		return list(
			"throne" = target_throne,
			"routes" = routes,
		)

	log_necromonolith_debug("failed to prepare routes from origin=[necromonolith_debug_coords(origin)] across [length(candidate_thrones)] throne candidates")
	return null

/proc/find_necromonolith_target_throne(turf/reference_turf)
	var/list/candidate_thrones = rank_necromonolith_candidate_thrones(reference_turf)
	if(length(candidate_thrones))
		return candidate_thrones[1]
	return null

/proc/rank_necromonolith_candidate_thrones(turf/reference_turf)
	var/obj/structure/roguethrone/king_throne = GLOB.king_throne
	var/mob/living/ruler = SSticker.rulermob
	var/area/ruler_area = get_area(ruler)
	var/list/scored_thrones = list()

	for(var/obj/structure/roguethrone/throne in world)
		if(QDELETED(throne))
			continue
		var/base_score = (throne == king_throne) ? 200000 : 100000
		scored_thrones[throne] = score_necromonolith_throne(throne, reference_turf, ruler, ruler_area, base_score)

	for(var/obj/structure/chair/wood/rogue/throne/throne_chair in world)
		if(QDELETED(throne_chair))
			continue
		var/base_score = (throne_chair == king_throne) ? 2000 : 1000
		scored_thrones[throne_chair] = score_necromonolith_throne(throne_chair, reference_turf, ruler, ruler_area, base_score)

	var/list/ranked_thrones = list()
	while(length(scored_thrones))
		var/atom/movable/best_throne
		var/best_score = -1.0e31
		for(var/atom/movable/throne as anything in scored_thrones)
			var/score = scored_thrones[throne]
			if(score <= best_score)
				continue
			best_score = score
			best_throne = throne
		if(!best_throne)
			break
		ranked_thrones += best_throne
		scored_thrones -= best_throne
	return ranked_thrones

/proc/score_necromonolith_throne(atom/movable/throne, turf/reference_turf, mob/living/ruler, area/ruler_area, base_score)
	var/score = base_score
	if(ruler)
		if(throne.z == ruler.z)
			score += 250
		score -= get_dist(ruler, throne)
	if(ruler_area && get_area(throne) == ruler_area)
		score += 1500
	if(reference_turf)
		if(throne.z == reference_turf.z)
			score += 50
		score -= (get_dist(reference_turf, throne) * 0.1)
	return score

/proc/get_necromonolith_goal_turfs(atom/movable/throne)
	var/list/goal_turfs = list()
	var/turf/throne_turf = get_turf(throne)
	if(!throne_turf)
		return goal_turfs

	if(is_necromonolith_turf_clear(throne_turf))
		goal_turfs += throne_turf

	for(var/turf/candidate in orange(1, throne_turf))
		if(candidate.z != throne_turf.z)
			continue
		if(!is_necromonolith_turf_clear(candidate))
			continue
		goal_turfs += candidate

	return goal_turfs

/proc/calculate_necromonolith_routes(turf/origin, list/goal_turfs)
	var/list/routes = list()
	var/list/primary_route = select_best_necromonolith_route(origin, goal_turfs)
	if(!length(primary_route))
		return routes

	routes += list(primary_route)
	var/list/goal_routes = collect_necromonolith_goal_routes(origin, goal_turfs)
	for(var/list/goal_route as anything in goal_routes)
		if(necromonolith_route_exists(goal_route, routes))
			continue
		routes += list(goal_route)
		if(length(routes) >= NECROMONOLITH_DESIRED_ROUTES)
			return routes

	var/list/seed_routes = list(primary_route)
	var/list/fractions = list(0.15, 0.3, 0.45, 0.6, 0.75, 0.9)

	var/seed_index = 1
	while(length(routes) < NECROMONOLITH_DESIRED_ROUTES && seed_index <= length(seed_routes))
		var/list/seed_route = seed_routes[seed_index]
		for(var/fraction in fractions)
			var/turf/exclusion = pick_necromonolith_exclusion(seed_route, fraction)
			if(!exclusion)
				continue
			var/list/alternate_route = select_best_necromonolith_route(origin, goal_turfs, exclusion)
			if(!length(alternate_route) || necromonolith_route_exists(alternate_route, routes))
				continue
			routes += list(alternate_route)
			seed_routes += list(alternate_route)
			if(length(routes) >= NECROMONOLITH_DESIRED_ROUTES)
				break
		seed_index++

	while(length(routes) < NECROMONOLITH_DESIRED_ROUTES)
		routes += list(primary_route.Copy())

	return routes

/proc/collect_necromonolith_goal_routes(turf/origin, list/goal_turfs)
	var/list/routes = list()
	for(var/turf/goal_turf as anything in goal_turfs)
		if(!goal_turf)
			continue
		var/list/path = get_path_to(origin, goal_turf, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d), 0, NECROMONOLITH_ROUTE_DEPTH, 0, adjacent = TYPE_PROC_REF(/turf, reachableTurftest3d))
		if(!length(path) || necromonolith_route_exists(path, routes))
			continue
		routes += list(path)
	return routes

/proc/select_best_necromonolith_route(turf/origin, list/goal_turfs, turf/exclusion)
	var/list/best_route = list()
	for(var/turf/goal_turf as anything in goal_turfs)
		if(!goal_turf)
			continue
		var/list/path = get_path_to(origin, goal_turf, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d), 0, NECROMONOLITH_ROUTE_DEPTH, 0, adjacent = TYPE_PROC_REF(/turf, reachableTurftest3d), exclude = exclusion)
		if(!length(path))
			continue
		if(!length(best_route) || length(path) < length(best_route))
			best_route = path
	return best_route

/proc/pick_necromonolith_exclusion(list/route, fraction)
	if(length(route) < 6)
		return null
	var/index = clamp(round(length(route) * fraction), 2, length(route) - 1)
	return route[index]

/proc/necromonolith_route_exists(list/candidate_route, list/routes)
	for(var/list/existing_route as anything in routes)
		if(necromonolith_routes_match(candidate_route, existing_route))
			return TRUE
	return FALSE

/proc/necromonolith_routes_match(list/left_route, list/right_route)
	if(length(left_route) != length(right_route))
		return FALSE
	for(var/i in 1 to length(left_route))
		if(left_route[i] != right_route[i])
			return FALSE
	return TRUE

/proc/normalize_necromonolith_routes(list/routes, turf/origin)
	var/list/normalized = list()
	for(var/list/route as anything in routes)
		var/list/clean_route = sanitize_necromonolith_route(route, origin)
		if(!length(clean_route))
			continue
		if(necromonolith_route_exists(clean_route, normalized))
			continue
		normalized += list(clean_route)
	return normalized

/proc/sanitize_necromonolith_route(list/route, turf/origin)
	var/list/clean_route = list()
	for(var/turf/step as anything in route)
		if(!step || QDELETED(step))
			continue
		if(!length(clean_route) && origin && step == origin)
			continue
		clean_route += step
	return clean_route

/proc/get_necromonolith_spawn_turfs(atom/source)
	var/list/spawn_turfs = list()
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return spawn_turfs

	if(is_necromonolith_turf_clear(source_turf, source))
		spawn_turfs += source_turf
	for(var/turf/candidate in orange(1, source_turf))
		if(!is_necromonolith_turf_clear(candidate))
			continue
		spawn_turfs += candidate
	return spawn_turfs

/proc/is_necromonolith_turf_clear(turf/target_turf, atom/ignore)
	if(!target_turf || !isopenturf(target_turf))
		return FALSE
	for(var/atom/movable/blocker in target_turf)
		if(blocker == ignore)
			continue
		if(blocker.density)
			return FALSE
	return TRUE

#undef NECROMONOLITH_BUILD_TIME
#undef NECROMONOLITH_SPAWN_INTERVAL
#undef NECROMONOLITH_MIN_SPAWN
#undef NECROMONOLITH_MAX_SPAWN
#undef NECROMONOLITH_DESIRED_ROUTES
#undef NECROMONOLITH_ROUTE_DEPTH
#undef NECROMONOLITH_REST_INTERVAL
#undef NECROMONOLITH_REST_DURATION
#undef NECROMONOLITH_MAX_MINIONS
#undef NECROMONOLITH_MINION_LIFETIME
#undef NECROMONOLITH_CHASE_TIMEOUT
#undef NECROMONOLITH_REENGAGE_COOLDOWN
#undef NECROMONOLITH_DEBUG
