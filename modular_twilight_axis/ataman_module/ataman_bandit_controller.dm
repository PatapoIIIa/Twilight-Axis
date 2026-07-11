/proc/ataman_target_is_secured(atom/target)
	var/mob/living/carbon/C = target
	return istype(C) && (C.handcuffed || C.legcuffed)

/datum/targetting_datum/basic/ataman_bandit/can_attack(mob/living/living_mob, atom/the_target)
	var/datum/ai_controller/controller = living_mob.ai_controller
	if(!controller || the_target != controller.blackboard[BB_ATAMAN_TARGET])
		return FALSE
	if(the_target == controller.blackboard[BB_ATAMAN_OWNER] || ataman_target_is_secured(the_target))
		return FALSE
	return ..()

/datum/targetting_datum/basic/ataman_bandit/faction_check(mob/living/living_mob, mob/living/the_target)
	return FALSE

/datum/ai_controller/human_npc/ataman_bandit
	blackboard = list(
		BB_WEAPON_TYPE = /obj/item/rogueweapon,
		BB_ARMOR_CLASS = 2,
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/ataman_bandit(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/ataman_bandit(),

		BB_HUMAN_NPC_ATTACK_ZONE_COUNTER = 0,
		BB_HUMAN_NPC_LAST_ATTACK_ZONE = null,
		BB_HUMAN_NPC_WEAKPOINT = null,
		BB_HUMAN_NPC_JUMP_COOLDOWN = 0,
		BB_HUMAN_NPC_FLANK_ANGLE = null,
		BB_HUMAN_NPC_FLANK_TARGET = null,
		BB_HUMAN_NPC_HARASS_MODE = FALSE,
		BB_HUMAN_NPC_HARASS_RETREATING = FALSE,
		BB_HUMAN_NPC_HARASS_COOLDOWN = 0,
		BB_HUMAN_NPC_JUKE_COOLDOWN = 0,
		BB_HUMAN_NPC_FEINT_COOLDOWN = INFINITY, // the squad, not the base combat AI, decides when this bandit feints

		BB_ATAMAN_SPAWN_TURF = null,
		BB_ATAMAN_OWNER = null,
		BB_ATAMAN_TARGET = null,
		BB_ATAMAN_ROLE = ATAMAN_ROLE_ENFORCER,
		BB_ATAMAN_SQUAD = null,
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/generic_break_restraints,
		/datum/ai_planning_subtree/use_powder,
		/datum/ai_planning_subtree/use_bandage,
		/datum/ai_planning_subtree/use_healing_drink,
		/datum/ai_planning_subtree/generic_resist,
		/datum/ai_planning_subtree/generic_stand,
		/datum/ai_planning_subtree/tree_climb,
		/datum/ai_planning_subtree/ataman_leash,
		/datum/ai_planning_subtree/squad_flank,
		/datum/ai_planning_subtree/ataman_squad_tactics,
		/datum/ai_planning_subtree/ataman_disarm_restrain,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/human_npc,
	)

/datum/ai_controller/human_npc/ataman_bandit/TryPossessPawn(atom/new_pawn)
	. = ..()
	RegisterSignal(new_pawn, COMSIG_MOB_ITEM_ATTACK_POST_SWINGDELAY, PROC_REF(cancel_invalid_item_attack))
	RegisterSignal(new_pawn, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(cancel_invalid_unarmed_attack))

/datum/ai_controller/human_npc/ataman_bandit/UnpossessPawn(destroy)
	UnregisterSignal(pawn, list(COMSIG_MOB_ITEM_ATTACK_POST_SWINGDELAY, COMSIG_HUMAN_EARLY_UNARMED_ATTACK))
	return ..()

/datum/ai_controller/human_npc/ataman_bandit/proc/cancel_invalid_item_attack(mob/living/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(user != pawn)
		return
	if(target == blackboard[BB_ATAMAN_OWNER] || target != blackboard[BB_ATAMAN_TARGET] || target.stat == DEAD || ataman_target_is_secured(target))
		return COMPONENT_ITEM_NO_ATTACK

/datum/ai_controller/human_npc/ataman_bandit/proc/cancel_invalid_unarmed_attack(mob/living/source, atom/target, proximity)
	SIGNAL_HANDLER
	if(source != pawn)
		return
	var/mob/living/living_target = target
	if(target == blackboard[BB_ATAMAN_OWNER] || target != blackboard[BB_ATAMAN_TARGET] || !istype(living_target) || living_target.stat == DEAD || ataman_target_is_secured(target))
		return COMPONENT_NO_ATTACK_HAND
