/mob/living/carbon/human/npc/ataman_bandit
	name = "bandit"
	real_name = "bandit"
	ai_controller = /datum/ai_controller/human_npc/ataman_bandit
	faction = list(FACTION_BANDITS)
	ambushable = FALSE

	var/datum/weakref/ataman_owner_ref
	var/datum/weakref/ataman_target_ref
	var/turf/ataman_spawn_turf
	var/ataman_role = ATAMAN_ROLE_ENFORCER
	var/datum/ataman_squad/ataman_squad
	var/ataman_gave_up = FALSE
	var/ataman_disbanding = FALSE

/mob/living/carbon/human/npc/ataman_bandit/Initialize(mapload)
	. = ..()
	set_species(pick(NPC_RACES_TYPES))
	gender = pick(MALE, FEMALE)
	dna.species.random_character(src)
	addtimer(CALLBACK(src, PROC_REF(finish_bandit_setup)), 1 SECONDS)

/mob/living/carbon/human/npc/ataman_bandit/proc/finish_bandit_setup()
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NPC_EXAMINE, TRAIT_GENERIC)
	equipOutfit(new /datum/outfit/job/roguetown/human/species/human/northern/highwayman)
	ataman_apply_bandit_gear(src, ataman_squad?.gear_tier || 1)
	ataman_ai_log(src, "gear applied at tier [ataman_squad?.gear_tier || 1]")
	dna.species.handle_body(src)
	random_voice_NPC()
	random_hair_NPC()
	random_eye_color_NPC()
	correct_features_NPC()
	if(gender == FEMALE)
		real_name = pick(world.file2list("strings/names/first_female.txt"))
	else
		real_name = pick(world.file2list("strings/names/first_male.txt"))
	name = real_name

/mob/living/carbon/human/npc/ataman_bandit/proc/set_ataman(mob/living/carbon/human/owner, turf/spawn_turf, mob/living/target, role = ATAMAN_ROLE_ENFORCER, datum/ataman_squad/squad)
	ataman_spawn_turf = spawn_turf || get_turf(src)
	ataman_role = role
	ataman_squad = squad
	if(role == ATAMAN_ROLE_GRABBER)
		upgrade_ai_controller(/datum/ai_controller/human_npc/ataman_bandit/grabber)
	if(target)
		ataman_target_ref = WEAKREF(target)
	if(ai_controller)
		ai_controller.set_blackboard_key(BB_ATAMAN_SPAWN_TURF, ataman_spawn_turf)
		ai_controller.set_blackboard_key(BB_ATAMAN_OWNER, owner)
		ai_controller.set_blackboard_key(BB_ATAMAN_TARGET, target)
		ai_controller.set_blackboard_key(BB_ATAMAN_ROLE, ataman_role)
		ai_controller.set_blackboard_key(BB_ATAMAN_SQUAD, squad)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		ai_controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, target)
	ataman_ai_log(src, "spawned: role=[role] target=[target] spawn_turf=[ataman_spawn_turf] squad=[squad ? "#[REF(squad)]" : "none"]")
	if(!owner)
		return
	ataman_owner_ref = WEAKREF(owner)
	summoner = owner.real_name
	faction += "[owner.real_name]_ataman_gang"
	apply_mob_lifespan(src, owner, 5 MINUTES)

/proc/ataman_target_is_secured(atom/target)
	var/mob/living/carbon/C = target
	return istype(C) && C.handcuffed

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
		BB_HUMAN_NPC_FEINT_COOLDOWN = INFINITY,

		BB_ATAMAN_SPAWN_TURF = null,
		BB_ATAMAN_OWNER = null,
		BB_ATAMAN_TARGET = null,
		BB_ATAMAN_ROLE = ATAMAN_ROLE_ENFORCER,
		BB_ATAMAN_SQUAD = null,
		BB_ATAMAN_INTERCEPT_TURF = null,
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
		/datum/ai_planning_subtree/ataman_intercept,
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
	if(target == blackboard[BB_ATAMAN_OWNER] || target != blackboard[BB_ATAMAN_TARGET] || target.stat != CONSCIOUS || ataman_target_is_secured(target))
		return COMPONENT_ITEM_NO_ATTACK
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/victim = target
	var/mob/living/carbon/human/attacker = pawn
	var/zone = check_zone(attacker.zone_selected)
	if(zone == BODY_ZONE_CHEST && ataman_chest_broken(victim))
		return COMPONENT_ITEM_NO_ATTACK
	if(!ataman_weapon_is_blunt(weapon) && (zone == BODY_ZONE_HEAD || !ataman_zone_is_armored(victim, zone)))
		return COMPONENT_ITEM_NO_ATTACK

/datum/ai_controller/human_npc/ataman_bandit/proc/cancel_invalid_unarmed_attack(mob/living/source, atom/target, proximity)
	SIGNAL_HANDLER
	if(source != pawn)
		return
	var/mob/living/living_target = target
	if(target == blackboard[BB_ATAMAN_OWNER] || target != blackboard[BB_ATAMAN_TARGET] || !istype(living_target) || living_target.stat != CONSCIOUS || ataman_target_is_secured(target))
		return COMPONENT_NO_ATTACK_HAND

/datum/ai_controller/human_npc/ataman_bandit/grabber
	planning_subtrees = list(
		/datum/ai_planning_subtree/generic_break_restraints,
		/datum/ai_planning_subtree/use_powder,
		/datum/ai_planning_subtree/use_bandage,
		/datum/ai_planning_subtree/use_healing_drink,
		/datum/ai_planning_subtree/generic_resist,
		/datum/ai_planning_subtree/generic_stand,
		/datum/ai_planning_subtree/tree_climb,
		/datum/ai_planning_subtree/ataman_leash,
		/datum/ai_planning_subtree/ataman_squad_tactics,
		/datum/ai_planning_subtree/ataman_disarm_restrain,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/human_npc,
	)
