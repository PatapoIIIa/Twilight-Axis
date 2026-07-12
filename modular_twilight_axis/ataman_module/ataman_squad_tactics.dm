/// Reads the shared squad state and reacts to whatever the target is doing right
/// now. Priority: stop an escape attempt outright, knock a held-from-two-sides
/// target down so the binder can work, meet an ordinary cast with a guard, take
/// an opportunistic bite on an exposed face, and only then let the squad's
/// staged feint economy have a say before the generic melee subtree takes over.
/datum/ai_planning_subtree/ataman_squad_tactics/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(!squad)
		return
	var/mob/living/carbon/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(target) || target.stat == DEAD || ataman_target_is_secured(target) || !pawn.Adjacent(target))
		return
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

	var/role = controller.blackboard[BB_ATAMAN_ROLE]

	// Held from two sides and still on their feet - a kick only reliably drops them if
	// there's a wall behind them to slam into, same condition the base kick AI itself uses.
	if(role == ATAMAN_ROLE_ENFORCER && pawn.pulling != target && (target.mobility_flags & MOBILITY_STAND) && length(target.grabbedby) >= 2)
		if(ataman_target_is_walled(pawn, target))
			ataman_ai_log(pawn, "TACTICS: [target] held by [length(target.grabbedby)] grabs, walled - kicking")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			controller.queue_behavior(/datum/ai_behavior/npc_kick_attack, BB_ATAMAN_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		else
			ataman_ai_log(pawn, "TACTICS: [target] held by [length(target.grabbedby)] grabs but no wall behind them - kick would whiff, skipping")

	if(squad.target_channeling_spell())
		if(!pawn.has_status_effect(/datum/status_effect/buff/clash) && squad.claim_guard())
			ataman_ai_log(pawn, "TACTICS: [target] is casting - guarding")
			controller.set_blackboard_key(BB_ATAMAN_TACTICS_COOLDOWN, world.time + 1 SECONDS)
			pawn.try_guard()
		return SUBTREE_RETURN_FINISH_PLANNING

	// A feinted target with their face exposed is a free bite or two.
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
