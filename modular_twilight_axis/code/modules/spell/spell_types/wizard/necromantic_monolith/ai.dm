// ---- Necromantic Monolith: AI controllers, component & skeleton subtypes ----

// ---- Thin minion component (signal relay) ----

/datum/component/necromonolith_minion
	var/datum/weakref/monolith_ref
	var/datum/weakref/self_ref

/datum/component/necromonolith_minion/Initialize(obj/structure/necromantic_monolith/monolith)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/simple_animal/hostile/rogue/skeleton/skeleton = parent
	if(!istype(skeleton))
		return COMPONENT_INCOMPATIBLE
	monolith_ref = WEAKREF(monolith)
	self_ref = WEAKREF(skeleton)

/datum/component/necromonolith_minion/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_destroying))

/datum/component/necromonolith_minion/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_LIFE, COMSIG_ATOM_WAS_ATTACKED, COMSIG_PARENT_QDELETING))

/datum/component/necromonolith_minion/Destroy()
	var/obj/structure/necromantic_monolith/monolith = monolith_ref?.resolve()
	if(monolith && !QDELETED(monolith))
		monolith.unregister_minion(parent)
	monolith_ref = null
	self_ref = null
	return ..()

/datum/component/necromonolith_minion/proc/on_parent_destroying(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/necromonolith_minion/proc/on_life(datum/source)
	SIGNAL_HANDLER
	var/obj/structure/necromantic_monolith/monolith = monolith_ref?.resolve()
	if(!monolith || QDELETED(monolith))
		return
	monolith.direct_minion(parent, self_ref)

/datum/component/necromonolith_minion/proc/on_attacked(mob/living/source, atom/attacker, damage)
	SIGNAL_HANDLER
	var/obj/structure/necromantic_monolith/monolith = monolith_ref?.resolve()
	if(!monolith || QDELETED(monolith))
		return
	var/mob/living/simple_animal/hostile/rogue/skeleton/skeleton = source
	if(!istype(skeleton))
		return
	monolith.on_minion_attacked(skeleton, self_ref, attacker)

// ---- Route obstacle handling ----

/proc/get_necromonolith_obstacle_whitelist()
	var/static/list/obstacle_whitelist = typecacheof(list(
		/obj/structure/bars,
		/obj/structure/fence,
		/obj/structure/mineral_door/bars,
		/obj/structure/roguewindow,
	))
	return obstacle_whitelist

/datum/ai_planning_subtree/attack_obstacle_in_path/necromonolith_route
	target_key = BB_TRAVEL_DESTINATION
	attack_behaviour = /datum/ai_behavior/attack_obstructions/necromonolith

/datum/ai_planning_subtree/attack_obstacle_in_path/necromonolith_route/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET])
		return
	return ..()

/datum/ai_behavior/attack_obstructions/necromonolith
	can_attack_dense_objects = TRUE

/datum/ai_planning_subtree/simple_find_target/necromonolith

/datum/ai_planning_subtree/simple_find_target/necromonolith/SelectBehaviors(datum/ai_controller/controller, delta_time)
	controller.queue_behavior(/datum/ai_behavior/find_potential_targets/nearest/necromonolith, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)

/datum/ai_behavior/find_potential_targets/nearest/necromonolith
	action_cooldown = 0.5 SECONDS
	vision_range = NECROMONOLITH_AGGRO_RANGE

// ---- AI controllers ----

/datum/ai_controller/necromonolith_skeleton
	movement_delay = SKELETON_MOVEMENT_SPEED
	ai_movement = /datum/ai_movement/hybrid_pathing
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/necromonolith()
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target/necromonolith,
		/datum/ai_planning_subtree/attack_obstacle_in_path/necromonolith_route,
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
		/datum/ai_planning_subtree/simple_find_target/necromonolith,
		/datum/ai_planning_subtree/attack_obstacle_in_path/necromonolith_route,
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
		/datum/ai_planning_subtree/simple_find_target/necromonolith,
		/datum/ai_planning_subtree/attack_obstacle_in_path/necromonolith_route,
		/datum/ai_planning_subtree/travel_to_point/and_clear_target,
		/datum/ai_planning_subtree/spacing/ranged,
	)
	idle_behavior = /datum/idle_behavior/nothing
	can_idle = FALSE

/datum/targetting_datum/basic/necromonolith/can_attack(mob/living/living_mob, atom/the_target)
	. = ..()
	if(!.)
		return FALSE
	if(!ismob(the_target))
		return FALSE
	var/mob/target_mob = the_target
	if(!target_mob.client)
		return FALSE
	var/datum/component/necromonolith_minion/comp = living_mob.GetComponent(/datum/component/necromonolith_minion)
	if(!comp)
		return TRUE
	var/obj/structure/necromantic_monolith/monolith = comp.monolith_ref?.resolve()
	if(!monolith || QDELETED(monolith))
		return TRUE
	return monolith.can_minion_engage(comp.self_ref, the_target)

// ---- Skeleton subtypes ----

/mob/living/simple_animal/hostile/rogue/skeleton/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton
	vision_range = NECROMONOLITH_AGGRO_RANGE
	aggro_vision_range = NECROMONOLITH_AGGRO_RANGE

/mob/living/simple_animal/hostile/rogue/skeleton/axe/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton
	vision_range = NECROMONOLITH_AGGRO_RANGE
	aggro_vision_range = NECROMONOLITH_AGGRO_RANGE

/mob/living/simple_animal/hostile/rogue/skeleton/spear/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton_spear
	vision_range = NECROMONOLITH_AGGRO_RANGE
	aggro_vision_range = NECROMONOLITH_AGGRO_RANGE

/mob/living/simple_animal/hostile/rogue/skeleton/guard/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton
	vision_range = NECROMONOLITH_AGGRO_RANGE
	aggro_vision_range = NECROMONOLITH_AGGRO_RANGE

/mob/living/simple_animal/hostile/rogue/skeleton/bow/necromonolith
	ai_controller = /datum/ai_controller/necromonolith_skeleton_ranged
	vision_range = NECROMONOLITH_AGGRO_RANGE
	aggro_vision_range = NECROMONOLITH_AGGRO_RANGE
