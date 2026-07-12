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
		BB_HUMAN_NPC_FEINT_COOLDOWN = INFINITY,

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

/proc/ataman_last_feint_landed(mob/living/target)
	if(!istype(target))
		return FALSE
	return target.has_status_effect(/datum/status_effect/debuff/vulnerable) || target.has_status_effect(/datum/status_effect/debuff/exposed)

/proc/ataman_target_mouth_secured(mob/living/carbon/target)
	if(!istype(target))
		return FALSE
	for(var/obj/item/grabbing/grab in target.grabbedby)
		if(grab.sublimb_grabbed == BODY_ZONE_PRECISE_MOUTH)
			return TRUE
	return FALSE

/proc/ataman_recover_target(datum/ai_controller/controller, mob/living/carbon/human/npc/ataman_bandit/pawn)
	if(!istype(pawn) || !controller)
		return
	if(istype(controller.blackboard[BB_ATAMAN_TARGET], /mob/living))
		return
	var/mob/living/restored = pawn.ataman_target_ref?.resolve()
	if(!istype(restored) || restored.stat == DEAD)
		return
	if(pawn.ataman_gave_up)
		var/turf/spawn_turf = controller.blackboard[BB_ATAMAN_SPAWN_TURF]
		if(!spawn_turf || get_dist(restored, spawn_turf) > ATAMAN_LEASH_RANGE)
			return
		pawn.ataman_gave_up = FALSE
	ataman_ai_log(pawn, "CAPTURE: lost track of [restored] on the blackboard, recovering")
	controller.set_blackboard_key(BB_ATAMAN_TARGET, restored)

/proc/ataman_weapon_is_blunt(obj/item/weapon)
	return !weapon || weapon.d_type == "blunt"

/proc/ataman_zone_is_armored(mob/living/carbon/human/target, zone)
	return target.getarmor(zone, "blunt") > 0

/proc/ataman_chest_broken(mob/living/carbon/human/target)
	return target.has_wound(/datum/wound/fracture/chest)

