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
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_destroying))

/datum/component/necromonolith_minion/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_LIFE, COMSIG_PARENT_QDELETING))

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

// ---- AI controllers ----

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
	var/datum/component/necromonolith_minion/comp = living_mob.GetComponent(/datum/component/necromonolith_minion)
	if(!comp)
		return TRUE
	var/obj/structure/necromantic_monolith/monolith = comp.monolith_ref?.resolve()
	if(!monolith || QDELETED(monolith))
		return TRUE
	return monolith.can_minion_engage(living_mob, the_target)

// ---- Skeleton subtypes ----

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