/proc/ataman_pick_capture_zone(mob/living/carbon/human/pawn, mob/living/carbon/human/target)
	var/list/limbs = shuffle(list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	if(ataman_weapon_is_blunt(pawn.get_active_held_item()))
		for(var/zone in limbs)
			if(!ataman_zone_is_armored(target, zone))
				return zone
		if(!ataman_chest_broken(target) && !ataman_zone_is_armored(target, BODY_ZONE_CHEST))
			return BODY_ZONE_CHEST
		return limbs[1]
	for(var/zone in limbs)
		if(ataman_zone_is_armored(target, zone))
			return zone
	if(!ataman_chest_broken(target) && ataman_zone_is_armored(target, BODY_ZONE_CHEST))
		return BODY_ZONE_CHEST
	return null

/proc/ataman_target_is_walled(mob/living/pawn, mob/living/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE
	var/turf/behind_target = get_step(target_turf, get_dir(pawn, target))
	if(!behind_target || behind_target.density)
		return TRUE
	for(var/obj/structure/S in behind_target)
		if(S.density)
			return TRUE
	for(var/mob/living/M in behind_target)
		if(M == pawn || M == target)
			continue
		return TRUE
	return FALSE

/proc/ataman_free_hands_for_grabbing(datum/ai_controller/controller)
	var/mob/living/carbon/human/pawn = controller?.pawn
	if(!istype(pawn))
		return FALSE
	var/obj/item/active = pawn.get_active_held_item()
	if(active?.wielded)
		active.ungrip(pawn)
	var/datum/component/ai_inventory_manager/inventory = controller.get_inventory()
	for(var/obj/item/held in list(pawn.get_active_held_item(), pawn.get_inactive_held_item()))
		if(!held || istype(held, /obj/item/grabbing))
			continue
		if(!inventory?.stow_item(held))
			pawn.dropItemToGround(held)
	return TRUE

/proc/ataman_get_grab_on(mob/living/carbon/human/pawn, mob/living/target, sublimb)
	for(var/obj/item/grabbing/grab in list(pawn.get_active_held_item(), pawn.get_inactive_held_item()))
		if(grab.grabbed == target && grab.sublimb_grabbed == sublimb)
			return grab
	return null

/proc/ataman_make_grab_active(mob/living/carbon/human/pawn, obj/item/grabbing/grab)
	if(pawn.get_active_held_item() == grab)
		return TRUE
	if(pawn.get_inactive_held_item() != grab)
		return FALSE
	pawn.swap_hand()
	return pawn.get_active_held_item() == grab

/proc/ataman_try_mouth_grab(datum/ai_controller/controller, mob/living/carbon/human/pawn, mob/living/carbon/target, datum/ataman_squad/squad)
	if(!squad || pawn.pulling == target || ataman_target_mouth_secured(target))
		return FALSE
	if(!get_location_accessible(target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!squad.claim_mouth_grab(target))
		return FALSE
	if(!ataman_free_hands_for_grabbing(controller))
		return FALSE
	pawn.zone_selected = BODY_ZONE_PRECISE_MOUTH
	if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_PRECISE_MOUTH))
		ataman_ai_log(pawn, "MOUTH: grab on [target] failed to start")
		return FALSE
	ataman_ai_log(pawn, "MOUTH: secured [target]'s mouth")
	return TRUE

/datum/ataman_squad
	var/datum/weakref/target_ref
	var/feints_used = 0
	var/last_feint_at = 0
	var/mouth_claim_until = 0
	var/guard_claimed_until = 0
	var/bites_used = 0
	var/gear_tier = 1
	var/datum/weakref/holder_ref
	var/owner_took_custody = FALSE

/datum/ataman_squad/proc/get_target()
	return target_ref?.resolve()

/datum/ataman_squad/proc/is_target_caster(mob/living/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/H = target
	return H.get_skill_level(/datum/skill/magic/arcane) > SKILL_LEVEL_NONE || H.get_skill_level(/datum/skill/magic/holy) > SKILL_LEVEL_NONE

/datum/ataman_squad/proc/target_channeling_spell()
	var/mob/living/target = get_target()
	if(!istype(target))
		return FALSE
	var/datum/action/cooldown/spell/casting = target.channeling_spell
	return istype(casting) && (casting.currently_charging || casting.charged)

/datum/ataman_squad/proc/target_channeling_escape_spell()
	if(!target_channeling_spell())
		return FALSE
	var/mob/living/target = get_target()
	var/datum/action/cooldown/spell/casting = target.channeling_spell
	return casting.spell_color == GLOW_COLOR_DISPLACEMENT

/datum/ataman_squad/proc/claim_mouth_grab(mob/living/carbon/target)
	if(istype(target) && ataman_target_mouth_secured(target))
		return FALSE
	if(world.time < mouth_claim_until)
		return FALSE
	mouth_claim_until = world.time + 8 SECONDS
	return TRUE

/datum/ataman_squad/proc/claim_guard(duration = 2 SECONDS)
	if(world.time < guard_claimed_until)
		return FALSE
	guard_claimed_until = world.time + duration
	return TRUE

/datum/ataman_squad/proc/claim_holder(mob/living/bandit)
	var/mob/living/holder = holder_ref?.resolve()
	if(holder == bandit)
		return TRUE
	if(istype(holder) && !QDELETED(holder) && holder.stat != DEAD)
		return FALSE
	holder_ref = WEAKREF(bandit)
	return TRUE

/datum/ataman_squad/proc/consider_feint(mob/living/carbon/human/attacker, mob/living/target, emergency = FALSE)
	if(!istype(attacker) || attacker.has_status_effect(/datum/status_effect/debuff/feintcd))
		return FALSE
	if(!istype(attacker.rmb_intent, /datum/rmb_intent/feint))
		return FALSE
	if(emergency)
		return TRUE
	if(feints_used == 0)
		return TRUE
	if(feints_used == 1)
		return world.time >= last_feint_at + 1 SECONDS
	return is_target_caster(target) || !ataman_last_feint_landed(target)

/datum/ataman_squad/proc/register_feint()
	feints_used++
	last_feint_at = world.time

/datum/ai_behavior/npc_kick_attack/ataman_low

/datum/ai_behavior/npc_kick_attack/ataman_low/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/mob/living/pawn = controller.pawn
	if(istype(pawn))
		pawn.zone_selected = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	return ..()

/datum/ai_planning_subtree/ataman_squad_tactics/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/npc/ataman_bandit/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(!squad)
		return
	ataman_recover_target(controller, pawn)
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(target) || target.stat == DEAD || ataman_target_is_secured(target) || !pawn.Adjacent(target))
		return

	var/role = controller.blackboard[BB_ATAMAN_ROLE]
	if(role != ATAMAN_ROLE_GRABBER && ishuman(target) && target.stat == CONSCIOUS)
		var/capture_zone = ataman_pick_capture_zone(pawn, target)
		if(capture_zone)
			controller.set_blackboard_key(BB_HUMAN_NPC_WEAKPOINT, list(capture_zone, world.time + 3 SECONDS, target))

	if(world.time < (controller.blackboard[BB_ATAMAN_TACTICS_COOLDOWN] || 0))
		return

	if(squad.target_channeling_escape_spell())
		if(squad.consider_feint(pawn, target, emergency = TRUE))
			squad.register_feint()
			ataman_ai_log(pawn, "TACTICS: [target] is casting an escape spell - emergency feint (squad feints_used=[squad.feints_used])")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE))
		else
			ataman_ai_log(pawn, "TACTICS: [target] casting an escape spell but I can't feint right now (feintcd/rmb_intent)")
		return SUBTREE_RETURN_FINISH_PLANNING

	if(role == ATAMAN_ROLE_ENFORCER && pawn.pulling != target && (pawn.mobility_flags & MOBILITY_STAND) && !pawn.IsOffBalanced() && pawn.get_num_legs() >= 2 && (target.mobility_flags & MOBILITY_STAND))
		var/walled_kick = length(target.grabbedby) >= 2 && ataman_target_is_walled(pawn, target)
		if(walled_kick || target.IsOffBalanced())
			ataman_ai_log(pawn, "TACTICS: kicking [target] ([walled_kick ? "held and walled" : "off balance"])")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			controller.queue_behavior(/datum/ai_behavior/npc_kick_attack/ataman_low, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		else if(length(target.grabbedby) >= 2)
			ataman_ai_log(pawn, "TACTICS: [target] held by [length(target.grabbedby)] grabs but nothing solid behind them - kick would whiff, skipping")

	if(role == ATAMAN_ROLE_BINDER && squad.is_target_caster(target) && ataman_try_mouth_grab(controller, pawn, target, squad))
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(squad.target_channeling_spell())
		if(!pawn.has_status_effect(/datum/status_effect/buff/clash) && squad.claim_guard())
			ataman_ai_log(pawn, "TACTICS: [target] is casting - guarding")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			pawn.try_guard()
		return SUBTREE_RETURN_FINISH_PLANNING

	if(role == ATAMAN_ROLE_ENFORCER && pawn.pulling != target && ataman_last_feint_landed(target) && squad.bites_used < 2 && get_location_accessible(target, BODY_ZONE_PRECISE_L_EYE))
		squad.bites_used++
		ataman_ai_log(pawn, "TACTICS: [target] is feinted and exposed - taking bite #[squad.bites_used]")
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		target.onbite(pawn)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(squad.consider_feint(pawn, target))
		squad.register_feint()
		ataman_ai_log(pawn, "TACTICS: staged feint #[squad.feints_used] on [target]")
		controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
		controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE))
		return SUBTREE_RETURN_FINISH_PLANNING

	return

/datum/ai_planning_subtree/ataman_leash/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/turf/spawn_turf = controller.blackboard[BB_ATAMAN_SPAWN_TURF]
	if(!spawn_turf)
		return
	var/mob/living/carbon/human/npc/ataman_bandit/pawn = controller.pawn
	if(!istype(pawn))
		return
	if(get_dist(pawn, spawn_turf) <= ATAMAN_LEASH_RANGE)
		return
	var/atom/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(target)
		ataman_ai_log(pawn, "LEASH: giving up on [target] - [get_dist(pawn, spawn_turf)] tiles from spawn (limit [ATAMAN_LEASH_RANGE]), heading home")
		if(pawn.pulling == target)
			pawn.stop_pulling()
		pawn.cmode = FALSE
		pawn.ataman_gave_up = TRUE
		controller.clear_blackboard_key(BB_ATAMAN_TARGET)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
	controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_ATAMAN_SPAWN_TURF)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/ataman_disarm_restrain/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/npc/ataman_bandit/pawn = controller.pawn
	ataman_recover_target(controller, pawn)
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(pawn) || !istype(target) || target.stat == DEAD)
		if(istype(pawn) && (controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] || controller.blackboard[BB_HIGHEST_THREAT_MOB]))
			ataman_ai_log(pawn, "CAPTURE: target [target] gone/dead, clearing")
			controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
			controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
			pawn.cmode = FALSE
		return SUBTREE_RETURN_FINISH_PLANNING

	if(ataman_target_is_secured(target))
		var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
		var/mob/living/owner_mob = controller.blackboard[BB_ATAMAN_OWNER]
		if(squad && !squad.owner_took_custody && owner_mob && target.pulledby == owner_mob)
			squad.owner_took_custody = TRUE
			ataman_ai_log(pawn, "CUSTODY: [owner_mob] took [target], the gang loses interest")
		if(squad && !squad.owner_took_custody && squad.claim_holder(pawn))
			controller.queue_behavior(/datum/ai_behavior/ataman_hold_secured, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] || pawn.pulling == target || pawn.cmode)
			ataman_ai_log(pawn, "CAPTURE: [target] is secured, standing down")
			controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
			controller.clear_blackboard_key(BB_HIGHEST_THREAT_MOB)
			if(pawn.pulling == target)
				pawn.stop_pulling()
			pawn.cmode = FALSE
		return SUBTREE_RETURN_FINISH_PLANNING

	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, target)
	var/role = controller.blackboard[BB_ATAMAN_ROLE]
	var/target_is_armed = target.get_active_held_item() || target.get_inactive_held_item()

	switch(role)
		if(ATAMAN_ROLE_GRABBER)
			if(!(target.mobility_flags & MOBILITY_STAND))
				ataman_ai_log(pawn, "CAPTURE: grabber -> hold (target down)")
				controller.queue_behavior(/datum/ai_behavior/ataman_hold, BB_ATAMAN_TARGET)
			else if(target_is_armed)
				ataman_ai_log(pawn, "CAPTURE: grabber -> disarm (target armed)")
				controller.queue_behavior(/datum/ai_behavior/ataman_disarm, BB_ATAMAN_TARGET)
			else
				ataman_ai_log(pawn, "CAPTURE: grabber -> hold (target unarmed)")
				controller.queue_behavior(/datum/ai_behavior/ataman_hold, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_BINDER)
			if(target.stat == CONSCIOUS && (target_is_armed || (target.mobility_flags & MOBILITY_STAND)))
				ataman_ai_log(pawn, "CAPTURE: binder not ready (armed=[target_is_armed ? "yes" : "no"] standing=[(target.mobility_flags & MOBILITY_STAND) ? "yes" : "no"]) - falling back to attacking")
				return
			ataman_ai_log(pawn, "CAPTURE: binder -> restrain")
			controller.queue_behavior(/datum/ai_behavior/ataman_restrain, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(ATAMAN_ROLE_ENFORCER)
			if(!target_is_armed || target.pulledby || !(target.mobility_flags & MOBILITY_STAND))
				return

	return

/datum/ai_behavior/ataman_disarm
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_disarm/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_disarm/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target))
		finish_action(controller, FALSE, target_key)
		return
	if(!pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return

	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(squad?.is_target_caster(target) && !ataman_target_mouth_secured(target))
		if(!get_location_accessible(target, BODY_ZONE_PRECISE_MOUTH))
			if(target.mobility_flags & MOBILITY_STAND)
				ataman_ai_log(pawn, "DISARM: [target] is a masked caster, headhunting instead of grabbing")
				controller.set_blackboard_key(BB_HUMAN_NPC_WEAKPOINT, list(BODY_ZONE_HEAD, world.time + 2 SECONDS, target))
				finish_action(controller, FALSE, target_key)
				return
		else if(pawn.pulling == target)
			finish_action(controller, TRUE, target_key)
			return
		else if(ataman_try_mouth_grab(controller, pawn, target, squad))
			finish_action(controller, TRUE, target_key)
			return

	var/obj/item/armed_hand = target.get_active_held_item() || target.get_inactive_held_item()
	if(!armed_hand)
		ataman_ai_log(pawn, "DISARM: [target] already unarmed, nothing to do")
		finish_action(controller, TRUE, target_key)
		return

	var/grab_limb = target.get_active_held_item() ? BODY_ZONE_PRECISE_R_HAND : BODY_ZONE_PRECISE_L_HAND
	var/obj/item/grabbing/grab_item = ataman_get_grab_on(pawn, target, grab_limb)
	if(!grab_item)
		if(!ataman_free_hands_for_grabbing(controller))
			ataman_ai_log(pawn, "DISARM: couldn't free a hand to grab [target]")
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = grab_limb
		if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = grab_limb))
			ataman_ai_log(pawn, "DISARM: grab on [grab_limb] failed to start")
			finish_action(controller, FALSE, target_key)
			return
		grab_item = ataman_get_grab_on(pawn, target, grab_limb)

	if(!grab_item || !ataman_make_grab_active(pawn, grab_item))
		ataman_ai_log(pawn, "DISARM: grab on [target] was lost before it could be used")
		finish_action(controller, FALSE, target_key)
		return

	pawn.update_grab_intents()
	pawn.update_a_intents()

	var/datum/intent/grab/disarm/disarm_intent
	for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
		if(istype(candidate, /datum/intent/grab/disarm))
			disarm_intent = candidate
			break

	if(!disarm_intent)
		ataman_ai_log(pawn, "DISARM: no disarm intent even with grab active (active=[pawn.get_active_held_item()])")
		finish_action(controller, FALSE, target_key)
		return

	ataman_ai_log(pawn, "DISARM: attempting disarm on [target] ([armed_hand])")
	pawn.a_intent = disarm_intent
	pawn.used_intent = disarm_intent
	controller.ai_interact(target, TRUE, TRUE)
	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/ataman_hold
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_hold/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_hold/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target) || !pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return

	var/obj/item/grabbing/torso_grab = ataman_get_grab_on(pawn, target, BODY_ZONE_CHEST)
	if(!torso_grab)
		if(!ataman_free_hands_for_grabbing(controller))
			ataman_ai_log(pawn, "HOLD: couldn't free a hand to reinforce the grip on [target]")
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = BODY_ZONE_CHEST
		if(!pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_CHEST))
			ataman_ai_log(pawn, "HOLD: torso grip on [target] failed to start")
			finish_action(controller, FALSE, target_key)
			return
		ataman_ai_log(pawn, "HOLD: reinforced the grip with a hold on [target]'s torso")
		torso_grab = ataman_get_grab_on(pawn, target, BODY_ZONE_CHEST)

	if(!torso_grab || !ataman_make_grab_active(pawn, torso_grab))
		finish_action(controller, FALSE, target_key)
		return

	if(target.mobility_flags & MOBILITY_STAND)
		pawn.update_grab_intents()
		pawn.update_a_intents()
		var/datum/intent/grab/shove/shove_intent
		for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
			if(istype(candidate, /datum/intent/grab/shove))
				shove_intent = candidate
				break
		if(shove_intent)
			ataman_ai_log(pawn, "HOLD: shoving [target]")
			pawn.a_intent = shove_intent
			pawn.used_intent = shove_intent
			controller.ai_interact(target, TRUE, TRUE)
		else
			ataman_ai_log(pawn, "HOLD: no shove intent even with torso grip active")
	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/ataman_hold_secured
	action_cooldown = 2 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_hold_secured/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_hold_secured/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/human/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || target.stat == DEAD || !ataman_target_is_secured(target))
		finish_action(controller, FALSE, target_key)
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	var/mob/living/owner_mob = controller.blackboard[BB_ATAMAN_OWNER]
	if(squad && !squad.owner_took_custody && owner_mob && target.pulledby == owner_mob)
		squad.owner_took_custody = TRUE
		ataman_ai_log(pawn, "CUSTODY: [owner_mob] took [target], releasing")
	if(squad?.owner_took_custody)
		if(pawn.pulling == target)
			pawn.stop_pulling()
		pawn.cmode = FALSE
		finish_action(controller, TRUE, target_key)
		return
	if(!pawn.Adjacent(target))
		finish_action(controller, FALSE, target_key)
		return

	if(squad?.is_target_caster(target) && !target.mouth && get_location_accessible(target, BODY_ZONE_PRECISE_MOUTH))
		var/obj/item/natural/cloth/rag = new(get_turf(target))
		if(target.equip_to_slot_if_possible(rag, SLOT_MOUTH, TRUE, TRUE))
			ataman_ai_log(pawn, "CUSTODY: gagged [target] with a rag")
			target.visible_message(span_warning("[pawn] stuffs a rag into [target]'s mouth!"))
		else
			qdel(rag)

	if(pawn.pulling != target)
		if(!ataman_free_hands_for_grabbing(controller))
			finish_action(controller, FALSE, target_key)
			return
		pawn.zone_selected = BODY_ZONE_CHEST
		if(pawn.start_pulling(target, GRAB_PASSIVE, item_override = BODY_ZONE_CHEST))
			ataman_ai_log(pawn, "CUSTODY: holding [target] until the ataman collects them")
	else if(target.mobility_flags & MOBILITY_STAND)
		var/obj/item/grabbing/torso_grab = ataman_get_grab_on(pawn, target, BODY_ZONE_CHEST)
		if(torso_grab && ataman_make_grab_active(pawn, torso_grab))
			pawn.update_grab_intents()
			pawn.update_a_intents()
			for(var/datum/intent/candidate as anything in pawn.possible_a_intents)
				if(istype(candidate, /datum/intent/grab/shove))
					pawn.a_intent = candidate
					pawn.used_intent = candidate
					controller.ai_interact(target, TRUE, TRUE)
					break
	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/ataman_restrain
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/ataman_restrain/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/ataman_restrain/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/target = controller.blackboard[target_key]
	if(!istype(pawn) || !istype(target) || QDELETED(target) || ataman_target_is_secured(target))
		finish_action(controller, FALSE, target_key)
		return
	if(!pawn.Adjacent(target) || (target.stat == CONSCIOUS && (target.mobility_flags & MOBILITY_STAND)))
		finish_action(controller, FALSE, target_key)
		return
	if(!ataman_free_hands_for_grabbing(controller))
		finish_action(controller, FALSE, target_key)
		return

	ataman_ai_log(pawn, "RESTRAIN: attempting to bind [target]")
	var/obj/item/rope/binding = new(pawn)
	if(!pawn.put_in_hands(binding))
		qdel(binding)
		finish_action(controller, FALSE, target_key)
		return
	binding.try_cuff_arms(target, pawn)
	if(QDELETED(pawn) || QDELETED(target) || QDELETED(controller) || controller.pawn != pawn)
		return
	if(!target.handcuffed && !QDELETED(binding))
		binding.try_cuff_legs(target, pawn)
	if(!target.handcuffed && !target.legcuffed && !QDELETED(binding))
		qdel(binding)
	ataman_ai_log(pawn, "RESTRAIN: result on [target] - handcuffed=[target.handcuffed ? "yes" : "no"] legcuffed=[target.legcuffed ? "yes" : "no"]")
	finish_action(controller, target.handcuffed || target.legcuffed, target_key)
